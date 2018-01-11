//
//  ApplicationStateSerializer.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/29/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

class ApplicationStateSerializer {

    let serializer: ObjectSerializer
    let application: UIApplication

    init(application: UIApplication, configuration: ObjectSerializerConfig, objectIdentityProvider: ObjectIdentityProvider) {
        self.application = application
        self.serializer = ObjectSerializer(configuration: configuration, objectIdentityProvider: objectIdentityProvider)
    }

    func getScreenshotForKeyWindow() -> UIImage? {
        var image: UIImage? = nil
        
        if let window = application.keyWindow, !window.frame.equalTo(CGRect.zero) {
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, true, 1)
            if !window.drawHierarchy(in: window.bounds, afterScreenUpdates: false) {
                Logger.error(message: "Unable to get a screenshot for window at index \(index)")
            }
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
    
    func getScreenshotForWindow(at index: Int) -> UIImage? {
        var image: UIImage? = nil

        if let window = getWindow(at: index), !window.frame.equalTo(CGRect.zero) {
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, true, 1)
            if !window.drawHierarchy(in: window.bounds, afterScreenUpdates: false) {
                Logger.error(message: "Unable to get a screenshot for window at index \(index)")
            }
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
    
    func getObjectHierarchyForKeyWindow() -> [String: AnyObject] {
        if let window = application.keyWindow {
            return serializer.getSerializedObjects(rootObject: window)
        }
        return [:]
    }

    func getWindow(at index: Int) -> UIWindow? {
        return application.windows[index]
    }
    
    func getObjectHierarchyForWindow(at index: Int) -> [String: AnyObject] {
        if let window = getWindow(at: index) {
            return serializer.getSerializedObjects(rootObject: window)
        }
        return [:]
    }

}
