//
//  JiraToolsKitTests.swift
//  JiraToolsKitTests
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import XCTest
@testable import JiraToolsKit

class JiraToolsKitTests: XCTestCase {
    
    lazy var issueId: String = {
        return "HGVMQA-695"
    }()
    
    lazy var commentBody: String = {
        return "Build packaged by CI Buildbot with JiraToolsKit. Ready for QA in 2.0.0 #90 / 2016-06-15"
    }()
    
    lazy var apiClient: JTKAPIClient = {
        let endoint  = "http://localhost:2990/jira"
        let username = "username"
        let password = "password"

        let client = JTKAPIClient.init(endpointUrl: endPoint, username: username, password: password)
        return client
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetIssue() {

        // https://developer.apple.com/library/tvos/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/04-writing_tests.html#//apple_ref/doc/uid/TP40014132-CH4-SW6
        let asyncExpectation = expectationWithDescription("getIssue")

        apiClient.getIssue(self.issueId) { (result) in
            
            XCTAssertTrue(result.success, "GetIssue Success Failure")
            // On a success, the API Result's error should be nil
            XCTAssertNil(result.error, "Error: \(result.error)")
            // On a success, the API Result's data should not be nil
            XCTAssertNotNil(result.data)
            
            if let responseData = result.data, let issue:JTKIssue = responseData as? JTKIssue {
                XCTAssertNotNil(issue, "Issue Received from Service is Nil")
            } else {
                XCTFail()
            }
            
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(30) { error in
            //XCTAssertNotNil(error, "Test Never Finsihed")
        }
    }
    
    func testGetIssueFailure() {
        let asyncExpectation = expectationWithDescription("getIssue")
        
        apiClient.getIssue("bahahaha") { (result) in
            
            XCTAssertFalse(result.success, "GetIssue Success Failure")
            // On a success, the API Result's error should be nil
            XCTAssertNotNil(result.error, "Error: \(result.error)")
            // On a success, the API Result's data should not be nil
            XCTAssertNil(result.data)
            
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(30) { error in
        }
    }
    
    func testGetIssueTransitions() {
        
        // https://developer.apple.com/library/tvos/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/04-writing_tests.html#//apple_ref/doc/uid/TP40014132-CH4-SW6
        let asyncExpectation = expectationWithDescription("getIssue")
        let asyncTransitionExpectation = expectationWithDescription("getIssueTransition")
        
        apiClient.getIssue(self.issueId) { (result) in
            
            XCTAssertTrue(result.success, "GetIssue Success Failure")
            // On a success, the API Result's error should be nil
            XCTAssertNil(result.error, "Error: \(result.error)")
            // On a success, the API Result's data should not be nil
            XCTAssertNotNil(result.data)
            
            if let responseData = result.data, let issue:JTKIssue = responseData as? JTKIssue {
                XCTAssertNotNil(issue, "Issue Received from Service is Nil")
                
                self.apiClient.getIssueTransitions(issue, completion: { (transitionResult) in
                    
                    XCTAssertTrue(transitionResult.success, "GetIssueTransitions Success Failure")
                    // On a success, the API Result's error should be nil
                    XCTAssertNil(transitionResult.error, "Error: \(result.error)")
                    // On a success, the API Result's data should not be nil
                    XCTAssertNotNil(transitionResult.data)
                    
                    if let transitions:[JTKTransition] = transitionResult.data as? [JTKTransition] {
                        XCTAssertNotNil(transitions)
                        XCTAssertTrue(transitions.count > 0)
                    } else {
                        XCTFail()
                    }
                    
                    asyncTransitionExpectation.fulfill()
                })
            
            } else {
                XCTFail()
            }
            
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(30) { error in
            //XCTAssertNotNil(error, "Test Never Finsihed")
        }
    }
    
    func testTransitionIssueToQAReady() {
        
        let transitionNameWanted = "QA Ready" // "InProgressToQAReady"
        
        // https://developer.apple.com/library/tvos/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/04-writing_tests.html#//apple_ref/doc/uid/TP40014132-CH4-SW6
        
        let asyncIssueExpectation = expectationWithDescription("getIssue")
        let asyncTransitionExpectation = expectationWithDescription("getIssueTransition")
        let asyncTransitionUpdateExpectation = expectationWithDescription("issueTransitionUpdate")
        
        apiClient.getIssue(self.issueId) { (result) in
            
            XCTAssertTrue(result.success, "GetIssue Success Failure")
            // On a success, the API Result's error should be nil
            XCTAssertNil(result.error, "Error: \(result.error)")
            // On a success, the API Result's data should not be nil
            XCTAssertNotNil(result.data)
            
            if let responseData = result.data, let issue:JTKIssue = responseData as? JTKIssue {
                XCTAssertNotNil(issue, "Issue Received from Service is Nil")
                XCTAssertNotNil(issue.status, "Issue Status is Nil and should not be")
                
                XCTAssertTrue(issue.status?.name.lowercaseString == "In Progress".lowercaseString,
                              "Issue is not In Progress, status:\(issue.status?.description)")

                self.apiClient.getIssueTransitions(issue, completion: { (transitionResult) in
                    
                    XCTAssertTrue(transitionResult.success, "GetIssueTransitions Success Failure")
                    // On a success, the API Result's error should be nil
                    XCTAssertNil(transitionResult.error, "Error: \(result.error)")
                    // On a success, the API Result's data should not be nil
                    XCTAssertNotNil(transitionResult.data)
                    
                    if let transitions:[JTKTransition] = transitionResult.data as? [JTKTransition] {
                        XCTAssertNotNil(transitions)
                        XCTAssertTrue(transitions.count > 0)
                        
                        if let qaReadyTransition = (transitions.filter { $0.name == transitionNameWanted }).first {
                            self.apiClient.transitionIssue(issue, transition: qaReadyTransition, comment: self.commentBody, completion: { (transitionResult) in
                                
                                XCTAssertNil(transitionResult.data)
                                XCTAssertNil(transitionResult.error, "Expected Error to be nil but received:\(transitionResult.error)")
                                XCTAssertTrue(transitionResult.success, "Excected Success but was decimated with Failure")
                                
                                asyncIssueExpectation.fulfill()
                                asyncTransitionExpectation.fulfill()
                                asyncTransitionUpdateExpectation.fulfill()
                            })
                        } else {
                            XCTFail("Could not Locate QA Ready Transition to Apply to Issue. Wanted: \(transitionNameWanted) Transitions:\(transitions)")
                            asyncIssueExpectation.fulfill()
                            asyncTransitionUpdateExpectation.fulfill()
                        }
                        
                    } else {
                        XCTFail()
                        asyncIssueExpectation.fulfill()
                        asyncTransitionExpectation.fulfill()
                    }
                })
                
            } else {
                XCTFail()
                asyncIssueExpectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(90) { error in
            //XCTAssertNotNil(error, "Test Never Finsihed")
        }
    }
    
    func testCommentOnIssue() {
        
        let asyncIssueExpectation = expectationWithDescription("getIssue")
        let asyncIssueCommentExpectation = expectationWithDescription("issueCommentExpectation")
        
        apiClient.getIssue(self.issueId) { (result) in
            
            XCTAssertTrue(result.success, "GetIssue Success Failure")
            // On a success, the API Result's error should be nil
            XCTAssertNil(result.error, "Error: \(result.error)")
            // On a success, the API Result's data should not be nil
            XCTAssertNotNil(result.data)
            
            if let responseData = result.data, let issue:JTKIssue = responseData as? JTKIssue {
                XCTAssertNotNil(issue, "Issue Received from Service is Nil")

                self.apiClient.commentOnIssue(issue, comment: self.commentBody, completion: { (result) in
                    XCTAssertTrue(result.success)
                    
                    asyncIssueExpectation.fulfill()
                    asyncIssueCommentExpectation.fulfill()
                })
                
            } else {
                XCTFail()
                asyncIssueExpectation.fulfill()
                asyncIssueCommentExpectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(90) { error in
            //XCTAssertNotNil(error, "Test Never Finsihed")
        }
        
    }
}
