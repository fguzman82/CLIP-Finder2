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
    @Published var isGalleryEmpty: Bool = true
    
    private var customTokenizer: CLIPTokenizer?
    private var clipTextModel: CLIPTextModel
    private var clipImageModel: CLIPImageModel
    private var searchTask: Task<Void, Never>?
    @Published var isCameraActive = false
    @Published var isPaused = false
    var onFrameCaptured: ((CIImage) -> Void)?
    private var cameraManager: CameraManager
    @Published var processingProgress: Float = 0
    @Published var processedPhotosCount: Int = 0
    @Published var totalPhotosCount: Int = 0
    @Published var isProcessing: Bool = false
    @Published var useAsyncImageSearch: Bool = false
    private var wasPlayingBeforeTurbo: Bool = false
    
    private var updateTimer: Timer?
    
    
    init() {
        self.cameraManager = CameraManager()
        self.clipImageModel = CLIPImageModel()
        self.clipTextModel = CLIPTextModel()
        setupTokenizer()
        setupCameraManager()
    }
    
    private func setupCameraManager() {
        cameraManager.onFrameCaptured = { [weak self] ciImage in
            guard let self = self, self.isCameraActive, !self.isPaused else { return }
            self.performImageSearch(from: ciImage)
//            Task {
//                await self.performImageSearch(from: ciImage)
//            }
            
            self.onFrameCaptured?(ciImage)
        }
    }
    
    func startCamera() {
        isCameraActive = true
        isPaused = false
        cameraManager.startRunning()
    }

    func stopCamera() {
        isCameraActive = false
        isPaused = false
        cameraManager.stopRunning()
    }
    
    func pauseCamera() {
        isPaused = true
        cameraManager.pauseCapture()
    }

    func resumeCamera() {
        isPaused = false
        cameraManager.resumeCapture()
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            cameraManager.pauseCapture()
        } else {
            cameraManager.resumeCapture()
        }
    }
    
    func prepareTurboToggle() {
        wasPlayingBeforeTurbo = !isPaused
        if !isPaused {
            togglePause()
        }
    }

    func finalizeTurboToggle() {
        if wasPlayingBeforeTurbo && isPaused {
            togglePause()
        }
    }

    func toggleTurboMode() {
        useAsyncImageSearch.toggle()
    }
    
    func getCameraSession() -> AVCaptureSession {
        return cameraManager.session
    }

    func focusCamera(at point: CGPoint) {
        cameraManager.focusAtPoint(point)
    }

    func switchCamera() {
        cameraManager.switchCamera()
        if isPaused {
            
            cameraManager.resumeCapture()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.cameraManager.pauseCapture()
            }
        }
        objectWillChange.send()
    }
    
    
    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    #if DEBUG
                    print("Camera access granted")
                    #endif
                } else {
                    #if DEBUG
                    print("Camera access denied")
                    #endif
                }
                completion(granted)
            }
        }
    }
    
    private func updateGalleryStatus() {
        isGalleryEmpty = assets.isEmpty
    }

    private func setupTokenizer() {
        guard let bpePath = Bundle.main.path(forResource: "bpe_simple_vocab_16e6", ofType: "txt") else {
            fatalError("No se pudo encontrar el archivo BPE en el bundle")
        }
        customTokenizer = CLIPTokenizer(bpePath: bpePath)
    }
    
    func processTextSearch(_ searchText: String) {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            #if DEBUG
            print("Search text is empty, skipping search")
            #endif
            
            DispatchQueue.main.async {
                self.topPhotoIDs = []
            }
            return
        }
        
        searchTask = Task {
            
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                performSearch(searchText)
            }
        }
    }

    private func performSearch(_ searchText: String) {
        guard !isGalleryEmpty else {
            #if DEBUG
            print("Cannot perform search: Photo gallery is empty")
            #endif
            return
        }
        
        guard let tokenizer = customTokenizer else {
            #if DEBUG
            print("Tokenizer not initialized")
            #endif
            return
        }
        
        let tokens = tokenizer.tokenize(texts: [searchText])

        Task {
            do {
                if let textFeatures = try await clipTextModel.performInference(tokens[0]) {
                    let topIDs = calculateAndPrintTopPhotoIDs(textFeatures: textFeatures)
                    await MainActor.run {
                        self.topPhotoIDs = topIDs
                    }
                } else {
                    #if DEBUG
                    print("Failed to get text features from CLIP text model")
                    #endif
                }
            } catch {
                #if DEBUG
                print("Error performing CLIP text inference: \(error)")
                #endif
            }
        }
    }
    
    func performImageSearch(from ciImage: CIImage) {
        if useAsyncImageSearch {
            Task {
                await performImageSearchAsync(from: ciImage)
            }
        } else {
            performImageSearchSync(from: ciImage)
        }
    }
    
    func performImageSearchSync(from ciImage: CIImage) {
        guard !isGalleryEmpty else {
            #if DEBUG
            print("Cannot perform search: Photo gallery is empty")
            #endif
            return
        }
        guard isCameraActive else { return }
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)

        guard let pixelBuffer = Preprocessing.preprocessImage(uiImage, targetSize: CGSize(width: 256, height: 256)) else { return }

        guard let imageFeatures = clipImageModel.performInferenceSync(pixelBuffer) else { return }

        let topIDs = calculateAndPrintTopPhotoIDs(textFeatures: imageFeatures)
        DispatchQueue.main.async {
            self.topPhotoIDs = topIDs
        }
    }
    
    // Async implementation of performImageSearch
    func performImageSearchAsync(from ciImage: CIImage) async {
        guard isCameraActive else {
            #if DEBUG
            print("Camera is not active, skipping image search")
            #endif
            return
        }
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            #if DEBUG
            print("Failed to create CGImage from CIImage")
            #endif
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        guard let pixelBuffer = Preprocessing.preprocessImage(uiImage, targetSize: CGSize(width: 256, height: 256)) else {
            #if DEBUG
            print("Failed to preprocess image")
            #endif
            return
        }
        
        do {
            if let imageFeatures = try await clipImageModel.performInference(pixelBuffer) {
                let topIDs = calculateAndPrintTopPhotoIDs(textFeatures: imageFeatures)
                await MainActor.run {
                    self.topPhotoIDs = topIDs
                }
            } else {
                #if DEBUG
                print("Clip Image Inference returned nil.")
                #endif
            }
        } catch {
            #if DEBUG
            print("Error performing inference: \(error)")
            #endif
        }
    }


    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.fetchPhotos()
            } else {
                #if DEBUG
                print("Photo library access denied.")
                #endif
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
                self.updateGalleryStatus()
//                self.processAndCachePhotos()
                if !self.isGalleryEmpty {
                    profileAsync("processAndCachePhotos") { done in
                        self.processAndCachePhotos {
                            done()
                        }
                    } completion: { time in
                        #if DEBUG
                        print("Process and cache completted in \(time) ms")
                        #endif
                    }
                }
            }
        }
    }

    private func processAndCachePhotos(completion: @escaping () -> Void) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat

        DispatchQueue.global(qos: .userInitiated).async {
            let targetSize = CGSize(width: 256, height: 256)
            let totalPhotosCount = self.assets.count
            var localProcessedCount = 0
            let group = DispatchGroup()
            let countQueue = DispatchQueue(label: "com.CLIP-Finder.processedCountQueue")
            let backgroundContext = CoreDataManager.shared.backgroundContext()

            DispatchQueue.main.async {
                self.isProcessing = true
                self.totalPhotosCount = totalPhotosCount
                self.updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    DispatchQueue.main.async {
                        countQueue.sync {
                            self.processedPhotosCount = localProcessedCount
                            self.processingProgress = Float(localProcessedCount) / Float(totalPhotosCount)
                        }
                    }
                }
            }

            for asset in self.assets {
                group.enter()
                let identifier = asset.localIdentifier

                if CoreDataManager.shared.fetchVector(for: identifier, in: backgroundContext) != nil {
                    countQueue.sync {
                        localProcessedCount += 1
                    }
                    group.leave()
                } else {
                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, _ in
                        guard let self = self else {
                            group.leave()
                            return
                        }

                        if let image = image, let pixelBuffer = Preprocessing.preprocessImage(image, targetSize: targetSize) {
                            let pixelBufferCopy = pixelBuffer
                            Task {
                                do {
                                    if let vector = try await self.clipImageModel.performInference(pixelBufferCopy) {
                                        CoreDataManager.shared.saveVector(vector, for: identifier, in: backgroundContext)
                                    } else {
                                        let error = NSError(domain: "CLIPImageModel",
                                                            code: 1,
                                                            userInfo: [NSLocalizedDescriptionKey: "Inference returned nil for asset \(identifier)"])
                                        throw error
                                    }
                                    countQueue.sync {
                                        localProcessedCount += 1
                                    }
                                } catch {
                                    if let nsError = error as NSError? {
                                        #if DEBUG
                                        print("Error performing inference: \(nsError.localizedDescription)")
                                        print("Error domain: \(nsError.domain), code: \(nsError.code)")
                                        #endif
                                    } else {
                                        #if DEBUG
                                        print("Unknown error occurred: \(error)")
                                        #endif
                                    }
                                    countQueue.sync {
                                        localProcessedCount += 1
                                    }
                                }
                                group.leave()
                            }
                        } else {
                            countQueue.sync {
                                localProcessedCount += 1
                            }
                            group.leave()
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.updateTimer?.invalidate()
                countQueue.sync {
                    self.processedPhotosCount = localProcessedCount
                    self.processingProgress = 1.0
                }
                self.isProcessing = false
                completion()
            }
        }
    }

    
    func reprocessPhotos() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            CoreDataManager.shared.deleteAllData()
            
            DispatchQueue.main.async {
                profileAsync("processAndCachePhotos") { done in
                    self.processAndCachePhotos {
                        done()
                    }
                } completion: { time in
                    #if DEBUG
                    print("Process and cache completed in \(time) ms")
                    print("Avg CLIP MCI Image Prediction Time: \(PerformanceStats.shared.averageClipMCIImagePredictionTime()) ms")
                    print("Number of samples: \(PerformanceStats.shared.clipMCIImagePredictionTimes.count)")
                    #endif
                }
            }
            
        }
    }
    
    // Post-processing function in MPSGraph for calculating similarities and selecting TopPhotosIDs
    private func calculateAndPrintTopPhotoIDs(textFeatures: MLMultiArray) -> [String] {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let graph = MPSGraph()
        let textFeaturesArray = MPSGraphExtensions.convertTextFeaturesToMPSNDArray(textFeatures: textFeatures, device: device)
        
        let photoVectorsWithIDs = CoreDataManager.shared.fetchAllPhotoVectors()

        let photoVectors = photoVectorsWithIDs.map { $0.vector }
        let photoIDs = photoVectorsWithIDs.map { $0.id }
        
        let photoFeaturesDescriptor = MPSNDArrayDescriptor(dataType: .float16, shape: [NSNumber(value: photoVectors.count), 512])
        
        let photoFeatures = MPSNDArray(device: device, descriptor: photoFeaturesDescriptor)
        
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
        
        let textTensor = graph.placeholder(shape: [1, 512] as [NSNumber], dataType: .float16, name: "text_features")
        let photoTensor = graph.placeholder(shape: [NSNumber(value: photoVectors.count), 512] as [NSNumber], dataType: .float16, name: "photo_features")
        
        let similaritiesTensor = MPSGraphExtensions.calculateSimilarities(graph: graph, textTensor: textTensor, photoTensor: photoTensor)

        let textFeaturesData = MPSGraphTensorData(textFeaturesArray)
        let photoFeaturesData = MPSGraphTensorData(photoFeatures)

        let results = graph.run(with: device.makeCommandQueue()!, feeds: [textTensor: textFeaturesData, photoTensor: photoFeaturesData], targetTensors: [similaritiesTensor], targetOperations: nil)
        let similaritiesNDArray = results[similaritiesTensor]?.mpsndarray()
        
        var similarities = [Float16](repeating: 0, count: photoVectors.count)
        similaritiesNDArray?.readBytes(&similarities, strideBytes: nil)
        
        let bestPhotoIndices = similarities.enumerated().sorted(by: { $0.element > $1.element }).map { $0.offset }
        
        let bestPhotoIDs = bestPhotoIndices.prefix(48).map { photoIDs[$0] }
        
        return bestPhotoIDs
    }
    
    
}


















