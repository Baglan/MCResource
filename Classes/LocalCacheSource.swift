//
//  LocalCacheSource.swift
//  MCResourceLoader
//
//  Created by Baglan on 06/11/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

extension MCResource {
    class LocalCacheSource: MCResourceSource, ErrorSource {
        let localUrl: URL
        let priority: Int
        
        let fractionCompleted: Double = 0
        
        init(localUrl: URL, priority: Int = 0) {
            self.localUrl = localUrl
            self.priority = priority
        }
        
        convenience init(pathInCache: String, priority: Int) {
            var cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            cacheUrl.appendPathComponent(pathInCache)
            self.init(localUrl: cacheUrl, priority: priority)
        }
        
        private var request: NSBundleResourceRequest?
        private var task: URLSessionDownloadTask?
        func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
            if !FileManager.default.fileExists(atPath: localUrl.path) {
                completionHandler(nil, ErrorHelper.error(for: ErrorCodes.NotFound.rawValue, source: self))
                return
            }
            
            completionHandler(localUrl, nil)
        }
        
        func endAccessing() {
        }
        
        // MARK: - Errors
        
        static let errorDomain = "MCResourceLocalCacheSourceErrorDomain"
        
        enum ErrorCodes: Int {
            case SchemeNotSupported
            case NotFound
        }
        
        static let errorDescriptions: [Int: String] = [
            ErrorCodes.SchemeNotSupported.rawValue: "URL scheme is not 'http' or 'https'",
            ErrorCodes.NotFound.rawValue: "Item not found in local cache"
        ]
    }
}
