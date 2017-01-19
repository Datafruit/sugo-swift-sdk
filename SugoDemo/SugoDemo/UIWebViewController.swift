//
//  UIWebViewController.swift
//  SugoDemo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit

class UIWebViewController: UIViewController  {

    @IBOutlet weak var webView: UIWebView!
    var wv:UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UIWebView"
        // Do any additional setup after loading the view.
        self.webView.delegate = self
//        let url = URL(string: "http://baidu.com")
        let url = URL(string: "http://dev.ufile.ucloud.cn/test.html")
        let request = URLRequest(url: url!)
        
//        self.webView.loadRequest(request)
//        self.view.addSubview(self.webView)
        
        self.wv = UIWebView(frame: self.view.frame)
        self.wv.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.wv.translatesAutoresizingMaskIntoConstraints = false
        print("autoresizingMask: \(self.wv.autoresizingMask)")
        print("translatesAutoresizingMaskIntoConstraints: \(self.wv.translatesAutoresizingMaskIntoConstraints)")
        self.wv.loadRequest(request)
        self.view.addSubview(self.wv)
        self.navigationController?.isNavigationBarHidden = true
        
    }
    
    deinit {
        self.webView.delegate = nil
    }
    
}

// Mark: - UIWebViewDelegate
extension UIWebViewController: UIWebViewDelegate {
       
    // Note: - Developer should implement these very delegate method for codeless bindings
    func webViewDidStartLoad(_ webView: UIWebView) {
        print(#function)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print(#function)
    }
    
}
