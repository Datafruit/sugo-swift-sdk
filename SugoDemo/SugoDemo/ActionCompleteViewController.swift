//
//  ActionCompleteViewController.swift
//  SugoDemo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit

class ActionCompleteViewController: UIViewController {

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    var actionStr: String?
    var descStr: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popupView.clipsToBounds = true
        popupView.layer.cornerRadius = 6
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
        actionLabel.text = actionStr
        descLabel.text = descStr
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func handleTap(gesture: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

}
