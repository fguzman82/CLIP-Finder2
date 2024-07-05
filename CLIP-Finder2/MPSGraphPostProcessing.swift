//
//  MPSGraphPostProcessing.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 25/06/24.
//

import MetalPerformanceShadersGraph
import CoreML

class MPSGraphExtensions {

    static func convertTextFeaturesToMPSNDArray(textFeatures: MLMultiArray, device: MTLDevice) -> MPSNDArray {
        let descriptor = MPSNDArrayDescriptor(dataType: .float16, shape: [1, 512] as [NSNumber])
        let mpsArray = MPSNDArray(device: device, descriptor: descriptor)
        
        let buffer = UnsafeMutableBufferPointer<Float16>.allocate(capacity: 512)
        defer { buffer.deallocate() }
        
        for i in 0..<512 {
            buffer[i] = Float16(textFeatures[i].floatValue)
        }
        
        mpsArray.writeBytes(buffer.baseAddress!, strideBytes: nil)
        return mpsArray
    }

    
    static func calculateSimilarities(graph: MPSGraph, textTensor: MPSGraphTensor, photoTensor: MPSGraphTensor) -> MPSGraphTensor {
        let textTransposed = graph.transpose(textTensor, permutation: [1, 0] as [NSNumber], name: nil)
        let similarities = graph.matrixMultiplication(primary: photoTensor, secondary: textTransposed, name: nil)
        return similarities
    }
    
    
}

