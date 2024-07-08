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

class Preprocessing {
    static let device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        return device
    }()
    
    static let commandQueue: MTLCommandQueue = {
        guard let queue = device.makeCommandQueue() else {
            fatalError("Could not create Metal command queue")
        }
        return queue
    }()
    
    static func preprocessImage(_ image: UIImage, targetSize: CGSize) -> CVPixelBuffer? {
        guard let inputTexture = loadTexture(from: image),
              let outputTexture = makeTexture(descriptor: descriptor(for: targetSize)) else {
            #if DEBUG
            print("Failed to create textures")
            #endif
            return nil
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let bilinearScale = MPSImageBilinearScale(device: device)
        bilinearScale.encode(commandBuffer: commandBuffer!,
                             sourceTexture: inputTexture,
                             destinationTexture: outputTexture)
        
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        return convertToPixelBuffer(texture: outputTexture)
    }
    
    private static func loadTexture(from image: UIImage) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        return try? textureLoader.newTexture(cgImage: image.cgImage!, options: nil)
    }
    
    private static func makeTexture(descriptor: MTLTextureDescriptor) -> MTLTexture? {
        return device.makeTexture(descriptor: descriptor)
    }
    
    private static func descriptor(for size: CGSize) -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                  width: Int(size.width),
                                                                  height: Int(size.height),
                                                                  mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        return descriptor
    }
    
    private static func convertToPixelBuffer(texture: MTLTexture) -> CVPixelBuffer? {
        let ciImage = CIImage(mtlTexture: texture, options: nil)
        let context = CIContext(mtlDevice: device)
        
        var pixelBuffer: CVPixelBuffer?
        let pixelBufferOptions: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        let width = texture.width
        let height = texture.height
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, pixelBufferOptions as CFDictionary, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            #if DEBUG
            print("Failed to create CVPixelBuffer")
            #endif
            return nil
        }
        
        context.render(ciImage!, to: buffer)
        return buffer
    }
}

