//
//  Update.swift
//  jiraupdater
//
//  Created by Shane Zatezalo on 6/16/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation
import Swift
import JiraToolsKit
import Result
import Commandant
import ChangelogKit

/// The Update Jira Ticket subcommand
public struct UpdateCommand: CommandProtocol {
    public let verb = "update"
    public let function = "Update a Jira Ticket"
    
    public struct Options: OptionsProtocol {
        public let endpoint: String
        public let username: String
        public let password: String
        public let transitionname: String
        public let issueids: String
        public let comment: String?
        public let changelog: String?
        
        public static func create(_ endpoint: String)
            -> (_ username: String)
            -> (_ password: String)
            -> (_ transitionname: String)
            -> (_ issueids: String)
            -> (_ comment: String?)
            -> (_ changelog: String?)
            -> Options {
                return { username in { password in { transitionname in { issueids in { comment in { changelog in
                    return self.init(endpoint: endpoint,
                                     username: username,
                                     password: password,
                                     transitionname: transitionname,
                                     issueids: issueids,
                                     comment: comment,
                                     changelog: changelog)
                    } } } } } }
        }
        
        public static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<JiraUpdaterError>> {
            
            let env = ProcessInfo().environment
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
                <*> m <| Option(key: "issueids",
                                defaultValue: "", usage: "comma delim'd issue list. Required.")
                <*> m <| Option(key: "comment",
                                defaultValue: "", usage: "the comment to post to the issue. Optional.")
                <*> m <| Option(key: "changelog",
                                defaultValue: "", usage: "CHANGELOG absolute file path to use (instead of specifying issueIds")
        }
    }
    
