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
    var path: String
    var width: String
    var height: String
    var nodes: String
    
    static var global: WebViewInfoStorage {
        return singleton
    }
    private static let singleton = WebViewInfoStorage()
    
    private override init() {
        self.eventID = String()
        self.eventName = String()
        self.properties = String()
        self.path = String()
        self.width = String()
        self.height = String()
        self.nodes = String()
        super.init()
    }
}

