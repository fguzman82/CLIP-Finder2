//
//  CoreMLProfiler.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 2/07/24.
//

import CoreML
import Foundation
import CoreVideo
import Vision

class ModelProfiler: ObservableObject {
    static let shared = ModelProfiler()
    
    private let clipImageModel = CLIPImageModel()
    private let clipTextModel = CLIPTextModel()
    private let processingUnits: [MLComputeUnits] = [.all, .cpuOnly, .cpuAndGPU, .cpuAndNeuralEngine]
    public let processingUnitDescriptions = ["All", "CPU Only", "CPU + GPU", "CPU + ANE"]
    
    @Published var profileResultsImage: [[Double]] = Array(repeating: Array(repeating: 0, count: 10), count: 4)
    @Published var profileResultsText: [[Double]] = Array(repeating: Array(repeating: 0, count: 10), count: 4)
    
    private init() {}
    
    func runProfiler() async {
        for (index, unit) in processingUnits.enumerated() {
            await profileForUnit(unit, atIndex: index)
            await profileForUnitText(unit, atIndex: index)
        }
    }
    
    private func profileForUnit(_ unit: MLComputeUnits, atIndex index: Int) async {
        clipImageModel.setProcessingUnit(unit)
        await clipImageModel.reloadModel()
        
        guard let dummyInput = createDummyWhitePixelBuffer(width: 256, height: 256) else {
            print("Failed to create dummy input")
            return
        }
        
        for i in 0..<10 {
            do {
                await AsyncProfileModel("CLIP MCI Image Prediction") { done in
                    Task {
                        do {
                            if let _ = try await self.clipImageModel.performInference(dummyInput) {
                                done()
                            } else {
                                print("Inference returned nil")
                                done()
                            }
                        } catch {
                            print("Failed to perform inference: \(error)")
                            done()
                        }
                    }
                } storeIn: { time in
                    DispatchQueue.main.async {
                        self.profileResultsImage[index][i] = time
                        PerformanceStats.shared.addClipMCIImagePredictionTime(time)
                    }
                }
            }
        }
    }
    
    private func profileForUnitText(_ unit: MLComputeUnits, atIndex index: Int) async {
        clipTextModel.setProcessingUnit(unit)
        await clipTextModel.reloadModel()
        
        let dummyInput: [Int32] = Array(repeating: 0, count: 77)
        
        for i in 0..<10 {
            do {
                await AsyncProfileModel("CLIP Text Prediction") { done in
                    Task {
                        do {
                            if let _ = try await self.clipTextModel.performInference(dummyInput) {
                                done()
                            } else {
                                print("Text inference returned nil")
                                done()
                            }
                        } catch {
                            print("Failed to perform text inference: \(error)")
                            done()
                        }
                    }
                } storeIn: { time in
                    DispatchQueue.main.async {
                        self.profileResultsText[index][i] = time
                        PerformanceStats.shared.addClipTextPredictionTime(time)
                    }
                }
            }
        }
    }
    
    private func createDummyWhitePixelBuffer(width: Int = 256, height: Int = 256) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attributes,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Failed to create CVPixelBuffer")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            print("Failed to create CGContext")
            return nil
        }
        
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
    
    enum ModelType {
        case image
        case text
    }

    func getMedianForUnit(at index: Int, for modelType: ModelType) -> Double {
        let results = modelType == .image ? profileResultsImage : profileResultsText
        let sortedTimes = results[index].sorted()
        let count = sortedTimes.count
        if count % 2 == 0 {
            return (sortedTimes[count/2 - 1] + sortedTimes[count/2]) / 2
        } else {
            return sortedTimes[count/2]
        }
    }

    func getAverageForUnit(at index: Int, for modelType: ModelType) -> Double {
        let results = modelType == .image ? profileResultsImage : profileResultsText
        let sum = results[index].reduce(0, +)
        return sum / Double(results[index].count)
    }
}
