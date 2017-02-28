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
        }
    }
    
    func uiWebViewDidStartLoad(view: AnyObject?, command: Selector, webView: AnyObject?, param2: AnyObject?) {
        let jsContext = (webView as! UIWebView).value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        jsContext.setObject(SugoWebViewJSExport.self,
                            forKeyedSubscript: "SugoWebViewJSExport" as (NSCopying & NSObjectProtocol)!)
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
            jsContext.setObject(SugoWebViewJSExport.self,
                                forKeyedSubscript: "SugoWebViewJSExport" as (NSCopying & NSObjectProtocol)!)
            wv.stringByEvaluatingJavaScript(from: self.jsUIWebView)
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
    
    var jsUIWebView: String {
        
        let js = self.jsUIWebViewUtils
                + self.jsUIWebViewSugoBegin
                + self.jsUIWebViewVariables
                + self.jsUIWebViewAPI
                + self.jsUIWebViewBindings
                + self.jsUIWebViewReport
                + self.jsUIWebViewExcute
                + self.jsUIWebViewSugoEnd
        Logger.debug(message: "UIWebView JavaScript:\n\(js)")
        return js
    }
    
    var jsUIWebViewUtils: String {
        return self.jsSource(of: "Utils")
    }
    
    var jsUIWebViewSugoBegin: String {
        return self.jsSource(of: "SugoBegin")
    }
    
    var jsUIWebViewVariables: String {
        
        var nativePath = String()
        if let path = self.uiWebView?.request?.url?.path {
            if let frament = self.uiWebView?.request?.url?.fragment {
                nativePath =  path + "#" + frament
            } else {
                nativePath =  path
            }
        }
        var relativePath = "sugo.relative_path = window.location.pathname"
        
        let userDefaults = UserDefaults.standard
        if let rpr = userDefaults.object(forKey: "HomePath") as? [String: String] {
            let homePath: String = rpr.keys.first!
            let replacePath: String = rpr[homePath]!
            relativePath = relativePath + ".replace('\(homePath)', '\(replacePath)')"
            Logger.debug(message: "relativePath replace HomePath:\n\(relativePath)")
            do {
                let re = try NSRegularExpression(pattern: "^\(homePath)$",
                                                    options: NSRegularExpression.Options.anchorsMatchLines)
                nativePath = re.stringByReplacingMatches(in: nativePath,
                                                         options: [],
                                                         range: NSMakeRange(0, nativePath.characters.count),
                                                         withTemplate: replacePath)
            } catch {
                Logger.debug(message: "NSRegularExpression exception")
            }
        }
        
        if let replacements = SugoConfiguration.Replacements as? [String: [String: String]] {
            for replacement in replacements {
                
                let key = replacement.value.keys.first!
                let value = replacement.value[key]!
                
                relativePath = relativePath
                    + ".replace(\(key.characters.count >= 2 ? key : "''"), '\(value)')"
            }
        }
        relativePath = relativePath + ";\n"
        relativePath = relativePath + "sugo.relative_path += window.location.hash;\n"
        Logger.debug(message: "relativePath:\n\(relativePath)")
        
        var infoObject = ["code": "", "page_name": ""]
        if !SugoPageInfos.global.infos.isEmpty {
            for info in SugoPageInfos.global.infos {
                if let infoPage = info["page"] as? String,
                    infoPage == nativePath {
                    infoObject["page_name"] = infoPage
                    if let infoCode = info["code"] as? String {
                        infoObject["code"] = infoCode
                    }
                    break
                }
            }
        }
        
        var initInfo = "sugo.init = {};\n"
        do {
            let infoData = try JSONSerialization.data(withJSONObject: infoObject,
                                                       options: JSONSerialization.WritingOptions.prettyPrinted)
            let infoString = String(data: infoData, encoding: String.Encoding.utf8)!
            initInfo = "sugo.init = \(infoString);\n"
        } catch {
            Logger.debug(message: "Sugo init info exception")
        }
        
        let vcPath = "sugo.current_page = '\(self.uiVCPath)::' + window.location.pathname;\n"
        let bindings = "sugo.h5_event_bindings = \(self.stringBindings);\n"
        let variables = self.jsSource(of: "WebViewVariables")
        
        return relativePath
            + initInfo
            + vcPath
            + bindings
            + variables
    }
    
    var jsUIWebViewAPI: String {
        
        return self.jsSource(of: "WebViewAPI.UI")
    }
    
    var jsUIWebViewBindings: String {
        
        return self.jsSource(of: "WebViewBindings.UI")
    }
    
    var jsUIWebViewReport: String {
        return self.jsSource(of: "WebViewReport.UI")
    }
    
    var jsUIWebViewExcute: String {
        return self.jsSource(of: "WebViewExcute.Sugo")
    }
    
    var jsUIWebViewSugoEnd: String {
        return self.jsSource(of: "SugoEnd")
    }
    
}



