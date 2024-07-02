//
//  Profiler.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 1/07/24.
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
