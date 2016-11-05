//
//  HTTPSource.swift
//  MCResourceLoader
//
//  Created by Baglan on 31/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

extension MCResource {
    class HTTPSource: MCResource.Source {
        private var request: NSBundleResourceRequest?
        private var task: URLSessionDownloadTask?
        override func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
            guard HTTPSource.canHandle(URL: URL) else {
                completionHandler(nil, error(for: .SchemeNotSupported))
                return
            }
            
            // Check for the cached version
            var localURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileName = self.URL.lastPathComponent
            localURL.appendPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: localURL.path) {
                completionHandler(localURL, nil)
                return
            }
            
            currectOperationQueue = OperationQueue.current
            
            task = URLSession.shared.downloadTask(with: URL, completionHandler: { [unowned self] (tempURL, response, error) -> Void in
                if let error = error {
                    self.queue.addOperation { completionHandler(nil, error) }
                } else {
                    guard let tempURL = tempURL else {
                        self.queue.addOperation { [unowned self] in
                            completionHandler(nil, self.error(for: .NoTempFile))
                        }
                        return
                    }
                    
                    do {
                        try FileManager.default.moveItem(at: tempURL, to: localURL)
                        self.queue.addOperation { completionHandler(localURL, nil) }
                    } catch {
                        self.queue.addOperation { [unowned self] in
                            completionHandler(nil, self.error(for: .ErrorMovingToLocalURL))
                        }
                        return
                    }
                }
            })
            
            task?.resume()
        }
        
        override func endAccessing() {
            task?.cancel()
        }
        
        override class func canHandle(URL: URL) -> Bool {
            if let scheme = URL.scheme, (scheme == "http" || scheme == "https") {
                return true
            }
            return false
        }
        
        // MARK: - Errors
        
        static let errorDomain = "MCResourceHTTPSourceErrorDomain"
        enum ErrorCodes: Int {
            case SchemeNotSupported
            case NoTempFile
            case ErrorMovingToLocalURL
        }
        
        static let errorDescriptions: [ErrorCodes: String] = [
            .SchemeNotSupported: "URL scheme is not 'http' or 'https'",
            .NoTempFile: "Temporary file not found",
            .ErrorMovingToLocalURL: "Could not move temporary file to a new location"
        ]
        
        func error(for code: ErrorCodes) -> Error {
            return NSError(
                domain: HTTPSource.errorDomain,
                code: code.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: HTTPSource.errorDescriptions[code]!
                ]
            )
        }
        
        // MARK: - Operation queue
        
        private var currectOperationQueue: OperationQueue?
        private var queue: OperationQueue {
            if let oq = currectOperationQueue {
                return oq
            } else {
                return OperationQueue.main
            }
        }
    }
}
