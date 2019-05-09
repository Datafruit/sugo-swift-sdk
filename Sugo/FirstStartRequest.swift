//
//  FirstStartRequest.swift
//  Sugo
//
//  Created by 陈宇艺 on 2019/5/8.
//  Copyright © 2019 sugo. All rights reserved.
//

import Foundation


class FirstStartRequest: Network {
    
    typealias FirstStartResult = [String: Any]
    let firstStartPath = "/api/sdk/get-first-start-time"
    
    struct FirstLoginQueryItems {
        
        let deviceId: URLQueryItem
        let projectId: URLQueryItem
        let token: URLQueryItem
        let appVersion:URLQueryItem
        let appType:URLQueryItem
        
        init(deviceId: String, projectId: String, token: String,appVersion:String,appType:String) {
            
            self.deviceId = URLQueryItem(name: "device_id", value: deviceId)
            self.projectId = URLQueryItem(name: "project_id", value: projectId)
            self.token = URLQueryItem(name: "app_id", value: token)
            self.appVersion = URLQueryItem(name: "app_version", value: appVersion)
            self.appType = URLQueryItem(name: "app_type", value: appType)
        }
        
        func toArray() -> [URLQueryItem] {
            return [deviceId, projectId, token,appVersion,appType]
        }
    }
    
    func sendRequest(deviceId: String, projectId: String, token: String,appVersion:String, completion: @escaping (FirstStartResult?) -> Void) {
        
        let responseParser: (Data) -> FirstStartResult? = { data in
            var response: Any? = nil
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                Logger.warn(message: "exception decoding api data")
            }
            return response as? FirstStartResult
        }
        
        let queryItems = FirstLoginQueryItems(deviceId: deviceId, projectId: projectId, token: token,appVersion:appVersion, appType:"2")
        let resource = Network.buildResource(path: firstStartPath,
                                             method: .get,
                                             queryItems: queryItems.toArray(),
                                             headers: ["Accept-Encoding": "gzip"],
                                             parse: responseParser)
        
        firstLoginRequestHandler(BasePath.BindingEventsURL,
                                 resource: resource,
                                 completion: { result in
                                    completion(result)
        })
    }
    
    private func firstLoginRequestHandler(_ base: String,
                                          resource: Resource<FirstStartResult>,
                                          completion: @escaping (FirstStartResult?) -> Void) {
        Network.apiRequest(base: base,
                           resource: resource,
                           failure: { (reason, data, response) in
                            Logger.warn(message: "API request to \(resource.path) has failed with reason \(reason)")
                            completion(nil)
        }, success: { (result, response) in
            completion(result)
        })
    }
    
}
