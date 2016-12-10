//
//  SugoInstance.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/2/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

/**
 *  Delegate protocol for controlling the Sugo API's network behavior.
 */
public protocol SugoDelegate {
    /**
     Asks the delegate if data should be uploaded to the server.

     - parameter sugo: The sugo instance

     - returns: return true to upload now or false to defer until later
     */
    func sugoWillFlush(_ sugo: SugoInstance) -> Bool
}

public typealias Properties = [String: SugoType]
typealias InternalProperties = [String: Any]
typealias Queue = [InternalProperties]

protocol AppLifecycle {
    func applicationDidBecomeActive()
    func applicationWillResignActive()
}

/// The class that represents the Sugo Instance
open class SugoInstance: CustomDebugStringConvertible, FlushDelegate {

    /// The a SugoDelegate object that gives control over Sugo network activity.
    open var delegate: SugoDelegate?

    /// distinctId string that uniquely identifies the current user.
    open var distinctId = ""
    
    /// urlSchemes url that gives key to device_info_response
    open var urlSchemesKeyValue: String?

    /// Controls whether to show spinning network activity indicator when flushing
    /// data to the Sugo servers. Defaults to true.
    open var showNetworkActivityIndicator = true

    /// Flush timer's interval.
    /// Setting a flush interval of 0 will turn off the flush timer.
    open var flushInterval: Double {
        set {
            flushInstance.flushInterval = newValue
        }
        get {
            return flushInstance.flushInterval
        }
    }

    /// Control whether the library should flush data to Sugo when the app
    /// enters the background. Defaults to true.
    open var flushOnBackground: Bool {
        set {
            flushInstance.flushOnBackground = newValue
        }
        get {
            return flushInstance.flushOnBackground
        }
    }

    /// Controls whether to automatically send the client IP Address as part of
    /// event tracking. With an IP address, the Sugo Dashboard will show you the users' city.
    /// Defaults to true.
    open var useIPAddressForGeoLocation: Bool {
        set {
            flushInstance.useIPAddressForGeoLocation = newValue
        }
        get {
            return flushInstance.useIPAddressForGeoLocation
        }
    }

    /// The base URL used for Sugo API requests.
    /// Useful if you need to proxy Sugo requests. Defaults to
    /// https://sugo.io
    open var serverURL: String {
        set {
            BasePath.BindingEventsURL = newValue
        }
        get {
            return BasePath.BindingEventsURL
        }
    }

    open var debugDescription: String {
        return "Sugo(\n"
        + "    Token: \(apiToken),\n"
        + "    Events Queue Count: \(eventsQueue.count),\n"
        + "    Distinct Id: \(distinctId)\n"
        + ")"
    }

    /// This allows enabling or disabling of all Sugo logs at run time.
    /// - Note: All logging is disabled by default. Usually, this is only required
    ///         if you are running in to issues with the SDK and you need support.
    open var loggingEnabled: Bool = false {
        didSet {
            if loggingEnabled {
                Logger.enableLevel(.debug)
                Logger.enableLevel(.info)
                Logger.enableLevel(.warning)
                Logger.enableLevel(.error)

                Logger.info(message: "Logging Enabled")
            } else {
                Logger.info(message: "Logging Disabled")

                Logger.disableLevel(.debug)
                Logger.disableLevel(.info)
                Logger.disableLevel(.warning)
                Logger.disableLevel(.error)
            }
        }
    }

    #if os(iOS)
    /// Controls whether to enable the visual editor for codeless on sugo.io
    /// You will be unable to edit codeless events with this disabled, however previously
    /// created codeless events will still be delivered.
    open var enableVisualEditorForCodeless: Bool {
        set {
            decideInstance.enableVisualEditorForCodeless = newValue
            if !newValue {
                decideInstance.webSocketWrapper?.close()
            }
        }
        get {
            return decideInstance.enableVisualEditorForCodeless
        }
    }

    #endif

    var projectID = ""
    var apiToken = ""
    var superProperties = InternalProperties()
    var eventsQueue = Queue()
    var timedEvents = InternalProperties()
    var serialQueue: DispatchQueue!
    var taskId = UIBackgroundTaskInvalid
    let flushInstance = Flush()
    let trackInstance: Track
    let decideInstance = Decide()

