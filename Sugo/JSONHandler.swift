//
//  JSONHandler.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/3/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

class JSONHandler {

    typealias MPObjectToParse = Any

    class func encodeAPIData(_ obj: MPObjectToParse) -> String? {
        let data: Data? = serializeJSONObject(obj)

        guard let d = data else {
            Logger.warn(message: "couldn't serialize object")
            return nil
        }

        let base64Encoded = d.base64EncodedString(options: .endLineWithCarriageReturn)

        guard let b64 = base64Encoded
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            Logger.warn(message: "couldn't replace characters to allowed URL character set")
            return nil
        }

        return b64
    }

     class func serializeJSONObject(_ obj: MPObjectToParse) -> Data? {
        let serializableJSONObject = makeObjectSerializable(obj)

        guard JSONSerialization.isValidJSONObject(serializableJSONObject) else {
            Logger.warn(message: "object isn't valid and can't be serialzed to JSON")
            return nil
        }
        var serializedObject: Data? = nil
        do {
            serializedObject = try JSONSerialization
                .data(withJSONObject: serializableJSONObject, options: [])
        } catch {
            Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
            Logger.warn(message: "exception encoding api data")
        }
        return serializedObject
    }

    private class func makeObjectSerializable(_ obj: MPObjectToParse) -> MPObjectToParse {
        switch obj {
        case is String, is Int, is UInt, is Double, is Float:
            return obj

        case let obj as Array<Any>:
            return obj.map() { makeObjectSerializable($0) }

        case let obj as InternalProperties:
            var serializedDict = InternalProperties()
            _ = obj.map() { (k, v) in
                serializedDict[k] =
                    makeObjectSerializable(v) }
            return serializedDict

        case let obj as Date:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            return dateFormatter.string(from: obj)

        case let obj as URL:
            return obj.absoluteString

        default:
            Logger.info(message: "enforcing string on object: \(obj)")
            return String(describing: obj)
        }
    }
    
    class func parseJSONObjectString(properties: String) -> Properties? {
        
        var deserializedObject: Properties? = nil
        
        do {
            let pData = properties.data(using: String.Encoding.utf8)
            let pObject = try JSONSerialization.jsonObject(with: pData!,
                                                           options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            deserializedObject = JSONHandler.makeObjectDeserializable(pObject)
        } catch {
            Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
            Logger.debug(message: "exception: \(error)")
        }
        
        return deserializedObject
    }
    
    private class func makeObjectDeserializable(_ object: [String: Any]) -> Properties {
    
        var properties = Properties()
        for (key, value) in object {
            switch value {
            case is Float:
                properties[key] = value as! Float
                
            case is Double:
                properties[key] = value as! Double
                
            case is UInt:
                properties[key] = value as! UInt
                
            case is Int:
                properties[key] = value as! Int
                
            case is String:
                properties[key] = value as! String
                
            case let property as [SugoType]:
                properties[key] = property
                
            case let property as Properties:
                var deserializedDict = Properties()
                _ = property.map() { (k, v) in
                    deserializedDict[k] = makeObjectDeserializable(v as! [String : Any])
                }
                properties += deserializedDict
                    
            case let property as Date:
                properties[key] = String(format: "%.0f", property.timeIntervalSince1970 * 1000)
                
            case let property as URL:
                properties[key] = property.absoluteString
                
            default:
                Logger.info(message: "enforcing string on value: \(value)")
                properties[key] = String(describing: value)
            }
        }
        return properties
    }

}










