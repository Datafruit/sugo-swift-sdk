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
import JavaScriptCore

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
                "rootObject": objectIdentityProvider.getIdentifier(for: rootObject) as AnyObject]
    }

    func visitObject(_ object: AnyObject?, context: ObjectSerializerContext) {
        guard var object = object else {
            return
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
        if object is UIWebView {
            serializedObject["htmlPage"] = getUIWebViewHTMLInfo(from: object as! UIWebView)
        } else  if object is WKWebView {
            serializedObject["htmlPage"] = getWKWebViewHTMLInfo(from: object as! WKWebView)
        }
        context.addSerializedObject(serializedObject)
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

extension ObjectSerializer: WKScriptMessageHandler {
    
    func getUIWebViewHTMLInfo(from webView: UIWebView) -> [String: Any] {
        
        let jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        
        jsContext.setObject(WebViewJSExport.self,
                            forKeyedSubscript: "WebViewJSExport" as (NSCopying & NSObjectProtocol)!)
        jsContext.evaluateScript(self.jsUIWebViewReportSource)
        jsContext.evaluateScript(self.jsUIWebViewReportExcute)
        
        return ["url": WebViewInfoStorage.global.path,
                "clientWidth": WebViewInfoStorage.global.width,
                "clientHeight": WebViewInfoStorage.global.height,
                "nodes": WebViewInfoStorage.global.nodes
        ]
    }

    func getWKWebViewHTMLInfo(from webView: WKWebView) -> [String: Any] {
        
        let jsReportScript = WKUserScript(source: self.jsWKWebViewReport, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        if !webView.configuration.userContentController.userScripts.contains(jsReportScript) {
            webView.configuration.userContentController.addUserScript(jsReportScript)
        }
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "WKWebViewReporter")
        webView.configuration.userContentController.add(self, name: "WKWebViewReporter")
        webView.evaluateJavaScript(self.jsWKWebViewReport, completionHandler: nil)
        
        return ["url": WebViewInfoStorage.global.path,
                "clientWidth": WebViewInfoStorage.global.width,
                "clientHeight": WebViewInfoStorage.global.height,
                "nodes": WebViewInfoStorage.global.nodes
        ]
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "WKWebViewReporter" {
            if let body = message.body as? [String: Any] {
                if let path = body["path"] as? String {
                    WebViewInfoStorage.global.path = path
                }
                if let clientWidth = body["clientWidth"] as? String {
                    WebViewInfoStorage.global.width = clientWidth
                }
                if let clientHeight = body["clientHeight"] as? String {
                    WebViewInfoStorage.global.height = clientHeight
                }
                if let nodes = body["nodes"] as? String {
                    WebViewInfoStorage.global.nodes = nodes
                }
            }
        }
    }
    
    fileprivate var jsUIWebViewReportExcute: String {
        return "sugo_report.reportNodes();"
    }
    
    fileprivate var jsUIWebViewReportSource: String {
        return "var sugo_report={};\n" +
            " sugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);\n" +
            " sugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);\n" +
            " sugo_report.isElementInViewport = function(rect) {\n" +
            "         return (\n" +
            "                 rect.top >= 0 &&\n" +
            "                 rect.left >= 0 &&\n" +
            "                 rect.bottom <= sugo_report.clientHeight && \n" +
            "                 rect.right <= sugo_report.clientWidth\n" +
            "         );\n" +
            " };\n" +
            " sugo_report.get_node_name = function(node){\n" +
            "  var path = '';\n" +
            "  var name = node.localName;\n" +
            "  if(name == 'script'){return '';}\n" +
            "  if(name == 'link'){return '';}\n" +
            "  path = name;\n" +
            "  id = node.id;\n" +
            "  if(id && id.length>0){\n" +
            "   path += '#' + id;\n" +
            "  }\n" +
            "  return path;\n" +
            " };\n" +
            " sugo_report.reportChildNode = function(childrens, jsonArry, parent_path){\n" +
            "   var index_map={};\n" +
            "   for(var i=0;i<childrens.length;i++){\n" +
            "    var children = childrens[i];\n" +
            "    var node_name = sugo_report.get_node_name(children);\n" +
            "    if (node_name == ''){ continue;}\n" +
            "    if(index_map[node_name] == null){\n" +
            "     index_map[node_name] = 0;\n" +
            "    }else{\n" +
            "     index_map[node_name] = index_map[node_name]  + 1;\n" +
            "    }\n" +
            "    var htmlNode={};\n" +
            "   var path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n" +
            "  htmlNode.path=path;" +
            "    var rect = children.getBoundingClientRect();\n" +
            "    if(sugo_report.isElementInViewport(rect) == true){ \n" +
            "     htmlNode.rect=rect;\n" +
            "     jsonArry.push(htmlNode);\n" +
            "    }\n" +
            "    if(children.children){\n" +
            "     sugo_report.reportChildNode(children.children, jsonArry, path);\n" +
            "    }\n" +
            "   }\n" +
            " };\n" +
            " sugo_report.reportNodes = function(){\n" +
            "  var jsonArry=[];\n" +
            "  var body = document.getElementsByTagName('body')[0];\n" +
            "  var childrens = body.children;\n" +
            "  var parent_path='';\n" +
            "  sugo_report.reportChildNode(childrens, jsonArry, parent_path);\n" +
            "  WebViewJSExport.infoWithPathNodesWidthHeight(window.location.pathname, JSON.stringify(jsonArry), sugo_report.clientWidth, sugo_report.clientHeight);\n" +
            " };"
    }
    
    fileprivate var jsWKWebViewReport: String {
        return "var sugo_report={};\n" +
            " sugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);\n" +
            " sugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);\n" +
            " sugo_report.isElementInViewport = function(rect) {\n" +
            "         return (\n" +
            "                 rect.top >= 0 &&\n" +
            "                 rect.left >= 0 &&\n" +
            "                 rect.bottom <= sugo_report.clientHeight && \n" +
            "                 rect.right <= sugo_report.clientWidth\n" +
            "         );\n" +
            " };\n" +
            " sugo_report.get_node_name = function(node){\n" +
            "  var path = '';\n" +
            "  var name = node.localName;\n" +
            "  if(name == 'script'){return '';}\n" +
            "  if(name == 'link'){return '';}\n" +
            "  path = name;\n" +
            "  id = node.id;\n" +
            "  if(id && id.length>0){\n" +
            "   path += '#' + id;\n" +
            "  }\n" +
            "  return path;\n" +
            " };\n" +
            " sugo_report.reportChildNode = function(childrens, jsonArry, parent_path){\n" +
            "   var index_map={};\n" +
            "   for(var i=0;i<childrens.length;i++){\n" +
            "    var children = childrens[i];\n" +
            "    var node_name = sugo_report.get_node_name(children);\n" +
            "    if (node_name == ''){ continue;}\n" +
            "    if(index_map[node_name] == null){\n" +
            "     index_map[node_name] = 0;\n" +
            "    }else{\n" +
            "     index_map[node_name] = index_map[node_name]  + 1;\n" +
            "    }\n" +
            "    var htmlNode={};\n" +
            "   var path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n" +
            "  htmlNode.path=path;" +
            "    var rect = children.getBoundingClientRect();\n" +
            "    if(sugo_report.isElementInViewport(rect) == true){ \n" +
            "     htmlNode.rect=rect;\n" +
            "     jsonArry.push(htmlNode);\n" +
            "    }\n" +
            "    if(children.children){\n" +
            "     sugo_report.reportChildNode(children.children, jsonArry, path);\n" +
            "    }\n" +
            "   }\n" +
            " };\n" +
            " sugo_report.reportNodes = function(){\n" +
            "  var jsonArry=[];\n" +
            "  var body = document.getElementsByTagName('body')[0];\n" +
            "  var childrens = body.children;\n" +
            "  var parent_path='';\n" +
            "  sugo_report.reportChildNode(childrens, jsonArry, parent_path);\n" +
            "  var message = {\n" +
            "    'path' : window.location.pathname,\n" +
            "    'clientWidth' : sugo_report.clientWidth,\n" +
            "    'clientHeight' : sugo_report.clientHeight,\n" +
            "    'nodes' : JSON.stringify(jsonArry)\n" +
            "    };\n" +
            "  window.webkit.messageHandlers.WKWebViewReporter.postMessage(message);\n" +
            " };\n" +
            " sugo_report.reportNodes();"
    }
    
}
