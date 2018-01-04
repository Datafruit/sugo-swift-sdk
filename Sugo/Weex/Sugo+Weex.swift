//
//  Sugo+Weex.swift
//  SwiftWeexSample
//
//  Created by lzackx on 2018/1/3.
//  Copyright © 2018年 com.taobao.weex. All rights reserved.
//

import Sugo
import WeexSDK

public extension SugoInstance {
    
    public func registerModule() {
        WXSDKEngine.registerModule("sugo", with: NSClassFromString("SugoWeexModule"))
    }
    
}
