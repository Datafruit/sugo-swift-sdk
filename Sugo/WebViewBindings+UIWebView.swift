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
        guard !url.path.isEmpty else {
            return
        }
        if !self.uiWebViewJavaScriptInjected {
            let jsContext = wv.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
            jsContext.setObject(WebViewJSExport.self,
                                forKeyedSubscript: "WebViewJSExport" as (NSCopying & NSObjectProtocol)!)
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
        return "sugo_binding.bindEvent();"
    }
    
    var jsUIWebViewBindingsSource: String {
        return "var sugo_binding = {};\n" +
            "sugo_binding.current_page = '\(self.uiVCPath)::' + window.location.pathname;\n" +
            "sugo_binding.h5_event_bindings = \(self.stringBindings);\n" +
            "sugo_binding.current_event_bindings = {};\n" +
            "for (var i = 0; i < sugo_binding.h5_event_bindings.length; i++) {\n" +
            "  var b_event = sugo_binding.h5_event_bindings[i];\n" +
            "  if (b_event.target_activity === sugo_binding.current_page) {\n" +
            "    var key = JSON.stringify(b_event.path);\n" +
            "    sugo_binding.current_event_bindings[key] = b_event;\n" +
            "  }\n" +
            "};\n" +
            "sugo_binding.addEvent = function (children, event) {\n" +
            "  children.addEventListener(event.event_type, function (e) {\n" +
            "    var custom_props = {};\n" +
            "    if(event.code && event.code.replace(/(^\\s*)|(\\s*$)/g, \"\") != ''){\n" +
            "        eval(event.code);\n" +
            "        custom_props = sugo_props();\n" +
            "    }\n" +
            "    custom_props.from_binding = true;\n" +
            "    WebViewJSExport.eventWithIdNameProperties(event.event_id, event.event_name, JSON.stringify(custom_props));\n" +
            "  });\n" +
            "};\n" +
            "sugo_binding.bindEvent = function () {\n" +
            "  var paths = Object.keys(sugo_binding.current_event_bindings);\n" +
            "  for(var idx in paths){\n" +
            "    var path_str = paths[idx];\n" +
            "    var event = sugo_binding.current_event_bindings[path_str];\n" +
            "    var eles = document.querySelectorAll(JSON.parse(paths[idx]).path);\n" +
            "    if(eles){\n" +
            "      for(var eles_idx=0;eles_idx < eles.length; eles_idx ++){\n" +
            "        var ele = eles[eles_idx];\n" +
            "        sugo_binding.addEvent(ele, event);\n" +
            "      }\n" +
            "    }\n" +
            "    \n" +
            "  }\n" +
            "};\n"
    }
    
}



