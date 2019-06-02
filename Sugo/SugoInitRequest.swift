//
//  SugoInitRequest.swift
//  Sugo
//
//  Created by 陈宇艺 on 2019/5/23.
//  Copyright © 2019 sugo. All rights reserved.
//

import Foundation

class SugoInitRequest : Network {
    
    typealias SugoInitResult = [String: Any]
    let firstLoginPath = "/api/sdk/decide-config"
    
    struct FirstLoginQueryItems {
        
        let appVersion: URLQueryItem
        let projectId: URLQueryItem
        let tokenId: URLQueryItem
        
        init(appVersion: String, projectId: String, token: String) {
            self.appVersion = URLQueryItem(name: "appVersion", value: appVersion)
            self.projectId = URLQueryItem(name: "projectId", value: projectId)
            self.tokenId = URLQueryItem(name: "tokenId", value: token)
        }
        
        func toArray() -> [URLQueryItem] {
            return [appVersion, projectId, tokenId]
        }
    }
    
    func sendRequest(appVersion: String, projectId: String, token: String, completion: @escaping (SugoInitResult?) -> Void) {
        
        let responseParser: (Data) -> SugoInitResult? = { data in
            var response: Any? = nil
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
                Logger.warn(message: "exception decoding api data")
            }
            return response as? SugoInitResult
        }
        
        let queryItems = FirstLoginQueryItems(appVersion: appVersion, projectId: projectId, token: token)
        let resource = Network.buildResource(path: firstLoginPath,
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
                                          resource: Resource<SugoInitResult>,
                                          completion: @escaping (SugoInitResult?) -> Void) {
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
