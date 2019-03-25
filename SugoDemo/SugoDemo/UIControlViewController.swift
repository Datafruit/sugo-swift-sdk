//
//  UIControlViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit
import Sugo

class UIControlViewController: UIViewController {

    @IBOutlet weak var customButton: CustomButton!
    @IBOutlet weak var userId: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customButton.buttonTitle = "数果智能"
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func signIn(_ sender: UIButton) {
        
        if let userId = userId.text {
            Sugo.mainInstance().trackFirstLogin(with: userId, dimension: "test_user_id")
        }
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        
        Sugo.mainInstance().untrackFirstLogin()
    }
    
    
}
