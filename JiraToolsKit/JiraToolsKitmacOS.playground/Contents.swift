//: Playground - noun: a place where people can play

import Cocoa
import JiraToolsKit
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

var str = "Hello, playground"

let endPoint = "http://localhost:2990/jira"
let username = ""
let password = ""
let issueId = "MOBAPITEST-1"

var issue:JTKIssue? = nil

let api = JTKAPIClient.init(endpointUrl: endPoint, username: username, password: password)

api.getIssue(issueId) { (result) in
    
    if let error = result.error {
        print("Failure: \(error.localizedDescription)")
    } else {
        print("Success: \(result.data)")
        if let responseData = result.data, let foundIssue:JTKIssue = responseData as? JTKIssue {
            
            issue = foundIssue
            
            print("issue: \(foundIssue.description)")
            
            api.getIssueTransitions(foundIssue, completion: { (result) in
                
                if result.success {
                    
                    
                    if let responseData = result.data, let transitions:[JTKTransition] = responseData as? [JTKTransition] {
                        print("transitions: \(transitions)")
                    }
                } else {
                    print("transitions failed")
                    
                }
                XCPlaygroundPage.currentPage.finishExecution()
            })
        } else {
            XCPlaygroundPage.currentPage.finishExecution()
        }
    }
}

//XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
