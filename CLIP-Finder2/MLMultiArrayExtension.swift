//
//  MLMultiArrayExtension.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import CoreML

//extension MLMultiArray {
//    func toFloatArray() -> [Float] {
//        return (0..<self.count).map { Float(truncating: self[$0]) }
//    }
//}

extension MLMultiArray {
    func toData() -> Data {
        return self.withUnsafeBytes { Data($0) }
    }
    
    func toFloatArray() -> [Float] {
        return (0..<self.count).map { Float(truncating: self[$0]) }
    }
    
    func toNSNumberArray() -> [NSNumber] {
        return (0..<self.count).map { self[$0] }
    }
}
