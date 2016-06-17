//
//  JTKAPIClientOperation.swift
//  JiraToolsKit
//
//  Created by Shane Zatezalo on 6/13/16.
//  Copyright © 2016 Lottadot LLC. All rights reserved.
//

import Foundation

/// This is a base `NSOpertaion` class. All "Network Opertions" should inherit from this class.
public class JTKAPIClientOperation: NSOperation, NSURLSessionDataDelegate {
    
    var receivedData = NSMutableData()
    var error: NSError?
    
    let endpointURL: NSURL
    var dataProvider: JTKAPIClientOperatonDataProvider?
    
    private var swiftKVOFinished = false
    
    var urlSession: NSURLSession {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 30
        
        if let provider = self.dataProvider {
            // https://www.base64encode.org/
            let userPasswordString = "\(provider.clientUsername()):\(provider.clientPassword())"
            let userPasswordData = userPasswordString.dataUsingEncoding(NSASCIIStringEncoding)
            let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue:0))
            let authString = "Basic \(base64EncodedCredential)"
            configuration.HTTPAdditionalHeaders = ["Authorization" : authString]
        }
        
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    public override var asynchronous: Bool {
        return false
    }
    
    public override var finished: Bool {
        get {
            return swiftKVOFinished
        }
        set {
            self.willChangeValueForKey("isFinished")
            swiftKVOFinished = newValue
            self.didChangeValueForKey("isFinished")
        }
    }
    
    //    init(url: NSURL, result: NetworkResult) {
    //        self.endpointURL = url
    //        self.operationResult = result
    //        super.init()
    //    }
    
    public init(url: NSURL) {
        self.endpointURL = url
        //self.operationResult = result
        super.init()
    }
    
    func handleResponse() {
        fatalError("Subclasses should Override this")
    }
    
    // MARK: NSURLSessionDataDelegate
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if cancelled {
            finished = true
            dataTask.cancel()
            return
        }
        
        guard let httpResponse = response as? NSHTTPURLResponse else {
            fatalError("Did not receive NSHTTPURLResponse")
        }
        
        if isSuccessfulHTTPStatusCode(httpResponse.statusCode) {
            completionHandler(.Allow)
        } else {
            self.error = JTKAPIClientNetworkError.createError(JTKAPIClientNetworkError.Code.HttpError.rawValue, statusCode: httpResponse.statusCode, failureReason: "HTTP Status Invalid")
            completionHandler(.Cancel)
        }
    }
    
    private func isSuccessfulHTTPStatusCode(code: Int) -> Bool {
        return (code >= 200 && code < 300)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if cancelled {
            finished = true
            dataTask.cancel()
            return
        }
        
        receivedData.appendData(data)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if cancelled {
            self.receivedData = NSMutableData()
            finished = true
            task.cancel()
            return
        }
        
        if let httpError = self.error where httpError.domain == JTKAPIClientNetworkError.ErrorDomain
                && httpError.code == JTKAPIClientNetworkError.Code.HttpError.rawValue {
            self.receivedData = NSMutableData()
            finished = true
            task.cancel()
            return
        }
        
        if error != nil {
            self.error = error
            finished = true
            return
        }
        
        handleResponse()
        
        finished = true
    }
}

