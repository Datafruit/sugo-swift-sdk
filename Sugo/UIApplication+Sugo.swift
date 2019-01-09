//
//  UIApplication+Sugo.swift
//  Sugo
//
//  Created by 陈宇艺 on 2019/1/9.
//  Copyright © 2019 sugo. All rights reserved.
//

import Foundation

extension UIApplication {
    @objc func sugoSendEventBlock(_ event: UIEvent) {
        let originalSelector = #selector(UIApplication.sendEvent(_ :))
        if let originalMethod = class_getInstanceMethod(UIApplication.self, originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector, UIEvent) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector, event)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, event, nil)
            }
        }
    }

    @objc func sugoViewDidAppearBlock(_ animated: Bool) {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        if let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector, Bool) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector, animated)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, nil, nil)
            }
        }
    }
    
}

