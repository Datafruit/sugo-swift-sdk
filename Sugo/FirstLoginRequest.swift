//
//  FirstLoginRequest.swift
//  Sugo
//
//  Created by lzackx on 2017/11/14.
//  Copyright © 2017年 sugo. All rights reserved.
//

import Foundation

class FirstLoginRequest: Network {
    
    typealias FirstLoginResult = [String: Any]
    let firstLoginPath = "/api/sdk/get-first-login-time"
    
    struct FirstLoginQueryItems {
        
        let id: URLQueryItem
        let projectId: URLQueryItem
        let token: URLQueryItem

        init(id: String, projectId: String, token: String) {
            
            self.id = URLQueryItem(name: "userId", value: id)
            self.projectId = URLQueryItem(name: "projectId", value: projectId)
            self.token = URLQueryItem(name: "token", value: token)
        }
        
        func toArray() -> [URLQueryItem] {
            return [id, projectId, token]
        }
    }
    
    func sendRequest(id: String, projectId: String, token: String, completion: @escaping (FirstLoginResult?) -> Void) {
        
        let responseParser: (Data) -> FirstLoginResult? = { data in
            var response: Any? = nil
            do {
                response = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
                Logger.warn(message: "exception decoding api data")
            }
            return response as? FirstLoginResult
        }
        
        let queryItems = FirstLoginQueryItems(id: id, projectId: projectId, token: token)
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
                                     resource: Resource<FirstLoginResult>,
                                     completion: @escaping (FirstLoginResult?) -> Void) {
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
