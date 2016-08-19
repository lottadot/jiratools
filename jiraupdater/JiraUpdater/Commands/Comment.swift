//
//  Comment.swift
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

/// The Comment Jira Ticket subcommand
public struct CommentCommand: CommandType {
    public let verb = "comment"
    public let function = "Comment on a Jira Ticket"
    
    public struct Options: OptionsType {
        public let endpoint: String
        public let username: String
        public let password: String
        public let issueid: String?
        public let message: String
        public let issueids: String?
        
        public static func create(endpoint: String)
            -> (username: String)
            -> (password: String)
            -> (issueid: String)
            -> (message: String)
            -> (issueids: String)
            -> Options {
                return { username in { password in { issueid in { message in { issueids in
                    return self.init(endpoint: endpoint,
                                     username: username,
                                     password: password,
                                     issueid: issueid,
                                     message: message,
                                     issueids: issueids)
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
                <*> m <| Option(key: "issueid",
                                defaultValue: "", usage: "the Jira Ticket Id/Key. Optional.")
                <*> m <| Option(key: "message",
                                defaultValue: "", usage: "the message to post to the issue. Required.")
                <*> m <| Option(key: "issueids",
                                defaultValue: "", usage: "a comma delim'd list of issueids. Optional.")
        }
    }
    
    public func run(options: Options) -> Result<(), JiraUpdaterError> {
        
        guard let url:String = options.endpoint,
            let user:String  = options.username,
            let pass:String  = options.password,
            let issueIdentifier:String  = options.issueid,
            let message:String  = options.message,
            let issueIdentifiers: String = options.issueids,
            let api:JTKAPIClient = JTKAPIClient.init(endpointUrl: url, username: user, password: pass)
            where !options.endpoint.isEmpty
                && !options.username.isEmpty
                && !options.password.isEmpty
                && !options.message.isEmpty
                && (!options.issueid!.isEmpty || !options.issueids!.isEmpty)
            else {
                return .Failure(.InvalidArgument(description: "Missing values: endpoint, username, password, (issueids or issues) and transitionname are required"))
        }
        
        let runLoop = CFRunLoopGetCurrent()
        
        var issueids:[String] = []
        
        if let idents:String = issueIdentifiers, let identifiers:[String] = idents.componentsSeparatedByString(",") where !identifiers.isEmpty {
            print("found: \(identifiers)")
            issueids.appendContentsOf(identifiers)
        } else if let oneIssueIdentifier:String = issueIdentifier where oneIssueIdentifier.characters.count > 0 {
            issueids.append(oneIssueIdentifier)
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
            
            api.getIssue(identifier) { (result) in
                
                guard let issue:JTKIssue = result.data as? JTKIssue where result.success else {
                    if !result.success {
                        print(JiraUpdaterError.InvalidIssue(description: "Issue '\(identifier)' not found").description)
                        exit(EXIT_FAILURE)
                    }
                    CFRunLoopStop(runLoop)
                    return
                }
                
                api.commentOnIssue(issue, comment: message, completion: { (result) in
                    if !result.success {
                        print(JiraUpdaterError.CommentFailed(description: "Comment on Issue '\(identifier)' failed").description)
                        exit(EXIT_FAILURE)
                    }
                    CFRunLoopStop(runLoop)
                    return
                })
            }
        }
        
        CFRunLoopRun()
        return .Success(())
    }
}