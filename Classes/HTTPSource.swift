//
//  HTTPSource.swift
//  MCResourceLoader
//
//  Created by Baglan on 31/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

extension MCResource {
    class HTTPSource: MCResourceSource, ErrorSource {
        let priority: Int
        let remoteUrl: URL
        let localUrl: URL
        init(remoteUrl: URL, localUrl: URL, priority: Int = 0) {
            self.remoteUrl = remoteUrl
            self.localUrl = localUrl
            self.priority = priority
        }
        
        convenience init(remoteUrl: URL, pathInCache: String, priority: Int = 0) {
            var cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            cacheUrl.appendPathComponent(pathInCache)
            self.init(remoteUrl: remoteUrl, localUrl: cacheUrl, priority: priority)
        }
        
        private var request: NSBundleResourceRequest?
        private var task: URLSessionDownloadTask?
        let queueHelper = OperationQueueHelper()
        func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
            guard let scheme = remoteUrl.scheme, (scheme == "http" || scheme == "https") else {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.SchemeNotSupported.rawValue, source: self))
                return
            }
            
            if FileManager.default.fileExists(atPath: localUrl.path) {
                completionHandler(localUrl, nil)
                return
            }
            
            queueHelper.preferred = OperationQueue.current
            
            task = URLSession.shared.downloadTask(with: remoteUrl, completionHandler: { [unowned self] (tempURL, response, error) -> Void in
                if let error = error {
                    self.queueHelper.queue.addOperation { completionHandler(nil, error) }
                } else {
                    guard let tempURL = tempURL else {
                        
                        self.queueHelper.queue.addOperation { [unowned self] in
                            completionHandler(nil, ErrorHelper.error(for: ErrorCodes.NoTempFile.rawValue, source: self))
                        }
                        return
                    }
                    
                    do {
                        try FileManager.default.moveItem(at: tempURL, to: self.localUrl)
                        self.queueHelper.queue.addOperation { [unowned self] in
                            completionHandler(self.localUrl, nil)
                        }
                    } catch {
                        self.queueHelper.queue.addOperation { [unowned self] in
                            completionHandler(nil, ErrorHelper.error(for: ErrorCodes.ErrorMovingToLocalURL.rawValue, source: self))
                        }
                        return
                    }
                }
            })
            
            task?.resume()
        }
        
        func endAccessing() {
            task?.cancel()
        }
        
        // MARK: - Errors
        
        static let errorDomain = "MCResourceHTTPSourceErrorDomain"
        enum ErrorCodes: Int {
            case SchemeNotSupported
            case NoTempFile
            case ErrorMovingToLocalURL
        }
        
        static let errorDescriptions: [Int: String] = [
            ErrorCodes.SchemeNotSupported.rawValue: "URL scheme is not 'http' or 'https'",
            ErrorCodes.NoTempFile.rawValue: "Temporary file not found",
            ErrorCodes.ErrorMovingToLocalURL.rawValue: "Could not move temporary file to a new location"
        ]
    }
}
