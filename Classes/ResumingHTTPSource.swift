//
//  ResumingHTTPSource.swift
//  MCResourceLoader
//
//  Created by Baglan on 09/11/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

extension MCResource {
    class ResumingHTTPSource: MCResourceSource, ErrorSource {
        let priority: Int
        let remoteUrl: URL
        let localUrl: URL
        
        var fractionCompleted: Double {
            if let task = task {
                let expected = Double(task.countOfBytesExpectedToReceive)
                if expected == 0 {
                    return 0
                }
                return Double(task.countOfBytesReceived) / expected
            } else {
                return 0
            }
        }
        
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
        
        fileprivate var task: URLSessionDownloadTask?
        fileprivate let queueHelper = OperationQueueHelper()
        func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
            guard let scheme = remoteUrl.scheme, (scheme == "http" || scheme == "https") else {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.SchemeNotSupported.rawValue, source: self))
                return
            }
            
            // Is there a cached file already?
            if FileManager.default.fileExists(atPath: localUrl.path) {
                completionHandler(localUrl, nil)
                return
            }
            
            queueHelper.preferred = OperationQueue.current
            
            do {
                // Can download be restarted with resume data?
                let resumeData = try Data(contentsOf: resumeDataUrl)
                task = URLSession.shared.downloadTask(withResumeData: resumeData, completionHandler: { [unowned self] (tempURL, response, error) -> Void in
                    self.onComplete(url: tempURL, error: error, completionHandler: completionHandler)
                    self.removeResumeData()
                })
            } catch {
                // No resume data, start anew
                task = URLSession.shared.downloadTask(with: remoteUrl, completionHandler: { [unowned self] (tempURL, response, error) -> Void in
                    self.onComplete(url: tempURL, error: error, completionHandler: completionHandler)
                })
            }
            
            task?.resume()
        }
        
        func onComplete(url: URL?, error: Error?, completionHandler: @escaping (URL?, Error?) -> Void) {
            if let error = error {
                queueHelper.queue.addOperation { completionHandler(nil, error) }
            } else {
                guard let tempURL = url else {
                    queueHelper.queue.addOperation { [unowned self] in
                        completionHandler(nil, ErrorHelper.error(for: ErrorCodes.NoTempFile.rawValue, source: self))
                    }
                    return
                }
                
                do {
                    try FileManager.default.moveItem(at: tempURL, to: localUrl)
                    queueHelper.queue.addOperation { [unowned self] in
                        completionHandler(self.localUrl, nil)
                    }
                } catch {
                    queueHelper.queue.addOperation { [unowned self] in
                        completionHandler(nil, ErrorHelper.error(for: ErrorCodes.ErrorMovingToLocalURL.rawValue, source: self))
                    }
                    return
                }
            }
        }
        
        func endAccessing() {
            task?.cancel(byProducingResumeData: { [unowned self] (data) in
                guard let data = data else { return }
                
                OperationQueue().addOperation { [unowned self] in
                    do {
                        try data.write(to: self.resumeDataUrl)
                    } catch {
                    }
                }
            })
        }
        
        fileprivate var resumeDataUrl: URL {
            return localUrl.appendingPathExtension("ResumeData")
        }
        
        func removeResumeData() {
            do {
                try FileManager.default.removeItem(at: resumeDataUrl)
            } catch {
                
            }
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
