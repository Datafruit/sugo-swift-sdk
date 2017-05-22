//
//  AttributesPaser.swift
//  Sugo
//
//  Created by Zack on 19/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

import Foundation

class AttributesPaser {
    
    // Mark: - parse paths to objects
    class func parse(attributesPaths: [String: String]) -> [String: [AnyObject]] {
        
        var aObjects = [String: [AnyObject]]()
        for (key, path) in attributesPaths {
            let p = ObjectSelector(string: path)
            if let root = UIApplication.shared.keyWindow {
                var objects: [AnyObject]
                objects = p.selectFrom(root: root)
                aObjects += [key: objects]
            }
        }
        return aObjects
    }
}
