//
//  BackgroundDownloadHelper.swift
//  MCResourceLoader
//
//  Created by Baglan on 08/11/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

class BackgroundDownloadHelper: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let sessionId = "BackgroundDownloadHelperSessionId"
    
    static var completionHandler: (() -> Void)?
    
    fileprivate var session: URLSession!
    override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: type(of: self).sessionId)
        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    func download(from: URL, to: URL) {
        
    }
    
    // MARK: - URLSessionDelegate
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let completionHandler = type(of: self).completionHandler {
            OperationQueue.main.addOperation {
                completionHandler()
            }
        }
        
        type(of: self).completionHandler = nil
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
    
    
    // MARK: - Shared instance
    static let sharedInstance = BackgroundDownloadHelper()
}
