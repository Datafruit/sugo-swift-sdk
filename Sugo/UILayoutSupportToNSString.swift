//
//  UILayoutSupportToNSString.swift
//  Sugo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

import Foundation
import UIKit

@objc(UILayoutSupportToNSString) class UILayoutSupportToNSString: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value as? UILayoutSupport else {
            return nil
        }
        let uiLayoutSupport = value
        
        return "\(uiLayoutSupport.length)"
    }
}

