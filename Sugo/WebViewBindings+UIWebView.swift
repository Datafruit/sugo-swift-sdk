//
//  WebViewBindings+UIWebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import Foundation
import UIKit

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
            if self.uiWebView != nil,
                let delegate = webView.delegate {
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
            wv.stringByEvaluatingJavaScript(from: self.jsUIWebView)
            self.uiWebViewJavaScriptInjected = true
            Logger.debug(message: "UIWebView Injected")
        }
    }
    
    private func track(eventID: String? = nil, eventName: String?, properties: String? = nil) {
        if let properties = properties,
            let p = JSONHandler.parseJSONObjectString(properties: properties) {
            Sugo.mainInstance().track(eventID: eventID,
                                      eventName: eventName,
                                      properties: p)
        } else {
            Sugo.mainInstance().track(eventID: eventID,
                                      eventName: eventName)
        }
    }
    
    func trackStayEvent(of webView: UIWebView) {
        if let eventString = webView.stringByEvaluatingJavaScript(from: "sugo.trackStayEvent();"),
            let eventData = eventString.data(using: String.Encoding.utf8),
            let event = try? JSONSerialization.jsonObject(with: eventData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any],
            let eventID = event!["eventID"] as? String,
            let eventName = event!["eventName"] as? String,
            let properties = event!["properties"] as? String {
            let storage = WebViewInfoStorage.global
            storage.eventID = eventID
            storage.eventName = eventName
            storage.properties = properties
            track(eventID: storage.eventID, eventName: storage.eventName, properties: storage.properties)
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        var shouldStartLoad = true
        if let url = request.url {
            Logger.debug(message: "request: \(url.absoluteString)")
            if url.scheme == "sugo.npi" {
                if let npi = url.host,
                    let uuid = url.query?.components(separatedBy: "=").last,
                    let eventString = webView.stringByEvaluatingJavaScript(from: "sugo.dataOf('\(uuid)');"),
                    let eventData = eventString.data(using: String.Encoding.utf8),
                    let event = try? JSONSerialization.jsonObject(with: eventData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    let storage = WebViewInfoStorage.global
                    if npi == "track",
                        let eventID = event!["eventID"] as? String,
                        let eventName = event!["eventName"] as? String,
                        let properties = event!["properties"] as? String {
                        storage.eventID = eventID
                        storage.eventName = eventName
                        storage.properties = properties
                        track(eventID: storage.eventID, eventName: storage.eventName, properties: storage.properties)
                    } else if npi == "time",
                        let eventName = event!["eventName"] as? String {
                        Sugo.mainInstance().time(event: eventName)
                    }
                }
                shouldStartLoad = false
            }
        }
        if shouldStartLoad && webView.window != nil {
            trackStayEvent(of: webView)
        }
        
        return shouldStartLoad
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
            + self.jsUIWebViewHeatMap
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
        
        let userDefaults = UserDefaults.standard
        var homePathKey = ""
        var homePathValue = ""
        if let rpr = userDefaults.object(forKey: "HomePath") as? [String: String] {
            homePathKey = rpr.keys.first!
            homePathValue = rpr[homePathKey]!
        }
        var res = [[String: String]]()
        var resString = "[]"
        if let replacements = SugoConfiguration.Replacements as? [String: [String: String]] {
            for replacement in replacements {
                let key: String = replacement.value.keys.first!
                let value: String = replacement.value[key]!
                res.append([key: value])
            }
            var resJSON = Data()
            do {
                resJSON = try JSONSerialization.data(withJSONObject: res,
                                                     options: JSONSerialization.WritingOptions.prettyPrinted)
                if let string = String(data: resJSON, encoding: String.Encoding.utf8) {
                    resString = string
                }
            } catch {
                Logger.debug(message: "exception: \(error), decoding resJSON data: \(resJSON) -> \(resString)")
            }
        }
        var infosString = "[]"
        if !SugoPageInfos.global.infos.isEmpty {
            var infosJSON = Data()
            do {
                infosJSON = try JSONSerialization.data(withJSONObject: SugoPageInfos.global.infos,
                                                       options: JSONSerialization.WritingOptions.prettyPrinted)
                if let string = String(data: infosJSON, encoding: String.Encoding.utf8) {
                    infosString = string
                }
            } catch {
                Logger.debug(message: "exception: \(error), decoding resJSON data: \(infosJSON) -> \(infosString)")
            }
        }
        let vcPath = "sugo.view_controller = '\(self.uiVCPath)';\n"
        let homePath = "sugo.home_path = '\(homePathKey)';\n"
        let homePathReplacement = "sugo.home_path_replacement = '\(homePathValue)';\n"
        let regularExpressions = "sugo.regular_expressions = \(resString);\n"
        let pageInfos = "sugo.page_infos = \(infosString);\n"
        let bindings = "sugo.h5_event_bindings = \(self.stringBindings);\n"
        let canTrackWebPage = "sugo.can_track_web_page = \(SugoPermission.canTrackWebPage);\n"
        let canShowHeatMap = "sugo.can_show_heat_map = \(self.isHeatMapModeOn ? "true" : "false");\n"
        let heats = "sugo.h5_heats = \(self.stringHeats);\n"
        let vars = self.jsSource(of: "WebViewVariables")
        
        return vcPath
            + homePath
            + homePathReplacement
            + regularExpressions
            + pageInfos
            + bindings
            + canTrackWebPage
            + canShowHeatMap
            + heats
            + vars
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
    
    var jsUIWebViewHeatMap: String {
        return self.jsSource(of: "WebViewHeatmap")
    }
    
    var jsUIWebViewExcute: String {
        return self.jsSource(of: "WebViewExcute.Sugo.UI")
    }
    
    var jsUIWebViewSugoEnd: String {
        return self.jsSource(of: "SugoEnd")
    }
    
}



