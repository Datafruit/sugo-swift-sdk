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
    #if os(iOS)
    func updateNetworkActivityIndicator(_ on: Bool)
    #endif
}

class Cache: AppLifecycle {
    
    var timer: Timer?
    var delegate: CacheDelegate?
    var cacheOnBackground = true
    var _cacheInterval = 0.0
    var cacheInterval: Double {
        set {
            objc_sync_enter(self)
            _cacheInterval = newValue
            objc_sync_exit(self)
            
            delegate?.cache(completion: nil)
            startCacheTimer()
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            return _cacheInterval
        }
    }
    
    func startCacheTimer() {
        stopCacheTimer()
        if cacheInterval > 0 {
            DispatchQueue.main.async() {
                self.timer = Timer.scheduledTimer(timeInterval: self.cacheInterval,
                                                  target: self,
                                                  selector: #selector(self.cacheSelector),
                                                  userInfo: nil,
                                                  repeats: true)
            }
        }
    }
    
    @objc func cacheSelector() {
        delegate?.cache(completion: nil)
    }
    
    func stopCacheTimer() {
        if let timer = timer {
            DispatchQueue.main.async() {
                timer.invalidate()
                self.timer = nil
            }
        }
    }
    
    // MARK: - Lifecycle
    func applicationDidBecomeActive() {
        startCacheTimer()
    }
    
    func applicationWillResignActive() {
        stopCacheTimer()
    }
    
}
