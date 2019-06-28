//
//  Decide.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/5/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

struct DecideResponse {
    var newCodelessBindings: Set<CodelessBinding>
    var htmlCodelessBindings: [[String: Any]]

    init() {
        newCodelessBindings = Set()
        htmlCodelessBindings = [[String: Any]]()
    }
}

class Decide {

    var decideRequest = DecideRequest()
    var decideResponse = DecideResponse()
    var decideFetched = false
    var codelessInstance = Codeless()
    var webSocketWrapper: WebSocketWrapper?
    var enableVisualEditorForCodeless = true
    let codelessSugoServerURL = (Sugo.CodelessURL != nil && !Sugo.CodelessURL!.isEmpty) ? Sugo.CodelessURL! : SugoServerURL.codeless
    
    func runEventApiRequest(forceFetch: Bool = false,
                            sugoInstance: SugoInstance,
                            completion: @escaping ((_ response: DecideResponse?) -> Void)) {
        var cacheObject = [String: Any]()
        let userDefault = UserDefaults.standard
        var cacheAppVersion = String()
        let isUpdateConfig = userDefault.bool(forKey: "isUpdateConfig")
        var latestVersion = String()
        let latestDimensionVersion = userDefault.integer(forKey: "latestDimensionVersion")
        let latestEventBindingVersion = userDefault.integer(forKey: "latestEventBindingVersion")
        latestVersion = String(latestEventBindingVersion)
        if let sugoEventBindingsAppVersion = userDefault.string(forKey: "SugoEventBindingsAppVersion"){
            cacheAppVersion = sugoEventBindingsAppVersion
        }
        if let cacheData = userDefault.data(forKey: "SugoEventBindings") {
            
            let cacheString = String(data: cacheData, encoding: String.Encoding.utf8)
            Logger.debug(message: "Cache decide result:\n\(cacheString.debugDescription)")
            
            do {
                if let co = try JSONSerialization.jsonObject(with: cacheData,
                                                             options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    cacheObject = co
                }
            } catch {
                Logger.debug(message: "Failed to serialize cache event bindings")
            }
        }
        
        
        if isUpdateConfig {
            let userDefaults = UserDefaults.standard
            userDefaults.set(-1, forKey: "SugoEventBindingsAppVersion")
            userDefaults.synchronize()
        }else {
            if cacheAppVersion == latestVersion {
                handleDecideEvent(object:cacheObject)
                completion(decideResponse)
                return
            }
        }
        
        var resultData = Data()
        var responseObject = [String: Any]()
        
        let userDefaults = UserDefaults.standard
        var cacheVersion = -1;
        var currentAppVersion = String()
        
       
        if let sugoEventBindingsAppVersion = userDefaults.string(forKey: "SugoEventBindingsAppVersion"){
            cacheAppVersion = sugoEventBindingsAppVersion
        }
        
        if let infoDict = Bundle.main.infoDictionary,
            let bundleShortVersionString = infoDict["CFBundleShortVersionString"] as? String  {
            currentAppVersion = bundleShortVersionString
        }
        
        if let cv = cacheObject["event_bindings_version"] as? Int,
            cacheAppVersion == currentAppVersion {
            cacheVersion = cv
        }
        
        if !decideFetched || forceFetch {
            let semaphore = DispatchSemaphore(value: 0)
            decideRequest.sendRequest(projectId: sugoInstance.projectId,
                                      token: sugoInstance.apiToken,
                                      requestType: DecideRequest.RequestType.decideEvent.rawValue,
                                      distinctId: sugoInstance.distinctId,
                                      eventBindingsVersion: cacheVersion) { decideResult in
                                        
                                        guard let resultObject = decideResult else {
                                            semaphore.signal()
                                            completion(nil)
                                            return
                                        }
                                        
                                        do {
                                            resultData = try JSONSerialization.data(withJSONObject: resultObject,
                                                                                    options: JSONSerialization.WritingOptions.prettyPrinted)
                                            let resultString = String(data: resultData, encoding: String.Encoding.utf8)
                                            Logger.debug(message: "Decide result:\n\(resultString.debugDescription)")
                                        } catch {
                                            Logger.debug(message: "Decide serialize result error")
                                        }
                                        
                                        responseObject = resultObject
                                        
                                        self.decideFetched = true
                                        semaphore.signal()
            }
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            
        } else {
            Logger.info(message: "decide cache found, skipping network request")
        }
        
        let responseVersion = responseObject["event_bindings_version"] as? Int
        if responseVersion != cacheVersion || cacheAppVersion != currentAppVersion {
            userDefaults.synchronize()
            userDefaults.set(currentAppVersion, forKey: "SugoEventBindingsAppVersion")
            userDefaults.set(resultData, forKey: "SugoEventBindings")
            handleDecideEvent(object:responseObject)
        } else {
            handleDecideEvent(object:cacheObject)
        }
        completion(decideResponse)
    }
    
