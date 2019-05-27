//
//  SugoInstance+HeatMap.swift
//  Sugo
//
//  Created by 陈宇艺 on 2019/4/18.
//  Copyright © 2019 sugo. All rights reserved.
//

import UIKit

extension SugoInstance {
    public func buildApplicationMoveEvent(){
        let userDefaults = UserDefaults.standard
        let isHeatMapFunc = userDefaults.bool(forKey: "isHeatMapFunc")
        if(!isHeatMapFunc || !self.openHeatMapFunc()){
            return
        }
        let sendEventBlock = {
            [unowned self] (viewController: AnyObject?, command: Selector, param1: AnyObject?, param2: AnyObject?) in
            guard let app = viewController as? UIApplication else {
                return
            }
            
            guard let event = param1 as? UIEvent else{
                return
            }
            //            application: AnyObject?, command: AnyObject?, event:UIEvent
            let keys = SugoDimensions.keys
            let values = SugoDimensions.values
            //            NSSet *touches = [event allTouches];
            let touches:Set<UITouch> = event.allTouches!
            for touch in touches {
                switch(touch.phase){
                case UITouch.Phase.began:
                    let point:CGPoint = touch.location(in: UIApplication.shared.keyWindow)
                    let x:Float = Float(point.x)
                    let y:Float = Float(point.y)
                    let serialNum:NSInteger = self.calculateTouchArea(x: x, y: y)
                    
                    var p = Properties()
                    let userDefaults = UserDefaults.standard
                    let pagePath:String = userDefaults.string(forKey: Sugo.CURRENTCONTROLLER) as! String
                    p[keys["PagePath"]!] = pagePath
                    p[keys["OnclickPoint"]!] = "\(serialNum)"
                    if let vc = UIViewController.sugoCurrentUIViewController() {
                        p[keys["PagePath"]!] = NSStringFromClass(vc.classForCoder)
                        for info in SugoPageInfos.global.infos {
                            if let infoPage = info["page"] as? String,
                                infoPage == NSStringFromClass(vc.classForCoder) {
                                p[keys["PageName"]!] = info["page_name"] as? String
                                if let infoPageCategory = info["page_category"] as? String {
                                    p[keys["PageCategory"]!] = infoPageCategory;
                                }
                                break
                            }
                        }
                    }
                    
                    if(self.isSubmitPointWithThisPage(pathName: pagePath)){
                        self.track(eventName: values["ScreenTouch"]!, properties: p)
                    }
                    
                    break
                default:
                    break
                }
            }
        }
        Swizzler.swizzleSelector(#selector(UIApplication.sendEvent(_ :)),
                                 withSelector: #selector(UIApplication.sugoSendEventBlock(_ :)),
                                 for: UIApplication.self,
                                 name: UUID().uuidString,
                                 block: sendEventBlock)
    }
    
    private func openHeatMapFunc()->Bool{
        var isOk:Bool = false
        for info in SugoPageInfos.global.infos {
            if let isSubmitPoint = info["isSubmitPoint"] as? Bool {
                if(isSubmitPoint) {
                    isOk = true
                    break
                }
            }
        }
        return isOk
    }
    
    private func isSubmitPointWithThisPage(pathName:String) ->Bool{
        var isOk:Bool = false
        for info in SugoPageInfos.global.infos {
            if let name = info["page"] as? String{
                if(name == pathName){
                    continue
                }
                if let isSubmitPoint = info["isSubmitPoint"] as? Bool {
                    if(isSubmitPoint) {
                        isOk = true
                    }else{
                        break
                    }
                }
            }
        }
        return isOk
    }
    
    
    
    
    private func calculateTouchArea(x:Float,y:Float) ->NSInteger{
        let columnNum:Float = 36
        let lineNum:Float = 64
        var areaWidth:Float
        var areaHeight:Float
        let fullScreenH:Float = Float(UIScreen.main.bounds.size.height)
        let fullScreenW:Float = Float(UIScreen.main.bounds.size.width)
        var newY:Float = y
        if fullScreenH>fullScreenW {
            areaWidth = fullScreenW/columnNum
            areaHeight = fullScreenH/lineNum
        }else{//Landscape situation
            let ratio = (fullScreenH/columnNum)/(fullScreenW/lineNum)
            areaWidth = fullScreenW/columnNum
            areaHeight = areaWidth*ratio
            var statusheight:Float = 20
            if UIScreen.main.bounds.height == 812{
                statusheight = 44
            }
            let statusBarRatioHeight:Float = areaHeight/((fullScreenW/lineNum)/statusheight)
            newY = y + statusBarRatioHeight
        }
        let columnSerialValue:Float = x/areaWidth
        let lineNumSerialValue:Float = newY/areaHeight
        var columnSerialNum:Int
        if (columnSerialValue-Float(Int(columnSerialValue)))>0{
            columnSerialNum = (Int(columnSerialValue)+1)
        }else{
            columnSerialNum = Int(columnSerialValue)
        }
        var lineNumSerialNum:Int
        if(lineNumSerialValue-Float(Int(lineNumSerialValue)))>0{
            lineNumSerialNum = Int(lineNumSerialValue)
        }else{
            lineNumSerialNum = Int(lineNumSerialValue)-1
        }
        
        if columnSerialValue == 0{
            columnSerialNum = columnSerialNum + 1
        }
        
        return columnSerialNum + lineNumSerialNum*Int(columnNum)
    }
}
