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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.webView.delegate = self
        let url = URL(string: "http://dev.ufile.ucloud.cn/test.html")
        let request = URLRequest(url: url!)
        self.webView.loadRequest(request)
        self.view.addSubview(self.webView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// Mark: - UIWebViewDelegate
extension UIWebViewController: UIWebViewDelegate {
    
    // Note: Developer should implement this very delegate method
    @objc func webViewDidFinishLoad(_ webView: UIWebView) {
        print(#function)
    }
    
}
