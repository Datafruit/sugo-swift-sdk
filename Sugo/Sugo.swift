//
//  Sugo.swift
//  Sugo
//
//  Created by Yarden Eitan on 6/1/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

/// The primary class for integrating Sugo with your app.
open class Sugo {
    
    public static var BindingsURL: String?
    public static var CollectionURL: String?
    public static var CodelessURL: String?
    public static let CURRENTCONTROLLER:String = "CurrentControllerOrUrl"
    public static var classAttributeDict:Dictionary<String, String> = [:]
    public class func registerPriorityProperties(priorityProperties: [String: Any]) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(priorityProperties, forKey: "SugoPriorityProperties")
        userDefaults.synchronize()
    }
    
    /**
     Initializes an instance of the API with the given project token.

     Returns a new Sugo instance API object. This allows you to create more than one instance
     of the API object, which is convenient if you'd like to send data to more than
     one Sugo project from a single app.

     - parameter projectID:     your project ID
     - parameter token:         your project token
     - parameter launchOptions: Optional. App delegate launchOptions
     - parameter flushInterval: Optional. Interval to run background flushing
     - parameter instanceName:  Optional. The name you want to call this instance

     - important: If you have more than one Sugo instance, it is beneficial to initialize
     the instances with an instanceName. Then they can be reached by calling getInstance with name.

     - returns: returns a Sugo instance if needed to keep throughout the project.
     You can always get the instance by calling getInstance(name)
     */

    open class func initialize(isEnable: Bool? = true,
                               projectID: String,
                               token apiToken: String,
                               launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil,
                               flushInterval: Double = 60,
                               cacheInterval: Double = 3600,
                               instanceName: String = UUID().uuidString,
                               completion: () -> Void) {
        let sugoInitRequest = SugoInitRequest()
        let semaphore = DispatchSemaphore(value: 0)
        sugoInitRequest.sendRequest(appVersion: (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)!, projectId: projectID, token: apiToken) {
            (sugoInitResult) in

            guard let sugoInitResult = sugoInitResult,
                let isSugoInitialize = sugoInitResult["isSugoInitialize"] as? Bool,
                let isHeatMapFunc = sugoInitResult["isHeatMapFunc"] as? Bool,
                let uploadLocation = sugoInitResult["uploadLocation"] as? Int else {
                    semaphore.signal()
                    return
            }
            
            let userDefaults = UserDefaults.standard
            userDefaults.set(isSugoInitialize, forKey: "isSugoInitialize")
            userDefaults.set(isHeatMapFunc, forKey: "isHeatMapFunc")
            userDefaults.set(uploadLocation, forKey: "uploadLocation")
            userDefaults.synchronize()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        let userDefaults = UserDefaults.standard
        let isSugoInitialize = userDefaults.bool(forKey: "isSugoInitialize")
        if !isSugoInitialize {
            return
        }
        SugoManager.sharedInstance.initialize(isEnable:      isEnable!,
                                              id:            projectID,
                                              token:         apiToken,
                                              launchOptions: launchOptions,
                                              flushInterval: flushInterval,
                                              cacheInterval: cacheInterval,
                                              instanceName:  instanceName)
        completion()
    }

    /**
     Gets the Sugo instance with the given name

     - parameter name: the instance name

     - returns: returns the Sugo instance
     */
    open class func getInstance(name: String) -> SugoInstance? {
        return SugoManager.sharedInstance.getInstance(name: name)
    }

    /**
     Returns the main instance that was initialized.

     If not specified explicitly, the main instance is always the last instance added

     - returns: returns the main Sugo instance
     */
    open class func mainInstance() -> SugoInstance {
        let instance = SugoManager.sharedInstance.getMainInstance()
        if instance == nil {
            fatalError("You have to call initialize(token:) before calling the main instance, " +
                "or define a new main instance if removing the main one")
        }
        
        return instance!
    }

    /**
     Sets the main instance based on the instance name

     - parameter name: the instance name
     */
    open class func setMainInstance(name: String) {
        SugoManager.sharedInstance.setMainInstance(name: name)
    }

    /**
     Removes an unneeded Sugo instance based on its name

     - parameter name: the instance name
     */
    open class func removeInstance(name: String) {
        SugoManager.sharedInstance.removeInstance(name: name)
    }
}

class SugoManager {

    static let sharedInstance = SugoManager()
    private var instances: [String: SugoInstance]
    private var mainInstance: SugoInstance?

    init() {
        instances = [String: SugoInstance]()
        Logger.addLogging(PrintLogging())
        Logger.addLogging(FileLogging(path: "sugo.log"))
    }

    func initialize(isEnable: Bool? = true,
                    id projectID: String,
                    token apiToken: String,
                    launchOptions: [UIApplicationLaunchOptionsKey : Any]?,
                    flushInterval: Double,
                    cacheInterval: Double,
                    instanceName: String) -> SugoInstance {
        let instance = SugoInstance(isEnable:       isEnable,
                                    projectID:      projectID,
                                    apiToken:       apiToken,
                                    launchOptions:  launchOptions,
                                    flushInterval:  flushInterval,
                                    cacheInterval:  cacheInterval)
        mainInstance = instance
        instances[instanceName] = instance
        
        let values = SugoDimensions.values
        instance.trackIntegration()
        instance.track(eventName: values["AppEnter"]!)
        instance.time(event: values["AppStay"]!)
        instance.cache { 
            WebViewBindings.global.isWebViewNeedInject = true;
            WebViewBindings.global.fillBindings()
        }
        return instance
    }

    func getInstance(name instanceName: String) -> SugoInstance? {
        guard let instance = instances[instanceName] else {
            Logger.warn(message: "no such instance: \(instanceName)")
            return nil
        }
        return instance
    }

    func getMainInstance() -> SugoInstance? {
        return mainInstance
    }

    func setMainInstance(name instanceName: String) {
        guard let instance = instances[instanceName] else {
            return
        }
        mainInstance = instance
    }

    func removeInstance(name instanceName: String) {
        if instances[instanceName] === mainInstance {
            mainInstance = nil
        }
        instances[instanceName] = nil
    }

}
