//
//  CodelessBinding.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/22/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation


class CodelessBinding: NSObject, NSCoding {
    var name: String
    var path: ObjectSelector
    var eventID: String?
    var eventName: String
    var attributes: Attributes?
    var swizzleClass: AnyClass!
    var running: Bool
    var classAttr:String?

    init(eventID: String?, eventName: String, path: String, attributes: Attributes? = nil) {
        self.eventID = eventID
        self.eventName = eventName
        self.path = ObjectSelector(string: path)
        self.attributes = attributes
        self.name = UUID().uuidString
        self.running = false
        self.swizzleClass = nil
        self.classAttr = ""
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let path = aDecoder.decodeObject(forKey: "path") as? String,
            let eventID = aDecoder.decodeObject(forKey: "eventID") as? String,
            let eventName = aDecoder.decodeObject(forKey: "eventName") as? String,
            let swizzleString = aDecoder.decodeObject(forKey: "swizzleClass") as? String,
            let swizzleClass = NSClassFromString(swizzleString),
            let classAttrString = aDecoder.decodeObject(forKey: "swizzleClass") as? String,
            let paths = aDecoder.decodeObject(forKey: "paths") as? InternalProperties else {
                return nil
        }
        self.classAttr = classAttrString
        self.eventID = eventID
        self.eventName = eventName
        self.path = ObjectSelector(string: path)
        self.name = name
        self.running = false
        self.swizzleClass = swizzleClass
        self.attributes = Attributes(attributes: paths)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(path.string, forKey: "path")
        aCoder.encode(eventID, forKey: "eventID")
        aCoder.encode(eventName, forKey: "eventName")
        aCoder.encode(NSStringFromClass(swizzleClass), forKey: "swizzleClass")
        aCoder.encode(attributes?.paths, forKey: "paths")
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? CodelessBinding else {
            return false
        }

        if object === self {
            return true
        } else {
            return self.eventName == object.eventName && self.path == object.path
        }
    }

    override var hash: Int {
        return eventName.hash ^ path.hash
    }

    func execute() {}

    func stop() {}

    func track(eventID: String? = nil, eventName: String, properties: Properties) {
        var bindingProperties = properties
        bindingProperties["from_binding"] = true
        Sugo.mainInstance().track(eventID: eventID,
                                      eventName: eventName,
                                      properties: bindingProperties)
    }



}
