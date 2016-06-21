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
        public let issueid: String
        public let comment: String
        
        public static func create(endpoint: String)
            -> (username: String)
            -> (password: String)
            -> (issueid: String)
            -> (comment: String)
            -> Options {
                return { username in { password in { issueid in { comment in
                    return self.init(endpoint: endpoint,
                                     username: username,
                                     password: password,
                                     issueid: issueid,
                                     comment: comment)
                    } } } }
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
                                defaultValue: "", usage: "the Jira Ticket Id/Key")
                <*> m <| Option(key: "comment",
                                defaultValue: "", usage: "the comment to post to the issue. Optional.")
        }
    }
    
    public func run(options: Options) -> Result<(), JiraUpdaterError> {
        
        guard let url:String = options.endpoint,
            let user:String  = options.username,
            let pass:String  = options.password,
            let issueIdentifier:String  = options.issueid,
            let comment:String  = options.comment,
            let api:JTKAPIClient = JTKAPIClient.init(endpointUrl: url, username: user, password: pass)
            where !options.endpoint.isEmpty
                && !options.username.isEmpty
                && !options.password.isEmpty
                && !options.comment.isEmpty
            else {
                return .Failure(.InvalidArgument(description: "Missing values: endpoint, username, password, issueid and comment are required"))
        }
        
        let runLoop = CFRunLoopGetCurrent()
        
        api.getIssue(issueIdentifier) { (result) in
            guard let issue:JTKIssue = result.data as? JTKIssue where result.success else {
                if !result.success {
                    print(JiraUpdaterError.InvalidIssue(description: "Issue \(issueIdentifier) not found").description)
                    exit(EXIT_FAILURE)
                }
                CFRunLoopStop(runLoop)
                return
            }
            api.commentOnIssue(issue, comment: comment, completion: { (result) in
                if !result.success {
                    print(JiraUpdaterError.CommentFailed(description: "Comment on Issue \(issueIdentifier) failed").description)
                    exit(EXIT_FAILURE)
                }
                CFRunLoopStop(runLoop)
                return
            })
        }
        
        CFRunLoopRun()
        return .Success(())
    }
}