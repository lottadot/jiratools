//
//  JTKIssue.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// The `JTKIssue` class represents a JIRA API Issue.
public class JTKIssue {
    
    var issueId: String? = ""   // "10002"
    var url: String = ""        // "http://www.example.com/jira/rest/api/2/issue/10002"
    var key: String = ""        // "EX-1"
    var longDescription: String = "" // "example bug report"
    
    var status: JTKStatus?
    
    init(issueId: String, url: String, key: String, longDescription: String) {
        self.issueId = issueId
        self.url = url
        self.key = key
        self.longDescription = longDescription
    }
    
    convenience public init(issueId: String, url: String, key: String, longDescription: String, status: JTKStatus) {
        self.init(issueId: issueId, url: url, key: key, longDescription: longDescription)
        self.status = status
    }
    
    public static func withDictionary(dictionary: [String : AnyObject]) -> JTKIssue? {
    
        guard let fakeId = dictionary["id"] as? String,
            let fakeUrl = dictionary["self"] as? String,
            let fakeKey = dictionary["key"]  as? String,
            let fields = dictionary["fields"] as? [String: AnyObject],
            let desc = fields["description"] as? String else {
                return nil
            }
        
        let aIssue = JTKIssue.init(issueId: fakeId, url: fakeUrl, key: fakeKey, longDescription: desc)
        
        if let serviceStatus = fields["status"] as? [String: AnyObject],
            let serviceStatusId = serviceStatus["id"] as? String,
            let serviceStatusUrl = serviceStatus["self"] as? String,
            let serviceStatusName = serviceStatus["name"]  as? String  {
            
            aIssue.status = JTKStatus.init(statusId: serviceStatusId, url: serviceStatusUrl, name: serviceStatusName)
            
            if let serviceStatusCategoryJSON = serviceStatus["statusCategory"],
                let serviceStatusCategoryId = serviceStatusCategoryJSON["id"] as? UInt,
                let serviceStatusCategoryUrl = serviceStatusCategoryJSON["self"] as? String,
                let serviceStatusCategoryKey = serviceStatusCategoryJSON["key"]  as? String,
                let serviceStatusCategoryName = serviceStatusCategoryJSON["name"]  as? String {
                
                aIssue.status?.statusCategory = JTKStatusCategory.init(categoryId: serviceStatusCategoryId, url: serviceStatusCategoryUrl, key: serviceStatusCategoryKey, name: serviceStatusCategoryName)
            }
        }
    
        return aIssue
    }
    
    public var description:String {
        return "Issue id:\(issueId) url:\(url) key:\(key) status:\(status?.name)"
    }
    
    public var debugDescription:String {
        return "Issue id:\(issueId) url:\(url) key:\(key) status:\(status?.description)"
    }
}