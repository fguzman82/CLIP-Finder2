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
    @Published var assetsByID: [String: PHAsset] = [:]
    @Published var topPhotoIDs: [String] = []
    @Published var isGalleryEmpty: Bool = true
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Float = 0
    @Published var processedPhotosCount: Int = 0
    @Published var totalPhotosCount: Int = 0
    @Published var isCameraActive = false
    @Published var isPaused = false
    @Published var useAsyncImageSearch: Bool = false
    @Published var numberOfFilteredPhotos: Int = 50

    private var customTokenizer: CLIPTokenizer?
    private var clipTextModel: CLIPTextModel
    private var clipImageModel: CLIPImageModel
    private var cameraManager: CameraManager
    private var cachedPhotoVectors: [String: MLMultiArray] = [:]
    private var searchTask: Task<Void, Never>?
    private var wasPlayingBeforeTurbo: Bool = false
    var isSearchingAsync = false
    
    private let userDefaults = UserDefaults.standard
    private let initialProcessKey = "hasPerformedInitialProcess"

    var onFrameCaptured: ((CIImage) -> Void)?

    init() {
        self.cameraManager = CameraManager()
        self.clipImageModel = CLIPImageModel()
        self.clipTextModel = CLIPTextModel()
        setupTokenizer()
        setupCameraManager()
        
    }
    
    private func checkForInitialProcess() async -> Bool {
        let hasPerformedInitialProcess = userDefaults.bool(forKey: initialProcessKey)
        
        if !hasPerformedInitialProcess {
            userDefaults.set(true, forKey: initialProcessKey)
            return true
        }
        return false
    }

    private func setupTokenizer() {
        guard let bpePath = Bundle.main.path(forResource: "bpe_simple_vocab_16e6", ofType: "txt") else {
            fatalError("bpe_simple_vocab_16e6 File not found")
        }
        customTokenizer = CLIPTokenizer(bpePath: bpePath)
    }

    private func setupCameraManager() {
        cameraManager.onFrameCaptured = { [weak self] ciImage in
            guard let self = self, self.isCameraActive, !self.isPaused else { return }
            self.performImageSearch(from: ciImage)
            self.onFrameCaptured?(ciImage)
        }
    }

    func loadData() {
        Task {
            await MainActor.run {
                isLoading = true
                updateGalleryStatus()
            }

            let initialProcessNeeded = await checkForInitialProcess()

            if initialProcessNeeded {
                reprocessPhotos()
                return
            }
            
            await loadAssetsFromPhotoLibrary()
            await loadCachedVectors()
            await cleanupDeletedPhotos()
            
            let unprocessedAssets = assets.filter { !cachedPhotoVectors.keys.contains($0.localIdentifier) }
            if !unprocessedAssets.isEmpty {
                await processAndCachePhotos(unprocessedAssets)
            }

            await MainActor.run {
                isLoading = false
                updateGalleryStatus()
            }
        }
    }

    private func loadAssetsFromPhotoLibrary() async {
        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        let (assets, assetsByID) = await withCheckedContinuation { continuation in
            var newAssets: [PHAsset] = []
            allPhotos.enumerateObjects { asset, _, _ in
                newAssets.append(asset)
            }

            let newAssetsByID = Dictionary(newAssets.map { ($0.localIdentifier, $0) },
                                           uniquingKeysWith: { a,b in a})
            continuation.resume(returning: (newAssets, newAssetsByID))
        }

        await MainActor.run {
            self.assets = assets
            self.assetsByID = assetsByID
        }
    }

    private func loadCachedVectors() async {
        self.cachedPhotoVectors = await CoreDataManager.shared.fetchAllPhotoVectors()
    }
    
    private func cleanupDeletedPhotos() async {
        let currentPhotoIDs = Set(assets.map { $0.localIdentifier })
        let cachedPhotoIDs = Set(cachedPhotoVectors.keys)

        let deletedPhotoIDs = cachedPhotoIDs.subtracting(currentPhotoIDs)

        if !deletedPhotoIDs.isEmpty {
            await MainActor.run {
                for id in deletedPhotoIDs {
                    cachedPhotoVectors.removeValue(forKey: id)
                }
            }

            await CoreDataManager.shared.deleteVectors(for: Array(deletedPhotoIDs))
        }
    }

    // Batch Processing BS = 512
    private func processAndCachePhotos(_ assetsToProcess: [PHAsset]) async {
        guard !assetsToProcess.isEmpty else { return }

        await MainActor.run {
            isProcessing = true
            totalPhotosCount = assetsToProcess.count
            processedPhotosCount = 0
            processingProgress = 0
            updateGalleryStatus()
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        let targetSize = CGSize(width: 256, height: 256)
        let backgroundContext = CoreDataManager.shared.backgroundContext()

        let batchSize = 512
        let batches = stride(from: 0, to: assetsToProcess.count, by: batchSize).map {
            Array(assetsToProcess[$0..<min($0 + batchSize, assetsToProcess.count)])
        }

        for batch in batches {
            let results = await withTaskGroup(of: (String, CVPixelBuffer?).self) { group in
                for asset in batch {
                    group.addTask {
                        let identifier = asset.localIdentifier
                        guard let image = await self.requestImage(for: asset, targetSize: targetSize, options: options) else {
                            return (identifier, nil)
                        }
                        let pixelBuffer = Preprocessing.preprocessImageWithCoreImage(image, targetSize: targetSize)
                        return (identifier, pixelBuffer)
                    }
                }

                var batchResults: [(String, CVPixelBuffer?)] = []
                for await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }

            let validResults = results.compactMap { identifier, pixelBuffer -> (String, CVPixelBuffer)? in
                guard let pixelBuffer = pixelBuffer else { return nil }
                return (identifier, pixelBuffer)
            }

            let pixelBuffers = validResults.map { $0.1 }
            let identifiers = validResults.map { $0.0 }

            do {
                let vectors = try clipImageModel.performInferenceBatch(pixelBuffers)
                for (identifier, vector) in zip(identifiers, vectors) {
                    await MainActor.run {
                        cachedPhotoVectors[identifier] = vector
                    }
                    CoreDataManager.shared.saveVector(vector, for: identifier, in: backgroundContext)
                }
            } catch {
                print("Error performing batch inference: \(error)")
            }

            let processedCount = identifiers.count
            await MainActor.run {
                processedPhotosCount += processedCount
                processingProgress = Float(processedPhotosCount) / Float(totalPhotosCount)
            }
        }

        try? await backgroundContext.perform {
            try backgroundContext.save()
        }

        await MainActor.run {
            isProcessing = false
            processingProgress = 1.0
            updateGalleryStatus()
        }
    }

    private func requestImage(for asset: PHAsset, targetSize: CGSize, options: PHImageRequestOptions) async -> UIImage? {
        await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    

    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.loadData()
                } else {
                    print("Photo library access denied.")
                    self?.isGalleryEmpty = true
                }
            }
        }
    }
    
    func syncWithPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.loadData()
                } else {
                    print("Photo library access denied.")
                }
            }
        }
    }

    private func updateGalleryStatus() {
        isGalleryEmpty = assets.isEmpty
    }

    func processTextSearch(_ searchText: String) {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
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
    
    func updateFilteredPhotoCount(_ newCount: Int) {
        let totalAvailablePhotos = assets.count
        numberOfFilteredPhotos = min(newCount, totalAvailablePhotos)
        
        if !topPhotoIDs.isEmpty {
            performSearch(lastSearchText)
        }
    }
    
    private var lastSearchText: String = ""

    private func performSearch(_ searchText: String) {
        guard !isGalleryEmpty else { return }
        guard let tokenizer = customTokenizer else { return }

        let tokens = tokenizer.tokenize(texts: [searchText])
        lastSearchText = searchText

        Task {
            do {
                if let textFeatures = try await clipTextModel.performInference(tokens[0]) {
                    let topIDs = calculateAndPrintTopPhotoIDs(textFeatures: textFeatures)
                    await MainActor.run {
                        self.topPhotoIDs = topIDs
                    }
                }
            } catch {
                print("Error performing CLIP text inference: \(error)")
            }
        }
    }

    func performImageSearch(from ciImage: CIImage) {
        if useAsyncImageSearch {
            if !isSearchingAsync {
                Task {
                    await performImageSearchAsync(from: ciImage)
                }
            }
        } else {
            performImageSearchSync(from: ciImage)
        }
    }

    func performImageSearchSync(from ciImage: CIImage) {
        guard !isGalleryEmpty, isCameraActive else { return }
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)

        guard let pixelBuffer = Preprocessing.preprocessImageWithCoreImage(uiImage, targetSize: CGSize(width: 256, height: 256)) else { return }

        guard let imageFeatures = clipImageModel.performInferenceSync(pixelBuffer) else { return }

        let topIDs = calculateAndPrintTopPhotoIDs(textFeatures: imageFeatures)
        DispatchQueue.main.async {
            self.topPhotoIDs = topIDs
        }
    }

    func performImageSearchAsync(from ciImage: CIImage) async {
        guard isCameraActive else { return }
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)

        guard let pixelBuffer = Preprocessing.preprocessImageWithCoreImage(uiImage, targetSize: CGSize(width: 256, height: 256)) else { return }
        do {
            await MainActor.run {
                self.isSearchingAsync = true
            }
            
            if let imageFeatures = try await clipImageModel.performInference(pixelBuffer) {
                let topIDs = await Task {
                    calculateAndPrintTopPhotoIDs(textFeatures: imageFeatures)
                }.value
                await MainActor.run {
                    self.topPhotoIDs = topIDs
                    self.isSearchingAsync = false
                }
            }
        } catch {
            print("Error performing inference: \(error)")
        }
    }

    private func calculateAndPrintTopPhotoIDs(textFeatures: MLMultiArray) -> [String] {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let graph = MPSGraph()
        let textFeaturesArray = MPSGraphExtensions.convertTextFeaturesToMPSNDArray(textFeatures: textFeatures, device: device)

        let photoVectors = Array(cachedPhotoVectors.values)
        let photoIDs = Array(cachedPhotoVectors.keys)

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
        
        let availablePhotoCount = photoIDs.count
        let actualNumberOfFilteredPhotos = min(numberOfFilteredPhotos, availablePhotoCount)

        let bestPhotoIDs = bestPhotoIndices.prefix(actualNumberOfFilteredPhotos).map { photoIDs[$0] }

        return bestPhotoIDs
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
                completion(granted)
            }
        }
    }

    func reprocessPhotos() {
        Task {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    CoreDataManager.shared.deleteAllData()
                    continuation.resume()
                }
            }
            
            await MainActor.run {
                self.cachedPhotoVectors.removeAll()
                self.processedPhotosCount = 0
                self.totalPhotosCount = 0
                self.loadData()
            }
        }
    }
}
