//
//  Errors.swift
//  JiraUpdater
//
//  Created by Shane Zatezalo on 6/15/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// Possible errors that can originate from JiraUpdater.
public enum JiraUpdaterError: ErrorType, Equatable {
    
    /// One or more arguments was invalid.
    case InvalidArgument(description: String)
    
    /// Transition not found
    case InvalidTransition(description: String)
    
    /// Transition failed
    case TransitionFailed(description: String)
    
    /// Issue not found
    case InvalidIssue(description: String)
    
    /// Comment Failed
    case CommentFailed(description: String)
}

public func == (lhs: JiraUpdaterError, rhs: JiraUpdaterError) -> Bool {
    switch (lhs, rhs) {
    case let (.InvalidArgument(left), .InvalidArgument(right)):
        return left == right
    
    default:
        return false
    }
}

extension JiraUpdaterError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .InvalidArgument(description):
            return description
          
        case let .InvalidTransition(description):
            return description

        case let .TransitionFailed(description):
            return description

        case let .InvalidIssue(description):
            return description
            
        case let .CommentFailed(description):
            return description

        }
    }
}
