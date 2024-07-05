//
//  CLIPTextModel.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 27/06/24.
//


import CoreML

enum CLIPTextModelError: Error {
    case modelFileNotFound
    case modelNotLoaded
    case predictionFailed
}

final class CLIPTextModel {
    var model: MLModel?
    private var configuration: MLModelConfiguration
    
    init() {
        self.configuration = MLModelConfiguration()
        self.configuration.computeUnits = .all // Default
        
        Task {
            do {
                try await loadModel()
            } catch {
                print("Failed to load CLIP text model: \(error)")
            }
        }
    }
    
    func setProcessingUnit(_ unit: MLComputeUnits) {
        configuration.computeUnits = unit
    }
    
    func reloadModel() async {
        do {
            try await loadModel()
        } catch {
            print("Failed to reload CLIP text model: \(error)")
        }
    }
    
    private func loadModel() async throws {
        guard let modelURL = Bundle.main.url(forResource: "clip_text", withExtension: "mlmodelc") else {
            print("Current bundle URL: \(Bundle.main.bundleURL)")
            throw CLIPTextModelError.modelFileNotFound
        }
        
        model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        print("CLIP text model loaded successfully.")
    }
    
    func performInference(_ tokens: [Int32]) async throws -> MLMultiArray? {
        guard let model = model else {
            throw CLIPTextModelError.modelNotLoaded
        }
        
        do {
            let inputArray = try MLMultiArray(shape: [1, 77] as [NSNumber], dataType: .int32)
            for (index, token) in tokens.enumerated() {
                inputArray[index] = NSNumber(value: token)
            }
            
            let input = TextInputFeatureProvider(input_text: inputArray)
            
            let outputFeatures = try await model.prediction(from: input)
            
            if let multiArray = outputFeatures.featureValue(for: "var_475")?.multiArrayValue {
                return multiArray
            } else {
                throw CLIPTextModelError.predictionFailed
            }
        } catch {
            print("Failed to perform CLIP text inference: \(error)")
            throw error
        }
    }
}

class TextInputFeatureProvider : MLFeatureProvider {
    var input_text: MLMultiArray

    var featureNames: Set<String> {
        get {
            return ["input_text"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input_text") {
            return MLFeatureValue(multiArray: input_text)
        }
        return nil
    }
    
    init(input_text: MLMultiArray) {
        self.input_text = input_text
    }

    convenience init(input_text: MLShapedArray<Int32>) {
        self.init(input_text: MLMultiArray(input_text))
    }
}
