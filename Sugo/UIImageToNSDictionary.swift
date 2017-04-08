//
//  UIImageToDictionary.swift
//  Sugo
//
//  Created by Yarden Eitan on 9/2/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

@objc(UIImageToNSDictionary) class UIImageToNSDictionary: ValueTransformer {

    static var imageCache = [String: UIImage]()

    override class func transformedValueClass() -> AnyClass {
        return NSDictionary.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return false    // origin is true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let image = value as? UIImage else {
            return NSDictionary()
        }
        let sizeValue = NSValue(cgSize: image.size)
        guard let sizeTransformer = ValueTransformer(forName:
            NSValueTransformerName(rawValue: NSStringFromClass(CGSizeToNSDictionary.self))),
            let size = sizeTransformer.transformedValue(sizeValue) as? NSDictionary else {
                return NSDictionary()
        }
        let capInsetsValue = NSValue(uiEdgeInsets: image.capInsets)
        guard let insetsTransformer = ValueTransformer(forName:
            NSValueTransformerName(rawValue: NSStringFromClass(UIEdgeInsetsToNSDictionary.self))),
            let capInsets = insetsTransformer.transformedValue(capInsetsValue) as? NSDictionary else {
                return NSDictionary()
        }
        let alignmentRectInsetsValue = NSValue(uiEdgeInsets: image.alignmentRectInsets)
        guard let alignmentRectInsets = insetsTransformer.transformedValue(alignmentRectInsetsValue) as? NSDictionary else {
            return NSDictionary()
        }

        let images = image.images ?? [image]
        var imageDictionaries = [NSDictionary]()
        for img in images {
            if UIImagePNGRepresentation(img) != nil {
                let imageDictionary = ["scale": image.scale,
                                       "mime_type": "image/png"] as NSDictionary
                imageDictionaries.append(imageDictionary)
            }
        }

        return ["imageOrientation": image.imageOrientation.rawValue,
                "size": size,
                "renderingMode": image.renderingMode.rawValue,
                "resizingMode": image.resizingMode.rawValue,
                "duration": image.duration,
                "capInsets": capInsets,
                "alignmentRectInsets": alignmentRectInsets,
                "images": imageDictionaries]

    }

}
