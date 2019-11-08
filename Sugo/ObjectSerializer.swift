//
//  ObjectSerializer.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/30/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class ObjectSerializer: NSObject {
    let configuration: ObjectSerializerConfig
    let objectIdentityProvider: ObjectIdentityProvider
    var currentUIWebViewInfoVersion: Int?
    
    init(configuration: ObjectSerializerConfig, objectIdentityProvider: ObjectIdentityProvider) {
        self.configuration = configuration
        self.objectIdentityProvider = objectIdentityProvider
    }
    
    func getSerializedObjects(rootObject: AnyObject) -> [String: AnyObject] {
        let context = ObjectSerializerContext(object: rootObject)
        var collectionViewCellArray = [Any]()
        
        while context.hasUnvisitedObjects() {
            let object = context.dequeueUnvisitedObject()
            if object is UICollectionViewCell{
                collectionViewCellArray = visitObject(object, context: context, itemArray:collectionViewCellArray)
            }else{
                if object is UITableViewCell {
                    var a : Int = 0
                }
                visitObject(object, context: context, itemArray:collectionViewCellArray)
            }
            
        }
        var objectArray : Array = context.getAllSerializedObjects()
        
        if collectionViewCellArray.count>0 {
            let xDict = findCollectionViewCellInterval(of:collectionViewCellArray,type: 0)
            let yDict = findCollectionViewCellInterval(of:collectionViewCellArray,type: 1)
            let xDistance : Float = xDict["distance"] as! Float
            let xMegin : Float = xDict["megin"] as! Float
            let itemNum : Float = xDict["itemNum"] as! Float
            let yDistance : Float = yDict["distance"] as! Float
            let yMegin : Float = yDict["megin"] as! Float
            var i : Int = 0
            for dict in collectionViewCellArray {
                let value = requrieWidgetFrame(of: dict as! Dictionary<String, Any>)
                let y : Float = Float(truncating: value["Y"] as! NSNumber)
                let x : Float = Float(truncating: value["X"] as! NSNumber)
                let width : Float = Float(truncating: value["Width"] as! NSNumber)
                let height : Float = Float(truncating: value["Height"] as! NSNumber)
                
                var xNum : Int = 0
                
                let dis = (x-xMegin)/(xDistance + width)
                var xGap : Float
                if dis.isNaN || dis.isInfinite{
                    xGap = 0
                }else{
                    xGap = Float(Float((x - xMegin))/Float((xDistance + width))) - Float(Int(Float((x - xMegin))/Float((xDistance + width))))
                }
                
                if xGap > 0 {
                    xNum = Int(Float((x - xMegin))/Float((xDistance + width))) + 1
                }else{
                    if dis.isNaN || dis.isInfinite {
                        xNum = 0 ;
                    }else{
                        xNum = Int((x - xMegin)/(xDistance + width))
                    }
                    
                }
                let yDis : Float = (y-yMegin)/(yDistance+height)*itemNum
                let cellIndex : Int
                if yDis.isInfinite || yDis.isNaN {
                    cellIndex = xNum
                }else{
                    cellIndex = Int(yDis) + xNum
                }
                //                let cellIndex : Int = Int((y-yMegin)/(yDistance+height)*itemNum) + xNum;
                var propertiesDict : Dictionary = (dict as! Dictionary<String,Any>)["properties"] as! Dictionary<String,Any>
                propertiesDict["cellIndex"] = String(cellIndex)
                var newDict = dict as! Dictionary<String,Any>
                newDict.updateValue(propertiesDict, forKey: "properties")
                collectionViewCellArray[i] = newDict
                i = i + 1
                
            }
            for item in collectionViewCellArray {
                objectArray.append(item as AnyObject)
            }
        }
        return ["objects": objectArray as AnyObject,
                "rootObject": objectIdentityProvider.getIdentifier(for: rootObject) as AnyObject]
    }
    
    func findCollectionViewCellInterval(of xArray:Array<Any>,type:Int) -> Dictionary<String,Any> {
        let value : Dictionary = requrieWidgetFrame(of: xArray[0] as! Dictionary<String, Any>)
        var size : Float
        if type == 0  {
            size = Float(truncating: value["Width"] as! NSNumber)
        }else {
            size = Float(truncating: value["Height"] as! NSNumber)
        }
        var arr = [Float]()
        
        for item in xArray {
            var value : Dictionary = requrieWidgetFrame(of: item as! Dictionary<String,Any>)
            var num : Float
            if type == 0 {
                num = Float(truncating: value["X"] as! NSNumber)
            }else{
                num = Float(truncating: value["Y"] as! NSNumber)
            }
            arr.append(num)
        }
        if Set(arr).count != arr.count {
            arr = Array(Set(arr))
        }
        var newArray : Array = quickSort(arr)
        var distance : Float = 0
        var megin : Float = 0
        var itemNum : Float = 0
        if newArray.count == 1 {
            megin = newArray[0]
        }else if newArray.count > 1 {
            distance = newArray[1] - newArray[0] - size
            let arrayItem = newArray[0]
            let tmp : Float = newArray[0]/(distance + size)
            var tmp2 :Int
            if tmp.isNaN {
                tmp2 = 0
            }else{
                tmp2 = Int(tmp)
            }
            megin = newArray[0] - Float(tmp2 * Int(distance+size))
        }
        
        if type == 0 {
            itemNum = (newArray[newArray.count - 1] - newArray[0])/(distance + size) + 1
        }
        
        if distance.isInfinite || distance.isNaN{
            distance = 0
        }
        
        if megin.isInfinite || megin.isNaN{
            megin = 0
        }
        
        if itemNum.isInfinite || itemNum.isNaN{
            itemNum = 0
        }
        
        var result : Dictionary = ["distance":distance,"megin":megin,"itemNum":itemNum]
        return result
        
        
        
    }
    
    func quickSort(_ a: [Float]) -> [Float] {
        if a.count <= 1 { return a }
        return quickSort(a.filter({$0 < a[0]})) + a.filter({$0 == a[0]}) + quickSort(a.filter({$0 > a[0]}))
    }
    
    func requrieWidgetFrame(of serializedObject:Dictionary<String, Any>) -> Dictionary<String, Any> {
        var properties : Dictionary = serializedObject["properties"] as! Dictionary<String,Any>
        var frame : Dictionary = properties["frame"] as! Dictionary<String,Any>
        var values : Array = frame["values"] as! Array<Any>
        let dict : Dictionary = values[0] as! Dictionary<String,Any>
        let value : Dictionary = dict["value"] as! Dictionary<String,Any>
        return value
    }
    
    func visitObject(_ object: AnyObject?, context: ObjectSerializerContext,itemArray:Array<Any>) -> Array<Any>{
        guard var object = object else {
            return [Any]()
        }
        
        if let view = object as? UIView {
            if !view.translatesAutoresizingMaskIntoConstraints {
                view.translatesAutoresizingMaskIntoConstraints = true
            }
        }
        
        context.addVisitedObject(object)
        
        var propertyValues = [String: AnyObject]()
        var delegate: AnyObject? = nil
        var delegateMethods = [AnyObject]()
        
        if var classDescription = getClassDescription(of: object) {
            for propertyDescription in classDescription.getAllPropertyDescriptions() {
                if propertyDescription.shouldReadPropertyValue(of: object), let name = propertyDescription.name {
                    let propertyValue = getPropertyValue(of: &object, propertyDescription: propertyDescription, context: context)
                    propertyValues[name] = propertyValue as AnyObject
                }
            }
            
            let delegateSelector: Selector = NSSelectorFromString("delegate")
            var tmpObject = object
            
            if tmpObject is UITableViewCell {
                classDescription = classDescriptionForTableViewCellObject(of: object)
                tmpObject = requireParentObjectFromTableViewCellObject(of: object)
            }else if tmpObject is UICollectionViewCell {
                classDescription = classDescriptionForCollectionViewCellObject(of: object)
                tmpObject = requireParentObjectFromCollectionViewCellObject(of: object)
            }
            
            
            if !classDescription.delegateInfos.isEmpty && tmpObject.responds(to: delegateSelector) {
                let imp = tmpObject.method(for: delegateSelector)
                typealias MyCFunction = @convention(c) (AnyObject, Selector) -> AnyObject
                let curriedImplementation = unsafeBitCast(imp, to: MyCFunction.self)
                delegate = curriedImplementation(tmpObject, delegateSelector)
                for delegateInfo in classDescription.delegateInfos {
                    if let selectorName = delegateInfo.selectorName,
                        let respondsToDelegate = delegate?.responds(to: NSSelectorFromString(selectorName)), respondsToDelegate {
                        delegateMethods.append(selectorName as AnyObject)
                    }
                }
            }
        }
        
        var serializedObject: [String: Any] = ["id": objectIdentityProvider.getIdentifier(for: object),
                                               "class": getClassHierarchyArray(of: object),
                                               "properties": propertyValues,
                                               "delegate": ["class": delegate != nil ? NSStringFromClass(type(of: delegate!)) : "",
                                                            "selectors": delegateMethods]                       ]
        if let webView = object as? UIWebView, webView.window != nil {
            serializedObject["htmlPage"] = getUIWebViewHTMLInfo(from: webView)
        } else  if object is WKWebView {
            serializedObject["htmlPage"] = getWKWebViewHTMLInfo(from: object as! WKWebView)
        }
        
        if object is UITableViewCell {
            context.addSerializedObject(addTableViewCellIndexToSerializedObject(of: serializedObject))
            return [Any]()
        }else if object is UICollectionViewCell{
            var array : Array = itemArray
            array.append(serializedObject)
            return array
        }else {
            context.addSerializedObject(serializedObject)
            return [Any]()
        }
    }
    
    func addTableViewCellIndexToSerializedObject(of serializedObject : Dictionary<String, Any>)-> Dictionary<String, Any>{
        let properties : Dictionary = serializedObject["properties"] as! Dictionary<String, Any>
        let frame : Dictionary = properties["frame"] as! Dictionary<String, Any>
        let values: Array = frame["values"] as! Array<Any>
        let dict :Dictionary = values[0] as! Dictionary<String, Any>
        let value : Dictionary = dict["value"] as! Dictionary<String, Any>
        let height : Float = Float(value["Height"] as! Float)
        
        let center : Dictionary = properties["center"] as! Dictionary<String, Any>
        let valuesCenter : Array = center["values"] as! Array<Any>
        let dictCenter : Dictionary = valuesCenter[0] as! Dictionary<String, Any>
        let valueCenter : Dictionary = dictCenter["value"] as! Dictionary<String, Any>
        let y : Float = Float(valueCenter["Y"] as! Float)
        let i : Int = Int((y-height/2)/height)
        var tmpObject = serializedObject["properties"] as! Dictionary<String,Any>
        tmpObject.updateValue(i, forKey:"cellIndex")
        var newObject :Dictionary<String, Any> = serializedObject
        newObject["properties"] = tmpObject
        return newObject
    }
    
    
    func classDescriptionForTableViewCellObject(of object : AnyObject) -> ClassDescription {
        var parentDescription : ClassDescription
        parentDescription = configuration.getType("UITableView") as! ClassDescription
        return parentDescription
    }
    
    func requireParentObjectFromTableViewCellObject(of object : AnyObject) -> AnyObject{
        var view = object as! UIView
        while  !(view is UITableView) {
            view = view.superview!
        }
        return view
    }
    
    func classDescriptionForCollectionViewCellObject(of object : AnyObject) -> ClassDescription {
        var parentDescription : ClassDescription
        parentDescription = configuration.getType("UICollectionView") as! ClassDescription
        return parentDescription
    }
    
    func requireParentObjectFromCollectionViewCellObject(of object : AnyObject) -> AnyObject{
        var view = object as! UIView
        while  !(view is UICollectionView) {
            view = view.superview!
        }
        return view
    }
    
    
    
    func getClassHierarchyArray(of object: AnyObject) -> [String] {
        var classHierarchy = [String]()
        var aClass: AnyClass? = type(of: object)
        while aClass != nil {
            classHierarchy.append(NSStringFromClass(aClass!))
            aClass = aClass?.superclass()
        }
        return classHierarchy
    }
    
    func getAllValues(of typeName: String) -> [Any] {
        let typeDescription = configuration.getType(typeName)
        if let enumDescription = typeDescription as? EnumDescription {
            return enumDescription.getAllValues()
        }
        return []
    }
    
    func getParameterVariations(of propertySelectorDescription: PropertySelectorDescription) -> [[Any]] {
        var variations = [[Any]]()
        if let parameterDescription = propertySelectorDescription.parameters.first, let typeName = parameterDescription.type {
            variations = getAllValues(of: typeName).map { [$0] }
        } else {
            // An empty array of parameters (for methods that have no parameters).
            variations.append([])
        }
        return variations
    }
    
    func getTransformedValue(of propertyValue: Any?, propertyDescription: PropertyDescription, context: ObjectSerializerContext) -> Any? {
        if let propertyValue = propertyValue {
            if context.hasVisitedObject(propertyValue as AnyObject) {
                return objectIdentityProvider.getIdentifier(for: propertyValue as AnyObject)
            } else if isNestedObject(propertyDescription.type!) {
                context.enqueueUnvisitedObject(propertyValue as AnyObject)
                return objectIdentityProvider.getIdentifier(for: propertyValue as AnyObject)
            } else if propertyValue is [AnyObject] || propertyValue is Set<NSObject> {
                var arrayOfIdentifiers = [Any]()
                var values = propertyValue as? [AnyObject]
                if let propertyValue = propertyValue as? Set<NSObject> {
                    values = Array(propertyValue)
                }
                for value in values! {
                    if !context.hasVisitedObject(value) {
                        context.enqueueUnvisitedObject(value)
                    }
                    arrayOfIdentifiers.append(objectIdentityProvider.getIdentifier(for: value as AnyObject))
                }
                return propertyDescription.getValueTransformer()!.transformedValue(arrayOfIdentifiers)
            }
        }
        return propertyDescription.getValueTransformer()!.transformedValue(propertyValue)
    }
    
    func getPropertyValue(of object: inout AnyObject, propertyDescription: PropertyDescription, context: ObjectSerializerContext) -> Any {
        var values = [Any]()
        let selectorDescription = propertyDescription.getSelectorDescription
        if propertyDescription.useKeyValueCoding {
            // the "fast" path is to use KVC
            let valueForKey = object.value(forKey: selectorDescription.selectorName!)
            if let value = getTransformedValue(of: valueForKey,
                                               propertyDescription: propertyDescription,
                                               context: context) {
                values.append(["value": value])
            }
        } else {
            // for methods that need to be invoked to get the return value with all possible parameters
            let parameterVariations = getParameterVariations(of: selectorDescription)
            assert(selectorDescription.parameters.count <= 1)
            for parameters in parameterVariations {
                if let selector = selectorDescription.selectorName {
                    
                    var returnValue: AnyObject? = nil
                    if parameters.isEmpty {
                        returnValue = object.perform(Selector(selector))?.takeUnretainedValue()
                    } else if parameters.count == 1 {
                        returnValue = object.perform(Selector(selector), with: parameters.first!)?.takeUnretainedValue()
                    } else {
                        assertionFailure("Currently only allowing 1 parameter or less")
                    }
                    
                    if let value = getTransformedValue(of: returnValue,
                                                       propertyDescription: propertyDescription,
                                                       context: context) {
                        values.append(["where": ["parameters": parameters],
                                       "value": value])
                    }
                }
            }
        }
        return ["values": values]
    }
    
    func isNestedObject(_ typeName: String) -> Bool {
        return configuration.classes[typeName] != nil
    }
    
    func getClassDescription(of object: AnyObject) -> ClassDescription? {
        var aClass: AnyClass? = type(of: object)
        while aClass != nil {
            if let classDescription = configuration.classes[NSStringFromClass(aClass!)] {
                return classDescription
            }
            aClass = aClass?.superclass()
        }
        return nil
    }
}

