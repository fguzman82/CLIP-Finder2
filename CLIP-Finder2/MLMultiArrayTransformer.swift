//
//  MLMultiArrayTransformer.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import Foundation
import CoreML

class MLMultiArrayTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let multiArray = value as? MLMultiArray else {
            return nil
        }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: multiArray, requiringSecureCoding: true)
            return data
        } catch {
            #if DEBUG
            print("Failed to transform MLMultiArray to Data: \(error)")
            #endif
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            return nil
        }

        do {
            let multiArray = try NSKeyedUnarchiver.unarchivedObject(ofClass: MLMultiArray.self, from: data)
            return multiArray
        } catch {
            #if DEBUG
            print("Failed to reverse transform Data to MLMultiArray: \(error)")
            #endif
            return nil
        }
    }
}

