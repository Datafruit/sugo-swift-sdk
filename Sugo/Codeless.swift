//
//  Codeless.swift
//  Sugo
//
//  Created by Yarden Eitan on 8/25/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

import Foundation

class Codeless {

    var codelessBindings = Set<CodelessBinding>()

    enum BindingType: String {
        case viewBinding = "ui_view"
        case textViewBinding = "ui_text_view"
        case tableViewBinding = "ui_table_view"
        case collectionViewBinding = "ui_collection_view"
    }

    class func createBinding(object: [String: Any]) -> CodelessBinding? {
        guard let bindingType = object["event_type"] as? String,
              let bindingTypeEnum = BindingType.init(rawValue: bindingType) else {
            return UIViewBinding(object: object)
        }

        switch bindingTypeEnum {
        case .viewBinding:
            return UIViewBinding(object: object)
        case .textViewBinding:
            return UITextViewBinding(object: object)
        case .tableViewBinding:
            return UITableViewBinding(object: object)
        case .collectionViewBinding:
            return UICollectionViewBinding(object: object)
        }
    }
}
