//
//  JTKIssueStatus.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// The `JTKStatus` class represents a JIRA API Status.
public class JTKStatus {

    var url: String = ""
    var name: String = ""
    var statusId: String = "0"
    
    var statusCategory: JTKStatusCategory?
    
    init(statusId: String, url: String, name: String) {
        self.statusId = statusId
        self.url = url
        self.name = name
    }
    
    convenience public init(statusId: String, url: String, name: String, statusCategory: JTKStatusCategory) {
        self.init(statusId: statusId, url: url, name: name)
        self.statusCategory = statusCategory
    }

    public static func withDictionary(dictionary: [String : AnyObject]) -> JTKStatus? {
        
        guard let fakeId = dictionary["id"] as? String,
            let fakeUrl = dictionary["self"] as? String,
            let name = dictionary["name"]  as? String else {
                return nil
        }
        
        guard let statusCategoryJSON = dictionary["statusCategory"] as? [String: AnyObject],
                let statusCategoryFakeId = statusCategoryJSON["id"] as? UInt,
                let statusCategoryFakeUrl = statusCategoryJSON["self"] as? String,
                let statusCategoryFakeKey = statusCategoryJSON["key"]  as? String,
                let statusCategoryName = statusCategoryJSON["name"]  as? String
        else {
            return JTKStatus.init(statusId: fakeId, url: fakeUrl, name: name)
        }

        let statusCategory = JTKStatusCategory.init(categoryId: statusCategoryFakeId,
                                                    url: statusCategoryFakeUrl,
                                                    key: statusCategoryFakeKey,
                                                    name: statusCategoryName)
    
        return JTKStatus.init(statusId: fakeId, url: fakeUrl, name: name, statusCategory: statusCategory)
    }
    
    public var description:String {
        return "Status id:\(statusId) url:\(url) name:\(name) categoryName:\(statusCategory?.name)"
    }
    
    public var debugDescription:String {
        return "Status id:\(statusId) url:\(url) name:\(name) category:\(statusCategory?.description)"
    }
}
