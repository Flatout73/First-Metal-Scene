//
//  MTextureLoader.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 03/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit
import AppKit

class MTextureLoader {
    public static let shared = MTextureLoader()
    
    private init() { }
    
    let bytesPerPixel = 4
    let bitsPerComponent = 8
    
    func texture2D(with imageName: String, mipmapped: Bool, commandQueue: MTLCommandQueue) -> MTLTexture {
        let image = NSImage(named: imageName)!
        let imageSize = image.size
        
        let bytesPerRow = bytesPerPixel * Int(imageSize.width)
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(imageSize.width), height: Int(imageSize.height), mipmapped: mipmapped)
        textureDescriptor.usage = .shaderRead
        
        let texture = commandQueue.device.makeTexture(descriptor: textureDescriptor)!
        texture.label = imageName
        
        let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height));
        texture.replace(region: region, mipmapLevel: 0, withBytes: data(for: image)!, bytesPerRow: bytesPerRow)
        
        if mipmapped {
            generateMipmaps(for: texture, onQueue: commandQueue)
        }
        
        return texture
    }
    
    func data(for image: NSImage) -> UnsafeMutableRawPointer? {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = bytesPerPixel * width
        
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let bounds = CGRect(x: 0, y: 0, width: Int(width), height: Int(height))
        context.clear(bounds)
        
       // if flip == false{
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1.0, y: -1.0)
       // }
        
        context.draw(cgImage, in: bounds)
        
        return context.data
    }
    
    func generateMipmaps(for texture: MTLTexture, onQueue queue: MTLCommandQueue) {
        let commandBuffer = queue.makeCommandBuffer()!
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.generateMipmaps(for: texture)
        blitEncoder.endEncoding()
        commandBuffer.commit()
        // block
        commandBuffer.waitUntilCompleted()
    }
}
