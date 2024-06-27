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
//                // Inspeccionar el MLMultiArray
//                print("MLMultiArray inspection:")
//                print("Count: \(multiArray.count)")
//                // Desglosar el tipo de datos
//                switch multiArray.dataType {
//                case .int32:
//                    print("Data Type: int32")
//                case .float16:
//                    print("Data Type: float16")
//                case .float32:
//                    print("Data Type: float32")
//                case .double:
//                    print("Data Type: double")
//                default:
//                    print("Data Type: unknown")
//                }
//                print("Shape: \(multiArray.shape)")
//                print("Strides: \(multiArray.strides)")
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
