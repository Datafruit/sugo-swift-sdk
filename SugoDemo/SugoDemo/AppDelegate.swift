//
//  AppDelegate.swift
//  SugoDemo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import Sugo

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        initSugo()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        return Sugo.mainInstance().handle(url: url)
    }
    
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//        
//    }
//    
//    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
//        
//    }

}

// Mark: - Init Sugo framework
extension AppDelegate {
    
    fileprivate func initSugo() {
        let id: String = "tindex_H1bIzqK2SZ_project_iin8GdGuep" // 项目ID
        let token: String = "99524cf841b490c1f191f11443f5fb0c" // 应用ID
        Sugo.BindingsURL = "http://183.6.26.89:2270" // 设置获取绑定事件配置的URL，端口默认为8000
        Sugo.CollectionURL = "http://183.6.26.89:2271" // 设置传输绑定事件的网管URL，端口默认为80
        Sugo.CodelessURL = "ws://183.6.26.89:2227" // 设置连接可视化埋点的URL，端口默认为8887
        Sugo.initialize(projectID: id, token: token){
            Sugo.mainInstance().loggingEnabled = true // 如果需要查看SDK的Log，请设置为true
            Sugo.mainInstance().flushInterval = 5 // 被绑定的事件数据往服务端上传的时间间隔，单位是秒，如若不设置，默认时间是60秒
            Sugo.mainInstance().cacheInterval = 60 // 从服务端拉取绑定事件配置的时间间隔，单位是秒，如若不设置，默认时间是1小时
        }
    }
    
}

