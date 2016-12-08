//
//  Persistence.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/2/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

struct ArchivedProperties {
    let superProperties: InternalProperties
    let timedEvents: InternalProperties
    let distinctId: String
}

class Persistence {

    enum ArchiveType: String {
        case events
        case properties
        case codelessBindings
        case variants
    }

    class func filePathWithType(_ type: ArchiveType, token: String) -> String? {
        return filePathFor(type.rawValue, token: token)
    }

    class private func filePathFor(_ archiveType: String, token: String) -> String? {
        let filename = "sugo-\(token)-\(archiveType)"
        let manager = FileManager.default

        #if os(iOS)
            let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        #else
            let url = manager.urls(for: .cachesDirectory, in: .userDomainMask).last
        #endif

        guard let urlUnwrapped = url?.appendingPathComponent(filename).path else {
            return nil
        }

        return urlUnwrapped
    }

    class func archive(eventsQueue: Queue,
                       properties: ArchivedProperties,
                       codelessBindings: Set<CodelessBinding>,
                       token: String) {
        archiveEvents(eventsQueue, token: token)
        archiveProperties(properties, token: token)
        archiveCodelessBindings(codelessBindings, token: token)
    }

    class func archiveEvents(_ eventsQueue: Queue, token: String) {
        archiveToFile(.events, object: eventsQueue, token: token)
    }

    class func archiveProperties(_ properties: ArchivedProperties, token: String) {
        var p = InternalProperties()
        p["distinctId"] = properties.distinctId
        p["superProperties"] = properties.superProperties
        p["timedEvents"] = properties.timedEvents
        archiveToFile(.properties, object: p, token: token)
    }

    class func archiveCodelessBindings(_ codelessBindings: Set<CodelessBinding>, token: String) {
        archiveToFile(.codelessBindings, object: codelessBindings, token: token)
    }

    class private func archiveToFile(_ type: ArchiveType, object: Any, token: String) {
        let filePath = filePathWithType(type, token: token)
        guard let path = filePath else {
            Logger.error(message: "bad file path, cant fetch file")
            return
        }

        if !NSKeyedArchiver.archiveRootObject(object, toFile: path) {
            Logger.error(message: "failed to archive \(type.rawValue)")
        }

    }

    class func unarchive(token: String) -> (eventsQueue: Queue,
                                            superProperties: InternalProperties,
                                            timedEvents: InternalProperties,
                                            distinctId: String,
                                            codelessBindings: Set<CodelessBinding>) {

        let eventsQueue = unarchiveEvents(token: token)
        let codelessBindings = unarchiveCodelessBindings(token: token)

        let (superProperties,
            timedEvents,
            distinctId) = unarchiveProperties(token: token)

        return (eventsQueue,
                superProperties,
                timedEvents,
                distinctId,
                codelessBindings)
    }

    class private func unarchiveWithFilePath(_ filePath: String) -> Any? {
        let unarchivedData: Any? = NSKeyedUnarchiver.unarchiveObject(withFile: filePath)
        if unarchivedData == nil {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                Logger.info(message: "Unable to remove file at path: \(filePath)")
            }
        }

        return unarchivedData
    }

    class private func unarchiveEvents(token: String) -> Queue {
        let data = unarchiveWithType(.events, token: token)
        return data as? Queue ?? []
    }

    class private func unarchiveProperties(token: String) -> (InternalProperties, InternalProperties, String) {
        let properties = unarchiveWithType(.properties, token: token) as? InternalProperties
        let superProperties =
            properties?["superProperties"] as? InternalProperties ?? InternalProperties()
        let timedEvents =
            properties?["timedEvents"] as? InternalProperties ?? InternalProperties()
        let distinctId =
            properties?["distinctId"] as? String ?? ""

        return (superProperties,
                timedEvents,
                distinctId)
    }

    class private func unarchiveCodelessBindings(token: String) -> Set<CodelessBinding> {
        let data = unarchiveWithType(.codelessBindings, token: token)
        return data as? Set<CodelessBinding> ?? Set()
    }

    class private func unarchiveWithType(_ type: ArchiveType, token: String) -> Any? {
        let filePath = filePathWithType(type, token: token)
        guard let path = filePath else {
            Logger.info(message: "bad file path, cant fetch file")
            return nil
        }

        guard let unarchivedData = unarchiveWithFilePath(path) else {
            Logger.info(message: "can't unarchive file")
            return nil
        }

        return unarchivedData
    }

}
