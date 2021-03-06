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
public struct ChangelogCommand: CommandProtocol {
    public let verb = "changelog"
    public let function = "Update Jira tickets from a Changelog"
    
    public struct Options: OptionsProtocol {
        public let endpoint: String
        public let username: String
        public let password: String
        public let transitionname: String
        public let comment: String
        public let file: String?
        
        public static func create(_ endpoint: String)
            -> (_ username: String)
            -> (_ password: String)
            -> (_ transitionname: String)
            -> (_ comment: String)
            -> (_ file: String?)
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
        
        public static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<JiraUpdaterError>> {

            
            return create
                <*> m <| Option(key: "endpoint", defaultValue: "",
                                usage: "the JIRA API EndPoint URL ie http://jira.example.com/")
                <*> m <| Option(key: "username",
                                defaultValue: "", usage: "the username to authenticate with")
                <*> m <| Option(key: "password",
                                defaultValue: "", usage: "the password to authenticate with")
                <*> m <| Option(key: "transitionname",
                                defaultValue: "QA Ready", usage: "the Jira Transition to apply ie 'QA Ready'")
                <*> m <| Option(key: "comment",
                                defaultValue: "Ready for QA in {VERSION} #{BUILDNUMBER}.", usage: "the templated ({VERSION}, {BUILDNUMBER}) comment to post to the issue. Optional.")
                <*> m <| Option(key: "file",
                                defaultValue: "CHANGELOG", usage: "The absolute path of the changelog file to use.")
        }
    }
    
    public func run(_ options: Options) -> Result<(), JiraUpdaterError> {
        
        let env = ProcessInfo().environment
        let endPointDefault:String? = env["JIRAUPDATER_ENDPOINT"]
        let userDefault:String? = env["JIRAUPDATER_USERNAME"]
        let passwordDefault:String? = env["JIRAUPDATER_PASSWORD"]
        
        let comment:String = options.comment
        let url:String = endPointDefault ?? options.endpoint
        let user:String  = userDefault ?? options.username
        let pass:String  = passwordDefault ?? options.password
        let file:String = options.file ?? "CHANGELOG"
        
        guard !file.isEmpty
                && !user.isEmpty
                && !pass.isEmpty
                && !url.isEmpty
            else {
                return .failure(.invalidArgument(description: "Missing values: endpoint, username, password, changelog and transitionname are required"))
        }
        
        
        let issueTransitionName:String  = options.transitionname
        let api:JTKAPIClient = JTKAPIClient.init(endpointUrl: url, username: user, password: pass)
        
        do {
            let path = URL(fileURLWithPath: file)
            //let text = try String(contentsOf: path)
            let text = try String(contentsOf: path, encoding: .utf8)
            let lines = self.getChangelogLines(text: text)
            let log:ChangelogAnalyzer = ChangelogAnalyzer(changelog: lines)
            
            guard let versionString:String = log.buildVersionString(),
                let buildNumber:UInt = log.buildNumber(),
                let tickets = log.tickets(),
                let issueids:[String] = self.ticketIdsForTickets(tickets),
                !log.isTBD() && !tickets.isEmpty && !issueids.isEmpty else {
                    
                        print(JiraUpdaterError.invalidIssue(description: "Issue Identifier(s) must provided. Use --issueids or --issueid.").description)
                        return .failure(.invalidArgument(description: "Changelog has no date, is TBD or has no Jira Issue Identifiers"))
                        //exit(EXIT_FAILURE)
            }

            let buildNumberString:String = String(buildNumber)
            let postableComment:String = self.untemplateComment(comment, version: versionString, buildNumber: buildNumberString)
            
            guard !postableComment.isEmpty else {
                print(JiraUpdaterError.invalidComment(description: "Changelog updating requires postable comment text").description)
                exit(EXIT_FAILURE)
            }

            guard !issueTransitionName.isEmpty else {
                print(JiraUpdaterError.invalidComment(description: "Changelog updating requires transition name").description)
                exit(EXIT_FAILURE)
            }
            
            let runLoop = CFRunLoopGetCurrent()
            
            self.performChangeLog(ids: issueids, comment: postableComment, apiClient: api, transitionName: issueTransitionName, completion: { (result) in

                CFRunLoopStop(runLoop)
            })
                
            CFRunLoopRun()
            return .success(())
        } catch let error as NSError {
            return .failure(.invalidArgument(description: error.localizedDescription))
        }
    }
    
