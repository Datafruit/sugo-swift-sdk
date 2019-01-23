//
//  UITextViewBinding.swift
//  Sugo
//
//  Created by Zack on 1/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation

class UITextViewBinding: CodelessBinding {
    
    
    init(eventID: String?, eventName: String, path: String, delegate: AnyClass, attributes: Attributes? = nil) {
        super.init(eventID: eventID, eventName: eventName, path: path, attributes: attributes)
        self.swizzleClass = delegate
    }
    
    convenience init?(object: [String: Any]) {
        guard let path = object["path"] as? String, path.count >= 1 else {
            Logger.warn(message: "must supply a view path to bind by")
            return nil
        }
        
        guard let eventID = object["event_id"] as? String, eventID.count >= 1 else {
            Logger.warn(message: "binding requires an event id")
            return nil
        }
        
        guard let eventName = object["event_name"] as? String, eventName.count >= 1 else {
            Logger.warn(message: "binding requires an event name")
            return nil
        }
        
        guard let delegate = object["table_delegate"] as? String, let delegateClass = NSClassFromString(delegate) else {
            Logger.warn(message: "binding requires a delegate class")
            return nil
        }
        
        var attr: Attributes? = nil
        if let attributes = object["attributes"] as? InternalProperties {
            attr = Attributes(attributes: attributes)
        }
        self.init(eventID: eventID,
                  eventName: eventName,
                  path: path,
                  delegate: delegateClass,
                  attributes: attr)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func execute() {
        if !running && swizzleClass != nil {
            
            let executeBlock = {
                (view: AnyObject?, command: Selector, textView: AnyObject?, parameter: AnyObject?) in
                guard let textView = textView as? UITextView else {
                    return
                }

                if let root = UIApplication.shared.keyWindow {
                    // select targets based off path
                    if self.path.isSelected(leaf: textView, from: root) {
                        var p = Properties()
                        if let a = self.attributes {
                            p += a.parse()
                        }
                        let keys = SugoDimensions.keys
                        let values = SugoDimensions.values
                        if let vc = UIViewController.sugoCurrentUIViewController() {
                            p[keys["PagePath"]!] = NSStringFromClass(vc.classForCoder)
                            for info in SugoPageInfos.global.infos {
                                if let infoPage = info["page"] as? String,
                                    infoPage == NSStringFromClass(vc.classForCoder) {
                                    p[keys["PageName"]!] = infoPage
                                    if let infoPageCategory = info["page_category"] as? String {
                                        p[keys["PageCategory"]!] = infoPageCategory;
                                    }
                                    break
                                }
                            }
                        }
                        p[keys["EventType"]!] = values["focus"]!
                        let text = textView.text != nil ? textView.text : ""
                        p[keys["EventLabel"]!] = text
                        
                        let classAttr = self.classAttr
                        if classAttr != nil{
                            p =  BindingUtils.requireExtraAttrWithValue(classAttr: classAttr!, p: p, view: textView as UIView)
                        }
                        
                        
                        self.track(eventID: self.eventID,
                                   eventName: self.eventName,
                                   properties: p)
                    }
                }
            }
            
            //swizzle
            Swizzler.swizzleSelector(NSSelectorFromString("textViewDidBeginEditing:"),
                                     withSelector: #selector(UIViewController.sugoTextViewDidBeginEditing(_:)),
                                     for: swizzleClass,
                                     name: name,
                                     block: executeBlock)
            
            running = true
        }
    }
    
    override func stop() {
        if running {
            //unswizzle
            Swizzler.unswizzleSelector(NSSelectorFromString("textViewDidBeginEditing:"),
                                       aClass: swizzleClass,
                                       name: name)
            running = false
        }
    }
    
    override var description: String {
        return "UITextView Codeless Binding: \(eventName) for \(path)"
    }

}