    init(projectID: String?,
         apiToken: String?,
         launchOptions: [UIApplicationLaunchOptionsKey : Any]?,
         flushInterval: Double) {
        
        if let projectID = projectID, !projectID.isEmpty {
            self.projectID = projectID
        }
        
        if let apiToken = apiToken, !apiToken.isEmpty {
            self.apiToken = apiToken
        }

        trackInstance = Track(apiToken: self.apiToken)
        flushInstance.delegate = self
        let label = "io.sugo.\(self.apiToken)"
        serialQueue = DispatchQueue(label: label)
        distinctId = defaultDistinctId()
        flushInstance._flushInterval = flushInterval
        setupListeners()
        unarchive()

        #if os(iOS)
            executeCachedCodelessBindings()
        #endif
    }

    private func setupListeners() {
        let notificationCenter = NotificationCenter.default
        trackIntegration()
        #if os(iOS)
            setCurrentRadio()
            notificationCenter.addObserver(self,
                                           selector: #selector(setCurrentRadio),
                                           name: .CTRadioAccessTechnologyDidChange,
                                           object: nil)
        #endif
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillTerminate(_:)),
                                       name: .UIApplicationWillTerminate,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillResignActive(_:)),
                                       name: .UIApplicationWillResignActive,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidBecomeActive(_:)),
                                       name: .UIApplicationDidBecomeActive,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidEnterBackground(_:)),
                                       name: .UIApplicationDidEnterBackground,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillEnterForeground(_:)),
                                       name: .UIApplicationWillEnterForeground,
                                       object: nil)
        #if os(iOS)
        initializeGestureRecognizer()
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        flushInstance.applicationDidBecomeActive()
        #if os(iOS)
            checkDecide { decideResponse in
                if let decideResponse = decideResponse {
                    DispatchQueue.main.sync {
                        for binding in decideResponse.newCodelessBindings {
                            binding.execute()
                        }
                    }
                }
            }
        #endif
    }

    @objc private func applicationWillResignActive(_ notification: Notification) {
        flushInstance.applicationWillResignActive()
    }

    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        let sharedApplication = UIApplication.shared

        taskId = sharedApplication.beginBackgroundTask() {
            self.taskId = UIBackgroundTaskInvalid
        }

        if flushOnBackground {
            flush()
        }

        serialQueue.async() {
            self.archive()
            self.decideInstance.decideFetched = false

            if self.taskId != UIBackgroundTaskInvalid {
                sharedApplication.endBackgroundTask(self.taskId)
                self.taskId = UIBackgroundTaskInvalid
            }
        }
    }

    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        serialQueue.async() {
            if self.taskId != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(self.taskId)
                self.taskId = UIBackgroundTaskInvalid
                #if os(iOS)
                    self.updateNetworkActivityIndicator(false)
                #endif
            }
        }
    }

    @objc private func applicationWillTerminate(_ notification: Notification) {
        serialQueue.async() {
            self.archive()
        }
    }

    func defaultDistinctId() -> String {
        var distinctId: String? = IFA()
        if distinctId == nil && NSClassFromString("UIDevice") != nil {
            distinctId = UIDevice.current.identifierForVendor?.uuidString
        }
        guard let distId = distinctId else {
            return UUID().uuidString
        }
        return distId
    }

    func IFA() -> String? {
        var ifa: String? = nil
        if let ASIdentifierManagerClass = NSClassFromString("ASIdentifierManager") {
            let sharedManagerSelector = NSSelectorFromString("sharedManager")
            if let sharedManagerIMP = ASIdentifierManagerClass.method(for: sharedManagerSelector) {
                typealias sharedManagerFunc = @convention(c) (AnyObject, Selector) -> AnyObject!
                let curriedImplementation = unsafeBitCast(sharedManagerIMP, to: sharedManagerFunc.self)
                if let sharedManager = curriedImplementation(ASIdentifierManagerClass.self, sharedManagerSelector) {
                    let advertisingTrackingEnabledSelector = NSSelectorFromString("isAdvertisingTrackingEnabled")
                    if let isTrackingEnabledIMP = sharedManager.method(for: advertisingTrackingEnabledSelector) {
                        typealias isTrackingEnabledFunc = @convention(c) (AnyObject, Selector) -> Bool
                        let curriedImplementation2 = unsafeBitCast(isTrackingEnabledIMP, to: isTrackingEnabledFunc.self)
                        let isTrackingEnabled = curriedImplementation2(self, advertisingTrackingEnabledSelector)
                        if isTrackingEnabled {
                            let advertisingIdentifierSelector = NSSelectorFromString("advertisingIdentifier")
                            if let advertisingIdentifierIMP = sharedManager.method(for: advertisingIdentifierSelector) {
                                typealias adIdentifierFunc = @convention(c) (AnyObject, Selector) -> NSUUID
                                let curriedImplementation3 = unsafeBitCast(advertisingIdentifierIMP, to: adIdentifierFunc.self)
                                ifa = curriedImplementation3(self, advertisingIdentifierSelector).uuidString
                            }
                        }
                    }
                }
            }
        }
        return ifa
    }

    #if os(iOS)
    func updateNetworkActivityIndicator(_ on: Bool) {
        if showNetworkActivityIndicator {
            UIApplication.shared.isNetworkActivityIndicatorVisible = on
        }
    }

    @objc func setCurrentRadio() {
        let currentRadio = AutomaticProperties.getCurrentRadio()
        serialQueue.async() {
            AutomaticProperties.properties["$radio"] = currentRadio
        }
    }

    func initializeGestureRecognizer() {
        DispatchQueue.main.async {
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.connectGestureRecognized(gesture:)))
            gestureRecognizer.minimumPressDuration = 3
            gestureRecognizer.cancelsTouchesInView = false
            #if (arch(i386) || arch(x86_64)) && os(iOS)
                gestureRecognizer.numberOfTouchesRequired = 2
            #else
                gestureRecognizer.numberOfTouchesRequired = 4
            #endif
            UIApplication.shared.keyWindow?.addGestureRecognizer(gestureRecognizer)
        }
    }

    @objc func connectGestureRecognized(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began && enableVisualEditorForCodeless {
            connectToWebSocket()
        }
    }
    #endif

}

