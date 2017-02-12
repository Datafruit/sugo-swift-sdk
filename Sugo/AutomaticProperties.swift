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
        
        guard let key = SugoConfiguration.DimensionKey as? [String: String] else {
            return InternalProperties()
        }
        var p = InternalProperties()
        let size = UIScreen.main.bounds.size
        let infoDict = Bundle.main.infoDictionary
        if let infoDict = infoDict {
            p[key["AppBundleVersion"]!] = infoDict["CFBundleVersion"]
            p[key["AppBundleShortVersionString"]!] = infoDict["CFBundleShortVersionString"]
        }
        p[key["Carrier"]!] = AutomaticProperties.telephonyInfo.subscriberCellularProvider?.carrierName
        p[key["SDKType"]!] = "Swift"
        p[key["SDKVersion"]!] = AutomaticProperties.libVersion()
        p[key["Manufacturer"]!] = "Apple"
        p[key["SystemName"]!] = UIDevice.current.systemName
        p[key["SystemVersion"]!] = UIDevice.current.systemVersion
        p[key["DeviceModel"]!] = AutomaticProperties.deviceModel()
        p[key["ScreenWidth"]!] = Int(size.width)
        p[key["ScreenHeight"]!] = Int(size.height)
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
