//
//  InstructionsViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit
import Sugo

class InstructionsViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.webView.delegate = self
        let url = URL(string: "http://docs.sugo.io/")
        let request = URLRequest(url: url!)
        self.webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("\(#function)")
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        print("\(#function)")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("\(#function)")
    }
}
