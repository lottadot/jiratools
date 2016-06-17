//
//  JTKAPIClientFetchIssueTransitions.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// A Network Operation to Get a JIRA Issue's Transitions (from Workflows)
public class JTKAPIClientFetchIssueTransitions: JTKAPIClientOperation {
    
    public var transitions: [JTKTransition] = []
    private var issueIdOrKey: String?
    
    convenience public init(dataProvider: JTKAPIClientOperatonDataProvider, issueIdOrKey: String) {
        self.init(url: dataProvider.clientEndPoint())
        self.dataProvider = dataProvider
        self.issueIdOrKey = issueIdOrKey
    }
    
    public override func start() {
        queuePriority = .Normal
        
        if cancelled {
            finished = true
            return
        }
        
        // /rest/api/2/issue/{issueIdOrKey}/transitions
        guard let issueId = issueIdOrKey, let requestURL = NSURL.init(string: self.endpointURL.absoluteString + "/rest/api/2/issue/" + issueId + "/transitions") else {
            
            self.error = JTKAPIClientNetworkError.createError(1001, statusCode: 1001, failureReason: "Cannot build Request URL")
            self.cancel()
            
            return
        }
        
        let urlRequest = NSMutableURLRequest(URL: requestURL)
        urlRequest.HTTPMethod = "GET"

        let task = self.urlSession.dataTaskWithRequest(urlRequest)
        task.resume()
    }
    
    override func handleResponse() {
        do {
            
            if cancelled {
                return
            }
            
            guard let rawdata:NSData = self.receivedData,
                let json:[String : AnyObject] = try NSJSONSerialization.JSONObjectWithData(rawdata, options: NSJSONReadingOptions.MutableContainers) as? [String : AnyObject] else {
                    
                    self.error = JTKAPIClientNetworkError.createError(1002, statusCode: 1002, failureReason: "Could not convert JSON")
                    self.cancel()
                    
                    return
            }
            
            guard let serviceTransitions = json["transitions"] as? [[String: AnyObject]] else {
                self.error = JTKAPIClientNetworkError.createError(1003, statusCode: 1003, failureReason: "Could not convert Issue JSON")
                self.cancel()
                finished = true

                return
            }
            
            for serviceTransition in serviceTransitions {                
                if let transition = JTKTransition.withDictionary(serviceTransition) {
                    transitions.append(transition)
                }
            }
            
            finished = true
            return
        }
        catch (_) {
            self.error = JTKAPIClientNetworkError.createError(1002, statusCode: 1002, failureReason: "Error Converting JSON")
            self.cancel()
            return
        }
    }
    
}