    func handleDecideEvent(object:[String: Any]) {
        var parsedCodelessBindings = Set<CodelessBinding>()
        if let commonCodelessBindings = object["event_bindings"] as? [[String: Any]] {
            for commonBinding in commonCodelessBindings {
                if let binding = Codeless.createBinding(object: commonBinding) {
                    parsedCodelessBindings.insert(binding)
                }
            }
        }
        
        //        let finishedCodelessBindings = self.codelessInstance.codelessBindings.subtracting(parsedCodelessBindings)
        let finishedCodelessBindings = self.codelessInstance.codelessBindings
        for finishedBinding in finishedCodelessBindings {
            finishedBinding.stop()
        }
        
        //        let newCodelessBindings = parsedCodelessBindings.subtracting(self.codelessInstance.codelessBindings)
        let newCodelessBindings = parsedCodelessBindings
        decideResponse.newCodelessBindings = newCodelessBindings
        
        self.codelessInstance.codelessBindings.formUnion(newCodelessBindings)
        self.codelessInstance.codelessBindings.subtract(finishedCodelessBindings)
        
        if let htmlCodelessBindings = object["h5_event_bindings"] as? [[String: Any]] {
            decideResponse.htmlCodelessBindings = htmlCodelessBindings
            WebViewBindings.global.decideBindings = htmlCodelessBindings
        }
        
        if let pageInfo = object["page_info"] as? [[String: Any]] {
            SugoPageInfos.global.infos.removeAll()
            SugoPageInfos.global.infos = pageInfo
        }
    }
    
    func runDimApiRequest(forceFetch: Bool = false,
                          sugoInstance: SugoInstance) {
        var cacheObject = [String: Any]()
        let userDefault = UserDefaults.standard
        var cacheAppVersion = String()
        let isUpdateConfig = userDefault.bool(forKey: "isUpdateConfig")
        var latestVersion = String()
        let latestDimensionVersion = userDefault.integer(forKey: "latestDimensionVersion")
        let latestEventBindingVersion = userDefault.integer(forKey: "latestEventBindingVersion")
        latestVersion = String(latestDimensionVersion)
        if let sugoEventBindingsAppVersion = userDefault.string(forKey: "SugoDecideDimesionAppVersion"){
            cacheAppVersion = sugoEventBindingsAppVersion
        }
        if let cacheData = userDefault.data(forKey: "SugoDecideDimesion") {
            
            let cacheString = String(data: cacheData, encoding: String.Encoding.utf8)
            Logger.debug(message: "Cache decide result:\n\(cacheString.debugDescription)")
            
            do {
                if let co = try JSONSerialization.jsonObject(with: cacheData,
                                                             options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    cacheObject = co
                }
            } catch {
                Logger.debug(message: "Failed to serialize cache event bindings")
            }
        }
        
        
        if isUpdateConfig {
            let userDefaults = UserDefaults.standard
            userDefaults.set(-1, forKey: "SugoDecideDimesionAppVersion")
            userDefaults.synchronize()
        }else {
            if cacheAppVersion == latestVersion {
                handleDecideDimensions(object: cacheObject)
                return
            }
        }
        
        var resultData = Data()
        var responseObject = [String: Any]()
        
        let userDefaults = UserDefaults.standard
        var cacheVersion = -1;
        var currentAppVersion = String()
        if let sugoEventBindingsAppVersion = userDefaults.string(forKey: "SugoDecideDimesionAppVersion"){
            cacheAppVersion = sugoEventBindingsAppVersion
        }
        
        if let infoDict = Bundle.main.infoDictionary,
            let bundleShortVersionString = infoDict["CFBundleShortVersionString"] as? String  {
            currentAppVersion = bundleShortVersionString
        }
        
        if let cv = cacheObject["event_bindings_version"] as? Int,
            cacheAppVersion == currentAppVersion {
            cacheVersion = cv
        }
        
        if !decideFetched || forceFetch {
            let semaphore = DispatchSemaphore(value: 0)
            decideRequest.sendRequest(projectId: sugoInstance.projectId,
                                      token: sugoInstance.apiToken,
                                      requestType: DecideRequest.RequestType.decideDimesion.rawValue,
                                      distinctId: sugoInstance.distinctId,
                                      eventBindingsVersion: cacheVersion) { decideResult in
                                        
                                        guard let resultObject = decideResult else {
                                            semaphore.signal()
                                            return
                                        }
                                        
                                        do {
                                            resultData = try JSONSerialization.data(withJSONObject: resultObject,
                                                                                    options: JSONSerialization.WritingOptions.prettyPrinted)
                                            let resultString = String(data: resultData, encoding: String.Encoding.utf8)
                                            Logger.debug(message: "Decide result:\n\(resultString.debugDescription)")
                                        } catch {
                                            Logger.debug(message: "Decide serialize result error")
                                        }
                                        
                                        responseObject = resultObject
                                        
                                        self.decideFetched = true
                                        semaphore.signal()
            }
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            
        } else {
            Logger.info(message: "decide cache found, skipping network request")
        }
        
        let responseVersion = responseObject["event_bindings_version"] as? Int
        if responseVersion != cacheVersion || cacheAppVersion != currentAppVersion {
            userDefaults.synchronize()
            userDefaults.set(currentAppVersion, forKey: "SugoDecideDimesionAppVersion")
            userDefaults.set(resultData, forKey: "SugoDecideDimesion")
            handleDecideDimensions(object: responseObject)
        } else {
            handleDecideDimensions(object: cacheObject)
        }
    }
    
