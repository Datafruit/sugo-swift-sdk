//
//  UIViewSelectors.swift
//  Sugo
//
//  Created by Yarden Eitan on 9/2/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

private var key: Void?

extension UIView {

    @objc func mp_encryptHelper(input: String?) -> NSString {
        let encryptedStuff = NSMutableString(capacity: 64);
        guard let input = input, !input.isEmpty else {
            return encryptedStuff
        }
        let SALT = "1l0v3c4a8s4n018cl3d93kxled3kcle3j19384jdo2dk3"
        let data = (input + SALT).data(using: .unicode)
        if let digest = data?.sha256()?.bytes {
            for i in 0..<20 {
                encryptedStuff.appendFormat("%02x", digest[i])
            }
        }
        return encryptedStuff
    }

    @objc func mp_fingerprintVersion() -> NSNumber {
        return NSNumber(value: 1)
    }

    @objc func mp_varA() -> NSString? {
        return mp_encryptHelper(input: mp_viewId())
    }

    @objc func mp_varB() -> NSString? {
        return mp_encryptHelper(input: mp_controllerVariable())
    }

    @objc func mp_varC() -> NSString? {
        return mp_encryptHelper(input: mp_imageFingerprint())
    }

    @objc func mp_varSetD() -> NSArray {
        return mp_targetActions().map {
            mp_encryptHelper(input: $0)
        } as NSArray
    }

    @objc func mp_varE() -> NSString? {
        return mp_encryptHelper(input: mp_text())
    }

    @objc public var sugoViewId: String? {
        get {
            return objc_getAssociatedObject(self, &key) as? String
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc func mp_viewId() -> String? {
        return sugoViewId
    }

    @objc func mp_controllerVariable() -> String? {
        /* Deprecated
        // when a UIViewController has a property that is not a NSObject, Mirror.children will crash, and ivar_getTypeEncoding isn't available in Swift
        // when current UIVIewController is a rootViewController of a UINavigationController, this function cannot get correct responder
        if self is UIControl {
            var responder = self.next
            while responder != nil && !(responder is UIViewController) {
                responder = responder?.next
            }
            if let responder = responder {
                let mirrored_object = Mirror(reflecting: responder)
                for (_, attr) in mirrored_object.children.enumerated() {
                    if let property_name = attr.label {
                        if let value = attr.value as? UIView, value == self {
                            return property_name
                        }
                    }
                }
            }
        }
         */
        return nil
    }

    @objc func mp_imageFingerprint() -> String? {
        var result: String? = String()
        var originalImage: UIImage? = nil
        let imageSelector = NSSelectorFromString("image")

        if let button = self as? UIButton {
            originalImage = button.image(for: UIControl.State.normal)
        } else if let superviewUnwrapped = self.superview,
            NSStringFromClass(type(of: superviewUnwrapped)) == "UITabBarButton" && self.responds(to: imageSelector) {
            originalImage = self.perform(imageSelector).takeRetainedValue() as? UIImage
        }
        
        if let originalImage = originalImage,
            let data: Data = originalImage.pngData(),
            let hashData = "\(data.hashValue)".data(using: String.Encoding.utf8) {
            result = hashData.base64EncodedString()
        }
        
        /* Deprecated
        if let originalImage = originalImage, let cgImage = originalImage.cgImage {
            let space = CGColorSpaceCreateDeviceRGB()
            let data32 = UnsafeMutablePointer<UInt32>.allocate(capacity: 64)
            let data4 = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            let context = CGContext(data: data32,
                                    width: 8,
                                    height: 8,
                                    bitsPerComponent: 8,
                                    bytesPerRow: 8*4,
                                    space: space,
                                    bitmapInfo: bitmapInfo)
            context?.setAllowsAntialiasing(false)
            context?.clear(CGRect(x: 0, y: 0, width: 8, height: 8))
            context?.interpolationQuality = .none
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: 8, height: 8))
            for i in 0..<32 {
                let j = 2*i
                let k = 2*i + 1
                var part1 = ((data32[j] & 0x80000000) >> 24) | ((data32[j] & 0x800000) >> 17)
                part1 = part1 | ((data32[j] & 0x8000) >> 10)
                var part2 = ((data32[j] & 0x80) >> 3) | ((data32[k] & 0x80000000) >> 28)
                part2 = part2 | ((data32[k] & 0x800000) >> 21)
                let part3 = ((data32[k] & 0x8000) >> 14) | ((data32[k] & 0x80) >> 7)
                data4[i] = UInt8(part1 | part2 | part3)
            }
            let arr = Array(UnsafeBufferPointer(start: data4, count: 32))
            result = Data(bytes: arr).base64EncodedString()
        }
         */
        return result
    }

    @objc func mp_targetActions() -> [String] {
        var targetActions = [String]()
        if let control = self as? UIControl {
            for target in control.allTargets {
                let allEvents: UIControl.Event = [.allTouchEvents, .allEditingEvents]
                let allEventsRaw = allEvents.rawValue
                var e: UInt = 0
                while allEventsRaw >> e > 0 {
                    let event = allEventsRaw & (0x01 << e)
                    let controlEvent = UIControl.Event(rawValue: event)
                    let ignoreActions = ["preVerify:forEvent:", "execute:forEvent:"]
                    if let actions = control.actions(forTarget: target, forControlEvent: controlEvent) {
                        for action in actions {
                            if ignoreActions.index(of: action) == nil {
                                targetActions.append("\(event)/\(action)")
                            }
                        }
                    }
                    e += 1
                }
            }
        }
        return targetActions
    }

    @objc func mp_text() -> String? {
        var text: String? = String()
        let titleSelector = NSSelectorFromString("title")
        if let label = self as? UILabel {
            text = label.text
        } else if let button = self as? UIButton {
            text = button.title(for: .normal)
        } else if self.responds(to: titleSelector) {
            if let property = self.perform(titleSelector),
                let titleImp = property.takeUnretainedValue() as? String {
                text = titleImp
            }
        }
        return text
    }
}
