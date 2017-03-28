//
//  Attributes.swift
//  Sugo
//
//  Created by Zack on 19/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

import Foundation


class Attributes: NSObject {
    
    var paths: InternalProperties
    
    init(attributes: InternalProperties) {
        self.paths = attributes
        super.init()
    }
    
    // Mark: - parse paths to values
    func parse() -> Properties {
        
        Logger.debug(message: self.paths as! [String: String])
        var aValues = Properties()
        let aObjects = AttributesPaser.parse(attributesPaths: self.paths as! [String: String])
        for (key, objects) in aObjects {
            for object in objects {
                
                let objectClass = NSStringFromClass(object.classForCoder)
                Logger.debug(message: "attributes class: \(objectClass)")
                switch objectClass {
                case NSStringFromClass(UISearchBar.classForCoder()):
                    let o = object as! UISearchBar
                    if let t = o.text {
                        aValues += [key: "\(t)"]
                    } else {
                        aValues += [key: ""]
                    }
                case NSStringFromClass(UIButton.classForCoder()):
                    let o = object as! UIButton
                    if let tittle = o.titleLabel {
                        aValues += [key: "\(tittle)"]
                    } else {
                        aValues += [key: ""]
                    }
                case NSStringFromClass(UIDatePicker.classForCoder()):
                    let o = object as! UIDatePicker
                    aValues += [key: "\(o.date)"]
                case NSStringFromClass(UISegmentedControl.classForCoder()):
                    let o = object as! UISegmentedControl
                    aValues += [key: "\(o.selectedSegmentIndex)"]
                case NSStringFromClass(UISlider.classForCoder()):
                    let o = object as! UISlider
                    aValues += [key: "\(o.value)"]
                case NSStringFromClass(UISwitch.classForCoder()):
                    let o = object as! UISwitch
                    aValues += [key: "\(o.isOn)"]
                case NSStringFromClass(UITextField.classForCoder()):
                    let o = object as! UITextField
                    aValues += [key: "\(o.text ?? "")"]
                default:
                    aValues += [key: "\(self.paths[key]!)"]
                    Logger.debug(message: "\(String(describing: self.paths[key]))")
                }
            }
        }
        return aValues
    }
}
