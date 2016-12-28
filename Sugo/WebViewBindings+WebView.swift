//
//  WebViewBindings+WebView.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

extension WebViewBindings {
    
    func execute() {
        if !self.viewSwizzleRunning {
            Swizzler.swizzleSelector(#selector(UIWebView.didMoveToWindow),
                                     withSelector: #selector(UIWebView.sugoWebViewDidMoveToWindow),
                                     for: NSClassFromString("UIWebView")!,
                                     name: self.uiDidMoveToWindowBlockName,
                                     block: self.uiDidMoveToWindow)
            Swizzler.swizzleSelector(#selector(UIWebView.removeFromSuperview),
                                     withSelector: #selector(UIWebView.sugoWebViewRemoveFromSuperview),
                                     for: NSClassFromString("UIWebView")!,
                                     name: self.uiRemoveFromSuperviewBlockName,
                                     block: self.uiRemoveFromSuperview)
            Swizzler.swizzleSelector(#selector(WKWebView.didMoveToWindow),
                                     withSelector: #selector(WKWebView.sugoWebViewDidMoveToWindow),
                                     for: WKWebView.self,
                                     name: self.wkDidMoveToWindowBlockName,
                                     block: self.wkDidMoveToWindow)
            Swizzler.swizzleSelector(#selector(WKWebView.removeFromSuperview),
                                     withSelector: #selector(WKWebView.sugoWebViewRemoveFromSuperview),
                                     for: WKWebView.self,
                                     name: self.wkRemoveFromSuperviewBlockName,
                                     block: self.wkRemoveFromSuperview)
            self.viewSwizzleRunning = true
        }
    }
    
    func stop() {
        if self.viewSwizzleRunning {
            if let webView = self.uiWebView {
                stopUIWebViewBindings(webView: webView)
            }
            if let webView = self.wkWebView {
                stopWKWebViewBindings(webView: webView)
            }
            Swizzler.unswizzleSelector(#selector(UIWebView.didMoveToWindow),
                                       aClass: NSClassFromString("UIWebView")!,
                                       name: self.uiDidMoveToWindowBlockName)
            Swizzler.unswizzleSelector(#selector(UIWebView.removeFromSuperview),
                                       aClass: NSClassFromString("UIWebView")!,
                                       name: self.uiRemoveFromSuperviewBlockName)
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

extension WebViewBindings {
    
    // Mark: - UIWebView
    func uiDidMoveToWindow(view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) {
        guard let webView = view as? UIWebView else {
            return
        }
        guard self.uiVCPath.isEmpty else {
            return
        }
        var responder: UIResponder = webView
        while responder.next != nil {
            responder = responder.next!
            if responder is UIViewController {
                self.uiVCPath = NSStringFromClass(responder.classForCoder)
                Logger.debug(message: "view controller name: \(NSStringFromClass(responder.classForCoder))")
                break
            }
        }
        self.uiWebView = webView
        self.startUIWebViewBindings(webView: &(self.uiWebView!))
    }
    
    func uiRemoveFromSuperview(view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) {
        guard let webView = view as? UIWebView else {
            return
        }
        self.uiVCPath.removeAll()
        self.stopUIWebViewBindings(webView: webView)
        if self.isTimerStarted && !self.lastURLString.isEmpty {
            let pLastURL: Properties = ["page": self.lastURLString]
            Sugo.mainInstance().track(eventName: "h5_stay_event", properties: pLastURL)
            self.isTimerStarted = false
        }
    }

    // Mark: - WKWebView
    func wkDidMoveToWindow(view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) {
        guard let webView = view as? WKWebView else {
            return
        }
        guard self.wkVCPath.isEmpty else {
            return
        }
        var responder: UIResponder = webView
        while responder.next != nil {
            responder = responder.next!
            if responder is UIViewController {
                self.wkVCPath = NSStringFromClass(responder.classForCoder)
                Logger.debug(message: "view controller name: \(NSStringFromClass(responder.classForCoder))")
                break
            }
        }
        self.wkWebView = webView
        self.startWKWebViewBindings(webView: &(self.wkWebView!))
    }
    
    func wkRemoveFromSuperview(view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) {
        guard let webView = view as? WKWebView else {
            return
        }
        self.wkVCPath.removeAll()
        self.stopWKWebViewBindings(webView: webView)
        if self.isTimerStarted && !self.lastURLString.isEmpty {
            let pLastURL: Properties = ["page": self.lastURLString]
            Sugo.mainInstance().track(eventName: "h5_stay_event", properties: pLastURL)
            self.isTimerStarted = false
        }
    }
    
}

extension WebViewBindings {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        Logger.debug(message: "Object = \(object): K: \(keyPath) = V: \(change?[NSKeyValueChangeKey.newKey])")
        if keyPath == "stringBindings" {
            if self.mode == WebViewBindingsMode.codeless
                && Sugo.mainInstance().isCodelessTesting {
                self.isWebViewNeedReload = true
            }
            if !self.isWebViewNeedReload {
                stop()
                execute()
            }
        }
        
        if keyPath == "isWebViewNeedReload" {
            guard self.isWebViewNeedReload else {
                return
            }
            if let wv = self.uiWebView {
                updateUIWebViewBindings(webView: &(self.uiWebView!))
                wv.perform(#selector(wv.reload),
                           on: Thread.main,
                           with: nil,
                           waitUntilDone: false)
            }
            if let wv = self.wkWebView {
                updateWKWebViewBindings(webView: &(self.wkWebView!))
                wv.perform(#selector(wv.reload),
                           on: Thread.main,
                           with: nil,
                           waitUntilDone: false)
            }
        }
    }
}

extension UIWebView {
    
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


