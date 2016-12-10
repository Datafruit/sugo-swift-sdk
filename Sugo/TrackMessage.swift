//
//  TrackMessage.swift
//  Sugo
//
//  Created by Zack on 9/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

import Foundation

class TrackMessage: BaseWebSocketMessage {
    
    init?(payload: [String: AnyObject]?) {
        guard let payload = payload else {
            return nil
        }
        super.init(type: MessageType.trackMessage.rawValue, payload: payload)
    }
    
}









