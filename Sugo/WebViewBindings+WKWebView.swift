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
            "sugo_bind.current_page ='\(self.wkVCPath)::' + window.location.pathname;\n" +
            "sugo_bind.h5_event_bindings = \(self.stringBindings);\n" +
            "sugo_bind.current_event_bindings = {};\n" +
            "for(var i=0;i<sugo_bind.h5_event_bindings.length;i++){\n" +
            " var b_event = sugo_bind.h5_event_bindings[i];\n" +
            " if(b_event.target_activity === sugo_bind.current_page){\n" +
            "  var key = JSON.stringify(b_event.path);\n" +
            "  sugo_bind.current_event_bindings[key] = b_event;\n" +
            " }\n" +
            "};\n" +
            "sugo_bind.get_node_name = function(node){\n" +
            " var path = '';\n" +
            " var name = node.localName;\n" +
            " if(name == 'script'){return '';}\n" +
            " if(name == 'link'){return '';}\n" +
            " path = name;\n" +
            " id = node.id;\n" +
            " if(id && id.length>0){\n" +
            "  path += '#' + id;\n" +
            " }\n" +
            " return path;\n" +
            "};\n" +
            "sugo_bind.bindChildNode = function (childrens, jsonArry, parent_path){\n" +
            "  var index_map={};\n" +
            "  for(var i=0;i<childrens.length;i++){\n" +
            "   var children = childrens[i];\n" +
            "   var node_name = sugo_bind.get_node_name(children);\n" +
            "   if (node_name == ''){continue;}\n" +
            "   if(index_map[node_name] == null){\n" +
            "    index_map[node_name] = 0;\n" +
            "   }else{\n" +
            "    index_map[node_name] = index_map[node_name]  + 1;\n" +
            "   }\n" +
            "   var htmlNode={};\n" +
            "   var path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n" +
            "   htmlNode.path=path;   \n" +
            "   var b_event = sugo_bind.current_event_bindings[JSON.stringify(htmlNode)];\n" +
            " if(b_event){\n" +
            "    var event = JSON.parse(JSON.stringify(b_event));\n" +
            "    sugo_bind.addEvent(children, event);\n" +
            " }\n" +
            "   if(children.children){\n" +
            "    sugo_bind.bindChildNode(children.children, jsonArry, path);\n" +
            "   }\n" +
            "  }\n" +
            "};\n" +
            "sugo_bind.addEvent = function (children, event) {\n" +
            "  children.addEventListener(event.event_type, function (e) {\n" +
            "    var message = {\n" +
            "    'eventID' : event.event_id,\n" +
            "    'eventName' : event.event_name,\n" +
            "    'properties' : '{}'\n" +
            "    };\n" +
            "    window.webkit.messageHandlers.WKWebViewBindings.postMessage(message);\n" +
            "  });\n" +
            "}\n" +
            "sugo_bind.bindEvent = function(){\n" +
            " var jsonArry=[];\n" +
            " var body = document.getElementsByTagName('body')[0];\n" +
            " var childrens = body.children;\n" +
            " var parent_path='';\n" +
            " sugo_bind.bindChildNode(childrens, jsonArry, parent_path);\n" +
            "};"
    }
}

