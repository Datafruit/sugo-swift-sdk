//
//  HeatMap.swift
//  Sugo
//
//  Created by Zack on 6/5/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import UIKit

class HeatMap: NSObject {

    var mode: Bool
    var data: Data
    var coldColor: [String: Double]
    var hotColor: [String: Double]
    var hmLayers: [String: HeatMapLayer];
    
    init(data: Data) {
        self.mode = false
        self.data = data
        self.coldColor = ["red": 211, "green": 177, "blue": 125]
        self.hotColor = ["red": 255, "green": 45, "blue": 81]
        self.hmLayers = [String: HeatMapLayer]()
        super.init()
    }
    
    func switchMode(mode: Bool) {
        guard self.mode != mode else {
            return
        }
        self.mode = mode
    }
    
    func renderObjectOfPath(path: String, root: AnyObject) {
        
        let heats = parse()
        if heats[path] == nil || self.hmLayers.keys.contains(path) {
            return
        }
        
        let selector = ObjectSelector(string: path)
        let objects = selector.selectFrom(root: root)
        for object in objects {
            if let control = object as? UIControl,
                let rate = heats[path] {
                let hmLayer = HeatMapLayer(frame: control.layer.bounds,
                                           heat: colorOfRate(rate: rate))
                hmLayer.setNeedsDisplay()
                control.layer.addSublayer(hmLayer)
                self.hmLayers += [path: hmLayer]
            }
        }
    }
    
    func wipeObjectOfPath(path: String) {
        
        if self.hmLayers.keys.contains(path) {
            self.hmLayers[path]?.removeFromSuperlayer()
            self.hmLayers.removeValue(forKey: path)
        }
    }
    
}

// Color
extension HeatMap {
    
    fileprivate func colorOfRate(rate: Double) -> [String: Double] {
        
        var color = self.coldColor
        
        let red: Double = (self.hotColor["red"]! - self.coldColor["red"]!) * rate
        let green: Double = (self.hotColor["green"]! - self.coldColor["green"]!) * rate
        let blue: Double = (self.hotColor["blue"]! - self.coldColor["blue"]!) * rate
        
        color["red"] = self.coldColor["red"]! + red
        color["green"] = self.coldColor["green"]! + green
        color["blue"] = self.coldColor["blue"]! + blue
        
        return color
    }
    
}

// Parser
extension HeatMap {
    
    fileprivate func parse() -> [String: Double] {
        
        var heats = [String: Double]()
        
        let nativeEventBindings = serializedNativeEventBindings()
        if !nativeEventBindings.isEmpty {
            let heatMap = serializedHeatMap()
            
            var hs = [String: Double]()
            var locations = [String: String]()
            for eventId in heatMap.keys {
                if let binding = nativeEventBindings[eventId] as? [String: Any],
                    let path = binding["path"] as? String {
                    let page = pageOfPath(path: path)
                    locations += [path: page]
                    if let heat = heatMap[eventId] as? Double {
                        hs += [path: heat]
                    }
                }
            }
            
            var pages = [String: [String]]()
            for path in locations.keys {
                if let page = locations[path] {
                    var paths = [String]()
                    if let ps = pages[page] {
                        paths = ps
                    }
                    paths.append(path)
                    pages += [page: paths]
                }
            }
            
            for page in pages.keys {
                var events: Double = 0.0
                for path in pages[page]! {
                    if events < hs[path]! {
                        events = hs[path]!
                    }
                }
                for path in pages[page]! {
                    if let heat = hs[path] {
                        let rate = heat / events
                        heats += [path: rate]
                    }
                }
            }
            
        }
        return heats
    }

    private func pageOfPath(path: String) -> String {
        
        var page = ""
        
        if path.components(separatedBy: "/").count > 2 {
            page = path.components(separatedBy: "/")[1]
        }
        
        return page
    }
    
    private func serializedHeatMap() -> [String: Any] {
        
        var heats = [String: Any]()
        
        do {
            if let object = try JSONSerialization.jsonObject(with: self.data,
                                                             options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any],
                let hm = object["heat_map"] as? [String: Any] {
                heats = hm
            }
        } catch {
            Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
            Logger.error(message: "Heat Map Exception: \(error.localizedDescription)")
        }
        
        return heats
    }
    
    private func serializedNativeEventBindings() -> [String: Any] {
        
        var nativeEventBindings = [String: Any]()
        
        let userDefaults = UserDefaults.standard
        if let cacheData = userDefaults.data(forKey: "SugoEventBindings") {
            do {
                if let object = try JSONSerialization.jsonObject(with: cacheData,
                                                                 options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any],
                    let eventBindings = object["event_bindings"] as? [[String: Any]] {
                    
                    for binding in eventBindings {
                        if let bindingType = binding["event_type"] as? String,
                            bindingType == "ui_control",
                            let bindingId = binding["event_id"] as? String {
                            nativeEventBindings += [bindingId: binding]
                        }
                    }
                }
            } catch {
                Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
                Logger.error(message: "Heat Map Exception: \(error.localizedDescription)")
            }
        }
        return nativeEventBindings
    }
    
}










