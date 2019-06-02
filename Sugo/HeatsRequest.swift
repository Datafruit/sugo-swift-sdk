//
//  HeatsRequest.swift
//  Sugo
//
//  Created by Zack on 8/5/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation

class HeatsRequest: Network {
    
    typealias HeatsResult = [String: Any]
    let heatsPath = "/api/sdk/heat"
    
    struct HeatsQueryItems {
        let version: URLQueryItem
        let lib: URLQueryItem
        let token: URLQueryItem
        let secretKey :URLQueryItem
        
        init(token: String, secretKey: String) {
            let infoDict = Bundle.main.infoDictionary
            if let infoDict = infoDict,
                let version = infoDict["CFBundleShortVersionString"] {
                self.version = URLQueryItem(name: "app_version",
                                            value: "\(version)")
            } else {
                self.version = URLQueryItem(name: "app_version",
                                            value: "1.0.0")
            }
            self.lib = URLQueryItem(name: "lib", value: "iphone")
            self.token = URLQueryItem(name: "token", value: token)
            self.secretKey = URLQueryItem(name: "sKey", value: secretKey)
        }
        
        func toArray() -> [URLQueryItem] {
            return [version, lib, token, secretKey]
        }
    }
    
    func sendRequest(token: String,
                     secretKey: String,
                     completion: @escaping (HeatsResult?) -> Void) {
        
        let responseParser: (Data) -> HeatsResult? = { data in
            var response: Any? = nil
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
                Logger.warn(message: "exception decoding api data")
            }
            return response as? HeatsResult
        }
        
        let queryItems = HeatsQueryItems(token: token, secretKey: secretKey)
        let resource = Network.buildResource(path: heatsPath,
                                             method: .get,
                                             queryItems: queryItems.toArray(),
                                             headers: ["Accept-Encoding": "gzip"],
                                             parse: responseParser)
        
        heatsRequestHandler(BasePath.BindingEventsURL,
                             resource: resource,
                             completion: { result in
                                completion(result)
        })
    }
    
    private func heatsRequestHandler(_ base: String,
                                      resource: Resource<HeatsResult>,
                                      completion: @escaping (HeatsResult?) -> Void) {
        Network.apiRequest(base: base, resource: resource,
                           failure: { (reason, data, response) in
                            Logger.warn(message: "API request to \(resource.path) has failed with reason \(reason)")
                            completion(nil)
        }, success: { (result, response) in
            completion(result)
        })
    }
    
}
