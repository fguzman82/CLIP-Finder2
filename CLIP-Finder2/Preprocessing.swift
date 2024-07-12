//
//  Preprocessing.swift
//  CLIP-Finder2
//
//  Created by Fabio Guzman on 24/06/24.
//

import UIKit
import Metal
import MetalKit
import MetalPerformanceShaders

import UIKit
import CoreImage

//class Preprocessing {
//    static let device: MTLDevice = {
//        guard let device = MTLCreateSystemDefaultDevice() else {
//            fatalError("Metal is not supported on this device")
//        }
//        return device
//    }()
//    
//    static let commandQueue: MTLCommandQueue = {
//        guard let queue = device.makeCommandQueue() else {
//            fatalError("Could not create Metal command queue")
//        }
//        return queue
//    }()
//    
//    static func preprocessImage(_ image: UIImage, targetSize: CGSize) -> CVPixelBuffer? {
//        guard let inputTexture = loadTexture(from: image),
//              let outputTexture = makeTexture(descriptor: descriptor(for: targetSize)) else {
//            #if DEBUG
//            print("Failed to create textures")
//            #endif
//            return nil
//        }
//
//        let commandBuffer = commandQueue.makeCommandBuffer()
//        let bilinearScale = MPSImageBilinearScale(device: device)
//        bilinearScale.encode(commandBuffer: commandBuffer!,
//                             sourceTexture: inputTexture,
//                             destinationTexture: outputTexture)
//        
//        commandBuffer?.commit()
//        commandBuffer?.waitUntilCompleted()
//        
//        return convertToPixelBuffer(texture: outputTexture)
//    }
//    
//    private static func loadTexture(from image: UIImage) -> MTLTexture? {
//        let textureLoader = MTKTextureLoader(device: device)
//        return try? textureLoader.newTexture(cgImage: image.cgImage!, options: nil)
//    }
//    
//    private static func makeTexture(descriptor: MTLTextureDescriptor) -> MTLTexture? {
//        return device.makeTexture(descriptor: descriptor)
//    }
//    
//    private static func descriptor(for size: CGSize) -> MTLTextureDescriptor {
//        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
//                                                                  width: Int(size.width),
//                                                                  height: Int(size.height),
//                                                                  mipmapped: false)
//        descriptor.usage = [.shaderRead, .shaderWrite]
////        descriptor.storageMode = .shared
//        return descriptor
//    }
//    
//    private static func convertToPixelBuffer(texture: MTLTexture) -> CVPixelBuffer? {
//        let ciImage = CIImage(mtlTexture: texture, options: nil)
//        let context = CIContext(mtlDevice: device)
//        
//        var pixelBuffer: CVPixelBuffer?
//        let pixelBufferOptions: [String: Any] = [
//            kCVPixelBufferCGImageCompatibilityKey as String: true,
//            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
//            kCVPixelBufferMetalCompatibilityKey as String: true
//        ]
//        
//        let width = texture.width
//        let height = texture.height
//        
//        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, pixelBufferOptions as CFDictionary, &pixelBuffer)
//        
//        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//            #if DEBUG
//            print("Failed to create CVPixelBuffer")
//            #endif
//            return nil
//        }
//        
//        context.render(ciImage!, to: buffer)
//        return buffer
//    }
//}
//

class Preprocessing {

    static let context = CIContext(options: [.useSoftwareRenderer : false])

    static func preprocessImageWithCoreImage(_ image: UIImage, targetSize: CGSize) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Calcular la escala
        let scaleX = targetSize.width / ciImage.extent.width
        let scaleY = targetSize.height / ciImage.extent.height
        let scale = min(scaleX, scaleY)

        // Crear el filtro de escala bilineal
        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            print("Failed to create CILanczosScaleTransform filter")
            return nil
        }

        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)  // 1.0 para interpolación bilineal

        guard let outputImage = scaleFilter.outputImage else {
            print("Failed to get output image from scale filter")
            return nil
        }

        // Recortar la imagen al tamaño exacto si es necesario
        let cropRect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        let croppedImage = outputImage.cropped(to: cropRect)

        // Crear un CVPixelBuffer
        let pixelBuffer = createPixelBuffer(width: Int(targetSize.width), height: Int(targetSize.height))

        guard let buffer = pixelBuffer else {
            print("Failed to create pixel buffer")
            return nil
        }

        // Renderizar la imagen CIImage en el CVPixelBuffer
        context.render(croppedImage, to: buffer)

        return buffer
    }

    private static func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
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

        guard status == kCVReturnSuccess else {
            print("Failed to create CVPixelBuffer: \(status)")
            return nil
        }

        return pixelBuffer
    }
}