extension SugoInstance {
    // MARK: - Identity

    /**
     Sets the distinct ID of the current user.

     Sugo uses the IFV String (`UIDevice.current().identifierForVendor`)
     as the default distinct ID. This ID will identify a user across all apps by the same
     vendor, but cannot be used to link the same user across apps from different
     vendors. If we are unable to get the IFV, we will fall back to generating a
     random persistent UUID

     For tracking events, you do not need to call `identify:` if you
     want to use the default. However,
     **Sugo People always requires an explicit call to `identify:`.**
     If calls are made to
     `set:`, `increment` or other `People`
     methods prior to calling `identify:`, then they are queued up and
     flushed once `identify:` is called.

     If you'd like to use the default distinct ID for Sugo People as well
     (recommended), call `identify:` using the current distinct ID:
     `sugoInstance.identify(sugoInstance.distinctId)`.

     - parameter distinctId: string that uniquely identifies the current user
     */
    open func identify(distinctId: String) {
        if distinctId.isEmpty {
            Logger.error(message: "\(self) cannot identify blank distinct id")
            return
        }

        serialQueue.async() {
            self.distinctId = distinctId
            self.archiveProperties()
        }
    }

    /**
     Creates a distinctId alias from alias to the current id.

     This method is used to map an identifier called an alias to the existing Sugo
     distinct id. This causes all events requests sent with the alias to be
     mapped back to the original distinct id. The recommended usage pattern is to call
     both createAlias: and identify: when the user signs up, and only identify: (with
     their new user ID) when they log in. This will keep your signup funnels working
     correctly.

     This makes the current id and 'Alias' interchangeable distinct ids.
     Sugo.
     sugoInstance.createAlias("Alias", sugoInstance.distinctId)

     - precondition: You must call identify if you haven't already
     (e.g. when your app launches)

     - parameter alias:      the new distinct id that should represent the original
     - parameter distinctId: the old distinct id that alias will be mapped to
     */
    open func createAlias(_ alias: String, distinctId: String) {
        if distinctId.isEmpty {
            Logger.error(message: "\(self) cannot identify blank distinct id")
            return
        }

        if alias.isEmpty {
            Logger.error(message: "\(self) create alias called with empty alias")
            return
        }

        let properties = ["distinct_id": distinctId, "alias": alias]
        track(eventName: "$create_alias",
              properties: properties)
        flush()
    }

    /**
     Clears all stored properties including the distinct Id.
     Useful if your app's user logs out.
     */
    open func reset() {
        serialQueue.async() {
            self.distinctId = self.defaultDistinctId()
            self.superProperties = InternalProperties()
            self.eventsQueue = Queue()
            self.timedEvents = InternalProperties()
            self.decideInstance.decideFetched = false
            self.decideInstance.codelessInstance.codelessBindings = Set()
            self.archive()
        }
    }
}

