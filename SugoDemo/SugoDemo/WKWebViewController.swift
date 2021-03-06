//
//  WKWebViewController.swift
//  SugoDemo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WKWebView"
        // Do any additional setup after loading the view.
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: self.view.frame, configuration: configuration)
        self.webView.navigationDelegate = self
        let url = URL(string: "http://www.jd.com")
        let request = URLRequest(url: url!)
        self.webView.load(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
    }

}
