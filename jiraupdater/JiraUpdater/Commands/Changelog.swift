//
//  Changelog.swift
//  jiraupdater
//
//  Created by Shane Zatezalo on 8/22/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation
import Swift
import JiraToolsKit
import Result
import Commandant
import ChangelogKit

/// Update Jira based on a CHANGELOG
public struct ChangelogCommand: CommandType {
    public let verb = "changelog"
    public let function = "Update Jira tickets from a Changelog"
    
    public struct Options: OptionsType {
        public let endpoint: String
        public let username: String
        public let password: String
        public let transitionname: String
        public let comment: String
        public let file: String?
        
        public static func create(endpoint: String)
            -> (username: String)
            -> (password: String)
            -> (transitionname: String)
            -> (comment: String)
            -> (file: String?)
            -> Options {
                return { username in { password in { transitionname in { comment in { file in
                    return self.init(endpoint: endpoint,
                                     username: username,
                                     password: password,
                                     transitionname: transitionname,
                                     comment: comment,
                                     file: file)
                    } } } } }
        }
        
        public static func evaluate(m: CommandMode) -> Result<Options, CommandantError<JiraUpdaterError>> {
            
            let env = NSProcessInfo().environment
            let endPointDefault = env["JIRAUPDATER_ENDPOINT"] ?? ""
            let userDefault = env["JIRAUPDATER_USERNAME"] ?? ""
            let passwordDefault = env["JIRAUPDATER_PASSWORD"] ?? ""
            
            return create
                <*> m <| Option(key: "endpoint", defaultValue: endPointDefault,
                                usage: "the JIRA API EndPoint URL ie http://jira.example.com/")
                <*> m <| Option(key: "username",
                                defaultValue: userDefault, usage: "the username to authenticate with")
                <*> m <| Option(key: "password",
                                defaultValue: passwordDefault, usage: "the password to authenticate with")
                <*> m <| Option(key: "transitionname",
                                defaultValue: "", usage: "the Jira Transition to apply ie 'QA Ready'")
                <*> m <| Option(key: "comment",
                                defaultValue: "Ready for QA in {VERSION} #{BUILDNUMBER}.", usage: "the templated ({VERSION}, {BUILDNUMBER}) comment to post to the issue. Optional.")
                <*> m <| Option(key: "file",
                                defaultValue: "CHANGELOG", usage: "The absolute path of the changelog file to use.")
        }
    }
    
    public func run(options: Options) -> Result<(), JiraUpdaterError> {
        
        guard let url:String = options.endpoint,
            let user:String  = options.username,
            let pass:String  = options.password,
            let issueTransitionName:String  = options.transitionname,
            let file:String = options.file,
            let api:JTKAPIClient = JTKAPIClient.init(endpointUrl: url, username: user, password: pass),
            let comment:String = options.comment
            where !options.endpoint.isEmpty
                && !options.username.isEmpty
                && !options.password.isEmpty
                && !options.transitionname.isEmpty
            else {
                return .Failure(.InvalidArgument(description: "Missing values: endpoint, username, password, changelog and transitionname are required"))
        }
        
        let runLoop = CFRunLoopGetCurrent()

        do {
            let path = NSURL(fileURLWithPath: file)
            let text = try NSString(contentsOfURL: path, encoding: NSUTF8StringEncoding) as String
            var lines:[String] = []
            text.enumerateLines { lines.append($0.line)}
            
            guard
                let log:ChangelogAnalyzer = ChangelogAnalyzer(changelog: lines),
                let versionString:String = log.buildVersionString(),
                let buildNumber:UInt = log.buildNumber(),
                let buildNumberString:String = String(buildNumber),
                let postableComment:String = self.untemplateComment(comment, version: versionString, buildNumber: buildNumberString),
                let tickets:[String] = log.tickets(),
                let issueids:[String] = self.ticketIdsForTickets(tickets)
                where !log.isTBD() && !tickets.isEmpty else {
                return .Failure(.InvalidArgument(description: "Changelog has no date, is TBD or has no Jira Issue Identifiers"))
            }

            if issueids.isEmpty {
                print(JiraUpdaterError.InvalidIssue(description: "Issue Identifier(s) must provided. Use --issueids or --issueid.").description)
                exit(EXIT_FAILURE)
            }
            
            for identifier in issueids {
                
                guard identifier.characters.count > 0 else {
                    print(JiraUpdaterError.InvalidIssue(description: "Issue Identifier must be greater then zero characters in length").description)
                    exit(EXIT_FAILURE)
                }
                
                self.updateIssue(api, issueId: identifier, withTransitionNamed: issueTransitionName, withComment: nil) { (result) in
                    
                    if !result.success {
                        
                        if let error = result.error {
                            print(JiraUpdaterError.CommentFailed(description: error.description).description)
                        } else {
                            print(JiraUpdaterError.TransitionFailed(description: "Update of Issue '\(identifier)' failed").description)
                        }
                        
                        CFRunLoopStop(runLoop)
                        exit(EXIT_FAILURE)
                    } else {
                        
                        if !postableComment.isEmpty {
                            self.commentIssue(api, issueId: identifier, commentBody: postableComment, completion: { (result) in
                                if !result.success {
                                    
                                    if let error = result.error {
                                        print(JiraUpdaterError.CommentFailed(description: error.localizedDescription).description)
                                    } else {
                                        print(JiraUpdaterError.CommentFailed(description: "Comment on Issue '\(identifier)' failed").description)
                                    }
                                    exit(EXIT_FAILURE)
                                }
                                CFRunLoopStop(runLoop)
                            })
                        } else {
                            CFRunLoopStop(runLoop)
                        }
                    }
                }
            }
            
            CFRunLoopRun()
            return .Success(())
            
        } catch let error as NSError {
            return .Failure(.InvalidArgument(description: error.localizedDescription))
        }
    }
    
