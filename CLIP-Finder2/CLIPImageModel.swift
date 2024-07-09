//
//  CLIPImageModel.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 27/06/24.
//

import CoreML
enum DataModelError: Error {
    case modelFileNotFound
    case modelNotLoaded
    case predictionFailed
}

final class CLIPImageModel {
    var model: MLModel?
    private var configuration: MLModelConfiguration
    
    init() {
        self.configuration = MLModelConfiguration()
        self.configuration.computeUnits = .all //Default
        
        Task {
            do {
                try await loadModel()
            } catch {
                #if DEBUG
                print("Failed to load model: \(error)")
                #endif
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
            #if DEBUG
            print("Failed to reload model: \(error)")
            #endif
        }
    }
    
    private func loadModel() async throws {
        guard let modelURL = Bundle.main.url(forResource: "clip_mci_image", withExtension: "mlmodelc") else {
//            print("Current bundle URL: \(Bundle.main.bundleURL)")
            throw DataModelError.modelFileNotFound
        }
        
//        let compiledURL = try await MLModel.compileModel(at: modelURL)
        model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        #if DEBUG
        print("CLIP image model loaded successfully.")
        #endif
    }
    

    func performInference(_ pixelBuffer: CVPixelBuffer) async throws -> MLMultiArray? {
        guard let model = model else {
            throw NSError(domain: "ClipImageModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Model is not loaded"])
        }
        
        let input = InputFeatureProvider(pixelBuffer: pixelBuffer)
        
        do {
            let outputFeatures = try await model.prediction(from: input)
            
            if let multiArray = outputFeatures.featureValue(for: "var_1259")?.multiArrayValue {
                return multiArray
            } else {
                throw NSError(domain: "ClipImageModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve MLMultiArray from prediction"])
            }
        } catch {
            #if DEBUG
            print("ClipImageModel: Failed to perform inference: \(error)")
            #endif
            throw error
        }
    }
    
    func performInferenceSync(_ pixelBuffer: CVPixelBuffer) -> MLMultiArray? {
        guard let model else {
            #if DEBUG
            print("ClipImageModel is not loaded.")
            #endif
            return nil
        }

        let input = InputFeatureProvider(pixelBuffer: pixelBuffer)
        do {
            let outputFeatures = try model.prediction(from: input)

            if let multiArray = outputFeatures.featureValue(for: "var_1259")?.multiArrayValue {
                return multiArray
            }
            else {
                #if DEBUG
                print("ClipImageModel: Failed to retrieve MLMultiArray.")
                #endif
                return nil
            }
        } catch {
            #if DEBUG
            print("ClipImageModel: Failed to perform inference: \(error)")
            #endif
            return nil
        }

    }


}


class InputFeatureProvider: MLFeatureProvider {
    let pixelBuffer: CVPixelBuffer
    
    init(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }
    
    var featureNames: Set<String> {
        return ["input_image"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input_image" {
            return MLFeatureValue(pixelBuffer: pixelBuffer)
        }
        return nil
    }
}


