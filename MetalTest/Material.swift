//
//  Material.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 24/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit
import Cocoa

class Material {
    var specularColor = float3(1, 1, 1)
    var specularPower = Float(1)
    
    var baseColorTexture: MTLTexture?
    var metallic: MTLTexture?
    var roughness: MTLTexture?
    var normal: MTLTexture?
    var emissive: MTLTexture?
    
    func texture(for semantic: MDLMaterialSemantic, in material: MDLMaterial?, textureLoader: MTKTextureLoader) -> MTLTexture? {
        guard let materialProperty = material?.property(with: semantic) else { return nil }
        let wantMips = materialProperty.semantic != .tangentSpaceNormal
        let options: [MTKTextureLoader.Option : Any] = [ .generateMipmaps : wantMips ]
        if let sourceTexture = materialProperty.textureSamplerValue?.texture {
            return try? textureLoader.newTexture(texture: sourceTexture, options: options)
 //       }
//        else if let col = materialProperty.color {
//            let flo = materialProperty.float4Value
//            let color = CGColor(red: CGFloat(flo[0]), green: CGFloat(flo[1]), blue: CGFloat(flo[2]), alpha: 1)
////            let colorSpace = CGColorSpaceCreateDeviceRGB()
////            let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
////            let context = CGBitmapContextCreate(
////                nil,
////                Int(size.width),
////                Int(size.height),
////                8,
////                0,
////                colorSpace,
////                bitmapInfo)
////
////            drawFunc(context: context)
////
////            let image = CGBitmapContextCreateImage(context)
//            let size = 1000
//            let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
//            context?.setFillColor(color)
//            context?.fill(CGRect(x: 0, y: 0, width: size, height: size))
//            let cgimage = context?.makeImage()
//            guard let image = cgimage else { return nil }
//            return try? textureLoader.newTexture(cgImage: image, options: options)
        } else {
            return nil
        }
    }
    
    init(material sourceMaterial: MDLMaterial?, textureLoader: MTKTextureLoader) {
        baseColorTexture = texture(for: .baseColor, in: sourceMaterial, textureLoader: textureLoader)
        metallic = texture(for: .metallic, in: sourceMaterial, textureLoader: textureLoader)
        roughness = texture(for: .roughness, in: sourceMaterial, textureLoader: textureLoader)
        normal = texture(for: .tangentSpaceNormal, in: sourceMaterial, textureLoader: textureLoader)
        emissive = texture(for: .emission, in: sourceMaterial, textureLoader: textureLoader)
    }
    
    init(baseColorTexture: MTLTexture?) {
        self.baseColorTexture = baseColorTexture
    }

}
