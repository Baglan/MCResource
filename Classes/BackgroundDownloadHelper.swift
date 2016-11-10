//
//  BackgroundDownloadHelper.swift
//  MCResourceLoader
//
//  Created by Baglan on 08/11/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

class BackgroundDownloadHelper: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    static let defaultSessionId = "BackgroundDownloadHelper"
    static var completionHandler: (() -> Void)?
    
    fileprivate var session: URLSession!
    let sessionId: String
    init(sessionId: String) {
        self.sessionId = sessionId
        
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionId)
        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    // MARK: - Managing downloads
    
    var urls = [URL:Set<URL>]()
    var completionHandlers = [URL: [(Error?) -> Void]]()
    
    func download(from: URL, to: URL, completionHandler: @escaping (Error?) -> Void) {
        var handlers = completionHandlers[from] ?? [(Error?) -> Void]()
        handlers.append(completionHandler)
        completionHandlers[from] = handlers
        
        var localUrls = urls[from] ?? Set<URL>()
        localUrls.insert(to)
        urls[from] = localUrls
        
        startNewTasks()
    }
    
    func startNewTasks() {
        session.getAllTasks { [unowned self] (tasks) in
            let taskUrls = tasks.map({ (task) -> URL? in
                return task.originalRequest?.url
            })
            
            for url in taskUrls {
                if let url = url, !self.urls.keys.contains(url) {
                    self.session.downloadTask(with: url)
                }
            }
        }
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
        guard let url = downloadTask.originalRequest?.url else { return }
        
        do {
            // Store donwloaded file
            if var localUrls = urls[url], let firstUrl = localUrls.popFirst() {
                // Move to first
                try FileManager.default.moveItem(at: location, to: firstUrl)
                
                // Copy from first to the rest
                for localUrl in localUrls {
                    try FileManager.default.copyItem(at: firstUrl, to: localUrl)
                }
            }
            
            // Call completion handlers
            if let handlers = self.completionHandlers[url] {
                for handler in handlers {
                    handler(nil)
                }
            }
        } catch {
            NSLog("[\(String(describing: type(of: self)))] \(error.localizedDescription)")
        }
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
    
    
    // MARK: - Shared instance
    static let sharedInstance = BackgroundDownloadHelper(sessionId: BackgroundDownloadHelper.defaultSessionId)
}
