//
//  SwitchModeViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit
import Sugo

class SwitchModeViewController: UIViewController {

    var urlString: String?
    var type: String?
    @IBOutlet weak var switchLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.type = handleURL()
        if self.type == "heat" {
            self.switchLabel.text = "切换至热图模式"
        } else if self.type == "track" {
            self.switchLabel.text = "切换至可视化埋点模式"
        } else {
            self.switchLabel.text = "信息错误，请重新扫码"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirm(_ sender: UIButton) {
        
        print("url: \(self.urlString.debugDescription)")
        guard let string = self.urlString, let url = URL(string: string) else {
            return
        }
        
        if self.type == "heat" {
            Sugo.mainInstance().requestForHeatMap(via: url)
            self.navigationController?.popToRootViewController(animated: true)
        } else if self.type == "track" {
            Sugo.mainInstance().connectToCodeless(via: url)
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func handleURL() -> String {
        
        print("url: \(self.urlString.debugDescription)")
        guard let string = self.urlString,
            let url = URL(string: string),
            let query = url.query else {
                return ""
        }
        
        var querys = [String: String]()
        
        let items = query.components(separatedBy: "&")
        for item in items {
            let q = item.components(separatedBy: "=")
            if q.count != 2 {
                continue
            }
            querys[q.first!] = q.last!
        }
        
        if let type = url.path.components(separatedBy: "/").last,
            querys["sKey"] != nil {
            return type
        }
        return ""
    }
    
}
