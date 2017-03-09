//
//  Constants.swift
//  Sugo
//
//  Created by Zack on 1/12/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation


struct QueueConstants {
    static var queueSize = 5000
}

struct APIConstants {
    static let batchSize = 50
    static let minRetryBackoff = 60.0
    static let maxRetryBackoff = 600.0
    static let failuresTillBackoff = 2
}

struct BundleConstants {
    static let ID = "io.sugo.Sugo"
}

struct SugoPermission {
    /* 
     default to false.
     It means SDK could only send UUID to server instead of IFA.
     */
    static let canObtainIFA = false
}

struct SugoConfiguration {
    
    static let URLs                     = SugoConfigurationPropertyList.load(name: "SugoURLs")
    static let Dimensions               = SugoConfigurationPropertyList.load(name: "SugoCustomDimensions")
    static let PageEventsVCFilterList   = SugoConfigurationPropertyList.load(name: "SugoPageEventsViewControllerFilterList")
    static let Replacements             = SugoConfigurationPropertyList.load(name: "SugoResourcesPathReplacements")
}

struct SugoServerURL {
    /**
     static let bindings    = "Address_For_Bindings"
     static let collection  = "Address_For_Collecting_events"
     static let codeless    = "Address_For_Codeless_Bindings"
     **/
    static let bindings: String = {
        if let urls = SugoConfigurationPropertyList.load(name: "SugoURLs") as? [String: String],
            let bindings = urls["Bindings"] {
            return bindings
        }
        return ""
    }()
    static let collection: String = {
        if let urls = SugoConfigurationPropertyList.load(name: "SugoURLs") as? [String: String],
            let bindings = urls["Collection"] {
            return bindings
        }
        return ""
    }()
    static let codeless: String = {
        if let urls = SugoConfigurationPropertyList.load(name: "SugoURLs") as? [String: String],
            let bindings = urls["Codeless"] {
            return bindings
        }
        return ""
    }()
}

struct SugoDimensions {
    /**
     static let keys    = "Dimension_Keys"
     static let values  = "Dimension_Values"
     **/
    static let keys: [String: String] = {
        if let configuration = SugoConfigurationPropertyList.load(name: "SugoCustomDimensions", key: "Keys") as? [String: String] {
            return configuration
        }
        return [String: String]()
    }()
    
    static let values: [String: String] = {
        if let configuration = SugoConfigurationPropertyList.load(name: "SugoCustomDimensions", key: "Values") as? [String: String] {
            return configuration
        }
        return [String: String]()
    }()
}

struct SugoPageEventsVCFilterList {
    
    static let black: [String] = {
        if let configuration = SugoConfiguration.PageEventsVCFilterList["Black"] as? [String] {
            return configuration
        }
        return [String]()
    }()
    
    static let white: [String] = {
        if let configuration = SugoConfiguration.PageEventsVCFilterList["White"] as? [String] {
            return configuration
        }
        return [String]()
    }()
}








