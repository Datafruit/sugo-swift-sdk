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

        while context.hasUnvisitedObjects() {
            visitObject(context.dequeueUnvisitedObject(), context: context)
        }

        return ["objects": context.getAllSerializedObjects() as AnyObject,
                "rootObject": objectIdentityProvider.getIdentifier(for: rootObject) as AnyObject,
                "classAttr":Sugo.classAttributeDict as AnyObject]
    }

    func visitObject(_ object: AnyObject?, context: ObjectSerializerContext) {
        guard var object = object else {
            return
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
        
        let classNameArr : Array<String> = getClassHierarchyArray(of: object)
        let className :String = classNameArr[0]
        
        if className == "SugoDemo.CustomButton"{
            var a = 5
        }
        let value  = Sugo.classAttributeDict[className]
        if value == nil {
            var count = UInt32()
            let properties  = class_copyIvarList(object_getClass(object.self), &count)
            var str : String = ""
            for i in 0 ..< count {
                let ivar : Ivar = properties![Int(i)]
                let typeName: UnsafePointer<Int8> = ivar_getTypeEncoding(ivar)!
                let attrName:UnsafePointer<Int8> = ivar_getName(ivar)!
                let proper = String.init(cString: attrName)
                let type = String.init(cString: typeName)
                print ("type："+"\(type)"+";proper:"+"\(proper)")
                if isBaseType(typeName: type){
                    if str == "" {
                        str = "\(proper)"
                    }else{
                        str = str + ",\(proper)"
                    }
                }
            }
            Sugo.classAttributeDict[className]=str
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
        context.addSerializedObject(serializedObject)
    }
    
    
    
    
    
    func isBaseType(typeName:String) -> Bool{
        var typeStr:String = typeName
        let arr : Array = ["int","double","float","char","long","short","signed","unsigned","short int","long int","unsigned int","unsigned short","unsigned long","long double","number","Boolean","BOOL","bool","NSString","NSDate","NSNumber","NSInteger","NSUInteger","enum","struct","B","Q","d","q","c","i","s","l","C","I","S","L","f","d","b","b1","B",""]
        var isBaseType : Bool = false
        typeStr = typeStr.replacingOccurrences(of: "\\", with: "")
        typeStr = typeStr.replacingOccurrences(of: "\"", with: "")
        typeStr = typeStr.replacingOccurrences(of: "@", with: "")
        for item in arr{
            if item == typeStr{
                isBaseType = true
                break
            }
        }
        return isBaseType
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

    func getWKWebViewHTMLInfo(from webView: WKWebView) -> [String: Any] {
        
        let wvBindings = WebViewBindings.global
        webView.evaluateJavaScript(wvBindings.jsSource(of: "WebViewExcute.Report"), completionHandler: nil)
        return WebViewInfoStorage.global.getHTMLInfo()
    }
    
}
