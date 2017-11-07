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
        
        let userDefaults = UserDefaults.standard
        let dimensions = userDefaults.object(forKey: "SugoDimensions") as! [[String: Any]]
        
        var types = [String: String]()
        var localKeys = [String]()
        var keys = [String]()
        var values = [[String: Any]]()
        var dataString = String()
        
        let TypeSeperator = "|"
        let KeysSeperator = ","
        let ValuesSeperator = "\(Character(UnicodeScalar(1)))"
        let LinesSeperator = "\(Character(UnicodeScalar(2)))"
        
        // Mark: - For keys
        for object in batch {
            for key in object.keys.reversed() {
                if !localKeys.contains(key) {
                    localKeys.append(key)
                }
            }
        }
        
        for dimension in dimensions {
            let dimensionKey = "\(dimension["name"]!)"
            for key in localKeys {
                if dimensionKey == key {
                    keys.append(key)
                }
            }
        }
        
        // Mark: - For types
        for dimension in dimensions {
            let dimensionKey = "\(dimension["name"]!)"
            let dimensionType = "\(dimension["type"]!)"
            var type: String?
            for key in keys {
                if dimensionKey == key {
                    switch dimensionType {
                    case "0":
                        type = "l"
                        break
                    case "1":
                        type = "f"
                        break
                    case "2":
                        type = "s"
                        break
                    case "4":
                        type = "d"
                        break
                    case "5":
                        type = "i"
                        break
                    default:
                        break
                    }
                    if type != nil {
                        types[key] = type!
                    }
                    break
                }
            }
        }
        
        for key in keys {
            dataString = dataString + types[key]! + TypeSeperator + key + KeysSeperator
        }
        dataString = String(dataString[dataString.startIndex..<dataString.index(before: dataString.endIndex)])
        dataString = dataString + LinesSeperator
        
        // Mark: - For values
        for object in batch {
            var value: [String: Any] = [String: Any]()
            for key in keys {
                if object[key] != nil {
                    if types[key] == "i" {
                        value[key] = object[key]
                    } else if types[key] == "l" {
                        value[key] = object[key]
                    } else if types[key] == "f" {
                        value[key] = object[key]
                    } else if types[key] == "d" {
                        value[key] = object[key]
                    } else if types[key] == "s" {
                        value[key] = object[key]
                    } else {
                        value[key] = ""
                    }
                } else {
                    value[key] = ""
                }
            }
            values.append(value)
        }
        
        for value in values {
            for key in keys {
                dataString = dataString + "\(value[key]!)" + ValuesSeperator
            }
            dataString.removeLast()
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
        
        return base64Encoded
    }

}









