//
//  UITableViewBinding.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/24/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

class UITableViewBinding: CodelessBinding {


    init(eventID: String?, eventName: String, path: String, delegate: AnyClass, attributes: Attributes? = nil) {
        super.init(eventID: eventID, eventName: eventName, path: path, attributes: attributes)
        self.swizzleClass = delegate
    }

    convenience init?(object: [String: Any]) {
        guard let path = object["path"] as? String, path.characters.count >= 1 else {
            Logger.warn(message: "must supply a view path to bind by")
            return nil
        }
        
        guard let eventID = object["event_id"] as? String, eventID.characters.count >= 1 else {
            Logger.warn(message: "binding requires an event id")
            return nil
        }
        
        guard let eventName = object["event_name"] as? String, eventName.characters.count >= 1 else {
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
                (view: AnyObject?, command: Selector, tableView: AnyObject?, indexPath: AnyObject?) in
                guard let tableView = tableView as? UITableView, let indexPath = indexPath as? IndexPath else {
                    return
                }
                if let root = UIApplication.shared.keyWindow?.rootViewController {
                    // select targets based off path
                    if self.path.isSelected(leaf: tableView, from: root) {
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
                                    break
                                }
                            }
                        }
                        p[keys["EventType"]!] = values["click"]!
                        var label = ""
                        if let cell = tableView.cellForRow(at: indexPath) {
                            if let cellText = cell.textLabel?.text {
                                label = cellText
                            } else {
                                for subview in cell.contentView.subviews {
                                    if let lbl = subview as? UILabel, let text = lbl.text {
                                        label = text
                                        break
                                    }
                                }
                            }
                        }
                        p += ["cell_index": "\(indexPath.row)",
                            "cell_section": "\(indexPath.section)",
                            "cell_label": label]
                        self.track(eventID: self.eventID,
                                   eventName: self.eventName,
                                   properties: p)
                    }
                }
            }

            //swizzle
            Swizzler.swizzleSelector(NSSelectorFromString("tableView:didSelectRowAtIndexPath:"),
                                     withSelector:
                                        #selector(UIViewController.sugoTableViewDidSelectRowAtIndexPath(tableView:indexPath:)),
                                     for: swizzleClass,
                                     name: name,
                                     block: executeBlock)

            running = true
        }
    }

    override func stop() {
        if running {
            //unswizzle
            Swizzler.unswizzleSelector(NSSelectorFromString("tableView:didSelectRowAtIndexPath:"),
                aClass: swizzleClass,
                name: name)
            running = false
        }
    }

    override var description: String {
        return "UITableView Codeless Binding: \(eventName) for \(path)"
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? UITableViewBinding else {
            return false
        }

        if object === self {
            return true
        } else {
            return super.isEqual(object)
        }
    }

    override var hash: Int {
        return super.hash
    }
}










