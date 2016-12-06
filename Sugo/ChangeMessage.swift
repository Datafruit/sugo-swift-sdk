//
//  ChangeMessage.swift
//  Sugo
//
//  Created by Yarden Eitan on 10/4/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

class ChangeRequest: BaseWebSocketMessage {

    init?(payload: [String: AnyObject]?) {
        guard let payload = payload else {
            return nil
        }
        super.init(type: MessageType.changeRequest.rawValue, payload: payload)
    }

    override func responseCommand(connection: WebSocketWrapper) -> Operation? {
        let operation = BlockOperation { [weak connection] in
            guard let connection = connection else {
                return
            }

            let response = ChangeResponse()
            response.status = "OK"
            connection.send(message: response)
        }
        return operation
    }
}

class ChangeResponse: BaseWebSocketMessage {

    var status: String {
        get {
            return payload["status"] as! String
        }
        set {
            payload["status"] = newValue as AnyObject
        }
    }

    init() {
        super.init(type: MessageType.changeResponse.rawValue)
    }
}
