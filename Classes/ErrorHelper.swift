//
//  ErrorHelper.swift
//  MCResourceLoader
//
//  Created by Baglan on 08/11/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

protocol ErrorSource {
    static var errorDomain: String { get }
    static var errorDescriptions: [Int: String] { get }
}

class ErrorHelper {
    static let defaultDescription = "Undescribed error"
    
    class func error(for code: Int, source: ErrorSource) -> NSError {
        let description = type(of: source).errorDescriptions[code] ?? ErrorHelper.defaultDescription
        
        return NSError(
            domain: type(of: source).errorDomain,
            code: code,
            userInfo: [
                NSLocalizedDescriptionKey: description
            ]
        )
    }
}
