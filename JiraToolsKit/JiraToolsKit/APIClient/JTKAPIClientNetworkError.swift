//
//  JTKAPIClientNetworkError.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

import Foundation

public struct JTKAPIClientNetworkError {
    static let ErrorDomain = "com.lottadot.jiratoolkit"
    
    static let HttpStatusCode = "HttpStatusCode"
    
    enum Code: Int {
        case HttpError = -4000
    }
    
    public static func createError(code: Int, statusCode: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason, HttpStatusCode: statusCode] as [String: AnyObject]
        return NSError(domain: ErrorDomain, code: code, userInfo: userInfo)
    }
}

