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
    
    static let URLs             = Sugo.loadConfigurationPropertyList(name: "SugoURLs")
    static let DimensionKey     = Sugo.loadConfigurationPropertyList(name: "SugoCustomDimensionKeyTable")
    static let DimensionValue   = Sugo.loadConfigurationPropertyList(name: "SugoCustomDimensionValueTable")
    static let Replacement      = Sugo.loadConfigurationPropertyList(name: "SugoResourcesPathReplacement")
}

struct ServerURL {
    /**
     static let bindings = "Address_For_Bindings"
     static let collect = "Address_For_Collecting_events"
     static let codeless = "Address_For_Codeless_Bindings"
     **/
    static let bindings: String = {
        if let urls = SugoConfiguration.URLs as? [String: String],
            let bindings = urls["Bindings"] {
            return bindings
        }
        return ""
    }()
    static let collection: String = {
        if let urls = SugoConfiguration.URLs as? [String: String],
            let bindings = urls["Collection"] {
            return bindings
        }
        return ""
    }()
    static let codeless: String = {
        if let urls = SugoConfiguration.URLs as? [String: String],
            let bindings = urls["Codeless"] {
            return bindings
        }
        return ""
    }()
}
