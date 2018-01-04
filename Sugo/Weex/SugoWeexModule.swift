//
//  SugoWeexModule.swift
//  SwiftWeexSample
//
//  Created by lzackx on 2018/1/3.
//  Copyright © 2018年 com.taobao.weex. All rights reserved.
//

import Foundation
import Sugo
import WeexSDK

public extension SugoWeexModule {

    private func translate(properties: [String: Any]) -> Properties {
        
        var p = Properties()
        for property in properties {
            switch property.value {
            case is String:
                p[property.key] = property.value as! String
            case is Int:
                p[property.key] = property.value as! Int
            case is UInt:
                p[property.key] = property.value as! UInt
            case is Double:
                p[property.key] = property.value as! Double
            case is Float:
                p[property.key] = property.value as! Float
            case is [Any]:
                p[property.key] = property.value as! [Any]
            case is [String: Any]:
                p[property.key] = property.value as! [String: Any]
            default:
                p[property.key] = String(describing: property.value)
            }
        }
        return p
    }
    
    @objc public func track(_ eventName: String, props: [String: Any]) {
        Sugo.mainInstance().track(eventID: nil, eventName: eventName, properties: translate(properties: props))
    }
    
    @objc public func timeEvent(_ eventName: String) {
        Sugo.mainInstance().time(event: eventName)
    }
    
    @objc public func registerSuperProperties(_ superProps: [String: Any]) {
        Sugo.mainInstance().registerSuperPropertiesOnce(translate(properties: superProps))
    }
    
    @objc public func registerSuperPropertiesOnce(_ superProps: [String: Any]) {
        Sugo.mainInstance().registerSuperPropertiesOnce(translate(properties: superProps))
    }
    
    @objc public func unregisterSuperProperty(_ superPropertyName: String) {
        Sugo.mainInstance().unregisterSuperProperty(superPropertyName)
    }
    
    @objc public func getSuperProperties(_ callback: WXModuleCallback) {
        callback(Sugo.mainInstance().currentSuperProperties())
    }
    
    @objc public func clearSuperProperties() {
        Sugo.mainInstance().clearSuperProperties()
    }
    
    @objc public func login(_ userIdKey: String, userIdValue: String) {
        Sugo.mainInstance().trackFirstLogin(with: userIdValue, dimension: userIdKey)
    }
    
    @objc public func logout() {
        Sugo.mainInstance().untrackFirstLogin()
    }
}
