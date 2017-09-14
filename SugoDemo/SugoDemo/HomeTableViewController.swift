//
//  HomeTableViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit
import AVFoundation

class HomeTableViewController: UITableViewController {

    var deprecatedTimer: Timer?
    static var deprecatedTimes: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.deprecatedTimer = Timer.scheduledTimer(timeInterval: 5,
                                                    target: self,
                                                    selector: #selector(deprecate),
                                                    userInfo: nil,
                                                    repeats: true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func scan(_ sender: UIButton) {
        checkCameraPermissionForScan()
    }
    
    @IBAction func deprecatedAction(_ sender: UIButton) {
        HomeTableViewController.deprecatedTimes = HomeTableViewController.deprecatedTimes + 1
    }
    
    func checkCameraPermissionForScan() {
        
        let permission = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch permission {
        case .authorized:
            if let sb = self.storyboard {
                self.navigationController?.pushViewController(sb.instantiateViewController(withIdentifier: "Scan"),
                                                              animated: true)
            }
        case .denied:
            fallthrough
        case .restricted:
            self.present(createCameraAlertController(), animated: true, completion: nil)
        case .notDetermined:
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                    [unowned self] (granted: Bool) in
                    if granted {
                        DispatchQueue.main.sync {
                            if let sb = self.storyboard {
                                self.navigationController?.pushViewController(sb.instantiateViewController(withIdentifier: "Scan"),
                                                                              animated: true)
                            }
                        }
                    }
            })
        }
    }
    
    func createCameraAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "相机权限不足",
                                                message: "请到 设置->隐私->相机 中设置",
                                                preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "好",
                                         style: UIAlertActionStyle.default,
                                         handler: nil)
        alertController.addAction(cancelAction)
        return alertController
    }
    
    @objc func deprecate() {
        if HomeTableViewController.deprecatedTimes > 5 {
            self.deprecatedTimer?.invalidate()
            self.deprecatedTimer = nil;
            let sb = UIStoryboard(name: "Deprecated", bundle: Bundle.main)
            if let vc = sb.instantiateInitialViewController() {
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            HomeTableViewController.deprecatedTimes = 0
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
