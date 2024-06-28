//
//  CLIPTextModel.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 27/06/24.
//

import CoreML

class CLIPTextModel {
    private var model: clip_text?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            model = try clip_text(configuration: MLModelConfiguration())
            print("CLIP text model loaded successfully.")
        } catch {
            print("Failed to load CLIP text model: \(error)")
        }
    }
    
    func performInference(tokens: [Int32]) -> MLMultiArray? {
        guard let model = model else {
            print("CLIP text model is not loaded.")
            return nil
        }
        
        do {
            // Crear un MLMultiArray con los tokens
            let inputArray = try MLMultiArray(shape: [1, 77] as [NSNumber], dataType: .int32)
            for (index, token) in tokens.enumerated() {
                inputArray[index] = NSNumber(value: token)
            }
            
            // Realizar la predicción
            let prediction = try model.prediction(input_text: inputArray)
            
            print("CLIP text model prediction successful.")
            return prediction.featureValue(for: "var_475")?.multiArrayValue
        } catch {
            print("Failed to perform CLIP text model inference: \(error)")
            return nil
        }
    }
}
