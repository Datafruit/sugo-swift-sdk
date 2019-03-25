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
    
    var _locateInterval = 0.0
    var locateInterval: Double {
        set {
            objc_sync_enter(self)
            _locateInterval = newValue
            objc_sync_exit(self)
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            return _locateInterval
        }
    }
    var _recentlySendLoacationTime : UInt64 = 0
    
    var recentlySendLoacationTime: UInt64 {
        set {
            objc_sync_enter(self)
            _recentlySendLoacationTime = UInt64(newValue)
            objc_sync_exit(self)
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _recentlySendLoacationTime
        }
    }

    var decideRequest = DecideRequest()
    var decideResponse = DecideResponse()
    var decideFetched = false
    var codelessInstance = Codeless()
    var webSocketWrapper: WebSocketWrapper?
    var enableVisualEditorForCodeless = true
    let codelessSugoServerURL = (Sugo.CodelessURL != nil && !Sugo.CodelessURL!.isEmpty) ? Sugo.CodelessURL! : SugoServerURL.codeless

    func checkDecide(forceFetch: Bool = false,
                     sugoInstance: SugoInstance,
                     requestType:Int,
                     completion: @escaping ((_ response: DecideResponse?) -> Void)) {

        var resultData = Data()
        var responseObject = [String: Any]()
        
        let userDefaults = UserDefaults.standard
        var cacheObject = [String: Any]()
        var cacheVersion = -1;
        var cacheAppVersion = String()
        var currentAppVersion = String()
        
        if let sugoEventBindingsAppVersion = userDefaults.string(forKey: "SugoEventBindingsAppVersion"){
            cacheAppVersion = sugoEventBindingsAppVersion
        }
        
        if let infoDict = Bundle.main.infoDictionary,
            let bundleShortVersionString = infoDict["CFBundleShortVersionString"] as? String  {
            currentAppVersion = bundleShortVersionString
        }
        
        if let cacheData = userDefaults.data(forKey: "SugoEventBindings") {
            
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
        
        if let cv = cacheObject["event_bindings_version"] as? Int,
            cacheAppVersion == currentAppVersion {
            cacheVersion = cv
        }
        
        if !decideFetched || forceFetch {
            let semaphore = DispatchSemaphore(value: 0)
            decideRequest.sendRequest(projectId: sugoInstance.projectId,
                                      token: sugoInstance.apiToken,
                                      requestType: requestType,
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
            userDefaults.set(currentAppVersion, forKey: "SugoEventBindingsAppVersion")
            userDefaults.set(resultData, forKey: "SugoEventBindings")
            userDefaults.synchronize()
            if requestType == DecideRequest.RequestType.decideDimesion.rawValue{
                handleDecideDimensions(object: responseObject)
            }else {
                handleDecideEvent(object:responseObject)
            }
           } else {
            if requestType == DecideRequest.RequestType.decideDimesion.rawValue{
                handleDecideDimensions(object: cacheObject)
            }else {
                handleDecideEvent(object:cacheObject)
            }
     }
        
        Logger.info(message: "decide check found \(decideResponse.newCodelessBindings.count) " +
            "new codeless bindings out of \(codelessInstance.codelessBindings)")

        if requestType == DecideRequest.RequestType.decideEvent.rawValue{
            completion(decideResponse)
        }
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
    
    func handleDecideDimensions(object:[String: Any]) {
        if let dimensions = object["dimensions"] as? [[String: Any]] {
            let userDefaults = UserDefaults.standard
            userDefaults.set(dimensions, forKey: "SugoDimensions")
            userDefaults.synchronize()
        }
        
        //获取地理位置上传间隔
        if let locationConfigure = object["position_config"] as? Double {
            self.locateInterval = locationConfigure * 60
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
