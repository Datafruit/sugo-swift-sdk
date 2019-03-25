//
//  BindingUtils.swift
//  Sugo
//
//  Created by 陈宇艺 on 2019/1/14.
//  Copyright © 2019 sugo. All rights reserved.
//

import Foundation

class BindingUtils: NSObject {
     static func requireExtraAttrWithValue(classAttr:InternalProperties,p:InternalProperties,view:UIView) -> Properties {
        if Sugo.mainInstance().StartExtraAttrFunction == false {
            return p as! Properties
        }
        if p.count == 0{
            return p as! Properties
        }
        var newP:InternalProperties = p
        for item in classAttr.keys {
            let array : Array = (classAttr[item]! as AnyObject).components(separatedBy: ",")
            var data : String = ""
            for key in array{
                let morror = Mirror.init(reflecting: view)
                var attr:Any = 1
                for (name, value) in (morror.children) {
                    if name == key{
                        attr = unwrap(any: value)
                        break
                    }
                }
                if data == ""{
                    data = "\(String(describing: attr))"
                }else{
                    data = data + "," + "\(String(describing: attr))"
                }
            }
           newP[item] = data
        }
        return newP as! Properties
    }
}

func getValueByKey(obj:AnyObject, key: String) -> Any {
    let hMirror = Mirror(reflecting: obj)
    for case let (label?, value) in hMirror.children {
        if label == key {
            return unwrap(any: value)
        }
    }
    return NSNull()
}

//将可选类型（Optional）拆包
func unwrap(any:Any) -> Any {
    let mi = Mirror(reflecting: any)
//    if mi.displayStyle != .Optional {
//        return any
//    }
    
    if mi.children.count == 0 { return any }
    let (_, some) = mi.children.first!
    return some
}
