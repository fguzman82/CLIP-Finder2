//
//  ProfilerPerformanceStats.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 2/07/24.
//

import Foundation

public func profile<T>(_ title: String, operation: () -> T) -> T {
    let startTime = DispatchTime.now()
    let result = operation()
    let endTime = DispatchTime.now()
    
    let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let timeInterval = Double(nanoTime) / 1_000_000
    
    print("\(title) - Execution time: \(timeInterval) ms")
    
    return result
}

//let result = profile("Function without arguments") {
//    funcX()
//}

//let result = profile("Function with arguments") {
//    funcY(arg1, arg2)
//}

//profile("Function wtihout return") {
//    funcZ(arg1, arg2)
//}

//let myObject = MyClass()
//let result = profile("MyClass method or structure") {
//    myObject.someMethod(arg1, arg2)
//}

public func profileAsync(_ title: String, operation: (@escaping () -> Void) -> Void, completion: @escaping (TimeInterval) -> Void) {
    let startTime = DispatchTime.now()
    
    operation {
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000
        
        print("\(title) - Execution time: \(timeInterval) ms")
        completion(timeInterval)
    }
}

//public func AsyncProfileModel(_ title: String, operation: (@escaping () -> Void) -> Void, completion: @escaping (TimeInterval) -> Void, storeIn: ((Double) -> Void)? = nil) {
//    let startTime = DispatchTime.now()
//    
//    operation {
//        let endTime = DispatchTime.now()
//        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//        let timeInterval = Double(nanoTime) / 1_000_000
//        
////        print("\(title) - Execution time: \(timeInterval) ms")
//        storeIn?(timeInterval)
//        completion(timeInterval)
//    }
//}

//public func AsyncProfileModel(_ title: String, operation: (@escaping () -> Void) -> Void, storeIn: ((Double) -> Void)? = nil) {
//    let startTime = DispatchTime.now()
//    
//    operation {
//        let endTime = DispatchTime.now()
//        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//        let timeInterval = Double(nanoTime) / 1_000_000
//        
//        storeIn?(timeInterval)
//    }
//}

public func AsyncProfileModel(_ title: String, operation: @escaping (@escaping () -> Void) -> Void, storeIn: ((Double) -> Void)? = nil) async {
    let startTime = DispatchTime.now()
    
    await withCheckedContinuation { continuation in
        operation {
            let endTime = DispatchTime.now()
            let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000
            
            storeIn?(timeInterval)
            continuation.resume()
        }
    }
}



//public func profileAsync(_ title: String, operation: @escaping (@escaping () -> Void) async throws -> Void, completion: @escaping (TimeInterval) -> Void) {
//    Task {
//        let startTime = DispatchTime.now()
//        do {
//            try await operation {
//                let endTime = DispatchTime.now()
//                let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
//                let timeInterval = Double(nanoTime) / 1_000_000
//
//                print("\(title) - Execution time: \(timeInterval) ms")
//                completion(timeInterval)
//            }
//        } catch {
//            print("Error in profiled operation '\(title)': \(error)")
//            completion(-1)
//        }
//    }
//}

//profileAsync("processAndCachePhotos") { done in
//    self.processAndCachePhotos {
//        done()
//    }
//} completion: { time in
//    print("Procesamiento y caché completados en \(time) ms")
//}

//profileAsync("AsyncOperation") { done in
//    DispatchQueue.main.async {
//        // Tu código asíncrono aquí
//        // Por ejemplo:
//        self.processAndCachePhotos()
//        done()
//    }
//} completion: { time in
//    print("Operación completada en \(time) ms")
//}


class PerformanceStats: ObservableObject {
    static let shared = PerformanceStats()
    
    private init() {}
    
    @Published var clipMCIImagePredictionTimes: [Double] = []
    @Published var clipTextPredictionTimes: [Double] = []
    
    func addClipMCIImagePredictionTime(_ time: Double) {
        clipMCIImagePredictionTimes.append(time)
    }
    
    func addClipTextPredictionTime(_ time: Double) {
        clipTextPredictionTimes.append(time)
    }
    
    func averageClipMCIImagePredictionTime() -> Double {
        guard !clipMCIImagePredictionTimes.isEmpty else { return 0 }
        return clipMCIImagePredictionTimes.reduce(0, +) / Double(clipMCIImagePredictionTimes.count)
    }
    
    func averageClipTextPredictionTime() -> Double {
        guard !clipTextPredictionTimes.isEmpty else { return 0 }
        return clipTextPredictionTimes.reduce(0, +) / Double(clipTextPredictionTimes.count)
    }
}
