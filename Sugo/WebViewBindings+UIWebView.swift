//
//  WebViewBindings+UIWebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import Foundation
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
                + "sugo_bindings.current_page = '\(self.uiVCPath)::' + sugo.relative_path;\n"
                + "sugo_bindings.h5_event_bindings = \(self.stringBindings);\n"
                + self.jsSource(of: "WebViewBindings.2")
    }
    
    var jsUIWebViewTrack: String {
        
        var nativePath = String()
        if let path = self.uiWebView?.request?.url?.path {
            nativePath =  path
        }
        var relativePath = "sugo.relative_path = window.location.pathname"
        if let replacement = SugoConfiguration.Replacement as? [String: String] {
            for object in replacement {
                relativePath = relativePath
                    + ".replace(/\(object.key != "" ? object.key : " ")/g, \(object.value != "" ? object.value : "''"))"
                do {
                    var re = try NSRegularExpression(pattern: "^\(object.key != "" ? object.key : "")$", options: NSRegularExpression.Options.anchorsMatchLines)
                    nativePath = re.stringByReplacingMatches(in: nativePath,
                                                             options: [],
                                                             range: NSMakeRange(0, nativePath.characters.count),
                                                             withTemplate: "\(object.value != "" ? object.value : ""))")
                } catch {
                    Logger.debug(message: "NSRegularExpression exception")
                }
            }
            relativePath = relativePath + ";"
        }
        
        var pn = "''"
        var ic = "''"
        
        if !SugoPageInfos.global.infos.isEmpty {
            for info in SugoPageInfos.global.infos {
                if info["page"] == nativePath {
                    pn = info["page"]!
                    ic = info["code"]!
                    break
                }
            }
        }
        let pageName = "sugo.page_name = \(pn);"
        let initCode = "sugo.init_code = \(ic);"
        
        return self.jsSource(of: "WebViewTrack")
            + relativePath
            + pageName
            + initCode
            + self.jsSource(of: "WebViewTrack.UI")
    }
    
}



