//
//  OperationQueueHelper.swift
//  MCResourceLoader
//
//  Created by Baglan on 08/11/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation

class OperationQueueHelper {
    var preferred: OperationQueue?
    var queue: OperationQueue {
        return preferred ?? OperationQueue.main
    }
}
