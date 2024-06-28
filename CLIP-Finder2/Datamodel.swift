//
//  Datamodel.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import CoreImage
import CoreML
import SwiftUI

final class DataModel {
    let context = CIContext()
    var model: clip_mci_image?

    init() {
        loadModel()
    }

    func loadModel() {
        do {
            model = try clip_mci_image()
            print("Model loaded successfully.")
        } catch {
            print("Failed to load model: \(error)")
        }
    }

    func performInference(_ pixelBuffer: CVPixelBuffer) -> MLMultiArray? {
        guard let model else {
            print("Model is not loaded.")
            return nil
        }

        do {
            let prediction = try model.prediction(input_image: pixelBuffer)
            print("Prediction successful.")
            if let multiArray = prediction.featureValue(for: "var_1259")?.multiArrayValue {
                return multiArray
            }
            else {
                print("Failed to retrieve MLMultiArray.")
                return nil
            }
            //return prediction.featureValue(for: "var_1259")?.multiArrayValue
        } catch {
            print("Failed to perform inference: \(error)")
            return nil
        }
    }
}
