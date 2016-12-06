//
//  SugoType.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/19/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

/// Property keys must be String objects and the supported value types need to conform to SugoType.
///  SugoType can be either String, Int, UInt, Double, Float, Bool, [SugoType], [String: SugoType], Date, URL, or NSNull.
public protocol SugoType: Any {
    /**
     Checks if this object has nested object types that Sugo supports.
     */
    func isValidNestedType() -> Bool
}

extension String: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension Int: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension UInt: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension Double: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension Float: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension Bool: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension Date: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension URL: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension NSNull: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     Will always return true.
     */
    public func isValidNestedType() -> Bool { return true }
}
extension Array: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     */
    public func isValidNestedType() -> Bool {
        for element in self {
            guard let _ = element as? SugoType else {
                return false
            }
        }
        return true
    }
}
extension Dictionary: SugoType {
    /**
     Checks if this object has nested object types that Sugo supports.
     */
    public func isValidNestedType() -> Bool {
        for (key, value) in self {
            guard let _ = key as? String, let _ = value as? SugoType else {
                return false
            }
        }
        return true
    }
}


func assertPropertyTypes(_ properties: Properties?) {
    if let properties = properties {
        for (_, v) in properties {
            MPAssert(v.isValidNestedType(),
                "Property values must be of valid type (SugoType). Got \(type(of: v))")
        }
    }
}