    /// Performs the actions on tickets based off Changelog information.
    ///
    /// We deem success upon all ticket updates and comment posting successfull completion.
    ///
    /// - Parameters:
    ///   - ids: Array of the Ticket Identifiers
    ///   - comment: The text of the comment to post.
    ///   - api: The API Client to use.
    ///   - transition: The name of the Transition to apply to each ticket.
    ///   - completion: The completion block to execute.
    fileprivate func performChangeLog(ids: [String], comment: String, apiClient api: JTKAPIClient, transitionName transition: String,  completion: @escaping (_ result: JiraUpdaterResult) -> ()) {
        
        guard !comment.isEmpty, !transition.isEmpty, !ids.isEmpty else {
            print("performChangeLog requires transition (\transition) comment:\(comment) and ids:\(ids)")
            completion(JiraUpdaterResult.init(success: false, error: nil, data: nil))
            return
        }
        
        // Tracks failure count. We deem success upon all ticket updates and comment posting successfull completion.
        var failures = 0
        
        //let queue = DispatchQueue(label: "com.lottadot.jiraupdater.changelog.dispatchgroup", attributes: .concurrent, target: .main)
        let queue = DispatchQueue(label: "com.lottadot.jiraupdater.changelog.dispatchgroup.serial")
        let group = DispatchGroup()
        
        for identifier in ids {
            
            guard identifier.characters.count > 2 else {
                print(JiraUpdaterError.invalidIssue(description: "Issue Identifier must be greater then zero characters in length").description)
                continue
            }

            group.enter()
            queue.async(group: group) {
                
                self.updateIssue(api, issueId: identifier, withTransitionNamed: transition, withComment: nil) { (result) in
                    
                    if !result.success {
                        failures = failures + 1
                        if let error = result.error {
                            print(JiraUpdaterError.commentFailed(description: error.description).description)
                        } else {
                            print(JiraUpdaterError.transitionFailed(description: "Update of Issue '\(identifier)' failed").description)
                        }
                        group.leave()
                        
                    } else {
                        
                        
                        self.commentIssue(api, issueId: identifier, commentBody: comment, completion: { (result) in
                            
                            if !result.success {
                                failures = failures + 1
                                print("Commented FAIL\(identifier)")
                                if let error = result.error {
                                    print(JiraUpdaterError.commentFailed(description: error.localizedDescription).description)
                                } else {
                                    print(JiraUpdaterError.commentFailed(description: "Comment on Issue '\(identifier)' failed").description)
                                }
                            }
                            group.leave()
                        })
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion(JiraUpdaterResult.init(success: (failures == 0), error: nil, data: nil))
        }
    }
    
    /// Obtain each line from the Changelog
    fileprivate func getChangelogLines(text: String) -> [String] {
        var lines:[String] = []
        text.enumerateLines{ (line, stop) -> () in
            lines.append(line)
        }
        return lines
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
    
    func untemplateComment(_ templatedComment: String, version: String, buildNumber: String) -> String {
        var parsed = templatedComment
        parsed = parsed.replacingOccurrences(of: "{VERSION}", with: version, options: NSString.CompareOptions.literal, range: nil)
        parsed = parsed.replacingOccurrences(of: "{BUILDNUMBER}", with: buildNumber, options: NSString.CompareOptions.literal, range: nil)
        return parsed
    }
    
    /// Build a list of Ticket ID's from Issue line text from a changelog.
    ///
    /// - Parameter tickets: An array of strings representing the Issue lines from the file.
    /// - Returns: An array of the Ticket ID's (id SDK-123) or nil if none.
    func ticketIdsForTickets(_ tickets: [String]) -> [String]? {
        
        var ticketIds:[String] = []
        
        for ticket in tickets.reversed() {
            if let ticketId = ticket.components(separatedBy: " ").first, !ticket.isEmpty {
                ticketIds.append(ticketId)
            }
        }
        
        return ticketIds.count > 0 ? ticketIds : nil
    }
}
