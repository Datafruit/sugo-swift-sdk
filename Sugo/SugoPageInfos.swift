//
//  SugoPageInfos.swift
//  Sugo
//
//  Created by Zack on 3/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

import UIKit

class SugoPageInfos: NSObject {

    var infos: [[String: String]]
    
    static var global: SugoPageInfos {
        return singleton
    }
    private static let singleton = SugoPageInfos()
    
    private override init() {
        self.infos = [[String: String]]()
        super.init()
    }
    
    deinit {
        self.infos.removeAll()
    }

    
}
