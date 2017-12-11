//
//  WebViewBindings+WKWebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import Foundation
import WebKit

extension WebViewBindings: WKScriptMessageHandler {
    
    func startWKWebViewBindings(webView: inout WKWebView) {
        if !self.wkWebViewJavaScriptInjected {
            self.wkWebViewCurrentJS = self.wkJavaScript
            if !webView.configuration.userContentController.userScripts.contains(self.wkWebViewCurrentJS) {
                webView.configuration.userContentController.addUserScript(self.wkWebViewCurrentJS)
                webView.configuration.userContentController.add(self, name: "SugoWKWebViewBindingsTrack")
                webView.configuration.userContentController.add(self, name: "SugoWKWebViewBindingsTime")
                webView.configuration.userContentController.add(self, name: "SugoWKWebViewReporter")
            }
            self.wkWebViewJavaScriptInjected = true
            Logger.debug(message: "WKWebView Injected")
        }
    }
    
    func stopWKWebViewBindings(webView: WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "SugoWKWebViewBindingsTrack")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "SugoWKWebViewBindingsTime")
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "SugoWKWebViewReporter")
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
                
                if let p = JSONHandler.parseJSONObjectString(properties: WebViewInfoStorage.global.properties) {
                    Sugo.mainInstance().track(eventID: WebViewInfoStorage.global.eventID,
                                              eventName: WebViewInfoStorage.global.eventName,
                                              properties: p)
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
                    if let title = body["title"] as? String,
                        let path = body["path"] as? String,
                        let clientWidth = body["clientWidth"] as? Int,
                        let clientHeight = body["clientHeight"] as? Int,
                        let nodes = body["nodes"] as? String {
                        WebViewInfoStorage.global.setHTMLInfo(withTitle: title,
                                                              path: path,
                                                              width: "\(clientWidth)",
                            height: "\(clientHeight)",
                            nodes: nodes)
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
        
        let js = self.jsWKWebViewSugoioKit
            + self.jsWKWebViewSugoBegin
            + self.jsWKWebViewVariables
            + self.jsWKWebViewAPI
            + self.jsWKWebViewBindings
            + self.jsWKWebViewReport
            + self.jsWKWebViewHeatMap
            + self.jsWKWebViewExcute
            + self.jsWKWebViewSugoEnd
        Logger.debug(message: "WKWebView JavaScript:\n\(js)")
        return js
    }
    
    var jsWKWebViewSugoioKit: String {
        return self.jsSource(of: "SugoioKit")
    }
    
    var jsWKWebViewSugoBegin: String {
        return self.jsSource(of: "SugoBegin")
    }
    
    var jsWKWebViewVariables: String {
        
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
        let vcPath = "sugo.view_controller = '\(self.wkVCPath)';\n"
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
    
    var jsWKWebViewAPI: String {
        
        return self.jsSource(of: "WebViewAPI.WK")
    }
    
    var jsWKWebViewBindings: String {
        
        return self.jsSource(of: "WebViewBindings.WK")
    }
    
    var jsWKWebViewReport: String {
        return self.jsSource(of: "WebViewReport.WK")
    }
    
    var jsWKWebViewHeatMap: String {
        return self.jsSource(of: "WebViewHeatmap")
    }
    
    var jsWKWebViewExcute: String {
        return self.jsSource(of: "WebViewExcute.Sugo.WK")
    }
    
    var jsWKWebViewSugoEnd: String {
        return self.jsSource(of: "SugoEnd")
    }

}

