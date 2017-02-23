//
//  SugoConfigurationPropertyList.swift
//  Sugo
//
//  Created by Zack on 23/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import UIKit

class SugoConfigurationPropertyList: NSObject {

    class func load(name: String) -> InternalProperties {
        
        var configuration = InternalProperties()
        let bundle = Bundle(for: Sugo.self)
        if let url = bundle.url(forResource: name, withExtension: "plist"),
            let plist = try? PropertyListSerialization.propertyList(from: Data(contentsOf: url),
                                                                    options: PropertyListSerialization.ReadOptions.mutableContainersAndLeaves,
                                                                    format: nil),
            let c = plist as? InternalProperties {
            configuration = c
        }
        Logger.debug(message: "Configuration Property List:\n\(configuration)")
        return configuration
    }
    
    class func load(name: String, key: String) -> InternalProperties {
        
        if let configuration = SugoConfigurationPropertyList.load(name: name)[key] as? InternalProperties {
            return configuration
        } else {
            return InternalProperties()
        }
    }
    
}
