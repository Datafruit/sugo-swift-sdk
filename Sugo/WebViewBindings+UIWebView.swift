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
    
    func bindUIWebView(webView: inout UIWebView) {
        if !self.uiWebViewSwizzleRunning {
            let uiWebViewDidStartLoadBlock = {
                [unowned self] (view: AnyObject?, command: Selector, webView: AnyObject?, param2: AnyObject?) in
                
                if self.uiWebViewJavaScriptInjected {
                    self.uiWebViewJavaScriptInjected = false
                    Logger.debug(message: "UIWebView Uninjected")
                }
            }
            let uiWebViewDidFinishLoadBlock = {
                [unowned self] (view: AnyObject?, command: Selector, webView: AnyObject?, param2: AnyObject?) in
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
//                    Logger.debug(message: "UIWebView Injected")
                }
            }
            if let delegate = webView.delegate {
                Swizzler.swizzleSelector(#selector(delegate.webViewDidStartLoad(_:)),
                                         withSelector: #selector(UIWebView.sugoWebViewDidStartLoad(_:)),
                                         for: type(of: delegate),
                                         and: UIWebView.self,
                                         name: self.uiWebViewDidStartLoadBlockName,
                                         block: uiWebViewDidStartLoadBlock)
                Swizzler.swizzleSelector(#selector(delegate.webViewDidFinishLoad(_:)),
                                         withSelector: #selector(UIWebView.sugoWebViewDidFinishLoad(_:)),
                                         for: type(of: delegate),
                                         and: UIWebView.self,
                                         name: self.uiWebViewDidFinishLoadBlockName,
                                         block: uiWebViewDidFinishLoadBlock)
                self.uiWebViewSwizzleRunning = true
            }
        }
    }
    
    func stopUIWebViewSwizzle(webView: UIWebView) {
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
            }
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
        return "sugo_bind.bindEvent();"
    }
    
    var jsUIWebViewBindingsSource: String {
        return "var sugo_bind={};\n" +
            "sugo_bind.current_page ='\(self.uiVCPath)::' + window.location.pathname;\n" +
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
            "sugo_bind.addEvent = function (children, event) {\n" +
            "  children.addEventListener(event.event_type, function (e) {\n" +
            "    var custom_props = {};\n" +
            "    if(event.code && event.code.replace(/(^\\s*)|(\\s*$)/g, \"\") != ''){\n" +
            "        eval(event.code);\n" +
            "        custom_props = sugo_props();\n" +
            "    }\n" +
            "    custom_props.from_binding = true;\n" +
            "    WebViewJSExport.eventWithIdNameProperties(event.event_id, event.event_name, JSON.stringify(custom_props));\n" +
            "  });\n" +
            "}\n" +
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
            "sugo_bind.bindEvent = function(){\n" +
            " var jsonArry=[];\n" +
            " var body = document.getElementsByTagName('body')[0];\n" +
            " var childrens = body.children;\n" +
            " var parent_path='';\n" +
            " sugo_bind.bindChildNode(childrens, jsonArry, parent_path);\n" +
            "};"
    }
    
}



