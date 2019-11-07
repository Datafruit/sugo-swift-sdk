//
//  UIViewBinding.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/24/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

class UIViewBinding: CodelessBinding {

    let controlEvent: UIControl.Event
    let verifyEvent: UIControl.Event
    var verified: NSHashTable<UIControl>
    var appliedTo: NSHashTable<UIView>

    init(eventID: String, eventName: String, path: String, controlEvent: UIControl.Event? = nil, verifyEvent: UIControl.Event? = nil, attributes: Attributes? = nil) {
        if let controlEvent = controlEvent {
            self.controlEvent = controlEvent
        } else {
            self.controlEvent = UIControl.Event(rawValue: 0)
        }
        self.verifyEvent = self.controlEvent
        self.verified = NSHashTable(options: [NSHashTableWeakMemory, NSHashTableObjectPointerPersonality])
        self.appliedTo = NSHashTable(options: [NSHashTableWeakMemory, NSHashTableObjectPointerPersonality])
        super.init(eventID: eventID, eventName: eventName, path: path, attributes: attributes)
        self.swizzleClass = UIView.self
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

        var finalControlEvent: UIControl.Event?
        var finalVerifyEvent: UIControl.Event?
        if let controlEvent = object["control_event"] as? UInt, controlEvent & UIControl.Event.allEvents.rawValue != 0 {
            finalControlEvent = UIControl.Event(rawValue: controlEvent)
            if let verifyEvent = object["verify_event"] as? UInt, verifyEvent & UIControl.Event.allEvents.rawValue != 0 {
                finalVerifyEvent = UIControl.Event(rawValue: verifyEvent)
            } else if controlEvent & UIControl.Event.allTouchEvents.rawValue != 0 {
                finalVerifyEvent = UIControl.Event.touchDown
            } else if controlEvent & UIControl.Event.allEditingEvents.rawValue != 0 {
                finalVerifyEvent = UIControl.Event.editingDidBegin
            }
        }

        var finalAttributes: Attributes?
        if let attributes = object["attributes"] as? InternalProperties {
            finalAttributes = Attributes(attributes: attributes)
        }
        
        self.init(eventID: eventID,
                  eventName: eventName,
                  path: path,
                  controlEvent: finalControlEvent,
                  verifyEvent: finalVerifyEvent,
                  attributes: finalAttributes)
    }

    required init?(coder aDecoder: NSCoder) {
        controlEvent = UIControl.Event(rawValue: aDecoder.decodeObject(forKey: "controlEvent") as! UInt)
        verifyEvent = UIControl.Event(rawValue: aDecoder.decodeObject(forKey: "verifyEvent") as! UInt)
        verified = NSHashTable(options: [NSHashTableWeakMemory, NSHashTableObjectPointerPersonality])
        appliedTo = NSHashTable(options: [NSHashTableWeakMemory, NSHashTableObjectPointerPersonality])
        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(controlEvent.rawValue, forKey: "controlEvent")
        aCoder.encode(verifyEvent.rawValue, forKey: "verifyEvent")
        super.encode(with: aCoder)
    }


    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? UIViewBinding else {
            return false
        }

