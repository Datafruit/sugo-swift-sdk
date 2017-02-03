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
    var decideFetched = false
    var codelessInstance = Codeless()
    var webSocketWrapper: WebSocketWrapper?
    var enableVisualEditorForCodeless = true
    let codelessServerURL = ServerURL.codeless

    func checkDecide(forceFetch: Bool = false,
                     distinctId: String,
                     token: String,
                     completion: @escaping ((_ response: DecideResponse?) -> Void)) {
        var decideResponse = DecideResponse()

        if !decideFetched || forceFetch {
            let semaphore = DispatchSemaphore(value: 0)
            decideRequest.sendRequest(distinctId: distinctId, token: token) { decideResult in
                guard let result = decideResult else {
                    semaphore.signal()
                    completion(nil)
                    return
                }
                
                do {
                    let resultJSON = try JSONSerialization.data(withJSONObject: result, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let resultString = String(data: resultJSON, encoding: String.Encoding.utf8)
                    Logger.debug(message: "Decide result:\n\(resultString)")
                } catch {
                    Logger.debug(message: "Decide serialize result error")
                }

                var parsedCodelessBindings = Set<CodelessBinding>()
                if let commonCodelessBindings = result["event_bindings"] as? [[String: Any]] {
                    for commonBinding in commonCodelessBindings {
                        if let binding = Codeless.createBinding(object: commonBinding) {
                            parsedCodelessBindings.insert(binding)
                        }
                    }
                } else {
                    Logger.debug(message: "codeless event bindings check response format error")
                }
                
                let finishedCodelessBindings = self.codelessInstance.codelessBindings.subtracting(parsedCodelessBindings)
                for finishedBinding in finishedCodelessBindings {
                    finishedBinding.stop()
                }

                let newCodelessBindings = parsedCodelessBindings.subtracting(self.codelessInstance.codelessBindings)
                decideResponse.newCodelessBindings = newCodelessBindings

                self.codelessInstance.codelessBindings.formUnion(newCodelessBindings)
                self.codelessInstance.codelessBindings.subtract(finishedCodelessBindings)

                if let htmlCodelessBindings = result["h5_event_bindings"] as? [[String: Any]] {
                    decideResponse.htmlCodelessBindings = htmlCodelessBindings
                    WebViewBindings.global.decideBindings = htmlCodelessBindings
                    WebViewBindings.global.fillBindings()
                }
                
                if let pageInfo = result["page_info"] as? [[String: String]] {
                    SugoPageInfos.global.infos.removeAll()
                    SugoPageInfos.global.infos = pageInfo
                }

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

    func connectToWebSocket(token: String, sugoInstance: SugoInstance, reconnect: Bool = false) {
        var oldInterval = 0.0
        let webSocketURL = "\(codelessServerURL)/connect/\(token)"
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
