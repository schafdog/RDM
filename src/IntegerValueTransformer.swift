//
//  IntegerValueTransformer.swift
//  RDM
//
//  Created by JNR on 20. 9. 8..
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Foundation

@objc class IntegerValueTransformer: ValueTransformer {
    private static let name = NSValueTransformerName(rawValue: IntegerValueTransformer.className())

    @objc public static func registerTransformer() {
//        print(name)
        ValueTransformer.setValueTransformer(IntegerValueTransformer(),
                                             forName: name)
    }

    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        return value
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let number = value as? NSNumber else { return 0 }
        return number
    }
}
