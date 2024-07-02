//
//  Datamodel.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import CoreML


//final class DataModel {
//    var model: clip_mci_image?
//
//    init() {
//        loadModel()
//    }
//
//    func loadModel() {
//        do {
//            model = try clip_mci_image()
//            print("Model loaded successfully.")
//        } catch {
//            print("Failed to load model: \(error)")
//        }
//    }
//
//    func performInference(_ pixelBuffer: CVPixelBuffer) -> MLMultiArray? {
//        guard let model else {
//            print("Model is not loaded.")
//            return nil
//        }
//
//        do {
//            let prediction = try model.prediction(input_image: pixelBuffer)
////            print("Prediction successful.")
//            if let multiArray = prediction.featureValue(for: "var_1259")?.multiArrayValue {
//                return multiArray
//            }
//            else {
//                print("Failed to retrieve MLMultiArray.")
//                return nil
//            }
//        } catch {
//            print("Failed to perform inference: \(error)")
//            return nil
//        }
//    }
//}


//import CoreImage
//import CoreML
//import SwiftUI
//
enum DataModelError: Error {
    case modelFileNotFound
    case modelNotLoaded
    case predictionFailed
}

final class DataModel {
    var model: MLModel?
    private var configuration: MLModelConfiguration
    
    init() {
        self.configuration = MLModelConfiguration()
        self.configuration.computeUnits = .all // Por defecto, usa todas las unidades de cómputo
        
        Task {
            do {
                try await loadModel()
            } catch {
                print("Failed to load model: \(error)")
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
            print("Failed to reload model: \(error)")
        }
    }
    
    private func loadModel() async throws {
        guard let modelURL = Bundle.main.url(forResource: "clip_mci_image", withExtension: "mlmodelc") else {
            print("Current bundle URL: \(Bundle.main.bundleURL)")
            throw DataModelError.modelFileNotFound
        }
        
//        let compiledURL = try await MLModel.compileModel(at: modelURL)
        model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        print("Model loaded successfully.")
    }
    
//    func performInference(_ pixelBuffer: CVPixelBuffer) -> MLMultiArray? {
//        guard let model else {
//            print("Model is not loaded.")
//            return nil
//        }
//      
//        let input = InputFeatureProvider(pixelBuffer: pixelBuffer)
//        do {
//            let outputFeatures = try model.prediction(from: input)
//      
//            if let multiArray = outputFeatures.featureValue(for: "var_1259")?.multiArrayValue {
//                return multiArray
//            }
//            else {
//                print("Failed to retrieve MLMultiArray.")
//                return nil
//            }
//        } catch {
//            print("Failed to perform inference: \(error)")
//            return nil
//        }
//        
//    }
    func performInference(_ pixelBuffer: CVPixelBuffer) async throws -> MLMultiArray? {
        guard let model = model else {
            throw NSError(domain: "DataModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Model is not loaded"])
        }
        
        // Crear un MLFeatureProvider personalizado para la entrada
        let input = InputFeatureProvider(pixelBuffer: pixelBuffer)
        
        do {
            // Realizar la predicción
            let outputFeatures = try await model.prediction(from: input)
            // Extraer el MLMultiArray del resultado
            if let multiArray = outputFeatures.featureValue(for: "var_1259")?.multiArrayValue {
                return multiArray
            } else {
                throw NSError(domain: "DataModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve MLMultiArray from prediction"])
            }
        } catch {
            print("Failed to perform inference: \(error)")
            throw error
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

//
//Task {
//    do {
//        let result = try await dataModel.performInference(somePixelBuffer)
//        // Usar el resultado
//    } catch {
//        print("Error performing inference: \(error)")
//    }
//}
