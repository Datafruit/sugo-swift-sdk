//
//  Flush.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/3/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

protocol FlushDelegate {
    func flush(completion: (() -> Void)?)
    #if os(iOS)
    func updateNetworkActivityIndicator(_ on: Bool)
    #endif
}

class Flush: AppLifecycle {

    var timer: Timer?
    var delegate: FlushDelegate?
    var useIPAddressForGeoLocation = true
    var flushRequest = FlushRequest()
    var flushOnBackground = true
    var _flushInterval = 0.0
    var flushInterval: Double {
        set {
            objc_sync_enter(self)
            _flushInterval = newValue
            objc_sync_exit(self)

            delegate?.flush(completion: nil)
            startFlushTimer()
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }

            return _flushInterval
        }
    }

    func flushEventsQueue(_ eventsQueue: inout Queue) {
        flushQueue(type: .events, queue: &eventsQueue)
    }

    func flushQueue(type: FlushType, queue: inout Queue) {
        if flushRequest.requestNotAllowed() {
            return
        }
        flushQueueInBatches(&queue, type: type)
    }

    func startFlushTimer() {
        stopFlushTimer()
        if flushInterval > 0 {
            DispatchQueue.main.async() {
                self.timer = Timer.scheduledTimer(timeInterval: self.flushInterval,
                                                  target: self,
                                                  selector: #selector(self.flushSelector),
                                                  userInfo: nil,
                                                  repeats: true)
            }
        }
    }

    @objc func flushSelector() {
        delegate?.flush(completion: nil)
    }

    func stopFlushTimer() {
        if let timer = timer {
            DispatchQueue.main.async() {
                timer.invalidate()
                self.timer = nil
            }
        }
    }

    func flushQueueInBatches(_ queue: inout Queue, type: FlushType) {
        while !queue.isEmpty {
            var shouldContinue = false
            let batchSize = min(queue.count, APIConstants.batchSize)
            let range = 0..<batchSize
            let batch = Array(queue[range])
            let requestData = SugoEventsSerializer.encode(batch: batch)
            if let requestData = requestData {
                let semaphore = DispatchSemaphore(value: 0)
                #if os(iOS)
                    delegate?.updateNetworkActivityIndicator(true)
                #endif
                var shadowQueue = queue
                flushRequest.sendRequest(requestData,
                                         type: type,
                                         useIP: useIPAddressForGeoLocation,
                                         completion: { success in
                                            #if os(iOS)
                                                self.delegate?.updateNetworkActivityIndicator(false)
                                            #endif
                                            if success {
                                                shadowQueue.removeSubrange(range)
                                            }
                                            shouldContinue = success
                                            semaphore.signal()
                })
                _ = semaphore.wait(timeout: DispatchTime.distantFuture)
                queue = shadowQueue
            }

            if !shouldContinue {
                break
            }
        }
    }
    
    func flushQueueViaWebSocket(connection: WebSocketWrapper, queue: Queue) {
        let events: [String: AnyObject] = ["events": queue as AnyObject]
        let webSocketMessage = TrackMessage(payload: events)
        connection.send(message: webSocketMessage)
        Logger.debug(message: "via web socket: \(webSocketMessage?.payload)")
    }

    // MARK: - Lifecycle
    func applicationDidBecomeActive() {
        startFlushTimer()
    }

    func applicationWillResignActive() {
        stopFlushTimer()
    }

}
