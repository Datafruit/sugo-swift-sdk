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
            self.wkWebViewCurrentJSSugo = self.wkJavaScriptSugo
            self.wkWebViewCurrentJSTrack = self.wkJavaScriptTrack
            self.wkWebViewCurrentJSBindingsSource = self.wkJavaScriptBindingsSource
            self.wkWebViewCurrentJSUtils = self.wkJavaScriptUtils
            self.wkWebViewCurrentJSReportSource = self.wkJavaScriptReportSource
            self.wkWebViewCurrentJSBindingsExcute = self.wkJavaScriptBindingsExcute
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSSugo)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSTrack)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSBindingsSource)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSUtils)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSReportSource)
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSBindingsExcute)
            webView.configuration.userContentController.add(self, name: "WKWebViewBindingsTrack")
            webView.configuration.userContentController.add(self, name: "WKWebViewBindingsTime")
            webView.configuration.userContentController.add(self, name: "WKWebViewReporter")
            self.wkWebViewJavaScriptInjected = true
            Logger.debug(message: "WKWebView Injected")
        }
    }
    
    func stopWKWebViewBindings(webView: WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "WKWebViewBindingsTrack")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "WKWebViewBindingsTime")
            self.wkWebViewJavaScriptInjected = false
            self.wkWebView = nil
        }
    }
    
    func updateWKWebViewBindings(webView: inout WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            var userScripts = webView.configuration.userContentController.userScripts
            if let index = userScripts.index(of: self.wkWebViewCurrentJSBindingsSource) {
                userScripts.remove(at: index)
            }
            webView.configuration.userContentController.removeAllUserScripts()
            for userScript in userScripts {
                webView.configuration.userContentController.addUserScript(userScript)
            }
            self.wkWebViewCurrentJSBindingsSource = self.wkJavaScriptBindingsSource
            webView.configuration.userContentController
                .addUserScript(self.wkWebViewCurrentJSBindingsSource)
            Logger.debug(message: "WKWebView Updated")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let body = message.body as? [String: Any] {
            Logger.debug(message: "message name: \(message.name)")
            switch message.name {
            case "WKWebViewBindingsTrack":
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
                
            case "WKWebViewBindingsTime":
                if let eventName = body["eventName"] as? String {
                    Sugo.mainInstance().time(event: eventName)
                    Logger.debug(message: "time event name = \(eventName)")
                }
                
            case "WKWebViewReporter":
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
    
    var wkJavaScriptSugo: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewSugo,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var wkJavaScriptTrack: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewTrack,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var wkJavaScriptBindingsSource: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewBindingsSource,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var wkJavaScriptBindingsExcute: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewBindingsExcute,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var wkJavaScriptUtils: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewUtils,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var wkJavaScriptReportSource: WKUserScript {
        return WKUserScript(source: self.jsWKWebViewReportSource,
                            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
                            forMainFrameOnly: true)
    }
    
    var jsWKWebViewSugo: String {
        return self.jsSource(of: "Sugo")
    }
    
    var jsWKWebViewTrack: String {
        
        var nativePath = String()
        if let path = self.wkWebView?.url?.path {
            nativePath =  path
        }
        var relativePath = "sugo.relative_path = window.location.pathname"
        if let replacement = SugoConfiguration.Replacement as? [String: String] {
            for object in replacement {
                relativePath = relativePath
                    + ".replace(/\(object.key != "" ? object.key : " ")/g, \(object.value != "" ? object.value : "''"))"
                do {
                    let re = try NSRegularExpression(pattern: "^\(object.key != "" ? object.key : "")$", options: NSRegularExpression.Options.anchorsMatchLines)
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
            + self.jsSource(of: "WebViewTrack.WK")
    }
    
    var jsWKWebViewBindingsSource: String {
        return "sugo.current_page = '\(self.wkVCPath)::' + sugo.relative_path;\n"
            + "sugo.h5_event_bindings = \(self.stringBindings);\n"
            + self.jsSource(of: "WebViewBindings.WK")
    }
    
    var jsWKWebViewBindingsExcute: String {
        return self.jsSource(of: "WebViewBindings.excute")
    }
    
    var jsWKWebViewUtils: String {
        return self.jsSource(of: "Utils")
    }
    
    var jsWKWebViewReportSource: String {
        return self.jsSource(of: "WebViewReport.WK")
    }
    
}