extension SugoInstance {
    // MARK: - Persistence

    /**
     Writes current project info including the distinct Id, super properties,
     and pending event and People record queues to disk.

     This state will be recovered when the app is launched again if the Sugo
     library is initialized with the same project token.
     The library listens for app state changes and handles
     persisting data as needed.

     - important: You do not need to call this method.**
     */
    open func archive() {
        let properties = ArchivedProperties(superProperties: superProperties,
                                            timedEvents: timedEvents,
                                            distinctId: distinctId)
        Persistence.archive(eventsQueue: eventsQueue,
                            properties: properties,
                            codelessBindings: decideInstance.codelessInstance.codelessBindings,
                            token: apiToken)
    }

    func unarchive() {
        (eventsQueue,
         superProperties,
         timedEvents,
         distinctId,
         decideInstance.codelessInstance.codelessBindings) = Persistence.unarchive(token: apiToken)

        if distinctId == "" {
            distinctId = defaultDistinctId()
        }
    }

    func archiveProperties() {
        let properties = ArchivedProperties(superProperties: superProperties,
                                            timedEvents: timedEvents,
                                            distinctId: distinctId)
        Persistence.archiveProperties(properties, token: apiToken)
    }

    func trackIntegration() {
        let defaultsKey = "trackedKey"
        if !UserDefaults.standard.bool(forKey: defaultsKey) {
            serialQueue.async() {
                Network.trackIntegration(apiToken: self.apiToken) {
                    (success) in
                    if success {
                        UserDefaults.standard.set(true, forKey: defaultsKey)
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
    }
}

extension SugoInstance {
    // MARK: - Flush

    /**
     Uploads queued data to the Sugo server.

     By default, queued data is flushed to the Sugo servers every minute (the
     default for `flushInterval`), and on background (since
     `flushOnBackground` is on by default). You only need to call this
     method manually if you want to force a flush at a particular moment.

     - parameter completion: an optional completion handler for when the flush has completed.
     */
    open func flush(completion: (() -> Void)? = nil) {
        
        if self.decideInstance.webSocketWrapper == nil
            || !self.decideInstance.webSocketWrapper!.connected {
            serialQueue.async() {
                if let shouldFlush = self.delegate?.sugoWillFlush(self), !shouldFlush {
                    return
                }
                self.flushInstance.flushEventsQueue(&self.eventsQueue)
                self.archive()
                if let completion = completion {
                    DispatchQueue.main.async(execute: completion)
                }
            }
        }
    }
}

extension SugoInstance {
    // MARK: - Track

    /**
     Tracks an event with properties.
     Properties are optional and can be added only if needed.

     Properties will allow you to segment your events in your Sugo reports.
     Property keys must be String objects and the supported value types need to conform to SugoType.
     SugoType can be either String, Int, UInt, Double, Float, Bool, [SugoType], [String: SugoType], Date, URL, or NSNull.
     If the event is being timed, the timer will stop and be added as a property.

     - parameter event:      event name
     - parameter properties: properties dictionary
     */
    open func track(eventID: String? = nil, eventName: String?, properties: Properties? = nil) {
        let epochInterval = Date().timeIntervalSince1970
        serialQueue.async() {
            
            self.trackInstance.track(eventID: eventID,
                                     eventName: eventName,
                                     properties: properties,
                                     eventsQueue: &self.eventsQueue,
                                     timedEvents: &self.timedEvents,
                                     superProperties: self.superProperties,
                                     distinctId: self.distinctId,
                                     epochInterval: epochInterval)
            
            if self.decideInstance.webSocketWrapper != nil
                && self.decideInstance.webSocketWrapper!.connected {
                
                if !self.eventsQueue.isEmpty {
                    self.flushInstance.flushQueueViaWebSocket(connection: self.decideInstance.webSocketWrapper!,
                                                              queue: self.eventsQueue)
                    self.eventsQueue.removeAll()
                }
            }
            
            Persistence.archiveEvents(self.eventsQueue, token: self.apiToken)
        }
    }

    /**
     Starts a timer that will be stopped and added as a property when a
     corresponding event is tracked.

     This method is intended to be used in advance of events that have
     a duration. For example, if a developer were to track an "Image Upload" event
     she might want to also know how long the upload took. Calling this method
     before the upload code would implicitly cause the `track`
     call to record its duration.

     - precondition:
     // begin timing the image upload:
     sugoInstance.time(event:"Image Upload")
     // upload the image:
     self.uploadImageWithSuccessHandler() { _ in
     // track the event
     sugoInstance.track("Image Upload")
     }

     - parameter event: the event name to be timed

     */
    open func time(event: String) {
        let startTime = Date().timeIntervalSince1970
        serialQueue.async() {
            self.trackInstance.time(event: event, timedEvents: &self.timedEvents, startTime: startTime)
        }
    }

    /**
     Clears all current event timers.
     */
    open func clearTimedEvents() {
        serialQueue.async() {
            self.trackInstance.clearTimedEvents(&self.timedEvents)
        }
    }

    /**
     Returns the currently set super properties.

     - returns: the current super properties
     */
    open func currentSuperProperties() -> [String: Any] {
        return superProperties
    }

    /**
     Clears all currently set super properties.
     */
    open func clearSuperProperties() {
        dispatchAndTrack() {
            self.trackInstance.clearSuperProperties(&self.superProperties)
        }
    }

    /**
     Registers super properties, overwriting ones that have already been set.

     Super properties, once registered, are automatically sent as properties for
     all event tracking calls. They save you having to maintain and add a common
     set of properties to your events.
     Property keys must be String objects and the supported value types need to conform to SugoType.
     SugoType can be either String, Int, UInt, Double, Float, Bool, [SugoType], [String: SugoType], Date, URL, or NSNull.

     - parameter properties: properties dictionary
     */
    open func registerSuperProperties(_ properties: Properties) {
        dispatchAndTrack() {
            self.trackInstance.registerSuperProperties(properties,
                                                       superProperties: &self.superProperties)
        }
    }

    /**
     Registers super properties without overwriting ones that have already been set,
     unless the existing value is equal to defaultValue. defaultValue is optional.

     Property keys must be String objects and the supported value types need to conform to SugoType.
     SugoType can be either String, Int, UInt, Double, Float, Bool, [SugoType], [String: SugoType], Date, URL, or NSNull.

     - parameter properties:   properties dictionary
     - parameter defaultValue: Optional. overwrite existing properties that have this value
     */
    open func registerSuperPropertiesOnce(_ properties: Properties,
                                            defaultValue: SugoType? = nil) {
        dispatchAndTrack() {
            self.trackInstance.registerSuperPropertiesOnce(properties,
                                                           superProperties: &self.superProperties,
                                                           defaultValue: defaultValue)
        }
    }

    /**
     Removes a previously registered super property.

     As an alternative to clearing all properties, unregistering specific super
     properties prevents them from being recorded on future events. This operation
     does not affect the value of other super properties. Any property name that is
     not registered is ignored.
     Note that after removing a super property, events will show the attribute as
     having the value `undefined` in Sugo until a new value is
     registered.

     - parameter propertyName: array of property name strings to remove
     */
    open func unregisterSuperProperty(_ propertyName: String) {
        dispatchAndTrack() {
            self.trackInstance.unregisterSuperProperty(propertyName,
                                                       superProperties: &self.superProperties)
        }
    }

    func dispatchAndTrack(closure: @escaping () -> Void) {
        serialQueue.async() {
            closure()
            self.archiveProperties()
        }
    }
}

#if os(iOS)
extension SugoInstance {

    // MARK: - Decide
    func checkDecide(forceFetch: Bool = false, completion: @escaping ((_ response: DecideResponse?) -> Void)) {
        if self.distinctId.isEmpty {
            Logger.info(message: "Can't fetch from Decide without identifying first")
            return
        }
        serialQueue.async {
            self.decideInstance.checkDecide(forceFetch: forceFetch,
                                            distinctId: self.distinctId,
                                            token: self.apiToken,
                                            completion: completion)
        }
    }

    // MARK: - WebSocket
    func connectToWebSocket() {
        decideInstance.connectToWebSocket(token: apiToken, sugoInstance: self)
    }

    // MARK: - Codeless
    func executeCachedCodelessBindings() {
        for binding in decideInstance.codelessInstance.codelessBindings {
            binding.execute()
        }
    }
}
#endif


extension SugoInstance {
    
    open func handle(url: URL) -> Bool {
        
        if let urlKeyValue = url.query?.components(separatedBy: "=").last {
            self.urlSchemesKeyValue = urlKeyValue
            if self.enableVisualEditorForCodeless {
                connectToWebSocket()
                return true
            }
        }
        return false
    }
}







