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
            self.wkWebViewCurrentJS = self.wkJavaScript
            webView.configuration.userContentController.addUserScript(self.wkWebViewCurrentJS)
            webView.configuration.userContentController.add(self, name: "SugoWKWebViewBindingsTrack")
            webView.configuration.userContentController.add(self, name: "SugoWKWebViewBindingsTime")
            webView.configuration.userContentController.add(self, name: "SugoWKWebViewReporter")
            self.wkWebViewJavaScriptInjected = true
            Logger.debug(message: "WKWebView Injected")
        }
    }
    
    func stopWKWebViewBindings(webView: WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "SugoWKWebViewBindingsTrack")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "SugoWKWebViewBindingsTime")
            self.wkWebViewJavaScriptInjected = false
            self.wkWebView = nil
        }
    }
    
    func updateWKWebViewBindings(webView: inout WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            var userScripts = webView.configuration.userContentController.userScripts
            if let index = userScripts.index(of: self.wkWebViewCurrentJS) {
                userScripts.remove(at: index)
            }
            webView.configuration.userContentController.removeAllUserScripts()
            for userScript in userScripts {
                webView.configuration.userContentController.addUserScript(userScript)
            }
            self.wkWebViewCurrentJS = self.wkJavaScript
            webView.configuration.userContentController.addUserScript(self.wkWebViewCurrentJS)
            Logger.debug(message: "WKWebView Updated")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let body = message.body as? [String: Any] {
            Logger.debug(message: "message name: \(message.name)")
            switch message.name {
            case "SugoWKWebViewBindingsTrack":
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
                Logger.debug(message: "id = \(WebViewInfoStorage.global.eventID), name = \(WebViewInfoStorage.global.eventName)")
                
            case "SugoWKWebViewBindingsTime":
                if let eventName = body["eventName"] as? String {
                    Sugo.mainInstance().time(event: eventName)
                    Logger.debug(message: "time event name = \(eventName)")
                }
                
            case "SugoWKWebViewReporter":
                if let body = message.body as? [String: Any] {
                    if let path = body["path"] as? String {
                        WebViewInfoStorage.global.path = path
                    }
                    if let clientWidth = body["clientWidth"] as? String {
                        WebViewInfoStorage.global.width = clientWidth
                    }
                    if let clientHeight = body["clientHeight"] as? String {
                        WebViewInfoStorage.global.height = clientHeight
                    }
                    if let nodes = body["nodes"] as? String {
                        WebViewInfoStorage.global.nodes = nodes
                    }
                }
                
            default:
                Logger.debug(message: "Wrong message name = \(message.name)")
            }
        } else {
            Logger.debug(message: "Wrong message body type: body=\(message.body as? String)")
        }
    }
}

extension WebViewBindings {
    
    var wkJavaScript: WKUserScript {
        return WKUserScript(source: self.jsWKWebView,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var jsWKWebView: String {
        
        let js = self.jsWKWebViewUtils
            + self.jsWKWebViewSugoBegin
            + self.jsWKWebViewVariables
            + self.jsWKWebViewAPI
            + self.jsWKWebViewBindings
            + self.jsWKWebViewReport
            + self.jsWKWebViewExcute
            + self.jsWKWebViewSugoEnd
        Logger.debug(message: "WKWebView JavaScript:\n\(js)")
        return js
    }
    
    var jsWKWebViewUtils: String {
        return self.jsSource(of: "Utils")
    }
    
    var jsWKWebViewSugoBegin: String {
        return self.jsSource(of: "SugoBegin")
    }
    
    var jsWKWebViewVariables: String {
        
        var nativePath = String()
        if let path = self.wkWebView?.url?.path {
            nativePath =  path
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
        
        let vcPath = "sugo.current_page = '\(self.wkVCPath)::' + window.location.pathname;\n"
        let bindings = "sugo.h5_event_bindings = \(self.stringBindings);\n"
        let variables = self.jsSource(of: "WebViewVariables")
        
        return relativePath
            + initInfo
            + vcPath
            + bindings
            + variables
    }
    
    var jsWKWebViewAPI: String {
        
        return self.jsSource(of: "WebViewAPI.WK")
    }
    
    var jsWKWebViewBindings: String {
        
        return self.jsSource(of: "WebViewBindings.WK")
    }
    
    var jsWKWebViewReport: String {
        return self.jsSource(of: "WebViewReport.WK")
    }
    
    var jsWKWebViewExcute: String {
        return self.jsSource(of: "WebViewExcute.Sugo")
    }
    
    var jsWKWebViewSugoEnd: String {
        return self.jsSource(of: "SugoEnd")
    }

}

