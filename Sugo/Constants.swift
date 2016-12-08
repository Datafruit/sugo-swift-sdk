//
//  Constants.swift
//  Sugo
//
//  Created by Zack on 1/12/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation


struct QueueConstants {
    static var queueSize = 5000
}

struct APIConstants {
    static let batchSize = 50
    static let minRetryBackoff = 60.0
    static let maxRetryBackoff = 600.0
    static let failuresTillBackoff = 2
}

struct BundleConstants {
    static let ID = "io.sugo.Sugo"
}

struct ServerURL {
//    static let bindings = "http://192.168.0.212:8000"
//    static let collect = "http://collect.sugo.net"
//    static let codeless = "ws://192.168.0.212:8887"
    
    static let bindings = "http://192.168.0.111:8080"
    static let collect = "http://collect.sugo.net"
    static let codeless = "ws://192.168.0.111:8887"
}