    public func run(_ options: Options) -> Result<(), JiraUpdaterError> {
        
        let env = ProcessInfo().environment
        let endPointDefault:String? = env["JIRAUPDATER_ENDPOINT"]
        let userDefault:String? = env["JIRAUPDATER_USERNAME"]
        let passwordDefault:String? = env["JIRAUPDATER_PASSWORD"]
        
        
        let url:String = endPointDefault ?? options.endpoint
        let user:String  = userDefault ?? options.username
        let pass:String  = passwordDefault ?? options.password
        
        guard !user.isEmpty, !pass.isEmpty, !url.isEmpty else {
                return .failure(.invalidArgument(description: "Missing values: endpoint, username, password, changelog and transitionname are required"))
        }
        
        guard let changeLogFile:String = options.changelog, !options.transitionname.isEmpty, !options.issueids.isEmpty else {
                return .failure(.invalidArgument(description: "Missing values: Issues (issueids or issues) and transitionname are required"))
        }

        let api:JTKAPIClient = JTKAPIClient.init(endpointUrl: url, username: user, password: pass)
        let runLoop = CFRunLoopGetCurrent()
        
        let issueTransitionName:String  = options.transitionname
        var issueids:[String] = []
        let changelogFilePath:String = changeLogFile
        let path:URL = URL(fileURLWithPath: changelogFilePath)
        let rawNSString:NSString = try! NSString(contentsOf: path, encoding: String.Encoding.utf8.rawValue)
        let text:String = rawNSString as String
        
        if !text.isEmpty {

            var lines:[String] = []
            text.enumerateLines{ (line, stop) -> () in
                lines.append(line)
            }
            
            let cla = ChangelogAnalyzer(changelog: lines)
            if let tickets = cla.tickets() , !tickets.isEmpty {
                for ticket in tickets.reversed() {
                    if let ticketId = ticket.components(separatedBy: " ").first {
                        issueids.append(ticketId)
                    }
                }
            }
 
        } else {
            let ids = options.issueids.components(separatedBy: ",")
            issueids.append(contentsOf: ids)
        }
        
        if issueids.isEmpty {
            print(JiraUpdaterError.invalidIssue(description: "Issue Identifier(s) must provided. Use --issueids or --issueid.").description)
            exit(EXIT_FAILURE)
        }
        
        for identifier in issueids {
            
            guard identifier.characters.count > 0 else {
                print(JiraUpdaterError.invalidIssue(description: "Issue Identifier must be greater then zero characters in length").description)
                exit(EXIT_FAILURE)
            }
            
            self.updateIssue(api, issueId: identifier, withTransitionNamed: issueTransitionName, withComment: options.comment) { (result) in
                
                if !result.success {
                    
                    if let error = result.error {
                        print(JiraUpdaterError.commentFailed(description: error.description).description)
                    } else {
                        print(JiraUpdaterError.transitionFailed(description: "Update of Issue '\(identifier)' failed").description)
                    }
                    
                    CFRunLoopStop(runLoop)
                    exit(EXIT_FAILURE)
                } else {
                    
                    if !(options.comment?.isEmpty)! {
                        
                        self.commentIssue(api, issueId: identifier, commentBody: options.comment!, completion: { (result) in
                            if !result.success {
                                
                                if let error = result.error {
                                    print(JiraUpdaterError.commentFailed(description: error.localizedDescription).description)
                                } else {
                                    print(JiraUpdaterError.commentFailed(description: "Comment on Issue '\(identifier)' failed").description)
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
        return .success(())
    }
    
    /// Obtain an Issue
    fileprivate func getIssue(_ api: JTKAPIClient, issueId: String, completion: @escaping (_ result: JiraUpdaterResult) -> ()) {
        api.getIssue(issueId) { (result) in
            if let aIssue = result.data as? JTKIssue , result.success {
                completion(JiraUpdaterResult.init(success: true, error:nil, data: aIssue))
            } else {
                completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
            }
        }
    }
    
    /// Obtain an Issue's Transitions with JiraUpdater
    fileprivate func getTransitions(_ api: JTKAPIClient, issue: JTKIssue, completion: @escaping (_ result: JiraUpdaterResult) -> ()) {
        api.getIssueTransitions(issue) { (result) in
            
            if let transitions = result.data as? [JTKTransition] , result.success {
                completion(JiraUpdaterResult.init(success: true, error:nil, data: transitions as AnyObject?))
            } else {
                completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
            }
        }
    }
    
    /// Transition an Issue from it's current Status to another with a Transition
    fileprivate func transitionIssue(_ api: JTKAPIClient, issue: JTKIssue, transition: JTKTransition, completion: @escaping (_ result: JiraUpdaterResult) -> ()) {
        api.transitionIssue(issue, transition: transition, comment: nil) { (result) in
            completion(JiraUpdaterResult.init(success: result.success, error: result.error, data: nil))
        }
    }
    
    /// A transition of a specific name in a list of Transitions
    func transitionByName(_ transitions: [JTKTransition], transitionNameWanted name: String) -> JTKTransition? {
        return (transitions.filter { $0.name == name }).first
    }
    
    /// Update a Jira Issue with JiraUpdater
    func updateIssue(_ api: JTKAPIClient, issueId: String, withTransitionNamed name: String, withComment commentBody: String?, completion: @escaping (_ result: JiraUpdaterResult) -> ()) {
        
        self.getIssue(api, issueId: issueId) { (result) in
            
            guard let issue:JTKIssue = result.data as? JTKIssue , result.success else {
                completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                return
            }

            self.getTransitions(api, issue: issue, completion: { (result) in

                guard let transitions:[JTKTransition] = result.data as? [JTKTransition] , result.success else  {
                    completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                    return
                }
                
                guard let transition:JTKTransition = self.transitionByName(transitions, transitionNameWanted: name) else {
                    completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                    return
                }
                
                self.transitionIssue(api, issue: issue, transition: transition, completion: { (result) in

                    if !result.success {
                        completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                    } else {
                        completion(JiraUpdaterResult.init(success: true, error: nil, data: nil))
                    }
                })
            })
        }
    }
    
    /// Comment on an Issue with JiraUpdater
    func commentIssue(_ api: JTKAPIClient, issueId: String, commentBody: String, completion: @escaping (_ result: JiraUpdaterResult) -> ()) {
        
        self.getIssue(api, issueId: issueId) { (result) in
            guard let issue:JTKIssue = result.data as? JTKIssue , result.success else {
                completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                return
            }
            
            api.commentOnIssue(issue, comment: commentBody, completion: { (result) in
                if !result.success {
                    completion(JiraUpdaterResult.init(success: false, error: result.error, data: nil))
                } else {
                    completion(JiraUpdaterResult.init(success: true, error: nil, data: nil))
                }

            })
        }
    }
}
