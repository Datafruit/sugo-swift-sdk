//
//  WebViewBindings+WebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit

extension WebViewBindings {
    
    func execute() {
        if !self.viewSwizzleRunning {
      
            // Mark: - UIWebView
            let uiDidMoveToWindowExecuteBlock = {
                [unowned self] (view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) in
                guard let webView = view as? UIWebView else {
                    return
                }
                var responder: UIResponder = webView
                while responder.next != nil {
                    responder = responder.next!
                    if responder is UIViewController {
                        self.vcPath = NSStringFromClass(responder.classForCoder)
                        Logger.debug(message: "view controller name: \(NSStringFromClass(responder.classForCoder))")
                        break
                    }
                }
                self.bindUIWebView(webView: webView)
            }
            Swizzler.swizzleSelector(#selector(UIView.didMoveToWindow),
                                     withSelector: #selector(UIView.sugoViewDidMoveToWindow),
                                     for: UIView.self,
                                     name: self.uiDidMoveToWindowBlockName,
                                     block: uiDidMoveToWindowExecuteBlock)
            
            // Mark: - WKWebView
            let wkDidMoveToWindowExecuteBlock = {
                [unowned self] (view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) in
                guard let webView = view as? WKWebView else {
                    return
                }
                var responder: UIResponder = webView
                while responder.next != nil {
                    responder = responder.next!
                    if responder is UIViewController {
                        self.vcPath = NSStringFromClass(responder.classForCoder)
                        Logger.debug(message: "view controller name: \(NSStringFromClass(responder.classForCoder))")
                        break
                    }
                }
                self.bindWKWebView(webView: webView)
            }
            
            Swizzler.swizzleSelector(#selector(WKWebView.didMoveToWindow),
                                     withSelector: #selector(WKWebView.sugoWebViewDidMoveToWindow),
                                     for: WKWebView.self,
                                     name: self.wkDidMoveToWindowBlockName,
                                     block: wkDidMoveToWindowExecuteBlock)
            let wkRemoveFromSuperviewExecuteBlock = {
                [unowned self] (view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) in
                guard let webView = view as? WKWebView else {
                    return
                }
                self.stopWKWebViewSwizzle(webView: webView)
            }
            Swizzler.swizzleSelector(#selector(WKWebView.removeFromSuperview),
                                     withSelector: #selector(WKWebView.sugoWebViewRemoveFromSuperview),
                                     for: WKWebView.self,
                                     name: self.wkRemoveFromSuperviewBlockName,
                                     block: wkRemoveFromSuperviewExecuteBlock)
            // - WKWebView -
            
            self.viewSwizzleRunning = true
        }
    }
    
    func stop() {
        if self.viewSwizzleRunning {
            if let webView = self.uiWebView {
                stopUIWebViewSwizzle(webView: webView)
            }
            if let webView = self.wkWebView {
                stopWKWebViewSwizzle(webView: webView)
            }
            Swizzler.unswizzleSelector(#selector(UIView.didMoveToWindow),
                                       aClass: UIView.self,
                                       name: self.uiDidMoveToWindowBlockName)
            Swizzler.unswizzleSelector(#selector(WKWebView.didMoveToWindow),
                                       aClass: WKWebView.self,
                                       name: self.wkDidMoveToWindowBlockName)
            Swizzler.unswizzleSelector(#selector(WKWebView.removeFromSuperview),
                                       aClass: WKWebView.self,
                                       name: self.wkRemoveFromSuperviewBlockName)
            self.viewSwizzleRunning = false
        }
    }
}

extension WKWebView {
    
    @objc func webViewCallOriginalMethodWithSwizzledBlocks(originalSelector: Selector) {
        if let originalMethod = class_getInstanceMethod(type(of: self), originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, nil, nil)
            }
        }
    }
    
    @objc func sugoWebViewDidMoveToWindow() {
        let originalSelector = NSSelectorFromString("didMoveToWindow")
        webViewCallOriginalMethodWithSwizzledBlocks(originalSelector: originalSelector)
    }
    
    @objc func sugoWebViewRemoveFromSuperview() {
        let originalSelector = NSSelectorFromString("removeFromSuperview")
        webViewCallOriginalMethodWithSwizzledBlocks(originalSelector: originalSelector)
    }
}


