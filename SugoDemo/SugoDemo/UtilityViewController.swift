//
//  UtilityViewController.swift
//  SugoDemo
//
//  Created by Zack on 6/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

import UIKit
import Sugo

class UtilityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var tableViewItems = ["Create Alias",
                          "Reset",
                          "Archive",
                          "Flush"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Utility"
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.text = tableViewItems[indexPath.item]
        cell.textLabel?.textColor = #colorLiteral(red: 0.200000003, green: 0.200000003, blue: 0.200000003, alpha: 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionStr = tableViewItems[indexPath.item]
        var descStr = ""
        
        switch indexPath.item {
        case 0:
            Sugo.mainInstance().createAlias("New Alias", distinctId: Sugo.mainInstance().distinctId)
            descStr = "Alias: New Alias, from: \(Sugo.mainInstance().distinctId)"
        case 1:
            Sugo.mainInstance().reset()
            descStr = "Reset Instance"
        case 2:
            Sugo.mainInstance().archive()
            descStr = "Archived Data"
        case 3:
            Sugo.mainInstance().flush()
            descStr = "Flushed Data"
        default:
            break
        }
        
        let vc = storyboard!.instantiateViewController(withIdentifier: "ActionCompleteViewController") as! ActionCompleteViewController
        vc.actionStr = actionStr
        vc.descStr = descStr
        vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        vc.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        present(vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }
    
}
