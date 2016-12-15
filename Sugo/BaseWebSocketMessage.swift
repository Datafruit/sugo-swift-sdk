//
//  BaseWebSocketMessage.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/26/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

protocol WebSocketMessageProtocol: CustomDebugStringConvertible {
    var type: String { get set }
    var payload: [String: AnyObject] { get set }
    func JSONData() -> Data?
    func responseCommand(connection: WebSocketWrapper) -> Operation?

}

class BaseWebSocketMessage: WebSocketMessageProtocol {

    var type: String = ""
    var payload: [String: AnyObject]

    var debugDescription: String {
        return "message type: \(type)"
    }

    init(type: String, payload: [String: AnyObject] = [:]) {
        self.type = type
        self.payload = payload
    }

    func responseCommand(connection: WebSocketWrapper) -> Operation? {
        return nil
    }

    func JSONData() -> Data? {
        let jsonObject = ["type": type, "payload": payload] as [String : Any]
        var data: Data? = nil
        data = JSONHandler.serializeJSONObject(jsonObject)
        return data
    }

}