    /// Obtain an Issue
    private func getIssue(api: JTKAPIClient, issueId: String, completion: (result: JiraUpdaterResult) -> ()) {
        api.getIssue(issueId) { (result) in
            if let aIssue = result.data as? JTKIssue where result.success {
                completion(result: JiraUpdaterResult.init(success: true, error:nil, data: aIssue))
            } else {
                completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
            }
        }
    }
    
    /// Obtain an Issue's Transitions with JiraUpdater
    private func getTransitions(api: JTKAPIClient, issue: JTKIssue, completion: (result: JiraUpdaterResult) -> ()) {
        api.getIssueTransitions(issue) { (result) in
            
            if let transitions = result.data as? [JTKTransition] where result.success {
                completion(result: JiraUpdaterResult.init(success: true, error:nil, data: transitions))
            } else {
                completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
            }
        }
    }
    
    /// Transition an Issue from it's current Status to another with a Transition
    private func transitionIssue(api: JTKAPIClient, issue: JTKIssue, transition: JTKTransition, completion: (result: JiraUpdaterResult) -> ()) {
        api.transitionIssue(issue, transition: transition, comment: nil) { (result) in
            completion(result: JiraUpdaterResult.init(success: result.success, error: result.error, data: nil))
        }
    }
    
    /// A transition of a specific name in a list of Transitions
    func transitionByName(transitions: [JTKTransition], transitionNameWanted name: String) -> JTKTransition? {
        return (transitions.filter { $0.name == name }).first
    }
    
    /// Update a Jira Issue with JiraUpdater
    func updateIssue(api: JTKAPIClient, issueId: String, withTransitionNamed name: String, withComment commentBody: String?, completion: (result: JiraUpdaterResult) -> ()) {
        
        self.getIssue(api, issueId: issueId) { (result) in
            
            guard let issue:JTKIssue = result.data as? JTKIssue where result.success else {
                completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                return
            }
            
            self.getTransitions(api, issue: issue, completion: { (result) in
                
                guard let transitions:[JTKTransition] = result.data as? [JTKTransition] where result.success else  {
                    completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                    return
                }
                
                guard let transition:JTKTransition = self.transitionByName(transitions, transitionNameWanted: name) else {
                    completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                    return
                }
                
                self.transitionIssue(api, issue: issue, transition: transition, completion: { (result) in
                    
                    if !result.success {
                        completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                    } else {
                        completion(result: JiraUpdaterResult.init(success: true, error: nil, data: nil))
                    }
                })
            })
        }
    }
    
    /// Comment on an Issue with JiraUpdater
    func commentIssue(api: JTKAPIClient, issueId: String, commentBody: String, completion: (result: JiraUpdaterResult) -> ()) {
        
        self.getIssue(api, issueId: issueId) { (result) in
            guard let issue:JTKIssue = result.data as? JTKIssue where result.success else {
                completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                return
            }
            
            api.commentOnIssue(issue, comment: commentBody, completion: { (result) in
                if !result.success {
                    completion(result: JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                } else {
                    completion(result: JiraUpdaterResult.init(success: true, error: nil, data: nil))
                }
                
            })
        }
    }
    
    func untemplateComment(templatedComment: String, version: String, buildNumber: String) -> String {
        var parsed = templatedComment
        parsed = parsed.stringByReplacingOccurrencesOfString("{VERSION}", withString: version, options: NSStringCompareOptions.LiteralSearch, range: nil)
        parsed = parsed.stringByReplacingOccurrencesOfString("{BUILDNUMBER}", withString: buildNumber, options: NSStringCompareOptions.LiteralSearch, range: nil)
        return parsed
    }
    
    func ticketIdsForTickets(tickets: [String]) -> [String] {
        
        var ticketIds:[String] = []
        
        for ticket in tickets.reverse() {
            if let ticketId = ticket.componentsSeparatedByString(" ").first {
                ticketIds.append(ticketId)
            }
        }
        
        return ticketIds
    }
}
