//
//  Network.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/2/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation


struct BasePath {
    
    static var BindingEventsURL = ServerURL.bindings
    static var CollectEventsAPI = ServerURL.collection

    static func buildURL(base: String, path: String, queryItems: [URLQueryItem]?) -> URL? {
        guard let url = URL(string: base) else {
            return nil
        }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.path = path
        components?.queryItems = queryItems
        return components?.url
    }
}

enum RequestMethod: String {
    case get
    case post
}

struct Resource<A> {
    let path: String
    let method: RequestMethod
    let requestBody: Data?
    let queryItems: [URLQueryItem]?
    let headers: [String:String]
    let parse: (Data) -> A?
}

enum Reason {
    case parseError
    case noData
    case notOKStatusCode(statusCode: Int)
    case other(Error)
}

class Network {

    class func apiRequest<A>(base: String,
                          resource: Resource<A>,
                          failure: @escaping (Reason, Data?, URLResponse?) -> (),
                          success: @escaping (A, URLResponse?) -> ()) {
        guard let request = buildURLRequest(base, resource: resource) else {
            return
        }

        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) -> Void in
            guard let httpResponse = response as? HTTPURLResponse else {
                failure(.other(error!), data, response)
                return
            }
            guard httpResponse.statusCode == 200 else {
                failure(.notOKStatusCode(statusCode: httpResponse.statusCode), data, response)
                return
            }
            guard let responseData = data else {
                failure(.noData, data, response)
                return
            }
            guard let result = resource.parse(responseData) else {
                failure(.parseError, data, response)
                return
            }
//            Logger.debug(message: "Response Data:\(String(data: responseData, encoding: String.Encoding.utf8)!)")
//            Logger.debug(message: "Response URL:\(httpResponse.url!)")
//            Logger.debug(message: "Response State Code:\(httpResponse.statusCode)")
//            Logger.debug(message: "Response Header Field:\n\(httpResponse.allHeaderFields)")
//            Logger.debug(message: "Result:\(result)")
            success(result, response)
        }.resume()
    }

    private class func buildURLRequest<A>(_ base: String, resource: Resource<A>) -> URLRequest? {
        guard let url = BasePath.buildURL(base: base,
                                          path: resource.path,
                                          queryItems: resource.queryItems) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = resource.method.rawValue
        request.httpBody = resource.requestBody

        for (k, v) in resource.headers {
            request.setValue(v, forHTTPHeaderField: k)
        }
        return request as URLRequest
    }

    class func buildResource<A>(path: String,
                             method: RequestMethod,
                             requestBody: Data? = nil,
                             queryItems: [URLQueryItem]? = nil,
                             headers: [String: String],
                             parse: @escaping (Data) -> A?) -> Resource<A> {
        return Resource(path: path,
                        method: method,
                        requestBody: requestBody,
                        queryItems: queryItems,
                        headers: headers,
                        parse: parse)
    }

    class func trackIntegration(projectID: String, apiToken: String, distinct_id: String, completion: @escaping (Bool) -> ()) {
        let requestData = JSONHandler.encodeAPIData([["event_name": "Integration",
                                                      "properties": ["token": apiToken,
                                                                     "mp_lib": "Swift",
                                                                     "version": "3.0",
                                                                     "distinct_id": distinct_id]]])

        let responseParser: (Data) -> Int? = { data in
            let response = String(data: data, encoding: String.Encoding.utf8)
            if let response = response {
                return Int(response) ?? 0
            }
            return nil
        }

        if let requestData = requestData {
            let requestBody = requestData.data(using: String.Encoding.utf8)
            
            let resource = Network.buildResource(path: FlushType.events.rawValue,
                                                 method: .post,
                                                 requestBody: requestBody,
                                                 queryItems: [URLQueryItem(name: "locate",
                                                                           value: projectID)],
                                                 headers: ["Accept-Encoding": "gzip"],
                                                 parse: responseParser)

            Network.apiRequest(base: BasePath.CollectEventsAPI,
                               resource: resource,
                               failure: { (reason, data, response) in
                                Logger.debug(message: "failed to track integration")
                                completion(false)
                },
                               success: { (result, response) in
                                Logger.debug(message: "integration tracked")
                                completion(true)
                }
            )
        }
    }
}
