//
//  ScanViewController.swift
//  SugoDemo
//
//  Created by Zack on 30/3/17.
//  Copyright © 2017年 Sugo. All rights reserved.
//

import UIKit
import AVFoundation

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var scanView: UIView?
    
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var preview: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupScanner()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupScanner() {
        
        guard hasCameraPermission() else {
            return
        }
        
        if self.scanView == nil {
            let windowSize = UIScreen.main.bounds.size
            let scanSize = CGSize(width: windowSize.width * 3 / 4,
                                  height: windowSize.width * 3 / 4)
            var scanRect = CGRect(x: (windowSize.width - scanSize.width) / 2,
                                  y: (windowSize.height - scanSize.height) / 2,
                                  width: scanSize.width,
                                  height: scanSize.height)
            scanRect = CGRect(x: scanRect.origin.y / windowSize.height,
                              y: scanRect.origin.x / windowSize.width,
                              width: scanRect.size.height / windowSize.height,
                              height: scanRect.size.width / windowSize.width)
            self.device = AVCaptureDevice.default(for: AVMediaType.video)
            guard self.device != nil else {
                return
            }
            do {
                self.input = try AVCaptureDeviceInput(device: self.device!)
                self.output = AVCaptureMetadataOutput()
                self.output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                self.session = AVCaptureSession()
                self.session?.sessionPreset = UIScreen.main.bounds.size.height < 500 ? AVCaptureSession.Preset.vga640x480 : AVCaptureSession.Preset.high
                self.session?.addInput(self.input!)
                self.session?.addOutput(self.output!)
                self.output?.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                self.output?.rectOfInterest = scanRect
                
                self.preview = AVCaptureVideoPreviewLayer(session: self.session!)
                self.preview?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                self.preview?.frame = UIScreen.main.bounds
                self.view.layer.insertSublayer(self.preview!, at: 0)
                
                self.scanView = UIView(frame: CGRect(x: 0, y: 0, width: scanSize.width, height: scanSize.height))
                self.view.addSubview(self.scanView!)
                self.scanView?.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                self.scanView?.layer.borderColor = UIColor(red: 117 / 255, green: 102 / 255, blue: 1, alpha: 1).cgColor
                self.scanView?.layer.borderWidth = 1
                
            } catch {
                print("AVCaptureDeviceInput exception: \(error.localizedDescription)")
            }
        }
        self.session?.startRunning()
    }
    
    func hasCameraPermission() -> Bool {
        
        var hasPermission = false
        let permission = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch permission {
        case .authorized:
            hasPermission = true
        case .denied:
            fallthrough
        case .restricted:
            fallthrough
        case .notDetermined:
            break
        }
        return hasPermission
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard !metadataObjects.isEmpty else {
            return
        }
        
        self.session?.stopRunning()
        
        if let smvc = self.storyboard?.instantiateViewController(withIdentifier: "SwitchMode") as? SwitchModeViewController,
            let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            smvc.urlString = metadataObject.stringValue
            self.navigationController?.pushViewController(smvc, animated: true)
        }
        
    }

}
