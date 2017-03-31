//
//  WKWebViewViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: self.view.bounds,
                                 configuration: configuration)
        self.webView.navigationDelegate = self
        let url = URL(string: "https://www.jd.com/")
        let request = URLRequest(url: url!)
        self.webView.load(request)
        self.view.addSubview(self.webView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
