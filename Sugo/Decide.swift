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
    let codelessSugoServerURL = SugoServerURL.codeless

    func checkDecide(forceFetch: Bool = false,
                     projectId: String,
                     token: String,
                     distinctId: String,
                     completion: @escaping ((_ response: DecideResponse?) -> Void)) {

        let userDefaults = UserDefaults.standard
        if let cacheData = userDefaults.data(forKey: "EventBindings") {
            
            let cacheString = String(data: cacheData, encoding: String.Encoding.utf8)
            Logger.debug(message: "Cache decide result:\n\(cacheString)")

            do {
                if let cacheObject = try JSONSerialization.jsonObject(with: cacheData,
                                                                      options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    
                    handleDecide(object: cacheObject)
                }
            } catch {
                Logger.debug(message: "Failed to serialize EventBindings")
            }
        }
        
        if !decideFetched || forceFetch {
            let semaphore = DispatchSemaphore(value: 0)
            decideRequest.sendRequest(projectId: projectId,
                                      token: token,
                                      distinctId: distinctId) { decideResult in
                guard let resultObject = decideResult else {
                    semaphore.signal()
                    completion(nil)
                    return
                }
                
                do {
                    let resultData = try JSONSerialization.data(withJSONObject: resultObject, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let resultString = String(data: resultData, encoding: String.Encoding.utf8)
                    Logger.debug(message: "Decide result:\n\(resultString)")
                    userDefaults.set(resultData, forKey: "EventBindings")
                    userDefaults.synchronize()
                } catch {
                    Logger.debug(message: "Decide serialize result error")
                }

                self.handleDecide(object: resultObject)

                self.decideFetched = true
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        } else {
            Logger.info(message: "decide cache found, skipping network request")
        }

        Logger.info(message: "decide check found \(decideResponse.newCodelessBindings.count) " +
            "new codeless bindings out of \(codelessInstance.codelessBindings)")

        completion(decideResponse)
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
            WebViewBindings.global.fillBindings()
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
        var oldInterval = 0.0
        let webSocketURL = "\(codelessSugoServerURL)/connect/\(token)"
        guard let url = URL(string: webSocketURL) else {
            Logger.error(message: "bad URL to connect to websocket \(webSocketURL)")
            return
        }
        let connectCallback = { [weak sugoInstance] in
            guard let sugoInstance = sugoInstance else {
                return
            }
            oldInterval = sugoInstance.flushInterval
            sugoInstance.flushInterval = 1
            UIApplication.shared.isIdleTimerDisabled = true

            for binding in self.codelessInstance.codelessBindings {
                binding.stop()
            }
        }

        let disconnectCallback = { [weak sugoInstance] in
            guard let sugoInstance = sugoInstance else {
                return
            }
            sugoInstance.flushInterval = oldInterval
            UIApplication.shared.isIdleTimerDisabled = false

            for binding in self.codelessInstance.codelessBindings {
                binding.execute()
            }
            

        }

        webSocketWrapper = WebSocketWrapper(url: url,
                                            keepTrying: reconnect,
                                            connectCallback: connectCallback,
                                            disconnectCallback: disconnectCallback)
    }

}
