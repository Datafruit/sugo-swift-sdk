//
//  NSAttributedStringToNSDictionary.swift
//  Sugo
//
//  Created by Yarden Eitan on 9/6/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation
import UIKit

@objc(NSAttributedStringToNSDictionary) class NSAttributedStringToNSDictionary: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSDictionary.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return false    // origin is true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let attributedString = value as? NSAttributedString else {
            return nil
        }

        do {
            let data = try attributedString.data(from: NSRange(location: 0,
                                                               length: attributedString.length),
                                                 documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html])
            if String(data: data, encoding: String.Encoding.utf8) != nil {
                return ["mime_type": "text/html"]
            }
        } catch {
            Sugo.mainInstance().track(eventName: ExceptionUtils.SUGOEXCEPTION, properties: ExceptionUtils.exceptionInfo(error: error))
            Logger.debug(message: "Failed to convert NSAttributedString to HTML")
        }
        return nil
    }

}
