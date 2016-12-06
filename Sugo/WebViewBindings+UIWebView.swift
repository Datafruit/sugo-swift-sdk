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
    
    func bindUIWebView(webView: UIWebView) {
        self.uiWebView = webView
        if !self.uiWebViewSwizzleRunning {
            var responder: UIResponder = webView
            while responder.next != nil {
                responder = responder.next!
                if responder is UIViewController {
                    self.vcPath = NSStringFromClass(responder.classForCoder)
                    Logger.debug(message: "view controller name: \(NSStringFromClass(responder.classForCoder))")
                    break
                }
            }
            let executeBlock = {
                [unowned self] (view: AnyObject?, command: Selector, webView: AnyObject?, param2: AnyObject?) in
                guard let wv = webView as? UIWebView else {
                    return
                }
                let jsContext = wv.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
                jsContext.setObject(WebViewJSExport.self,
                                    forKeyedSubscript: "WebViewJSExport" as (NSCopying & NSObjectProtocol)!)
                jsContext.evaluateScript(self.jsUIWebViewBindingsSource)
                jsContext.evaluateScript(self.jsUIWebViewBindingsExcute)
            }
            
            if let delegate = webView.delegate {
                executeBlock(nil, #function, webView, nil)
                Swizzler.swizzleSelector(#selector(delegate.webViewDidFinishLoad(_:)),
                                         withSelector: #selector(UIWebView.sugoWebViewDidFinishLoad(_:)),
                                         for: type(of: delegate),
                                         and: UIWebView.self,
                                         name: self.uiWebViewSwizzleBlockName,
                                         block: executeBlock)
                self.uiWebViewSwizzleRunning = true
            }
        }
    }
    
    func stopUIWebViewSwizzle(webView: UIWebView) {
        if self.uiWebViewSwizzleRunning {
            if let delegate = webView.delegate {
                Swizzler.unswizzleSelector(#selector(delegate.webViewDidFinishLoad(_:)),
                                           aClass: type(of: delegate),
                                           name: self.uiWebViewSwizzleBlockName)
                self.uiWebViewSwizzleRunning = false
            }
        }
    }
}

extension UIWebView {
    
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
            "\t\t\t\t\tWebViewJSExport.eventWithIdNameProperties(event.event_id, event.event_name, '{}');\n" +
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