    func handleDecideDimensions(object:[String: Any]) {
        if let dimensions = object["dimensions"] as? [[String: Any]] {
            let userDefaults = UserDefaults.standard
            userDefaults.set(dimensions, forKey: "SugoDimensions")
            userDefaults.synchronize()
        }
    }
    
    
    func handleDecide(object:[String: Any]) {
        var parsedCodelessBindings = Set<CodelessBinding>()
        if let commonCodelessBindings = object["event_bindings"] as? [[String: Any]] {
            for commonBinding in commonCodelessBindings {
                if let binding = Codeless.createBinding(object: commonBinding) {
                    parsedCodelessBindings.insert(binding)
                }
            }
        }
        
        let finishedCodelessBindings = self.codelessInstance.codelessBindings.subtracting(parsedCodelessBindings)
        for finishedBinding in finishedCodelessBindings {
            finishedBinding.stop()
        }
        
        let newCodelessBindings = parsedCodelessBindings.subtracting(self.codelessInstance.codelessBindings)
        decideResponse.newCodelessBindings = newCodelessBindings
        
        self.codelessInstance.codelessBindings.formUnion(newCodelessBindings)
        self.codelessInstance.codelessBindings.subtract(finishedCodelessBindings)
        
        if let htmlCodelessBindings = object["h5_event_bindings"] as? [[String: Any]] {
            decideResponse.htmlCodelessBindings = htmlCodelessBindings
            WebViewBindings.global.decideBindings = htmlCodelessBindings
        }
        
        if let pageInfo = object["page_info"] as? [[String: Any]] {
            SugoPageInfos.global.infos.removeAll()
            SugoPageInfos.global.infos = pageInfo
        }
        
        if let dimensions = object["dimensions"] as? [[String: Any]] {
            let userDefaults = UserDefaults.standard
            userDefaults.set(dimensions, forKey: "SugoDimensions")
            userDefaults.synchronize()
        }
    }

    func connectToWebSocket(token: String, sugoInstance: SugoInstance, reconnect: Bool = false) {
        
        guard !sugoInstance.heatMap.mode else {
            return
        }
        
        let webSocketURL = "\(codelessSugoServerURL)/connect/\(token)"
        guard let url = URL(string: webSocketURL) else {
            Logger.error(message: "bad URL to connect to websocket \(webSocketURL)")
            return
        }
        let connectCallback = { [weak sugoInstance] in
            guard let sugoInstance = sugoInstance else {
                return
            }
            sugoInstance.eventsQueue.removeAll()
            sugoInstance.flushInstance.stopFlushTimer()
            sugoInstance.cacheInstance.stopCacheTimer()
            UIApplication.shared.isIdleTimerDisabled = true
            
        }

        let disconnectCallback = { [weak sugoInstance] in
            guard let sugoInstance = sugoInstance else {
                return
            }
            sugoInstance.eventsQueue.removeAll()
            sugoInstance.flushInstance.startFlushTimer()
            sugoInstance.cacheInstance.startCacheTimer()
            UIApplication.shared.isIdleTimerDisabled = false

        }

        webSocketWrapper = WebSocketWrapper(url: url,
                                            keepTrying: reconnect,
                                            connectCallback: connectCallback,
                                            disconnectCallback: disconnectCallback)
        
        
    }

}
