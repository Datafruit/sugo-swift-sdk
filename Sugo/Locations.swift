//
//  Locations.swift
//  Sugo
//
//  Created by lzackx on 2018/8/6.
//  Copyright © 2018年 sugo. All rights reserved.
//

import UIKit
import CoreLocation

class Locations: NSObject, CLLocationManagerDelegate {

    var locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.delegate = self
    }
    
    private func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        
        AutomaticProperties.properties["latitude"] = Double(0)
        AutomaticProperties.properties["longitude"] = Double(0)
    }
    
    private func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        let coordinate = location.coordinate
        AutomaticProperties.properties["latitude"] = Double(coordinate.latitude)
        AutomaticProperties.properties["longitude"] = Double(coordinate.longitude)
    }
    
    private func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        AutomaticProperties.properties["latitude"] = Double(0)
        AutomaticProperties.properties["longitude"] = Double(0)
    }
    
}