extension ObjectSerializer {
    
    func getUIWebViewHTMLInfo(from webView: UIWebView) -> [String: Any] {
        
        let wvBindings = WebViewBindings.global
        let storage = WebViewInfoStorage.global
        if var eventString = webView.stringByEvaluatingJavaScript(from: wvBindings.jsSource(of: "WebViewExcute.Report")),
            var eventData = eventString.data(using: String.Encoding.utf8),
            var event = try? JSONSerialization.jsonObject(with: eventData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any],
            let title = event["title"] as? String,
            let path = event["path"] as? String,
            let width = event["clientWidth"] as? Int,
            let height = event["clientHeight"] as? Int,
            let viewportContent = event["viewportContent"] as? String,
            let nodes = event["nodes"] as? String {
            storage.setHTMLInfo(withTitle: title, path: path, width: "\(width)", height: "\(height)", viewportContent: viewportContent, nodes: nodes)
            eventString.removeAll()
            eventData.removeAll()
            event.removeAll()
        }
        
        return storage.getHTMLInfo()
    }
    
    func getWKWebViewHTMLInfo(from webView: WKWebView) -> [String: Any] {
        
        let wvBindings = WebViewBindings.global
        webView.evaluateJavaScript(wvBindings.jsSource(of: "WebViewExcute.Report"), completionHandler: nil)
        return WebViewInfoStorage.global.getHTMLInfo()
    }
    
}
