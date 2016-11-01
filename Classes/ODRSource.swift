//
//  ODRSource.swift
//  MCResourceLoader
//
//  Created by Baglan on 31/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

extension MCResource {
    class ODRSource: MCResource.Source {
        var request: NSBundleResourceRequest?
        override func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
            guard request == nil else {
                completionHandler(nil, error(for: ErrorCodes.AlreadyAccessing))
                return
            }
            
            guard ODRSource.canHandle(URL: URL) else {
                completionHandler(nil, error(for: ErrorCodes.SchemeNotSupported))
                return
            }
            
            guard let tag = URL.host else {
                completionHandler(nil, error(for: ErrorCodes.TagMissingFromURL))
                return
            }
            
            var path = URL.path
            guard path != "" else {
                completionHandler(nil, error(for: ErrorCodes.PathMissingFromURL))
                return
            }
            path.remove(at: path.startIndex)
            
            let ch = completionHandler
            currectOperationQueue = OperationQueue.current
            
            request = NSBundleResourceRequest(tags: [tag])
            request?.beginAccessingResources(completionHandler: { [unowned self] (error) in
                if let error = error {
                    self.queue.addOperation { ch(nil, error) }
                } else {
                    guard let resourceURL = Bundle.main.url(forResource: path, withExtension: nil) else {
                        self.queue.addOperation { [unowned self] in
                            completionHandler(nil, self.error(for: ErrorCodes.NotFoundInBundle))
                        }
                        return
                    }
                    self.queue.addOperation {
                        ch(resourceURL, nil)
                    }
                }
            })
        }
        
        override func endAccessing() {
            request?.endAccessingResources()
            request = nil
        }
        
        override class func canHandle(URL: URL) -> Bool {
            if let scheme = URL.scheme, scheme == "odr" {
                return true
            }
            return false
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
        
        static let errorDescriptions: [ErrorCodes: String] = [
            .AlreadyAccessing: "Already accessing",
            .SchemeNotSupported: "URL scheme is not 'odr'",
            .TagMissingFromURL: "Malformed ODR URL: tag missing",
            .PathMissingFromURL: "Malformed ODR URL: path missing",
            .NotFoundInBundle: "Path not found in bundle"
        ]
        
        func error(for code: ErrorCodes) -> Error {
            return NSError(
                domain: ODRSource.errorDomain,
                code: code.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: ODRSource.errorDescriptions[code]!
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
