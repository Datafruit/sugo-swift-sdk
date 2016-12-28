//
//  WebViewBindings+WKWebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import Foundation
import WebKit
import JavaScriptCore

extension WebViewBindings: WKScriptMessageHandler {
    
    func startWKWebViewBindings(webView: inout WKWebView) {
        if !self.wkWebViewJavaScriptInjected {
            self.wkWebViewCurrentJSSource = self.wkJavaScriptSource
            self.wkWebViewCurrentJSExcute = self.wkJavaScriptExcute
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSSource)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSExcute)
            webView.configuration.userContentController.add(self, name: "WKWebViewBindings")
            if let delegate = webView.navigationDelegate {
                Swizzler.swizzleSelector(#selector(delegate.webView(_:didFinish:)),
                                         withSelector: #selector(WKWebView.sugoWebView(_:didFinish:)),
                                         for: type(of: delegate),
                                         and: WKWebView.self,
                                         name: self.wkWebViewDidFinishBlockName,
                                         block: self.wkWebViewDidFinish)
            }
            self.wkWebViewJavaScriptInjected = true
            Logger.debug(message: "WKWebView Injected")
        }
    }
    
    func stopWKWebViewBindings(webView: WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "WKWebViewBindings")
            if let delegate = webView.navigationDelegate {
                Swizzler.unswizzleSelector(#selector(delegate.webView(_:didFinish:)),
                                           aClass: type(of: delegate),
                                           name: self.wkWebViewDidFinishBlockName)
            }
            self.wkWebViewJavaScriptInjected = false
            self.wkWebView = nil
        }
    }
    
    func updateWKWebViewBindings(webView: inout WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            var userScripts = webView.configuration.userContentController.userScripts
            if let index = userScripts.index(of: self.wkWebViewCurrentJSSource) {
                userScripts.remove(at: index)
            }
            if let index = userScripts.index(of: self.wkWebViewCurrentJSExcute) {
                userScripts.remove(at: index)
            }
            webView.configuration.userContentController.removeAllUserScripts()
            for userScript in userScripts {
                webView.configuration.userContentController.addUserScript(userScript)
            }
            self.wkWebViewCurrentJSSource = self.wkJavaScriptSource
            self.wkWebViewCurrentJSExcute = self.wkJavaScriptExcute
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSSource)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSExcute)
            Logger.debug(message: "WKWebView Updated")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let body = message.body as? [String: Any] {
            if let eventID = body["eventID"] as? String {
                WebViewInfoStorage.global.eventID = eventID
            }
            if let eventName = body["eventName"] as? String {
                WebViewInfoStorage.global.eventName = eventName
            }
            if let properties = body["properties"] as? String {
                WebViewInfoStorage.global.properties = properties
            }
            
            let pData = WebViewInfoStorage.global.properties.data(using: String.Encoding.utf8)
            if let pJSON = try? JSONSerialization.jsonObject(with: pData!,
                                                             options: JSONSerialization.ReadingOptions.mutableContainers) as? Properties {
                Sugo.mainInstance().track(eventID: WebViewInfoStorage.global.eventID,
                                              eventName: WebViewInfoStorage.global.eventName,
                                              properties: pJSON)
            } else {
                Sugo.mainInstance().track(eventID: WebViewInfoStorage.global.eventID,
                                              eventName: WebViewInfoStorage.global.eventName)
            }
            Logger.debug(message: "id:\(WebViewInfoStorage.global.eventID), name:\(WebViewInfoStorage.global.eventName)")
        } else {
            Logger.debug(message: "Wrong message body type: name=\(message.name), body=\(message.body as? String)")
        }
    }
    
    func wkWebViewDidFinish(view: AnyObject?, command: Selector, webView: AnyObject?, navigation: AnyObject?) {
        guard let wv = webView as? WKWebView else {
            return
        }
        guard let url = webView?.url else {
            return
        }
        guard !url.absoluteString.isEmpty else {
            return
        }
        guard !wv.isLoading else {
            return
        }
        if self.isTimerStarted && !self.lastURLString.isEmpty {
            let pLastURL: Properties = ["page": self.lastURLString]
            Sugo.mainInstance().track(eventName: "h5_stay_event", properties: pLastURL)
            self.isTimerStarted = false
        }
        if let query = url.query {
            self.lastURLString = (url.path.isEmpty ? "/" : url.path) + "?" + query
        } else {
            self.lastURLString = url.path
        }
        let pURL: Properties = ["page": self.lastURLString]
        Sugo.mainInstance().track(eventName: "h5_enter_page_event", properties: pURL)
        Sugo.mainInstance().time(event: "h5_stay_event")
        self.isTimerStarted = true
    }
}

extension WKWebView {
    
    @objc func sugoWebView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let delegate = webView.navigationDelegate {
            let originalSelector = #selector(delegate.webView(_:didFinish:))
            if let originalMethod = class_getInstanceMethod(type(of: delegate), originalSelector),
                let swizzle = Swizzler.swizzles[originalMethod] {
                typealias SUGOCFunction = @convention(c) (AnyObject, Selector, WKWebView, WKNavigation) -> Void
                let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
                curriedImplementation(self, originalSelector, webView, navigation)
                
                for (_, block) in swizzle.blocks {
                    block(self, swizzle.selector, webView, navigation)
                }
            }
        }
    }
}

extension WebViewBindings {
    
    var wkJavaScriptExcute: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewBindingsExcute,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var wkJavaScriptSource: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewBindingsSource,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var jsWKWebViewBindingsExcute: String {
        return "sugo_binding.bindEvent();"
    }
    
    var jsWKWebViewBindingsSource: String {
        return "var sugo_binding = {};\n" +
            "sugo_binding.current_page = '\(self.wkVCPath)::' + window.location.pathname;\n" +
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
            "    var message = {\n" +
            "    'eventID' : event.event_id,\n" +
            "    'eventName' : event.event_name,\n" +
            "    'properties' : JSON.stringify(custom_props)\n" +
            "    };\n" +
            "    window.webkit.messageHandlers.WKWebViewBindings.postMessage(message);\n" +
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

