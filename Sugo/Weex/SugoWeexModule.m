//
//  SugoWeexModule.m
//  SwiftWeexSample
//
//  Created by lzackx on 2018/1/3.
//  Copyright © 2018年 com.taobao.weex. All rights reserved.
//

#import "SugoWeexModule.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"
@implementation SugoWeexModule

    @synthesize weexInstance;
    
    WX_EXPORT_METHOD_SYNC(@selector(track:props:))
    WX_EXPORT_METHOD_SYNC(@selector(timeEvent:))
    WX_EXPORT_METHOD_SYNC(@selector(registerSuperProperties:))
    WX_EXPORT_METHOD_SYNC(@selector(registerSuperPropertiesOnce:))
    WX_EXPORT_METHOD_SYNC(@selector(unregisterSuperProperty:))
    WX_EXPORT_METHOD_SYNC(@selector(getSuperProperties:))
    WX_EXPORT_METHOD_SYNC(@selector(clearSuperProperties))
    WX_EXPORT_METHOD_SYNC(@selector(login:userIdValue:))
    WX_EXPORT_METHOD_SYNC(@selector(logout))
    
@end
#pragma clang diagnostic pop