//
//  PhotoGalleryViewModel.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import SwiftUI
import Photos
import CoreML
import Combine
import MetalPerformanceShaders
import MetalPerformanceShadersGraph

import CoreVideo
import CoreImage

class PhotoGalleryViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var topPhotoIDs: [String] = []
    //private var model = DataModel()
    private var customTokenizer: CLIPTokenizer?
    private var clipTextModel: CLIPTextModel
    private var model: DataModel
    
    init() {
        self.model = DataModel()
        self.clipTextModel = CLIPTextModel()
        setupTokenizer()
    }

    private func setupTokenizer() {
        guard let bpePath = Bundle.main.path(forResource: "bpe_simple_vocab_16e6", ofType: "txt") else {
            fatalError("No se pudo encontrar el archivo BPE en el bundle")
        }
        customTokenizer = CLIPTokenizer(bpePath: bpePath)
    }

    func processTextSearch(_ searchText: String) {
        guard let tokenizer = customTokenizer else {
            print("Tokenizer not initialized")
            return
        }

        let tokenStartTime = DispatchTime.now()
        let tokens = tokenizer.tokenize(texts: [searchText])
        let tokenEndTime = DispatchTime.now()
        let tokenNanoTime = tokenEndTime.uptimeNanoseconds - tokenStartTime.uptimeNanoseconds
        let tokenTimeInterval = Double(tokenNanoTime) / 1_000_000
        print("token processing time: \(tokenTimeInterval)")
        print("Tokens:", tokens)

        // Aquí puedes agregar la lógica para procesar los tokens y actualizar la vista
        // Por ejemplo, podrías llamar a calculateAndPrintTopPhotoIDs() con estos tokens
        if let textFeatures = clipTextModel.performInference(tokens: tokens[0]) {
            print(textFeatures.toFloatArray())
            let topIDs = calculateAndPrintTopPhotoIDs(textFeatures: textFeatures)
            DispatchQueue.main.async {
                self.topPhotoIDs = topIDs
            }
        } else {
            print("Failed to get text features from CLIP text model")
        }

        
    }

    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.fetchPhotos()
            } else {
                print("Photo library access denied.")
            }
        }
    }

    private func fetchPhotos() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []
            allPhotos.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            DispatchQueue.main.async {
                self.assets = assets
                self.processAndCachePhotos()
            }
        }
    }

