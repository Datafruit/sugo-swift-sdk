//
//  WebViewBindings+UIWebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import JavaScriptCore

extension WebViewBindings {
    
    func startUIWebViewBindings(webView: inout UIWebView) {
        if !self.uiWebViewSwizzleRunning {
            if let delegate = webView.delegate {
                Swizzler.swizzleSelector(#selector(delegate.webViewDidStartLoad(_:)),
                                         withSelector: #selector(UIWebView.sugoWebViewDidStartLoad(_:)),
                                         for: type(of: delegate),
                                         and: UIWebView.self,
                                         name: self.uiWebViewDidStartLoadBlockName,
                                         block: self.uiWebViewDidStartLoad)
                Swizzler.swizzleSelector(#selector(delegate.webViewDidFinishLoad(_:)),
                                         withSelector: #selector(UIWebView.sugoWebViewDidFinishLoad(_:)),
                                         for: type(of: delegate),
                                         and: UIWebView.self,
                                         name: self.uiWebViewDidFinishLoadBlockName,
                                         block: self.uiWebViewDidFinishLoad)
                self.uiWebViewSwizzleRunning = true
            }
        }
    }
    
    func stopUIWebViewBindings(webView: UIWebView) {
        if self.uiWebViewSwizzleRunning {
            if let delegate = webView.delegate {
                Swizzler.unswizzleSelector(#selector(delegate.webViewDidStartLoad(_:)),
                                           aClass: type(of: delegate),
                                           name: self.uiWebViewDidStartLoadBlockName)
                Swizzler.unswizzleSelector(#selector(delegate.webViewDidFinishLoad(_:)),
                                           aClass: type(of: delegate),
                                           name: self.uiWebViewDidFinishLoadBlockName)
                self.uiWebViewJavaScriptInjected = false
                self.uiWebViewSwizzleRunning = false
                self.uiWebView = nil
            }
        }
    }
    
    func updateUIWebViewBindings(webView: inout UIWebView) {
        if self.uiWebViewSwizzleRunning {
            let jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
            jsContext.setObject(WebViewJSExport.self,
                                forKeyedSubscript: "WebViewJSExport" as (NSCopying & NSObjectProtocol)!)
            jsContext.evaluateScript(self.jsUIWebViewTrack)
            jsContext.evaluateScript(self.jsUIWebViewBindingsSource)
            jsContext.evaluateScript(self.jsUIWebViewBindingsExcute)
        }
    }
    
    func uiWebViewDidStartLoad(view: AnyObject?, command: Selector, webView: AnyObject?, param2: AnyObject?) {
        if self.uiWebViewJavaScriptInjected {
            self.uiWebViewJavaScriptInjected = false
            Logger.debug(message: "UIWebView Uninjected")
        }
    }
    func uiWebViewDidFinishLoad(view: AnyObject?, command: Selector, webView: AnyObject?, param2: AnyObject?) {
        guard let wv = webView as? UIWebView else {
            return
        }
        guard let url = webView?.request.url else {
            return
        }
        guard !url.absoluteString.isEmpty else {
            return
        }
        guard !wv.isLoading else {
            return
        }
        if !self.uiWebViewJavaScriptInjected {
            let jsContext = wv.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
            jsContext.setObject(WebViewJSExport.self,
                                forKeyedSubscript: "WebViewJSExport" as (NSCopying & NSObjectProtocol)!)
            jsContext.evaluateScript(self.jsUIWebViewTrack)
            jsContext.evaluateScript(self.jsUIWebViewBindingsSource)
            jsContext.evaluateScript(self.jsUIWebViewBindingsExcute)
            Logger.debug(message: "UI JS Track:\n\(self.jsUIWebViewTrack)")
            self.uiWebViewJavaScriptInjected = true
            Logger.debug(message: "UIWebView Injected")
        }
    }
}

extension UIWebView {
    
    @objc func sugoWebViewDidStartLoad(_ webView: UIWebView) {
        if let delegate = webView.delegate {
            let originalSelector = #selector(delegate.webViewDidStartLoad(_:))
            if let originalMethod = class_getInstanceMethod(type(of: delegate), originalSelector),
                let swizzle = Swizzler.swizzles[originalMethod] {
                typealias SUGOCFunction = @convention(c) (AnyObject, Selector, UIWebView) -> Void
                let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
                curriedImplementation(self, originalSelector, webView)
                
                for (_, block) in swizzle.blocks {
                    block(self, swizzle.selector, webView, nil)
                }
            }
        }
    }
    @objc func sugoWebViewDidFinishLoad(_ webView: UIWebView) {
        if let delegate = webView.delegate {
            let originalSelector = #selector(delegate.webViewDidFinishLoad(_:))
            if let originalMethod = class_getInstanceMethod(type(of: delegate), originalSelector),
                let swizzle = Swizzler.swizzles[originalMethod] {
                typealias SUGOCFunction = @convention(c) (AnyObject, Selector, UIWebView) -> Void
                let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
                curriedImplementation(self, originalSelector, webView)
                
                for (_, block) in swizzle.blocks {
                    block(self, swizzle.selector, webView, nil)
                }
            }
        }
    }
}

extension WebViewBindings {
    
    var jsUIWebViewBindingsExcute: String {
        return self.jsSource(of: "WebViewBindings.excute")
    }
    
    var jsUIWebViewBindingsSource: String {
        
        return self.jsSource(of: "WebViewBindings.1")
                + "sugo_bindings.current_page = '\(self.uiVCPath)::' + window.location.pathname;\n"
                + "sugo_bindings.h5_event_bindings = \(self.stringBindings);\n"
                + self.jsSource(of: "WebViewBindings.2")
    }
    
    var jsUIWebViewTrack: String {
        return self.jsSource(of: "UIWebViewTrack")
    }
    
}



