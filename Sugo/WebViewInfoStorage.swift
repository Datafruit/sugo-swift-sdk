//
//  WebViewInfoStorage.swift
//  Sugo
//
//  Created by Zack on 5/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import Foundation

class WebViewInfoStorage: NSObject {
    
    var eventID: String
    var eventName: String
    var properties: String
    var hasNewFrame: Bool {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return newFrame
        }
        set {
            objc_sync_enter(self)
            newFrame = newValue
            objc_sync_exit(self)
        }
    }
    private var newFrame: Bool
    private var title: String
    private var path: String
    private var width: String
    private var height: String
    private var nodes: String
    
    static var global: WebViewInfoStorage {
        return singleton
    }
    private static let singleton = WebViewInfoStorage()
    
    private override init() {
        self.eventID = String()
        self.eventName = String()
        self.properties = String()
        self.newFrame = false
        self.title = String()
        self.path = String()
        self.width = String()
        self.height = String()
        self.nodes = String()
        super.init()
    }
    
    func getHTMLInfo() -> [String: Any] {
        objc_sync_enter(self)
        if self.newFrame {
            self.newFrame = false
        }
        defer { objc_sync_exit(self) }
        
        return ["title": self.title,
                "url": self.path,
                "clientWidth": self.width,
                "clientHeight": self.height,
                "nodes": self.nodes]
    }
    
    func setHTMLInfo(withTitle title: String, path: String, width: String, height: String, nodes: String) {
        objc_sync_enter(self)
        self.title = title
        self.path = path
        self.width = width
        self.height = height
        self.nodes = nodes
        self.newFrame = true
        objc_sync_exit(self)
    }
    
}

