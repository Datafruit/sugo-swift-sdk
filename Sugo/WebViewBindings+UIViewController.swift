//
//  WebViewBindings+UIViewController.swift
//  Sugo
//
//  Created by Zack on 29/11/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit

extension WebViewBindings {
    
    func execute() {
        if !self.vcSwizzleRunning {
            let executeBlock = {
                [unowned self] (view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) in
                guard let view = view as? UIView else {
                    return
                }
                for subview in view.subviews {
                    if subview is UIWebView, let webView = subview as? UIWebView {
                        self.bindUIWebView(webView: webView)
                    } else if subview is WKWebView, let webView = subview as? WKWebView {
                        self.bindWKWebView(webView: webView)
                    }
                }
            }
            Swizzler.swizzleSelector(NSSelectorFromString("viewDidAppear:"),
                                     withSelector: #selector(UIViewController.sugoViewDidAppear(_:)),
                                     for: UIViewController.self,
                                     name: self.vcSwizzleBlockName,
                                     block: executeBlock)
            self.vcSwizzleRunning = true
        }
    }
    
    func stop() {
        if self.vcSwizzleRunning {
            if let webView = self.uiWebView {
                stopUIWebViewSwizzle(webView: webView)
            }
            if let webView = self.wkWebView {
                stopWKWebViewSwizzle(webView: webView)
            }
            Swizzler.unswizzleSelector(NSSelectorFromString("viewDidAppear:"),
                                       aClass: UIViewController.self,
                                       name: self.vcSwizzleBlockName)
            self.vcSwizzleRunning = false
        }
    }
}

extension UIViewController {
    
    @objc func sugoViewDidAppear(_ animated: Bool) {
        let originalSelector = NSSelectorFromString("viewDidAppear:")
        if let originalMethod = class_getInstanceMethod(type(of: self), originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector, Bool) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector, animated)
            
            for (_, block) in swizzle.blocks {
                block(self.view, swizzle.selector, nil, nil)
            }
        }
    }
}