//    private func processAndCachePhotos() {
//        let imageManager = PHImageManager.default()
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        options.deliveryMode = .highQualityFormat
//
//        DispatchQueue.main.async {
//            let targetSize = CGSize(width: 256, height: 256)
//            
//            print("cache async")
//
//            for asset in self.assets {
//                let identifier = asset.localIdentifier
//
//                if let cachedVector = CoreDataManager.shared.fetchVector(for: identifier) {
//                    // Handle the cached vector as needed
//                    print("ID: \(identifier), Vector: \(cachedVector.toFloatArray())")
//                } else {
//                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
//                        if let image = image, let pixelBuffer = Preprocessing.preprocessImage(image, targetSize: targetSize), let vector = self.model.performInference(pixelBuffer) {
//                            CoreDataManager.shared.saveVector(vector, for: identifier)
//                            print("ID: \(identifier), Vector: \(vector.toFloatArray())")
//                        }
//                    }
//                }
//            }
//
//            // Si estás utilizando `UICollectionView`, puedes eliminar o ajustar esta línea
//            // self.collectionView.reloadData()
//        }
//    }
    private func processAndCachePhotos() {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat

        DispatchQueue.main.async {
            let targetSize = CGSize(width: 256, height: 256)
            
            print("cache async")

            for asset in self.assets {
                let identifier = asset.localIdentifier

                if let cachedVector = CoreDataManager.shared.fetchVector(for: identifier) {
                    // CoreDataManager.shared.deleteAllData()
                    // Handle the cached vector as needed
                    // print("ID: \(identifier), Vector: \(cachedVector.toFloatArray())")
                } else {
                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                        if let image = image, let pixelBuffer = Preprocessing.preprocessImage(image, targetSize: targetSize), let vector = self.model.performInference(pixelBuffer) {
                            CoreDataManager.shared.saveVector(vector, for: identifier)
                            // print("ID: \(identifier), Vector: \(vector.toFloatArray())")
                        }
//                        if let dummyBuffer = self.createDummyWhitePixelBuffer(), let vector = self.model.performInference(dummyBuffer) {
//                            CoreDataManager.shared.saveVector(vector, for: identifier)
//                        }
                    }
                }
            }
//            let cpuStartTime = DispatchTime.now()
//            self.calculateAndPrintTopPhotoIDs_cpu()
//            let cpuEndTime = DispatchTime.now()
//            let cpuNanoTime = cpuEndTime.uptimeNanoseconds - cpuStartTime.uptimeNanoseconds
//            let cpuTimeInterval = Double(cpuNanoTime) / 1_000_000
//            print("cpu time: \(cpuTimeInterval) \n")
            
//            let gpuStartTime = DispatchTime.now()
//            self.calculateAndPrintTopPhotoIDs()
//            let gpuEndTime = DispatchTime.now()
//            let gpuNanoTime = gpuEndTime.uptimeNanoseconds - gpuStartTime.uptimeNanoseconds
//            let gpuTimeInterval = Double(gpuNanoTime) / 1_000_000
//            print("gpu time: \(gpuTimeInterval) \n")
            
//            // Asumiendo que el archivo se llama "bpe_simple_vocab_16e6.txt"
//            guard let bpePath = Bundle.main.path(forResource: "bpe_simple_vocab_16e6", ofType: "txt") else {
//                fatalError("No se pudo encontrar el archivo BPE en el bundle")
//            }
//            let customTokenizer = CLIPTokenizer(bpePath: bpePath)
//            let tokenStartTime = DispatchTime.now()
//            let textToTokenize = "this is a cat"
//            let tokens = customTokenizer.tokenize(texts: [textToTokenize])
//            let tokenEndTime = DispatchTime.now()
//            let tokenNanoTime = tokenEndTime.uptimeNanoseconds - tokenStartTime.uptimeNanoseconds
//            let tokenTimeInterval = Double(tokenNanoTime) / 1_000_000
//            print("token processing time: \(tokenTimeInterval) \n")
//            print("Tokens:", tokens)
            
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
    
    private func calculateAndPrintTopPhotoIDs_cpu() {
        // Obtener todos los vectores de fotos e IDs desde Core Data
        let photoVectorsWithIDs = CoreDataManager.shared.fetchAllPhotoVectors()
        let photoVectors = photoVectorsWithIDs.map { $0.vector }
        let photoIDs = photoVectorsWithIDs.map { $0.id }
        
        // Preparar los datos de entrada
        var inputVals = [Float](repeating: 0, count: photoVectors.count * 512)
        for (i, vector) in photoVectors.enumerated() {
            let floatArray = vector.toFloatArray()
            for j in 0..<512 {
                inputVals[i * 512 + j] = floatArray[j]
            }
        }

        // Crear el vector de características de texto
        let textFeatures = [Float](repeating: 1.0 / 512.0, count: 512)
        
        // Calcular similitudes
        var similarities = [Float](repeating: 0, count: photoVectors.count)
        for i in 0..<photoVectors.count {
            var similarity: Float = 0.0
            for j in 0..<512 {
                similarity += inputVals[i * 512 + j] * textFeatures[j]
            }
            similarities[i] = similarity
        }
        
        // Ordenar los índices por los valores de similitud en orden descendente
        let bestPhotoIndices = similarities.enumerated().sorted(by: { $0.element > $1.element }).map { $0.offset }
        
        // Obtener los IDs de las mejores fotos
        let bestPhotoIDs = bestPhotoIndices.prefix(10).map { photoIDs[$0] }
        
        print("Top 10 photo IDs (CPU): \(bestPhotoIDs)")
    }

    private func calculateAndPrintTopPhotoIDs(textFeatures: MLMultiArray) -> [String] {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let graph = MPSGraph()
        // let textFeatures = MPSGraphExtensions.generateTextFeatures(device: device)
        let textFeaturesArray = MPSGraphExtensions.convertTextFeaturesToMPSNDArray(textFeatures: textFeatures, device: device)
        
        // Obtener todos los vectores de fotos e IDs desde Core Data
        let photoVectorsWithIDs = CoreDataManager.shared.fetchAllPhotoVectors()
        let photoVectors = photoVectorsWithIDs.map { $0.vector }
        let photoIDs = photoVectorsWithIDs.map { $0.id }
        
        // Crear un descriptor para el MPSNDArray
        let photoFeaturesDescriptor = MPSNDArrayDescriptor(dataType: .float16, shape: [NSNumber(value: photoVectors.count), 512])
        
        // Crear el MPSNDArray utilizando el descriptor
        let photoFeatures = MPSNDArray(device: device, descriptor: photoFeaturesDescriptor)
        
        

        // let StartTime = DispatchTime.now()
        
        // mutable buffer
        let totalSize = photoVectors.count * 512 * MemoryLayout<Float16>.stride
        let buffer = UnsafeMutableBufferPointer<Float16>.allocate(capacity: totalSize / MemoryLayout<Float16>.stride)
        defer { buffer.deallocate() }

        var offset = 0
        for vector in photoVectors {
            let float16Pointer = vector.dataPointer.bindMemory(to: Float16.self, capacity: vector.count)
            buffer.baseAddress!.advanced(by: offset).initialize(from: float16Pointer, count: vector.count)
            offset += vector.count
        }
        photoFeatures.writeBytes(buffer.baseAddress!, strideBytes: nil)
        
        // Imprimir los primeros 10 elementos del buffer
//        print("Primeros 10 elementos del buffer (Float16):")
//        for i in 0..<min(1024, buffer.count) {
//            print("Elemento \(i): \(buffer[i])")
//        }
        
//        var inputVals = [Float](repeating: 0, count: photoVectors.count * 512)
//        for (i, vector) in photoVectors.enumerated() {
//            let floatArray = vector.toFloatArray()
//            for j in 0..<512 {
//                inputVals[i * 512 + j] = floatArray[j]
//            }
//        }
//        // Copiar los datos al MPSNDArray
//        photoFeatures.writeBytes(&inputVals, strideBytes: nil)
        
//        let EndTime = DispatchTime.now()
//        let NanoTime = EndTime.uptimeNanoseconds - StartTime.uptimeNanoseconds
//        let TimeInterval = Double(NanoTime) / 1_000_000
//        print("fill time: \(TimeInterval) \n")
        
//        // Copiar los datos de photoVectors al MPSNDArray
//        for (index, vector) in photoVectors.enumerated() {
//            let floatArray = vector.toFloatArray()
//            var mutableFloatArray = floatArray // Crear una copia mutable
//            mutableFloatArray.withUnsafeMutableBytes { bufferPointer in
//                photoFeatures.writeBytes(bufferPointer.baseAddress!, strideBytes: nil)
//            }
//        }

        
        // Definir placeholders
        let textTensor = graph.placeholder(shape: [1, 512] as [NSNumber], dataType: .float16, name: "text_features")
        let photoTensor = graph.placeholder(shape: [NSNumber(value: photoVectors.count), 512] as [NSNumber], dataType: .float16, name: "photo_features")
        
        let similaritiesTensor = MPSGraphExtensions.calculateSimilarities(graph: graph, textTensor: textTensor, photoTensor: photoTensor)
    
        // Crear MPSGraphTensorData para feeds
        let textFeaturesData = MPSGraphTensorData(textFeaturesArray)
        let photoFeaturesData = MPSGraphTensorData(photoFeatures)


//        // Imprimir el contenido de textFeaturesData
//        let outputNDArray = textFeaturesData.mpsndarray()
//        var outputValues = [Float16](repeating: 0, count: 512)
//        outputNDArray.readBytes(&outputValues, strideBytes: nil)
//        print("textFeaturesData: \(outputValues)")


        // Ejecutar el grafo
        let results = graph.run(with: device.makeCommandQueue()!, feeds: [textTensor: textFeaturesData, photoTensor: photoFeaturesData], targetTensors: [similaritiesTensor], targetOperations: nil)
        let similaritiesNDArray = results[similaritiesTensor]?.mpsndarray()
        
        var similarities = [Float16](repeating: 0, count: photoVectors.count)
        similaritiesNDArray?.readBytes(&similarities, strideBytes: nil)
        
        print("Similarities vector: \(similarities)")
        
        let bestPhotoIndices = similarities.enumerated().sorted(by: { $0.element > $1.element }).map { $0.offset }
        
        // Obtener los IDs de las mejores fotos
        let bestPhotoIDs = bestPhotoIndices.prefix(10).map { photoIDs[$0] }
        
        print("Top 10 photo IDs: \(bestPhotoIDs)")
        
        
        return bestPhotoIDs
    }
}

