//
//  MPSGraphPostProcessing.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 25/06/24.
//

import MetalPerformanceShadersGraph
import MetalPerformanceShadersGraph.MPSGraph

class MPSGraphExtensions {
    static func generateTextFeatures(device: MTLDevice) -> MPSNDArray {
        let graph = MPSGraph()
        
//        // Crear descriptor para la operación aleatoria
//        guard let descriptor = MPSGraphRandomOpDescriptor(distribution: .uniform, dataType: .float32) else {
//            fatalError("Failed to create MPSGraphRandomOpDescriptor")
//        }
//        
//        let textFeaturesTensor = graph.randomTensor(withShape: [1, 512], descriptor: descriptor, seed: 2024, name: nil)
//        
//        let commandQueue = device.makeCommandQueue()!
//        let results = graph.run(with: commandQueue, feeds: [:], targetTensors: [textFeaturesTensor], targetOperations: nil)
//        return results[textFeaturesTensor]!.mpsndarray()
        // Crear un tensor constante con valor 1/512
        let constantValue = 1.0 / 512.0
        //let textFeaturesTensor = graph.constant(constantValue, shape: [1, 512] as [NSNumber], dataType: .float16)
        
        // Crear el MPSNDArray para textFeatures
        let textFeaturesDescriptor = MPSNDArrayDescriptor(dataType: .float16, shape: [1, 512] as [NSNumber])
        let textFeatures = MPSNDArray(device: device, descriptor: textFeaturesDescriptor)
        
        var values = [Float16](repeating: Float16(constantValue), count: 512)
        textFeatures.writeBytes(&values, strideBytes: nil)
        
        return textFeatures
    }

    static func calculateSimilarities(graph: MPSGraph, textTensor: MPSGraphTensor, photoTensor: MPSGraphTensor) -> MPSGraphTensor {
        let textTransposed = graph.transpose(textTensor, permutation: [1, 0] as [NSNumber], name: nil)
        let similarities = graph.matrixMultiplication(primary: photoTensor, secondary: textTransposed, name: nil)
        return similarities
    }
    
    
}

