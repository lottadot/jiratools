//
//  JTKTransition.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// The `JTKTransition` class represents a JIRA API Transition.
public class JTKTransition {
    
    var transitionId: String = "0"
    public var name: String = ""
    
    var status: JTKStatus?
    var statusCategory: JTKStatusCategory?
    
    init(transitionId: String, name: String) {
        self.transitionId = transitionId
        self.name = name
    }
    
    convenience public init(transitionId: String, name: String, status: JTKStatus, statusCategory: JTKStatusCategory) {
        self.init(transitionId: transitionId, name: name)
        self.status = status
        self.statusCategory = statusCategory
    }
    
    public static func withDictionary(dictionary: [String : AnyObject]) -> JTKTransition? {
        
        guard
            // The Transition is a Status and a StatusCategory
            let fakeId = dictionary["id"] as? String,
            let name = dictionary["name"] as? String,
            let statusJSON = dictionary["to"] as? [String: AnyObject],
            
            let statusUrl = statusJSON["self"] as? String,
            let statusName = statusJSON["name"] as? String,
            let statusId = statusJSON["id"] as? String,

            let serviceStatusCategoryJSON = statusJSON["statusCategory"] as? [String: AnyObject],
        
            let serviceCategoryId = serviceStatusCategoryJSON["id"] as? UInt,
            let serviceCategoryStatusUrl = serviceStatusCategoryJSON["self"] as? String,
            let serviceCategoryStatusKey = serviceStatusCategoryJSON["key"] as? String,
            let serviceCategoryStatusName = serviceStatusCategoryJSON["name"] as? String
            else {
                return nil
        }
        
        let status = JTKStatus.init(statusId: statusId, url: statusUrl, name: statusName)
        let statusCategory = JTKStatusCategory.init(categoryId: serviceCategoryId, url: serviceCategoryStatusUrl, key: serviceCategoryStatusKey, name: serviceCategoryStatusName)
        return JTKTransition.init(transitionId: fakeId, name: name, status: status, statusCategory: statusCategory)
     }
    
    public var description:String {
        return "Transition id:\(transitionId) name:\(name) status:\(status?.name) category:\(statusCategory?.name)"
    }
    
    public var debugDescription:String {
        return "Transition id:\(transitionId) name:\(name) status:\(status?.description) category:\(statusCategory?.description)"
    }
}