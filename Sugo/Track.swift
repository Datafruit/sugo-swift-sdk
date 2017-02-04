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
               eventsQueue: inout Queue,
               timedEvents: inout InternalProperties,
               superProperties: InternalProperties,
               distinctId: String,
               date: Date) {
        
        guard let key = SugoConfiguration.DimensionKey as? [String: String] else {
            return
        }
        
        var evn = eventName
        if evn == nil || evn!.characters.isEmpty {
            Logger.info(message: "sugo track called with empty event parameter. using 'mp_event'")
            evn = "sugo_event"
        }

        assertPropertyTypes(properties)
        let epochSeconds = date.timeIntervalSince1970
        let eventStartTime = timedEvents[evn!] as? Double
        var p = InternalProperties()
        let sugo = Sugo.mainInstance()
        
        if let vc = UIViewController.sugoCurrentViewController {
            p[key["PagePath"]!] = NSStringFromClass(vc.classForCoder)
            if !SugoPageInfos.global.infos.isEmpty  {
                for info in SugoPageInfos.global.infos {
                    if info["page"] == NSStringFromClass(vc.classForCoder) {
                        p[key["PageName"]!] = info["page_name"]
                    }
                }
            }
        }
        p[key["Token"]!] = apiToken
        if let eventStartTime = eventStartTime {
            timedEvents.removeValue(forKey: evn!)
            p[key["Duration"]!] = Double(String(format: "%.2f", epochSeconds - eventStartTime))
        }
        p[key["DistinctID"]!] = distinctId
        p += superProperties
        if let properties = properties {
            p += properties
        }

        var trackEvent: InternalProperties
        if let evid = eventID {
            trackEvent = [key["EventID"]!: evid, key["EventName"]!: evn!]
        } else {
            trackEvent = [key["EventName"]!: evn!]
        }
        if sugo.decideInstance.webSocketWrapper == nil
            || !sugo.decideInstance.webSocketWrapper!.connected
            || !sugo.isCodelessTesting {
            p += AutomaticProperties.properties
            p[key["Time"]!] = date
            trackEvent += p
        } else {
            p[key["Time"]!] = epochSeconds
            trackEvent["properties"] = p
        }
        eventsQueue.append(trackEvent)

        if eventsQueue.count > QueueConstants.queueSize {
            eventsQueue.remove(at: 0)
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
