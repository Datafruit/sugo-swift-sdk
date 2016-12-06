//
//  WKWebViewController.swift
//  SugoDemo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewController: UIViewController {

    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: self.view.frame, configuration: configuration)
        let url = URL(string: "http://dev.ufile.ucloud.cn/test.html")
        let request = URLRequest(url: url!)
        self.webView.load(request)
        self.view.addSubview(self.webView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