        if object === self {
            return true
        } else {
            return super.isEqual(object) && self.controlEvent == object.controlEvent && self.verifyEvent == object.verifyEvent
        }
    }

    override var hash: Int {
        return super.hash ^ Int(self.controlEvent.rawValue) ^ Int(self.verifyEvent.rawValue)
    }

    override var description: String {
        return "UIView Codeless Binding: \(eventName) for \(path)"
    }

    func resetUIViewStore() {
        verified = NSHashTable(options: [NSHashTableWeakMemory, NSHashTableObjectPointerPersonality])
        appliedTo = NSHashTable(options: [NSHashTableWeakMemory, NSHashTableObjectPointerPersonality])
    }

    override func execute() {

        if !self.running {
            let executeBlock = {
                (view: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) in
                if let root = UIApplication.shared.keyWindow {
                    if let view = view as? UIView, self.appliedTo.contains(view) {
                        if !self.path.isSelected(leaf: view, from: root, isFuzzy: true) {
                            if Sugo.mainInstance().heatMap.mode {
                                Sugo.mainInstance().heatMap.wipeObjectOfPath(path: self.path.string)
                            }
                            self.stopOn(view: view)
                            self.appliedTo.remove(view)
                        }
                    } else {
                        var objects: [UIView]
                        // select targets based off path
                        if let view = view as? UIView {
                            if self.path.isSelected(leaf: view, from: root, isFuzzy: true) {
                                objects = [view]
                            } else {
                                objects = []
                            }
                        } else {
                            objects = self.path.selectFrom(root: root) as! [UIView]
                        }

                        for view in objects {
                            if let view = view as? UIControl {
                                if self.verifyEvent != UIControl.Event(rawValue:0) && self.verifyEvent != self.controlEvent {
                                    view.addTarget(self, action: #selector(self.preVerify(sender:event:)), for: self.verifyEvent)
                                }
                                view.addTarget(self, action: #selector(self.execute(sender:event:)), for: self.controlEvent)
                            } else if view.isUserInteractionEnabled
                                && view.gestureRecognizers != nil
                                && view.gestureRecognizers!.count > 0 {
                                for gestureRecognizer in view.gestureRecognizers! {
                                    if !(gestureRecognizer is UITapGestureRecognizer) || !gestureRecognizer.isEnabled {
                                        continue
                                    }
                                    gestureRecognizer.addTarget(self, action: #selector(self.handleGesture(_:)))
                                    break;
                                }
                            }
                            self.appliedTo.add(view)
                        }
                        if Sugo.mainInstance().heatMap.mode {
                            Sugo.mainInstance().heatMap.renderObjectOfPath(path: self.path.string, root: root)
                        }
                    }
                }
            }

            // Execute once in case the view to be tracked is already on the screen
            executeBlock(nil, #function, nil, nil)

            Swizzler.swizzleSelector(NSSelectorFromString("didMoveToWindow"),
                                     withSelector: #selector(UIView.sugoViewDidMoveToWindow),
                                     for: swizzleClass,
                                     name: name,
                                     block: executeBlock)
            Swizzler.swizzleSelector(NSSelectorFromString("didMoveToSuperview"),
                                     withSelector: #selector(UIView.sugoViewDidMoveToSuperview),
                                     for: swizzleClass,
                                     name: name,
                                     block: executeBlock)
            running = true
        }
    }
    
    @objc func handleGesture(_ sender: UIGestureRecognizer) {
        
        guard let view = sender.view else {
            return
        }
        var shouldTrack = false
        shouldTrack = verifyControlMatchesPath(view)
        if shouldTrack {
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
            p[keys["EventType"]!] = values["click"]!
            self.track(eventID: self.eventID,
                       eventName: self.eventName,
                       properties: p)
        }
    }

    override func stop() {
        if running {
            // remove what has been swizzled
            Swizzler.unswizzleSelector(NSSelectorFromString("didMoveToWindow"),
                                       aClass: swizzleClass,
                                       name: name)
            Swizzler.unswizzleSelector(NSSelectorFromString("didMoveToSuperview"),
                                       aClass: swizzleClass,
                                       name: name)

            // remove target-action pairs
            for view in appliedTo.allObjects {
                stopOn(view: view)
            }
            resetUIViewStore()
            running = false
        }
    }

    func stopOn(view: UIView) {
        if let view = view as? UIControl {
            if verifyEvent != UIControl.Event(rawValue: 0) && verifyEvent != controlEvent {
                view.removeTarget(self, action: #selector(self.preVerify(sender:event:)), for: verifyEvent)
            }
            view.removeTarget(self, action: #selector(self.execute(sender:event:)), for: controlEvent)
        } else if view.isUserInteractionEnabled
            && view.gestureRecognizers != nil
            && view.gestureRecognizers!.count > 0 {
            for gestureRecognizer in view.gestureRecognizers! {
                if !(gestureRecognizer is UITapGestureRecognizer) || !gestureRecognizer.isEnabled {
                    continue
                }
                gestureRecognizer.removeTarget(self, action: #selector(self.handleGesture(_:)))
                break;
            }
        }
    }

    func verifyControlMatchesPath(_ control: AnyObject) -> Bool {
        if let root = UIApplication.shared.keyWindow {
            return path.isSelected(leaf: control, from: root)
        }
        return false
    }

    @objc func preVerify(sender: UIControl, event: UIEvent) {
        if verifyControlMatchesPath(sender) {
            verified.add(sender)
        } else {
            verified.remove(sender)
        }
    }

    @objc func execute(sender: UIControl, event: UIEvent) {
        var shouldTrack = false
        if verifyEvent != UIControl.Event(rawValue: 0) && verifyEvent != controlEvent {
            shouldTrack = verified.contains(sender)
        } else {
            shouldTrack = verifyControlMatchesPath(sender)
        }
        if shouldTrack {
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
            if controlEvent == UIControl.Event.editingDidBegin {
                p[keys["EventType"]!] = values["focus"]!
            } else {
                p[keys["EventType"]!] = values["click"]!
            }
            self.track(eventID: self.eventID,
                       eventName: self.eventName,
                       properties: p)
        }
    }

}

extension UIView {
    
    @objc func viewCallOriginalMethodWithSwizzledBlocks(originalSelector: Selector) {
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
    
    @objc func sugoViewDidMoveToWindow() {
        let originalSelector = NSSelectorFromString("didMoveToWindow")
        viewCallOriginalMethodWithSwizzledBlocks(originalSelector: originalSelector)
    }

    @objc func sugoViewDidMoveToSuperview() {
        let originalSelector = NSSelectorFromString("didMoveToSuperview")
        viewCallOriginalMethodWithSwizzledBlocks(originalSelector: originalSelector)
    }

    @objc func sugoViewLayoutSubviews() {
        let originalSelector = NSSelectorFromString("layoutSubviews")
        viewCallOriginalMethodWithSwizzledBlocks(originalSelector: originalSelector)
    }
    

}
