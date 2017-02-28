//
//  Track.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/3/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

class Track {
    let apiToken: String

    init(apiToken: String) {
        self.apiToken = apiToken
    }
    
    func track(eventID: String? = nil,
               eventName: String?,
               properties: Properties? = nil,
               date: Date,
               sugo: SugoInstance) {
        
        let keys = SugoDimensions.keys
        
        var evn = eventName
        if evn == nil || evn!.characters.isEmpty {
            Logger.info(message: "sugo track called with empty event parameter. using 'mp_event'")
            evn = "sugo_event"
        }
        
        assertPropertyTypes(properties)
        let epochSeconds = date.timeIntervalSince1970
        let eventStartTime = sugo.timedEvents[evn!] as? Double
        var p = InternalProperties()
        
        p[keys["Token"]!] = apiToken
        p[keys["SessionID"]!] = sugo.sessionID
        if let eventStartTime = eventStartTime {
            sugo.timedEvents.removeValue(forKey: evn!)
            p[keys["Duration"]!] = Double(String(format: "%.2f", epochSeconds - eventStartTime))
        }
        p[keys["DeviceID"]!] = sugo.deviceId
        p[keys["DistinctID"]!] = sugo.distinctId
        p += sugo.superProperties
        if let properties = properties {
            p += properties
        }
        
        var trackEvent: InternalProperties
        if let evid = eventID {
            trackEvent = [keys["EventID"]!: evid, keys["EventName"]!: evn!]
        } else {
            trackEvent = [keys["EventName"]!: evn!]
        }
        if sugo.decideInstance.webSocketWrapper == nil
            || !sugo.decideInstance.webSocketWrapper!.connected {
            p += AutomaticProperties.properties
            p[keys["EventTime"]!] = date
            trackEvent += p
        } else {
            p[keys["EventTime"]!] = String(format: "%.0f", epochSeconds * 1000)
            trackEvent["properties"] = p
        }
        sugo.eventsQueue.append(trackEvent)
        
        if sugo.eventsQueue.count > QueueConstants.queueSize {
            sugo.eventsQueue.remove(at: 0)
        }
    }

    func registerSuperProperties(_ properties: Properties, superProperties: inout InternalProperties) {
        assertPropertyTypes(properties)
        superProperties += properties
    }

    func registerSuperPropertiesOnce(_ properties: Properties,
                                     superProperties: inout InternalProperties,
                                     defaultValue: SugoType?) {
        assertPropertyTypes(properties)
            _ = properties.map() {
                let val = superProperties[$0.key]
                if val == nil ||
                    (defaultValue != nil && (val as? NSObject == defaultValue as? NSObject)) {
                    superProperties[$0.key] = $0.value
                }
            }
    }

    func unregisterSuperProperty(_ propertyName: String, superProperties: inout InternalProperties) {
        superProperties.removeValue(forKey: propertyName)
    }

    func clearSuperProperties(_ superProperties: inout InternalProperties) {
        superProperties.removeAll()
    }

    func time(event: String?, timedEvents: inout InternalProperties, startTime: Double) {
        guard let event = event, !event.isEmpty else {
            Logger.error(message: "sugo cannot time an empty event")
            return
        }
        timedEvents[event] = startTime
    }

    func clearTimedEvents(_ timedEvents: inout InternalProperties) {
        timedEvents.removeAll()
    }
}
