//
//  UIViewController+Sugo.swift
//  Sugo
//
//  Created by Zack on 20/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation



extension UIViewController {
    
    @objc func sugoCollectionViewDidSelectItemAtIndexPath(collectionView: UICollectionView, indexPath: IndexPath) {
        let originalSelector = NSSelectorFromString("collectionView:didSelectItemAtIndexPath:")
        if let originalMethod = class_getInstanceMethod(type(of: self), originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector, UICollectionView, IndexPath) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector, collectionView, indexPath)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, collectionView, indexPath as AnyObject?)
            }
        }
    }
    
    @objc func sugoTableViewDidSelectRowAtIndexPath(tableView: UITableView, indexPath: IndexPath) {
        let originalSelector = NSSelectorFromString("tableView:didSelectRowAtIndexPath:")
        if let originalMethod = class_getInstanceMethod(type(of: self), originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector, UITableView, IndexPath) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector, tableView, indexPath)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, tableView, indexPath as AnyObject?)
            }
        }
    }
    
    @objc func sugoTextViewDidBeginEditing(_ textView: UITextView) {
        let originalSelector = NSSelectorFromString("textViewDidBeginEditing:")
        if let originalMethod = class_getInstanceMethod(type(of: self), originalSelector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias SUGOCFunction = @convention(c) (AnyObject, Selector, UITextView) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: SUGOCFunction.self)
            curriedImplementation(self, originalSelector, textView)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, textView, nil)
            }
        }
    }
    
}

extension UIViewController {
    
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
    
    @objc func sugoViewDidDisappearBlock(_ animated: Bool) {
        Logger.info(message: "sugoViewDidDisappearBlock")
        let originalSelector = #selector(UIViewController.viewDidDisappear(_:))
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

extension UIViewController {
    
    class func sugoCurrentUITabBarController() -> UITabBarController? {
        let vc = UIViewController.sugoCurrentUIViewController()
        return vc?.tabBarController
    }
    
    class func sugoCurrentUINavigationController() -> UINavigationController? {
        let vc = UIViewController.sugoCurrentUIViewController()
        return vc?.navigationController
    }
    
    class func sugoCurrentUIViewController() -> UIViewController? {
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            return searchViewController(from: rootViewController)
        }
        return nil
    }
    
    private class func searchViewController(from viewController: UIViewController) -> UIViewController? {
        
        if viewController is UINavigationController,
            let nvc = viewController as? UINavigationController {
            
            if let visibleVC = nvc.visibleViewController {
                return searchViewController(from:visibleVC)
            }
            if let topVC = nvc.topViewController {
                return searchViewController(from:topVC)
            }
            if !nvc.childViewControllers.isEmpty {
                return searchViewController(from: nvc.childViewControllers.last!)
            }
        }
        if viewController is UITabBarController,
            let tvc = viewController as? UITabBarController {
            
            if let selectedVC = tvc.selectedViewController {
                return searchViewController(from:selectedVC)
            }
            if !tvc.childViewControllers.isEmpty {
                return searchViewController(from: tvc.childViewControllers.last!)
            }
        }
        if viewController is UISplitViewController,
            let svc = viewController as? UISplitViewController {
            if !svc.viewControllers.isEmpty {
                return searchViewController(from: svc.viewControllers.last!)
            }
        }
        if !viewController.childViewControllers.isEmpty {
            return searchViewController(from:viewController.childViewControllers.last!)
        }
        if let presentedVC = viewController.presentedViewController {
            return searchViewController(from:presentedVC)
        }
        
        return viewController
    }
    
}









