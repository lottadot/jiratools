//
//  JTKClientIssueComment.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/14/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// A Network Operation to post a comment to a JIRA Issue.
public class JTKClientIssueComment: JTKAPIClientOperation {
    
    /// The Issue to Post to.
    private var issue: JTKIssue?
    
    /// The Comment Text to Post.
    private var commentBody: String!
    
    private typealias JTKAPIClientTransitionIssueComment = [ String : AnyObject]
    
    convenience public init(dataProvider: JTKAPIClientOperatonDataProvider, issue: JTKIssue, commentBody: String?) {
        self.init(url: dataProvider.clientEndPoint())
        self.dataProvider = dataProvider
        self.issue = issue
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
            let requestURL = NSURL.init(string: self.endpointURL.absoluteString + "/rest/api/2/issue/" + issueId + "/comment") else {
                
                self.error = JTKAPIClientNetworkError.createError(1001, statusCode: 1001, failureReason: "Cannot build Request URL")
                self.cancel()
                
                return
        }
        
        let urlRequest = NSMutableURLRequest(URL: requestURL)
        urlRequest.HTTPMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var uploadDictionary = Dictionary<String, AnyObject>()
        uploadDictionary["body"] = self.commentBody

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