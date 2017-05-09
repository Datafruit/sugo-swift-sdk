//
//  Heats.swift
//  Sugo
//
//  Created by Zack on 8/5/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation
import UIKit

class Heats {
    
    var heatRequest = HeatsRequest()
    let heatsSugoServerURL = (Sugo.CodelessURL != nil && !Sugo.CodelessURL!.isEmpty) ? Sugo.CodelessURL! : SugoServerURL.codeless
    
    func checkHeats(sugoInstance: SugoInstance,
                    completion: @escaping ((_ response: HeatsResponse?) -> Void)) {
        
        if sugoInstance.decideInstance.webSocketWrapper != nil
            && sugoInstance.decideInstance.webSocketWrapper!.connected {
            return
        }
        
        var heatResponse = HeatsResponse()
        
        let semaphore = DispatchSemaphore(value: 0)
        if let secretKey = sugoInstance.urlHeatMapSecretKey {
            heatRequest.sendRequest(token: sugoInstance.apiToken, secretKey: secretKey) {
                                        HeatsResult in
                                        
                                        guard let resultObject = HeatsResult else {
                                            semaphore.signal()
                                            completion(nil)
                                            return
                                        }
                                        
                                        do {
                                            let resultData = try JSONSerialization.data(withJSONObject: resultObject,
                                                                                        options: JSONSerialization.WritingOptions.prettyPrinted)
                                            heatResponse.heats = resultData
                                            let resultString = String(data: resultData, encoding: String.Encoding.utf8)
                                            Logger.debug(message: "Heats result:\n\(resultString.debugDescription)")
                                        } catch {
                                            Logger.debug(message: "Heats serialize result error")
                                        }
                                        
                                        semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        completion(heatResponse)
    }

}
