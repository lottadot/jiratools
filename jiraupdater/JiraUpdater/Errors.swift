//
//  Errors.swift
//  JiraUpdater
//
//  Created by Shane Zatezalo on 6/15/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// Possible errors that can originate from JiraUpdater.
public enum JiraUpdaterError: Error, Equatable {
    
    /// One or more arguments was invalid.
    case invalidArgument(description: String)
    
    /// Transition not found
    case invalidTransition(description: String)
    
    /// Transition failed
    case transitionFailed(description: String)
    
    /// Issue not found
    case invalidIssue(description: String)
    
    /// Comment Failed
    case commentFailed(description: String)
}

public func == (lhs: JiraUpdaterError, rhs: JiraUpdaterError) -> Bool {
    switch (lhs, rhs) {
    case let (.invalidArgument(left), .invalidArgument(right)):
        return left == right
    
    default:
        return false
    }
}

extension JiraUpdaterError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .invalidArgument(description):
            return description
          
        case let .invalidTransition(description):
            return description

        case let .transitionFailed(description):
            return description

        case let .invalidIssue(description):
            return description
            
        case let .commentFailed(description):
            return description

        }
    }
}
