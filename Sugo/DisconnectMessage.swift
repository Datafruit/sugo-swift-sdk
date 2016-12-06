//
//  DisconnectMessage.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/26/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

class DisconnectMessage: BaseWebSocketMessage {

    init() {
        super.init(type: MessageType.disconnect.rawValue)
    }

    override func responseCommand(connection: WebSocketWrapper) -> Operation? {
        let operation = BlockOperation { [weak connection] in
            guard let connection = connection else {
                return
            }

            connection.connected = false
            connection.close()
        }
        return operation
    }

}
