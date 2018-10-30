//
//  UITableViewCellBinding.swift
//  Sugo
//
//  Created by 陈宇艺 on 2018/10/29.
//  Copyright © 2018年 sugo. All rights reserved.
//

import Foundation
import UIKit

class UITableViewCellBinding: CodelessBinding {
    
    
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
                (view: AnyObject?, command: Selector, tableView: AnyObject?, indexPath: AnyObject?) in
                guard let tableView = tableView as? UITableView, let indexPath = indexPath as? IndexPath else {
                    return
                }
                
                let pathString = self.path.string
                let array : Array = pathString.components(separatedBy: "/")
                var strPath=String()
                var i = 0
                while i < array.count-2 {
                    strPath = String(format: "%@:%@", arguments:["/",array[i]])
                    i+=1
                }
                strPath = strPath + "[0]"
                self.path.string=strPath
                let sectionCell = array[array.count-1]
                let cellArray : Array = sectionCell.components(separatedBy: "[")
                var row = 0
                if  cellArray.count <= 1{
                    row = indexPath.row
                }else{
                    let rowStr = Int(cellArray[1].components(separatedBy: "]")[0])
                    row = rowStr!
                }
                
                
                if row == indexPath.row , let root = UIApplication.shared.keyWindow {
                    
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
                                    if let infoPageCategory = info["page_category"] as? String {
                                        p[keys["PageCategory"]!] = infoPageCategory;
                                    }
                                    break
                                }
                            }
                        }
                        p[keys["EventType"]!] = values["click"]!
                        var textLabel = String()
                        var detailTextLabel = String()
                        var contentInfo = String()
                        if let cell = tableView.cellForRow(at: indexPath) {
                            if let cellText = cell.textLabel?.text {
                                textLabel = cellText
                            }
                            if let cellDetailText = cell.detailTextLabel?.text {
                                detailTextLabel = cellDetailText
                            }
                            contentInfo = self.contentInfoOfView(view: cell.contentView)
                        }
                        p += ["cell_index": "\(indexPath.row)",
                            "cell_section": "\(indexPath.section)",
                            "cell_label": textLabel,
                            "cell_detail_label": detailTextLabel,
                            "cell_content_info": contentInfo]
                        self.track(eventID: self.eventID,
                                   eventName: self.eventName,
                                   properties: p)
                    }
                }
                self.path.string=pathString
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
    
    func contentInfoOfView(view: UIView) -> String {
        
        var infos = String()
        for subview in view.subviews {
            let objectClass = NSStringFromClass(subview.classForCoder)
            Logger.debug(message: "attributes class: \(objectClass)")
            switch objectClass {
            case NSStringFromClass(UISearchBar.classForCoder()):
                let o = subview as! UISearchBar
                if let t = o.text {
                    infos += "\(t)"
                }
            case NSStringFromClass(UIButton.classForCoder()):
                let o = subview as! UIButton
                if let tittle = o.titleLabel {
                    infos += "\(tittle.text ?? "")"
                }
            case NSStringFromClass(UIDatePicker.classForCoder()):
                let o = subview as! UIDatePicker
                infos += "\(o.date)"
            case NSStringFromClass(UISegmentedControl.classForCoder()):
                let o = subview as! UISegmentedControl
                infos += "\(o.selectedSegmentIndex)"
            case NSStringFromClass(UISlider.classForCoder()):
                let o = subview as! UISlider
                infos += "\(o.value)"
            case NSStringFromClass(UISwitch.classForCoder()):
                let o = subview as! UISwitch
                infos += "\(o.isOn)"
            case NSStringFromClass(UITextField.classForCoder()):
                let o = subview as! UITextField
                infos += "\(o.text ?? "")"
            case NSStringFromClass(UITextView.classForCoder()):
                let o = subview as! UITextView
                infos += "\(o.text ?? "")"
            case NSStringFromClass(UILabel.classForCoder()):
                let o = subview as! UILabel
                infos += "\(o.text ?? "")"
            default:
                Logger.debug(message: "There is not any info in this view: \(view.debugDescription)")
            }
            infos += ",\(contentInfoOfView(view: subview))"
        }
        
        return infos
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
