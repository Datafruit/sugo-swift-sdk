//
//  SugoEventsSerializer.swift
//  Sugo
//
//  Created by Zack on 18/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation


class SugoEventsSerializer {
    
    class func encode(batch: [[String: Any]]) -> String? {
        
        var types = [String: String]()
        var keys = [String]()
        var values = [[String: Any]]()
        var dataString = String()
        
        let TypeSeperator = "|"
        let KeysSeperator = ","
        let ValuesSeperator = "\(Character(UnicodeScalar(1)))"
        let LinesSeperator = "\(Character(UnicodeScalar(2)))"
        
        // Mark: - For types and keys
        for object in batch {
            for key in object.keys.reversed() {
                if !keys.contains(key) {
                    if object[key] is Int {
                        types[key] = "i"
                    } else if object[key] is Int64 {
                        types[key] = "l"
                    } else if object[key] is Date {
                        types[key] = "d"
                    } else if object[key] is Float
                        || object[key] is Double {
                        types[key] = "f"
                    } else {
                        types[key] = "s"
                    }
                    keys.append(key)
                }
            }
        }
        
        for key in keys {
            dataString = dataString + types[key]! + TypeSeperator + key + KeysSeperator
        }
        dataString.characters.removeLast()
        dataString = dataString + LinesSeperator
        
        // Mark: - For values
        for object in batch {
            var value: [String: Any] = [String: Any]()
            for key in keys {
                if object[key] != nil {
                    
                    if types[key] == "d" {
                        value[key] = String(format: "%.0f", ((object[key] as! Date).timeIntervalSince1970 * 1000))
                    } else {
                        value[key] = object[key]
                    }
                    
                } else {
                    if types[key] == "s" {
                        value[key] = ""
                    } else {
                        value[key] = 0
                    }
                }
            }
            values.append(value)
        }
        
        for value in values {
            for key in keys {
                dataString = dataString + "\(value[key]!)" + ValuesSeperator
            }
            dataString = dataString + LinesSeperator
        }
        
        return base64Encode(dataString: dataString)
    }
    
    private class func base64Encode(dataString: String) -> String? {
        
        let data: Data? = dataString.data(using: String.Encoding.utf8)
        guard let d = data else {
            print("couldn't serialize object")
            return nil
        }
        
        let base64Encoded = d.base64EncodedString(options: .endLineWithCarriageReturn)
        
        guard let b64 = base64Encoded
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                print("couldn't replace characters to allowed URL character set")
                return nil
        }
        return b64
    }
}









