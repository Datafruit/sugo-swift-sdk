//
//  AutomaticProperties.swift
//  Sugo
//
//  Created by Yarden Eitan on 7/8/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit
#if os(iOS)
    import CoreTelephony
#endif

class AutomaticProperties {
    #if os(iOS)
    static let telephonyInfo = CTTelephonyNetworkInfo()
    #endif

    static var properties: InternalProperties = {
        
        let keys = SugoDimensions.keys
        var p = InternalProperties()
        let size = UIScreen.main.bounds.size
        let infoDict = Bundle.main.infoDictionary
        if let infoDict = infoDict {
            p[keys["AppBundleName"]!] = infoDict["CFBundleName"]
            p[keys["AppBundleVersion"]!] = infoDict["CFBundleVersion"]
            p[keys["AppBundleShortVersionString"]!] = infoDict["CFBundleShortVersionString"]
        }
        p[keys["Carrier"]!] = AutomaticProperties.telephonyInfo.subscriberCellularProvider?.carrierName
        p[keys["SDKType"]!] = "Swift"
        p[keys["SDKVersion"]!] = AutomaticProperties.libVersion()
        p[keys["Manufacturer"]!] = "Apple"
        p[keys["SystemName"]!] = UIDevice.current.systemName
        p[keys["SystemVersion"]!] = UIDevice.current.systemVersion
        p[keys["DeviceModel"]!] = AutomaticProperties.deviceModel()
        p[keys["DeviceBrand"]!] = AutomaticProperties.deviceBrand()
        p[keys["ScreenWidth"]!] = Int(size.width)
        p[keys["ScreenHeight"]!] = Int(size.height)
        return p
    }()

    static var deviceProperties: InternalProperties = {
        var p = InternalProperties()
        let infoDict = Bundle.main.infoDictionary
        if let infoDict = infoDict {
            p["ios_app_version"] = infoDict["CFBundleVersion"]
            p["ios_app_release"] = infoDict["CFBundleShortVersionString"]
        }
        p["ios_device_model"]  = AutomaticProperties.deviceModel()
        p["ios_version"]       = UIDevice.current.systemVersion
        p["ios_lib_version"]   = AutomaticProperties.libVersion()

        return p
    }()

    #if os(iOS)
    class func getCurrentRadio() -> String? {
        var radio = telephonyInfo.currentRadioAccessTechnology
        let prefix = "CTRadioAccessTechnology"
        if radio == nil {
            radio = "None"
        } else if radio!.hasPrefix(prefix) {
            radio = (radio! as NSString).substring(from: prefix.characters.count)
        }
        return radio
    }
    #endif

    class func deviceBrand() -> String {
        
        let device = UIDevice.current
        
        switch device.userInterfaceIdiom {
        case .phone:
            return "iPhone"
        case .pad:
            return "iPad"
        case .unspecified:
            fallthrough
        default:
            return "Unrecognized"
        }
        
    }
    
    class func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let size = MemoryLayout<CChar>.size
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: size) {
                String(cString: UnsafePointer<CChar>($0))
            }
        }
        if let model = String(validatingUTF8: modelCode) {
            return model
        }
        return ""
    }

    class func libVersion() -> String {
        if let version = Bundle(for: self).infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        } else {
            return ""
        }
    }

}
