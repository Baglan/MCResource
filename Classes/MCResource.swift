//
//  MCResourceLoader.swift
//  MCResourceLoader
//
//  Created by Baglan on 28/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

class MCResource {
    var localURL: URL?
    
    private var sources = [Source]()
    func add(source: Source) {
        sources.append(source)
    }
    
    private var currentSource: Source?
    private var batch = [Source]()
    private var isAccessing = false
    private var completionHandler: ((URL?, Error?) -> Void)?
    
    func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
        guard !isAccessing else {
            completionHandler(nil, error(for: .AlreadyAccessing))
            return
        }
        
        guard sources.count > 0 else {
            completionHandler(nil, error(for: .NoSourcesAvailable))
            return
        }
        
        isAccessing = true
        self.completionHandler = completionHandler
        currectOperationQueue = OperationQueue.current
        
        // Copy sources to batch in reversed order
        batch.removeAll()
        batch.append(contentsOf: sources.reversed())
        
        tryNextSource()
    }
    
    func tryNextSource() {
        currentSource?.endAccessing()
        
        guard let source = batch.popLast() else {
            if let completionHandler = completionHandler {
                queue.addOperation { [unowned self] in completionHandler(nil, self.error(for: .RunOutOfSources)) }
            }
            return
        }
        
        currentSource = source
        
        source.beginAccessing { [unowned self] (url, error) in
            if let error = error {
                NSLog("[Error] \(error)")
                self.tryNextSource()
            } else {
                self.localURL = url
                if let completionHandler = self.completionHandler {
                    self.queue.addOperation { completionHandler(url, nil) }
                }
            }
        }
    }
    
    func endAccessing() {
        if isAccessing {
            currentSource?.endAccessing()
            localURL = nil
            isAccessing = false
        }
    }
    
    deinit {
        endAccessing()
    }
    
    // MARK: - Errors
    
    static let errorDomain = "MCResourceErrorDomain"
    enum ErrorCodes: Int {
        case AlreadyAccessing
        case NoSourcesAvailable
        case RunOutOfSources
    }
    
    static let errorDescriptions: [ErrorCodes: String] = [
        .AlreadyAccessing: "Already accessing",
        .NoSourcesAvailable: "No sources available",
        .RunOutOfSources: "All sources failed"
    ]
    
    func error(for code: ErrorCodes) -> Error {
        return NSError(
            domain: MCResource.errorDomain,
            code: code.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: MCResource.errorDescriptions[code]!
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

extension MCResource {
    class Source {
        let URL: URL
        init(URL: URL) {
            self.URL = URL
        }
        func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {}
        func endAccessing() {}
        class func canHandle(URL: URL) -> Bool {
            return false
        }
    }
}
