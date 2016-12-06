//
//  WebViewJSExport.swift
//  Sugo
//
//  Created by Zack on 28/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore


@objc protocol WebViewJSExportProtocol: NSObjectProtocol, JSExport {
    
    static func eventWith(id: String, name: String, properties: String)
    static func infoWith(path: String, nodes: String, width: String, height: String)
}

class WebViewJSExport: NSObject, WebViewJSExportProtocol {
    
    class func eventWith(id: String, name: String, properties: String) {
        
        WebViewInfoStorage.global.eventID = id
        WebViewInfoStorage.global.eventName = name
        WebViewInfoStorage.global.properties = properties
        let pData = properties.data(using: String.Encoding.utf8)
        if let pJSON = try? JSONSerialization.jsonObject(with: pData!,
                                                         options: JSONSerialization.ReadingOptions.mutableContainers) as? Properties {
            Sugo.mainInstance().track(eventID: WebViewInfoStorage.global.eventID,
                                          eventName: WebViewInfoStorage.global.eventName,
                                          properties: pJSON)
        } else {
            Sugo.mainInstance().track(eventID: WebViewInfoStorage.global.eventID,
                                          eventName: WebViewInfoStorage.global.eventName)
        }
        Logger.debug(message: "id:\(WebViewInfoStorage.global.eventID),name:\(WebViewInfoStorage.global.eventName)")
    }
    
    class func infoWith(path: String, nodes: String, width: String, height: String) {
        
        WebViewInfoStorage.global.path = path
        WebViewInfoStorage.global.nodes = nodes
        WebViewInfoStorage.global.width = width
        WebViewInfoStorage.global.height = height
    }
}
