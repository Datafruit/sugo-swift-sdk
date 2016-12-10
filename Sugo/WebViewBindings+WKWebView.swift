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
    
    func bindWKWebView(webView: WKWebView) {
        self.wkWebView = webView
        if !self.wkWebViewJavaScriptInjected {
            let jsSource = WKUserScript(source: self.jsWKWebViewBindingsSource, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
            let jsExcute = WKUserScript(source: self.jsWKWebViewBindingsExcute, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
            self.wkWebView?.configuration.userContentController.addUserScript(jsSource)
            self.wkWebView?.configuration.userContentController.addUserScript(jsExcute)
            self.wkWebView?.configuration.userContentController.add(self, name: "WKWebViewBindings")
            Logger.debug(message: "WKWebView Injected")
            self.wkWebViewJavaScriptInjected = true
        }
    }
    
    func stopWKWebViewSwizzle(webView: WKWebView) {
        if self.wkWebViewJavaScriptInjected {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: "WKWebViewBindings")
            self.wkWebViewJavaScriptInjected = false
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
}

extension WebViewBindings {
    
    var jsWKWebViewBindingsExcute: String {
        return "sugo_bind.bindEvent();"
    }
    
    var jsWKWebViewBindingsSource: String {
        return "var sugo_bind={};\n" +
            "sugo_bind.current_page ='\(self.vcPath)::' + window.location.pathname;\n" +
            "sugo_bind.h5_event_bindings = \(self.stringBindings);\n" +
            "sugo_bind.current_event_bindings = {};\n" +
            "for(var i=0;i<sugo_bind.h5_event_bindings.length;i++){\n" +
            "\tvar b_event = sugo_bind.h5_event_bindings[i];\n" +
            "\tif(b_event.target_activity === sugo_bind.current_page){\n" +
            "\t\tvar key = JSON.stringify(b_event.path);\n" +
            "\t\tsugo_bind.current_event_bindings[key] = b_event;\n" +
            "\t}\n" +
            "};\n" +
            "sugo_bind.get_node_name = function(node){\n" +
            "\tvar path = '';\n" +
            "\tvar name = node.localName;\n" +
            "\tif(name == 'script'){return '';}\n" +
            "\tif(name == 'link'){return '';}\n" +
            "\tpath = name;\n" +
            "\tid = node.id;\n" +
            "\tif(id && id.length>0){\n" +
            "\t\tpath += '#' + id;\n" +
            "\t}\n" +
            "\treturn path;\n" +
            "};\n" +
            "sugo_bind.bindChildNode = function (childrens, jsonArry, parent_path){\n" +
            "\t\tvar index_map={};\n" +
            "\t\tfor(var i=0;i<childrens.length;i++){\n" +
            "\t\t\tvar children = childrens[i];\n" +
            "\t\t\tvar node_name = sugo_bind.get_node_name(children);\n" +
            "\t\t\tif (node_name == ''){continue;}\n" +
            "\t\t\tif(index_map[node_name] == null){\n" +
            "\t\t\t\tindex_map[node_name] = 0;\n" +
            "\t\t\t}else{\n" +
            "\t\t\t\tindex_map[node_name] = index_map[node_name]  + 1;\n" +
            "\t\t\t}\n" +
            "\t\t\tvar htmlNode={};\n" +
            "\t\t\tvar path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n" +
            "\t\t\thtmlNode.path=path;\t\t\t\n" +
            "\t\t\tvar b_event = sugo_bind.current_event_bindings[JSON.stringify(htmlNode)];\n" +
            "\tif(b_event){\n" +
            "\t\t\t\tvar event = JSON.parse(JSON.stringify(b_event));\n" +
            "\t\t\t\tchildren.addEventListener(event.event_type, function(e){\n" +
            "var message = {\n" +
            "\t\t\t\t'eventID' : event.event_id,\n" +
            "\t\t\t\t'eventName' : event.event_name,\n" +
            "\t\t\t\t'properties' : '{}'\n" +
            "\t\t\t\t};\n" +
            "window.webkit.messageHandlers.WKWebViewBindings.postMessage(message);\n" +
            "\t\t\t\t});\n" +
            "\t}\n" +
            "\t\t\tif(children.children){\n" +
            "\t\t\t\tsugo_bind.bindChildNode(children.children, jsonArry, path);\n" +
            "\t\t\t}\n" +
            "\t\t}\n" +
            "};" +
            "sugo_bind.bindEvent = function(){\n" +
            "\tvar jsonArry=[];\n" +
            "\tvar body = document.getElementsByTagName('body')[0];\n" +
            "\tvar childrens = body.children;\n" +
            "\tvar parent_path='';\n" +
            "\tsugo_bind.bindChildNode(childrens, jsonArry, parent_path);\n" +
        "};"
    }
}

