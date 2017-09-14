//
//  Cache.swift
//  Sugo
//
//  Created by Zack on 27/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation

protocol CacheDelegate {
    func cache(completion: (() -> Void)?)
//    #if os(iOS)
//    func updateNetworkActivityIndicator(_ on: Bool)
//    #endif
}

class Cache {
    
    var timer: Timer?
    var delegate: CacheDelegate?
    var cacheInterval: Double = 3600 {
        didSet {
            startCacheTimer()
        }
    }
    
    func startCacheTimer() {
        stopCacheTimer()
        if cacheInterval > 0 {
            self.timer = Timer.scheduledTimer(timeInterval: self.cacheInterval,
                                              target: self,
                                              selector: #selector(self.cacheSelector),
                                              userInfo: nil,
                                              repeats: true)
        }
    }
    
    @objc func cacheSelector() {
        delegate?.cache(completion: nil)
    }
    
    func stopCacheTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
}
