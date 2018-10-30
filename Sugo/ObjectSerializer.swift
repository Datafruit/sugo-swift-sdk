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

        var collectionArray : Array<[String : Any]> = Array<[String : Any]>();
        
        while context.hasUnvisitedObjects() {
            let object = context.dequeueUnvisitedObject()
            let name : AnyClass = type(of:object) as! AnyClass
            let classStr : String = NSStringFromClass(name)
            if classStr .isEqual("UICollectionViewCell")  {
                collectionArray = visitObject(object, context: context,itemArray: collectionArray)
            }else{
                collectionArray = visitObject(context.dequeueUnvisitedObject(), context: context,itemArray: collectionArray)
            }
            
        }
        
        var objectArray : Array<[String : Any]> = context.getAllSerializedObjects() as! Array<[String : Any]>
        
        if collectionArray.count > 0 {
            var xDict : [String : Any] = findCollectionViewCellInterval(xArray: collectionArray, type: 0)
            var yDict : [String : Any] = findCollectionViewCellInterval(xArray: collectionArray, type: 1)
            let xDistance : Float = Float(xDict["distance"] as! String)!
            let xMegin : Float = Float(xDict["megin"] as! String)!
            let itemNum : Float = Float(xDict["itemNum"] as! String)!
            let yDistance : Float = Float (yDict["distance"] as! String)!
            let yMegin : Float = Float(yDict["megin"] as! String)!
            for dict : [String : Any] in collectionArray {
                var value : [String : Any] = requrieWidgetFrame(of: dict)
                let y : Float = Float(value["Y"] as! String)!
                let x : Float = Float(value["X"] as! String)!
                let width : Float = Float(value["Width"] as! String)!
                let height : Float = Float(value["Height"] as! String)!
                let cellIndex : Float = (y-yMegin)/(yDistance + height)*itemNum + (x-xMegin)/(xDistance + width)
                var properties : [String : Any] = dict["properties"] as! [String : Any]
                properties["cellIndex"] = cellIndex
            }
            objectArray = objectArray + collectionArray
        }

        return ["objects": objectArray as AnyObject,
                "rootObject": objectIdentityProvider.getIdentifier(for: rootObject) as AnyObject]
    }
    
    //find collection的line distance，item distance，left megin，top megin。
    //type:require X array or Y array;     0:X array ;   1:Y array;
    func findCollectionViewCellInterval(xArray : Array<[String : Any]>,type : Int) -> [String : Any] {
        var value : [String : Any] = requrieWidgetFrame(of: xArray[0])
        var size : Float
        if type == 0{
            size = Float(value["Width"] as! String)!
        }else{
            size = Float(value["Height"] as! String)!
        }
        var arr : Array<Float> = Array<Float>()
        for dict : [String : Any] in xArray{
            let value : [String : Any] = requrieWidgetFrame(of: dict)
            var num : Float
            if type == 0 {
                num = Float(value["X"] as! String)!
            }else{
                num = Float(value["Y"] as! String)!
            }
            arr.append(num)
        }
        var newArray : Array<Float> = Array(Set(arr))
        var distance : Float = 0.0
        var megin : Float = 0.0
        var itemNum = 0
        
        if newArray.count == 1 {
            megin = newArray[0]
        }else if newArray.count>1{
            distance = newArray[1]-newArray[0]-size
            let tmp : Int = Int(newArray[0]/(distance+size))
            megin = newArray[0] - Float(tmp)*(distance+size)
        }
        if type == 0{//when is x array,require per line cell num;
            itemNum = Int(newArray[newArray.count-1] - newArray[0]/(distance + size)+1)
        }
        
        let result : [NSString : Any] = ["distance" : String(distance),
                                         "megin" : String(megin),
                                         "itemNum" : String(itemNum)]
        return result as [String : Any]
    }
    
    func visitObject(_ object: AnyObject?, context: ObjectSerializerContext,itemArray : Array<[String : Any]>) -> Array<[String : Any]> {
        guard var object = object else {
            return Array()
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

        if let classDescription = getClassDescription(of: object) {
            for propertyDescription in classDescription.getAllPropertyDescriptions() {
                if propertyDescription.shouldReadPropertyValue(of: object), let name = propertyDescription.name {
                    let propertyValue = getPropertyValue(of: &object, propertyDescription: propertyDescription, context: context)
                    propertyValues[name] = propertyValue as AnyObject
                }
            }
            
            

            let delegateSelector: Selector = NSSelectorFromString("delegate")
            if !classDescription.delegateInfos.isEmpty && object.responds(to: delegateSelector) {
                let imp = object.method(for: delegateSelector)
                typealias MyCFunction = @convention(c) (AnyObject, Selector) -> AnyObject
                let curriedImplementation = unsafeBitCast(imp, to: MyCFunction.self)
                delegate = curriedImplementation(object, delegateSelector)
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
        
        let webFrame : [String : Any] = requrieWidgetFrame(of: serializedObject)
        if let webView = object as? UIWebView, webView.window != nil {
            serializedObject["htmlPage"] = getUIWebViewHTMLInfo(from: webView, webViewFrame:webFrame)
        } else  if object is WKWebView {
            serializedObject["htmlPage"] = getWKWebViewHTMLInfo(from: object as! WKWebView,webViewFrame:webFrame )
        }
        
        let name : AnyClass = type(of:object)
        let classStr : String = NSStringFromClass(name)
        if classStr .isEqual("UITableViewCell")  {
            context.addVisitedObject(addTableViewCellIndexToSerializedObject(serializedObject: serializedObject) as AnyObject)
            return Array()
        }else if classStr .isEqual("UICollectionViewCell"){
            var items : Array<[String : Any]> = itemArray
            items.append(serializedObject)
            return items
        }else{
            context.addSerializedObject(serializedObject)
            return Array()
        }
    }
    
    func addTableViewCellIndexToSerializedObject(serializedObject : [String : Any]) -> [String : Any] {
        var properties : [String : Any] = serializedObject["properties"] as! [String : Any]
        let frame : [String : Any] = properties["frame"] as! [String : Any]
        let values : Array = frame["values"] as! Array<AnyObject>
        let dict : [String : Any] = values[0] as! [String : Any]
        let value : [String : Any] = dict["value"] as! [String : Any]
        let height : Float = value["Height"] as! Float
        
        let center : [String : Any] = properties["center"] as! [String : Any]
        let valuesCenter : Array = center["values"] as! Array<AnyObject>
        let dictCenter : [String : Any] = valuesCenter[0] as! [String : Any]
        let valueCenter : [String : Any] = dictCenter["value"] as! [String : Any]
        let y : Float = valueCenter["Y"] as! Float
        let i : Int = Int((y-height/2)/height)
        
        properties["cellIndex"] = String(i)
        return serializedObject
    }
    
    func requrieWidgetFrame(of serializedObject : [String: Any]) -> [String: Any] {
        let properties : [String : Any] = serializedObject["properties"] as! [String : Any]
        let frame : [String : Any] = properties["frame"] as! [String : Any]
        let values : Array<[String : Any]> = frame["values"] as! Array<[String : Any]>
        let dict : [String : Any] = values[0]
        let value : [String : Any] = dict["value"] as! [String : Any]
        return value
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
            let title = event!["title"] as? String,
            let path = event!["path"] as? String,
            let width = event!["clientWidth"] as? Int,
            let height = event!["clientHeight"] as? Int,
            let viewportContent = event!["viewportContent"] as? String,
            let nodes = event!["nodes"] as? String {
            storage.setHTMLInfo(withTitle: title, path: path, width: "\(width)", height: "\(height)", viewportContent: viewportContent, nodes: nodes)
            eventString.removeAll()
            eventData.removeAll()
            event?.removeAll()
        }
        
        return storage.getHTMLInfo()
    }
    
    func getUIWebViewHTMLInfo(from webView: UIWebView , webViewFrame : [String : Any]) -> [String: Any] {
        
        let wvBindings = WebViewBindings.global
        let storage = WebViewInfoStorage.global
        if var eventString = webView.stringByEvaluatingJavaScript(from: wvBindings.jsSource(of: "WebViewExcute.Report")),
            var eventData = eventString.data(using: String.Encoding.utf8),
            var event = try? JSONSerialization.jsonObject(with: eventData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any],
            let title = event!["title"] as? String,
            let path = event!["path"] as? String,
            let width = event!["clientWidth"] as? Int,
            let height = event!["clientHeight"] as? Int,
            let viewportContent = event!["viewportContent"] as? String,
            let nodes = event!["nodes"] as? String {
            
            let tempDic : [String : Any]  = NSKeyedUnarchiver.unarchiveObject(with: eventData) as! [String : Any]
            var clientHeight : Float = 0.0
            if tempDic["clientHeight"] is Float {
                clientHeight = (tempDic["clientHeight"] as? Float)!
            }
            var webHeight : Float = 0.0
            if webViewFrame["Height"] is Float {
                webHeight = (webViewFrame["Height"] as? Float)!
            }
            let distance = clientHeight == 0.0 ? 0 :webHeight-clientHeight
            storage.setHTMLInfo(withTitle: title, path: path, width: "\(width)", height: "\(height)", viewportContent: viewportContent, nodes: nodes,distance:"\(distance)")
            
            eventString.removeAll()
            eventData.removeAll()
            event?.removeAll()
        }
        
        return storage.getHTMLInfo()
    }

    func getWKWebViewHTMLInfo(from webView: WKWebView ,webViewFrame : [String : Any]) -> [String: Any] {
        
        let wvBindings = WebViewBindings.global
        webView.evaluateJavaScript(wvBindings.jsSource(of: "WebViewExcute.Report"), completionHandler: nil)
        
        var dict : [String:Any] = WebViewInfoStorage.global.getHTMLInfo()
        var clientHeight : Float = 0.0
        if dict["clientHeight"] is Float {
            clientHeight = (dict["clientHeight"] as? Float)!
        }
        var webHeight : Float = 0.0
        if webViewFrame["Height"] is Float {
            webHeight = (webViewFrame["Height"] as? Float)!
        }
        let distance = clientHeight == 0.0 ? 0 :webHeight-clientHeight
        dict["distance"] = "\(distance)"
        
        return dict
    }
    
}
