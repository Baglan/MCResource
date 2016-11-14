//
//  ODRSource.swift
//  MCResourceLoader
//
//  Created by Baglan on 31/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

extension MCResource {
    class ODRSource: MCResourceSource, ErrorSource {
        var request: NSBundleResourceRequest?
        
        var fractionCompleted: Double {
            if let request = request {
                return request.progress.fractionCompleted
            } else {
                return 0
            }
        }
        
        let url: URL
        var priority: Int
        init(url: URL, priority: Int = 0) {
            self.url = url
            self.priority = priority
        }
        
        let queueHelper = OperationQueueHelper()
        func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
            guard request == nil else {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.AlreadyAccessing.rawValue, source: self))
                return
            }
            
            guard let scheme = url.scheme, scheme == "odr" else {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.SchemeNotSupported.rawValue, source: self))
                return
            }
            
            guard let tag = url.host else {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.TagMissingFromURL.rawValue, source: self))
                return
            }
            
            var path = url.path
            guard path != "" else {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.PathMissingFromURL.rawValue, source: self))
                return
            }
            path.remove(at: path.startIndex)
            
            let ch = completionHandler
            queueHelper.preferred = OperationQueue.current
            
            request = NSBundleResourceRequest(tags: [tag])
            request?.beginAccessingResources(completionHandler: { [unowned self] (error) in
                if let error = error {
                    self.queueHelper.queue.addOperation { ch(nil, error) }
                } else {
                    guard let resourceURL = Bundle.main.url(forResource: path, withExtension: nil) else {
                        self.queueHelper.queue.addOperation { [unowned self] in
                            completionHandler(nil, ErrorHelper.error(for: ErrorCodes.NotFoundInBundle.rawValue, source: self))
                        }
                        return
                    }
                    self.queueHelper.queue.addOperation {
                        ch(resourceURL, nil)
                    }
                }
            })
        }
        
        func endAccessing() {
            request?.endAccessingResources()
            request = nil
        }
        
        // MARK: - Errors
        
        static let errorDomain = "MCResourceODRSourceErrorDomain"
        
        enum ErrorCodes: Int {
            case AlreadyAccessing
            case SchemeNotSupported
            case TagMissingFromURL
            case PathMissingFromURL
            case NotFoundInBundle
        }
        
        static let errorDescriptions: [Int: String] = [
            ErrorCodes.AlreadyAccessing.rawValue: "Already accessing",
            ErrorCodes.SchemeNotSupported.rawValue: "URL scheme is not 'odr'",
            ErrorCodes.TagMissingFromURL.rawValue: "Malformed ODR URL: tag missing",
            ErrorCodes.PathMissingFromURL.rawValue: "Malformed ODR URL: path missing",
            ErrorCodes.NotFoundInBundle.rawValue: "Path not found in bundle"
        ]
        
//        func error(for code: ErrorCodes) -> Error {
//            return NSError(
//                domain: ODRSource.errorDomain,
//                code: code.rawValue,
//                userInfo: [
//                    NSLocalizedDescriptionKey: ODRSource.errorDescriptions[code]!
//                ]
//            )
//        }
        
//        // MARK: - Operation queue
//        
//        private var currentOperationQueue: OperationQueue?
//        private var queue: OperationQueue {
//            if let oq = currentOperationQueue {
//                return oq
//            } else {
//                return OperationQueue.main
//            }
//        }
    }
}
