# PredictionModes
## Refer to this Blog for more details: https://huggingface.co/blog/fguzman82/coreml-async-batch-prediction

## Sync prediction (sequential)
    private func processAndCachePhotos(_ assetsToProcess: [PHAsset]) async {
        guard !assetsToProcess.isEmpty else { return }

        await MainActor.run {
            isProcessing = true
            totalPhotosCount = assetsToProcess.count
            processedPhotosCount = 0
            processingProgress = 0
        }

        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        let targetSize = CGSize(width: 256, height: 256)
        let backgroundContext = CoreDataManager.shared.backgroundContext()

        for asset in assetsToProcess {
            let identifier = asset.localIdentifier

            guard let image = await withCheckedContinuation({ continuation in
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                    continuation.resume(returning: image)
                }
            }) else { continue }

            guard let pixelBuffer = Preprocessing.preprocessImageWithCoreImage(image, targetSize: targetSize) else { continue }

            do {
                if let vector = try await clipImageModel.performInference(pixelBuffer) {
                    await MainActor.run {
                        cachedPhotoVectors[identifier] = vector
                    }
                    CoreDataManager.shared.saveVector(vector, for: identifier, in: backgroundContext)
                }
            } catch {
                print("Error performing inference for asset \(identifier): \(error)")
            }

            await MainActor.run {
                processedPhotosCount += 1
                processingProgress = Float(processedPhotosCount) / Float(totalPhotosCount)
            }
        }

        try? await backgroundContext.perform {
            try backgroundContext.save()
        }

        await MainActor.run {
            isProcessing = false
            processingProgress = 1.0
        }
    }
    
    
##  Async prediction
    private func processAndCachePhotos(_ assetsToProcess: [PHAsset]) {
        guard !assetsToProcess.isEmpty else { return }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.totalPhotosCount = assetsToProcess.count
            self.processedPhotosCount = 0
            self.processingProgress = 0
        }

        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        let targetSize = CGSize(width: 256, height: 256)
        let backgroundContext = CoreDataManager.shared.backgroundContext()

        let group = DispatchGroup()

        for asset in assetsToProcess {
            group.enter()
            let identifier = asset.localIdentifier

            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, _ in
                guard let self = self, let image = image else {
                    group.leave()
                    return
                }

                guard let pixelBuffer = Preprocessing.preprocessImageWithCoreImage(image, targetSize: targetSize) else {
                    group.leave()
                    return
                }

                Task {
                    do {
                        if let vector = try await self.clipImageModel.performInference(pixelBuffer) {
                            DispatchQueue.main.async {
                                self.cachedPhotoVectors[identifier] = vector
                            }
                            CoreDataManager.shared.saveVector(vector, for: identifier, in: backgroundContext)
                        }
                    } catch {
                        print("Error performing inference for asset \(identifier): \(error)")
                    }

                    DispatchQueue.main.async {
                        self.processedPhotosCount += 1
                        self.processingProgress = Float(self.processedPhotosCount) / Float(self.totalPhotosCount)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            backgroundContext.perform {
                do {
                    try backgroundContext.save()
                } catch {
                    print("Error saving context: \(error)")
                }
            }

            self.isProcessing = false
            self.processingProgress = 1.0
        }
    }

    
    
    
 ## Batch prediction
    private func processAndCachePhotos(_ assetsToProcess: [PHAsset]) {
        guard !assetsToProcess.isEmpty else { return }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.totalPhotosCount = assetsToProcess.count
            self.processedPhotosCount = 0
            self.processingProgress = 0
        }

        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        let targetSize = CGSize(width: 256, height: 256)
        let backgroundContext = CoreDataManager.shared.backgroundContext()

        let batchSize = 128
        let batches = stride(from: 0, to: assetsToProcess.count, by: batchSize).map {
            Array(assetsToProcess[$0..<min($0 + batchSize, assetsToProcess.count)])
        }

        Task {
            for batch in batches {
                let batchResults = await withTaskGroup(of: (String, CVPixelBuffer?).self) { group in
                    for asset in batch {
                        group.addTask {
                            await self.requestImage(for: asset, targetSize: targetSize, options: options)
                        }
                    }

                    var results: [(String, CVPixelBuffer?)] = []
                    for await result in group {
                        results.append(result)
                    }
                    return results
                }

                let validBuffers = batchResults.compactMap { (identifier, buffer) -> (String, CVPixelBuffer)? in
                    guard let buffer = buffer else { return nil }
                    return (identifier, buffer)
                }

                let pixelBuffers = validBuffers.map { $0.1 }
                let identifiers = validBuffers.map { $0.0 }

                do {
                    let vectors = try self.clipImageModel.performInferenceBatch(pixelBuffers)
                    for (identifier, vector) in zip(identifiers, vectors) {
                        await MainActor.run {
                            self.cachedPhotoVectors[identifier] = vector
                        }
                        CoreDataManager.shared.saveVector(vector, for: identifier, in: backgroundContext)
                    }
                } catch {
                    print("Error performing batch inference: \(error)")
                }

                await MainActor.run {
                    self.processedPhotosCount += pixelBuffers.count
                    self.processingProgress = Float(self.processedPhotosCount) / Float(self.totalPhotosCount)
                }
            }

            await backgroundContext.perform {
                do {
                    try backgroundContext.save()
                } catch {
                    print("Error saving context: \(error)")
                }
            }

            await MainActor.run {
                self.isProcessing = false
                self.processingProgress = 1.0
            }
        }
    }

    private func requestImage(for asset: PHAsset, targetSize: CGSize, options: PHImageRequestOptions) async -> (String, CVPixelBuffer?) {
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image, let pixelBuffer = Preprocessing.preprocessImageWithCoreImage(image, targetSize: targetSize) {
                    continuation.resume(returning: (asset.localIdentifier, pixelBuffer))
                } else {
                    continuation.resume(returning: (asset.localIdentifier, nil))
                }
            }
        }
    }
 

 ###  Load data for ASync prediction
    func loadData() {
        Task {
            await MainActor.run {
                isLoading = true
                updateGalleryStatus()
            }

            await loadAssetsFromPhotoLibrary()
            await loadCachedVectors()

            let unprocessedAssets = assets.filter { !cachedPhotoVectors.keys.contains($0.localIdentifier) }
            if !unprocessedAssets.isEmpty {
                await withCheckedContinuation { continuation in
                    processAndCachePhotos(unprocessedAssets)
                    continuation.resume()
                }
            }

            await MainActor.run {
                self.isLoading = false
                self.updateGalleryStatus()
            }
        }
    }


