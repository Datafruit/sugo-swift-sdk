//
//  WebViewBindings.swift
//  Sugo
//
//  Created by Zack on 28/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

enum WebViewBindingsMode: String {
    case decide     = "decide"
    case codeless   = "codeless"
}

class WebViewBindings: NSObject {
    
    var mode: WebViewBindingsMode
    var decideBindings: [[String: Any]]
    var codelessBindings: [[String: Any]]
    var bindings: [[String: Any]]
    var uiVCPath: String
    var wkVCPath: String
    var stringBindings: String
    
    var viewSwizzleRunning = false
    
    var uiWebView: UIWebView?
    var uiWebViewSwizzleRunning = false
    var uiWebViewJavaScriptInjected = false
    var uiDidMoveToWindowBlockName = UUID().uuidString
    var uiRemoveFromSuperviewBlockName = UUID().uuidString
    var uiWebViewDidStartLoadBlockName = UUID().uuidString
    var uiWebViewDidFinishLoadBlockName = UUID().uuidString
    
    var wkWebView: WKWebView?
    var wkWebViewJavaScriptInjected = false
    var wkDidMoveToWindowBlockName = UUID().uuidString
    var wkRemoveFromSuperviewBlockName = UUID().uuidString
    
    static var global: WebViewBindings {
        return singleton
    }
    private static let singleton = WebViewBindings(mode: WebViewBindingsMode.decide)
    
    private init(mode: WebViewBindingsMode) {
        self.mode = mode
        self.decideBindings = [[String: Any]]()
        self.codelessBindings = [[String: Any]]()
        self.bindings = [[String: Any]]()
        self.uiVCPath = String()
        self.wkVCPath = String()
        self.stringBindings = String()
        super.init()
    }
    
    func fillBindings() {
        if self.mode == WebViewBindingsMode.decide {
            self.bindings = self.decideBindings
        } else if self.mode == WebViewBindingsMode.codeless {
            self.bindings = self.codelessBindings
        } else {
            self.bindings = [[String: Any]]()
        }
        if !self.bindings.isEmpty {
            do {
                let jsonBindings = try JSONSerialization.data(withJSONObject: self.bindings,
                                                              options: JSONSerialization.WritingOptions.prettyPrinted)
                self.stringBindings = String(data: jsonBindings, encoding: String.Encoding.utf8)!
            } catch {
                Logger.debug(message: "Failed to serialize JSONObject: \(self.bindings)")
            }
        }
        stop()
        execute()
    }
}









