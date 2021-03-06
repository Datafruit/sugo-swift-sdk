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
            Swizzler.swizzleSelector(#selector(UIWebView.didMoveToWindow),
                                     withSelector: #selector(UIWebView.sugoWebViewDidMoveToWindow),
                                     for: NSClassFromString("UIWebView")!,
                                     name: self.uiDidMoveToWindowBlockName,
                                     block: self.uiDidMoveToWindow)
            Swizzler.swizzleSelector(#selector(WKWebView.didMoveToWindow),
                                     withSelector: #selector(WKWebView.sugoWebViewDidMoveToWindow),
                                     for: WKWebView.self,
                                     name: self.wkDidMoveToWindowBlockName,
                                     block: self.wkDidMoveToWindow)
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
            Swizzler.unswizzleSelector(#selector(WKWebView.didMoveToWindow),
                                       aClass: WKWebView.self,
                                       name: self.wkDidMoveToWindowBlockName)
            self.viewSwizzleRunning = false
        }
    }
    
    func jsSource(of fileName: String) -> String {
        var source: String = String()
        let bundle = Bundle(for: Sugo.self)
        if let sourcePath = bundle.path(forResource: fileName, ofType: "js") {
            do {
                source = try NSString(contentsOfFile: sourcePath,
                                      encoding: String.Encoding.utf8.rawValue) as String
            } catch {
                Logger.debug(message: "Can not get javascript source from bundle resource")
            }
        }
        return source
    }
}

extension WebViewBindings {
    
    // Mark: - UIWebView
    func uiDidMoveToWindow(view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) {
        guard let webView = view as? UIWebView else {
            return
        }        
        if self.uiWebView == nil || webView.window != nil {
            if self.uiWebView != nil && self.uiWebView == webView {
                return
            }
            if self.uiWebView != nil
                && self.uiWebView != webView
                && self.uiWebViewSwizzleRunning {
                self.trackStayEvent(of: self.uiWebView!)
                self.stopUIWebViewBindings(webView: self.uiWebView!)
            }
            if let vc = UIViewController.sugoCurrentUIViewController() {
                self.uiVCPath = NSStringFromClass(vc.classForCoder)
                Logger.debug(message: "view controller name: \(self.uiVCPath)")
            }
            self.uiWebView = webView
            self.startUIWebViewBindings(webView: &(self.uiWebView!))
        } else {
            if self.uiWebView != webView {
                return
            }
            if self.uiWebView != nil && self.uiWebViewSwizzleRunning {
                self.trackStayEvent(of: self.uiWebView!)
                self.stopUIWebViewBindings(webView: self.uiWebView!)
            }
        }
        
    }

    // Mark: - WKWebView
    func wkDidMoveToWindow(view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) {
        guard let webView = view as? WKWebView else {
            return
        }
        if self.wkWebView != nil {
            self.wkVCPath.removeAll()
            self.stopWKWebViewBindings(webView: self.wkWebView!)
            return
        }
        self.stopWKWebViewBindings(webView: webView)
        if let vc = UIViewController.sugoCurrentUIViewController() {
            self.wkVCPath = NSStringFromClass(vc.classForCoder)
            Logger.debug(message: "view controller name: \(self.wkVCPath)")
        }
        self.wkWebView = webView
        self.startWKWebViewBindings(webView: &(self.wkWebView!))
    }
    
}

// Mark: - KVO
extension WebViewBindings {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        Logger.debug(message: "Object = \(object.debugDescription): K: \(keyPath.debugDescription) = V: \((change?[NSKeyValueChangeKey.newKey]).debugDescription)")
        if keyPath == "stringBindings" {
            if self.mode == WebViewBindingsMode.codeless {
                self.isWebViewNeedReload = true
            }
            if !self.isWebViewNeedReload && self.isWebViewNeedInject {
                stop()
                execute()
                if self.isWebViewNeedInject {
                    self.isWebViewNeedInject = false
                }
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
        
        if keyPath == "isHeatMapModeOn" {
            self.isWebViewNeedReload = true
        }
        
    }
}

// Mark: - UIWebView Swizzle method
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

// Mark: - WKWebView Swizzle method
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


