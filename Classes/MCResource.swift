//
//  MCResourceLoader.swift
//  MCResourceLoader
//
//  Created by Baglan on 28/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

protocol MCResourceSource: class {
    var priority: Int { get }
    func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void)
    func endAccessing()
}

class MCResource: ErrorSource {
    var localURL: URL?
    
    private var sources = [MCResourceSource]()
    func add(source: MCResourceSource) {
        sources.append(source)
    }
    
    private var currentSource: MCResourceSource?
    private var batch = [MCResourceSource]()
    private var isAccessing = false
    private var completionHandler: ((URL?, Error?) -> Void)?
    private var queueHelper = OperationQueueHelper()
    
    func beginAccessing(completionHandler: @escaping (URL?, Error?) -> Void) {
        guard !isAccessing else {
            completionHandler(nil, ErrorHelper.error(for: ErrorCodes.AlreadyAccessing.rawValue, source: self))
            return
        }
        
        guard sources.count > 0 else {
            completionHandler(nil, ErrorHelper.error(for: ErrorCodes.NoSourcesAvailable.rawValue, source: self))
            return
        }
        
        isAccessing = true
        self.completionHandler = completionHandler
        queueHelper.preferred = OperationQueue.current
        
        // Copy sources to batch in reversed order
        batch.removeAll()
        
        batch.append(
            contentsOf: sources.sorted { (a, b) -> Bool in
                return a.priority <= b.priority
            }
        )
        
        tryNextSource()
    }
    
    func tryNextSource() {
        currentSource?.endAccessing()
        
        guard let source = batch.popLast() else {
            if let completionHandler = completionHandler {
                queueHelper.queue.addOperation { [unowned self] in
                    completionHandler(nil, ErrorHelper.error(for: ErrorCodes.RunOutOfSources.rawValue, source: self))
                }
            }
            return
        }
        
        currentSource = source
        
        NSLog("[MCResource] trying \(String(describing: type(of: source)))")
        
        source.beginAccessing { [unowned self] (url, error) in
            guard self.isAccessing else { return }
            
            if let error = error {
                NSLog("[Error] \(error)")
                self.tryNextSource()
            } else {
                self.localURL = url
                if let completionHandler = self.completionHandler {
                    self.queueHelper.queue.addOperation { completionHandler(url, nil) }
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
    
    static let errorDescriptions: [Int: String] = [
        ErrorCodes.AlreadyAccessing.rawValue: "Already accessing",
        ErrorCodes.NoSourcesAvailable.rawValue: "No sources available",
        ErrorCodes.RunOutOfSources.rawValue: "All sources failed"
    ]
}
