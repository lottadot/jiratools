//
//  JTKAPIClientTransitionIssue.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// A Network Operation to Transition a Jira Issue to a different status. Can post optional comment.
public class JTKAPIClientTransitionIssue: JTKAPIClientOperation {

    
    private var issue: JTKIssue?
    private var transition: JTKTransition?
    private var commentBody: String?
   
    private typealias JTKAPIClientTransitionIssueComment = [ String : AnyObject]
    
    convenience public init(dataProvider: JTKAPIClientOperatonDataProvider, issue: JTKIssue, transition: JTKTransition, commentBody: String?) {
        self.init(url: dataProvider.clientEndPoint())
        self.dataProvider = dataProvider
        self.issue = issue
        self.transition = transition
        self.commentBody = commentBody
    }
    
    public override func start() {
        queuePriority = .Normal
        
        if cancelled {
            finished = true
            return
        }
        
        // /rest/api/2/issue/{issueIdOrKey}/transitions
        guard let issueId = issue?.issueId,
            let transitionToChangeTo = self.transition,
            //let transitionId = UInt32(transitionToChangeTo.transitionId),
            //let serviceTransitionId:NSNumber = NSNumber.init(unsignedInt: transitionId),
            let requestURL = NSURL.init(string: self.endpointURL.absoluteString + "/rest/api/2/issue/" + issueId + "/transitions?expand=transitions.fields") else {
            
            self.error = JTKAPIClientNetworkError.createError(1001, statusCode: 1001, failureReason: "Cannot build Request URL")
            self.cancel()
            
            return
        }
        
        let urlRequest = NSMutableURLRequest(URL: requestURL)
        urlRequest.HTTPMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var uploadDictionary = Dictionary<String, AnyObject>()
        var updates = Dictionary<String, AnyObject>()
        var comments:[JTKAPIClientTransitionIssueComment] = []
        let fields = Dictionary<String, AnyObject>()
        
        if let body = self.commentBody {
            let comment:JTKAPIClientTransitionIssueComment = [ "body" : body ]
            let add:[ String: AnyObject] = [ "add" : comment ]
            comments.append(add)
        }
        
        if comments.count > 0 {
            updates["comment"] = comments
        }
        
        if updates.keys.count > 0 {
            uploadDictionary["update"] = updates
        }
        
        //fields["resolution"] = [ "name" : "Ready For QA"]
        //fields["assignee"] = [ "name" : "" ]
        
        if fields.keys.count > 0 {
            uploadDictionary["fields"] = fields
        }
        
        uploadDictionary["transition"] = [ "id" : transitionToChangeTo.transitionId ]
        // po print(uploadDictionary)
        
        var uploadData: NSData
        
        do {
            uploadData = try NSJSONSerialization.dataWithJSONObject(uploadDictionary, options: [])
        } catch let error as NSError {
            self.error = error
            finished = true
            return
        }
        
        let task = urlSession.uploadTaskWithRequest(urlRequest, fromData: uploadData)
        task.resume()
    }
    
    override func handleResponse() {
        if cancelled {
            return
        }
        
        finished = true
        return
    }
}


