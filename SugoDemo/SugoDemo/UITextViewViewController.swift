//
//  UITextViewViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit

class UITextViewViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.textView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("\(#function)")
    }

}
