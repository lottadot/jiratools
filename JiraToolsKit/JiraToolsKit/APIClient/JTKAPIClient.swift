//
//  JTKAPIClient.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// The structure returned as of the result of an `JTKAPIClient` request
public struct JTKAPIClientResult {
    public var success = false
    public var error: NSError? = nil
    public var data: AnyObject? = nil
}

/// The Protocol used to provider `JTKAPIClientOperation`'s with required data.
public protocol JTKAPIClientOperatonDataProvider {
    func clientUsername() -> String
    func clientPassword() -> String
    func clientEndPoint() -> NSURL
}

/// The Jira Tools API Client
public class JTKAPIClient {
    
    private var endpointURL: NSURL!
    private var queue: NSOperationQueue!
    private var username: String!
    private var password: String!
    
    public init(endpointUrl: String, username: String, password: String) {

        guard let url = NSURL.init(string: endpointUrl) else {
            fatalError()
        }
        
        self.endpointURL = url
        self.username = username
        self.password = password
        
        self.queue = NSOperationQueue.init()
        self.queue.maxConcurrentOperationCount = 1
    }
    
    /// Get a Jira Issue.
    public func getIssue(issueIdOrKey: String, completion: (result: JTKAPIClientResult) -> ()) {
        // /rest/api/2/issue/{issueIdOrKey}

        // http://localhost:2990/jira/rest/api/2/issue/TP1-1
        
        let op = JTKAPIClientFetchIssueOperation.init(dataProvider: self, issueIdOrKey: issueIdOrKey)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.cancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult.init(success: nil != strongOp.issue, error: strongOp.error, data: strongOp.issue)
            completion(result: apiResult)
        }
        
        queue.addOperation(op)
    }
    
    /// Get a Jira Issue's Transitions
    public func getIssueTransitions(issue: JTKIssue, completion: (result: JTKAPIClientResult) -> ()) {
        // /rest/api/2/issue/{issueIdOrKey}/transitions

        // http://localhost:2990/jira/rest/api/2/issue/TP1-1/transitions
        
        let op = JTKAPIClientFetchIssueTransitions(dataProvider: self, issueIdOrKey: issue.key)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.cancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult.init(success: (nil == strongOp.error), error: strongOp.error, data: strongOp.transitions)
            completion(result: apiResult)
        }
        
        queue.addOperation(op)
    }
    
    /// Update a Jira Issue by applying a `JTKTransition` Transition. Can post an optional comment.
    public func transitionIssue(issue: JTKIssue, transition: JTKTransition, comment: String?, completion: (result: JTKAPIClientResult) -> ()) {
        
        let op = JTKAPIClientTransitionIssue(dataProvider: self, issue: issue, transition: transition, commentBody: comment)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.cancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult.init(success: nil == strongOp.error, error: strongOp.error, data: nil)
            completion(result: apiResult)
        }
        
        queue.addOperation(op)
    }
    
    /// Update a Jira Issue by posting a comment.
    public func commentOnIssue(issue: JTKIssue, comment: String?, completion: (result: JTKAPIClientResult) -> ()) {
        
        let op = JTKClientIssueComment(dataProvider: self, issue: issue, commentBody: comment)
        op.completionBlock = {
            [weak op] in
            guard let strongOp = op else {
                return
            }
            
            if strongOp.cancelled {
                return
            }
            
            let apiResult = JTKAPIClientResult.init(success: nil == strongOp.error, error: strongOp.error, data: nil)
            completion(result: apiResult)
        }
        
        queue.addOperation(op)
    }
}

// MARK: - JTKAPIClientOperatonDataProvider

extension JTKAPIClient: JTKAPIClientOperatonDataProvider {
    
    public func clientUsername() -> String {
        return self.username
    }
    
    public func clientPassword() -> String {
        return self.password
    }
    
    public func clientEndPoint() -> NSURL {
        return self.endpointURL
    }
}
