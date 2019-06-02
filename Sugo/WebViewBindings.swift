//
//  WebViewBindings.swift
//  Sugo
//
//  Created by Zack on 28/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit

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
    @objc dynamic var stringBindings: String
    var stringHeats: String
    
    lazy var viewSwizzleRunning = false
    @objc dynamic var isWebViewNeedReload = false
    var isWebViewNeedInject = true
    @objc dynamic var isHeatMapModeOn = false
    
    var uiWebView: UIWebView?
    lazy var uiWebViewSwizzleRunning = false
    lazy var uiWebViewJavaScriptInjected = false
    lazy var uiDidMoveToWindowBlockName = UUID().uuidString
    lazy var uiWebViewShouldStartLoadBlockName = UUID().uuidString
    lazy var uiWebViewDidStartLoadBlockName = UUID().uuidString
    lazy var uiWebViewDidFinishLoadBlockName = UUID().uuidString
    
    var wkWebView: WKWebView?
    lazy var wkDidMoveToWindowBlockName = UUID().uuidString
    lazy var wkWebViewCurrentJS = WKUserScript()
    
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
        self.stringHeats = "{}"
        super.init()
        self.addObserver(self,
                         forKeyPath: "stringBindings",
                         options: NSKeyValueObservingOptions.new,
                         context: nil)
        self.addObserver(self,
                         forKeyPath: #keyPath(WebViewBindings.isWebViewNeedReload),
                         options: NSKeyValueObservingOptions.new,
                         context: nil)
        self.addObserver(self,
                         forKeyPath: #keyPath(WebViewBindings.isHeatMapModeOn),
                         options: NSKeyValueObservingOptions.new,
                         context: nil)
    }
    
    deinit {
        stop()
        self.mode = .decide
        self.decideBindings.removeAll()
        self.codelessBindings.removeAll()
        self.bindings.removeAll()
        self.uiVCPath.removeAll()
        self.wkVCPath.removeAll()
        self.removeObserver(self, forKeyPath: "stringBindings")
        self.stringBindings.removeAll()
        self.viewSwizzleRunning = false
        self.removeObserver(self, forKeyPath: "isWebViewNeedReload")
        self.isWebViewNeedReload = false
        
        self.uiWebView = nil
        self.uiWebViewSwizzleRunning = false
        self.uiWebViewJavaScriptInjected = false
        self.uiDidMoveToWindowBlockName.removeAll()
        self.uiWebViewShouldStartLoadBlockName.removeAll()
        self.uiWebViewDidStartLoadBlockName.removeAll()
        self.uiWebViewDidFinishLoadBlockName.removeAll()
        
        self.wkWebView = nil
        self.wkDidMoveToWindowBlockName.removeAll()
    }
    
    func fillBindings() {
        if self.mode == WebViewBindingsMode.decide {
            self.bindings = self.decideBindings
        } else if self.mode == WebViewBindingsMode.codeless {
            self.bindings = self.codelessBindings
        } else {
            self.bindings = [[String: Any]]()
        }
        do {
            let jsonBindings = try JSONSerialization.data(withJSONObject: self.bindings,
                                                          options: JSONSerialization.WritingOptions.prettyPrinted)
            self.stringBindings = String(data: jsonBindings, encoding: String.Encoding.utf8)!
        } catch {
            Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
            Logger.debug(message: "Failed to serialize JSONObject: \(self.bindings)")
        }
    }
    
    func switchHeatMap(mode: Bool, with data: Data) {
        
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            self.stringHeats = string
            self.isHeatMapModeOn = mode
        }
    }
    
}









