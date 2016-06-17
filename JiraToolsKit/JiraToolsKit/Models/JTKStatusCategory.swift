//
//  JTKStatusCategory.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// The `JTKStatusCategory` class represents a JIRA API StatusCategory.
public class JTKStatusCategory {

    var url: String = ""
    var categoryId: UInt = 0
    var key: String = ""
    var name: String = ""
    
    init(categoryId: UInt, url: String, key: String, name: String) {
        self.categoryId = categoryId
        self.url = url
        self.key = key
        self.name = name
    }

    public static func withDictionary(dictionary: [String : AnyObject]) -> JTKStatusCategory? {
        
        guard let fakeId = dictionary["id"] as? UInt,
            let fakeUrl = dictionary["self"] as? String,
            let fakeKey = dictionary["key"]  as? String,
            let name = dictionary["name"]  as? String else {
                return nil
        }
        
        return JTKStatusCategory.init(categoryId: fakeId, url: fakeUrl, key: fakeKey, name: name)
    }
    
    public var description:String {
        return "StatusCategory id:\(categoryId) url:\(url) name:\(name) key:\(key)"
    }
    
    public var debugDescription:String {
        return "StatusCategory id:\(categoryId) url:\(url) name:\(name) key:\(key)"
    }
}