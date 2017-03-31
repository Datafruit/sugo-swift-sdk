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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirm(_ sender: UIButton) {
        
        print("url: \(self.urlString.debugDescription)")
        if let url = URL(string: self.urlString!) {
            Sugo.mainInstance().connectToCodeless(via: url)
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}
