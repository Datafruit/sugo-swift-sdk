//
//  ExceptionUtils.swift
//  Sugo
//
//  Created by 陈宇艺 on 2019/6/13.
//  Copyright © 2019 sugo. All rights reserved.
//

import Foundation
class ExceptionUtils {
    public static var SUGOEXCEPTION:String = "SugoSdkException"
    
    open class func exceptionInfo(error:Error) ->[String:String]{
        var dict = [String:String]()
        
        let infoDictionary = Bundle.main.infoDictionary!
        dict.updateValue(Sugo.mainInstance().apiToken, forKey: "token")
        dict.updateValue(Sugo.mainInstance().projectId, forKey: "projectId")
        dict.updateValue(AutomaticProperties.libVersion(), forKey: "sdkVersion")
        dict.updateValue(infoDictionary["CFBundleShortVersionString"] as! String, forKey: "appVersion")
        dict.updateValue(deviceId(), forKey: "deviceId")
        dict.updateValue(UIDevice.current.systemVersion, forKey: "systemVersion")
        dict.updateValue(UIDevice.current.model, forKey: "PhoneModel")
        dict.updateValue(error.localizedDescription, forKey: "exception")
        return dict
    }
    
    class func deviceId() -> String {
        let userDefaults = UserDefaults.standard
        let defaultsKey = "deviceIdKey"
        if let deviceId = userDefaults.string(forKey: defaultsKey) {
            return deviceId
        } else {
            if SugoPermission.canObtainIFA {
                var deviceId: String? = IFA()
                if deviceId == nil && NSClassFromString("UIDevice") != nil {
                    deviceId = UIDevice.current.identifierForVendor?.uuidString
                }
                if let devId = deviceId {
                    userDefaults.set(devId, forKey: defaultsKey)
                } else {
                    userDefaults.set(UUID().uuidString, forKey: defaultsKey)
                }
            } else {
                userDefaults.set(UUID().uuidString, forKey: defaultsKey)
            }
            userDefaults.synchronize()
            if let id = userDefaults.string(forKey: defaultsKey) {
                return id
            } else {
                return UUID().uuidString
            }
        }
    }
    
    class func IFA() -> String? {
        var ifa: String? = nil
        if let ASIdentifierManagerClass = NSClassFromString("ASIdentifierManager") {
            let sharedManagerSelector = NSSelectorFromString("sharedManager")
            if let sharedManagerIMP = ASIdentifierManagerClass.method(for: sharedManagerSelector) {
                typealias sharedManagerFunc = @convention(c) (AnyObject, Selector) -> AnyObject?
                let curriedImplementation = unsafeBitCast(sharedManagerIMP, to: sharedManagerFunc.self)
                if let sharedManager = curriedImplementation(ASIdentifierManagerClass.self, sharedManagerSelector) {
                    let advertisingTrackingEnabledSelector = NSSelectorFromString("isAdvertisingTrackingEnabled")
                    if let isTrackingEnabledIMP = sharedManager.method(for: advertisingTrackingEnabledSelector) {
                        typealias isTrackingEnabledFunc = @convention(c) (AnyObject, Selector) -> Bool
                        let curriedImplementation2 = unsafeBitCast(isTrackingEnabledIMP, to: isTrackingEnabledFunc.self)
                        let isTrackingEnabled = curriedImplementation2(self, advertisingTrackingEnabledSelector)
                        if isTrackingEnabled {
                            let advertisingIdentifierSelector = NSSelectorFromString("advertisingIdentifier")
                            if let advertisingIdentifierIMP = sharedManager.method(for: advertisingIdentifierSelector) {
                                typealias adIdentifierFunc = @convention(c) (AnyObject, Selector) -> NSUUID
                                let curriedImplementation3 = unsafeBitCast(advertisingIdentifierIMP, to: adIdentifierFunc.self)
                                ifa = curriedImplementation3(self, advertisingIdentifierSelector).uuidString
                            }
                        }
                    }
                }
            }
        }
        return ifa
    }
    
}
