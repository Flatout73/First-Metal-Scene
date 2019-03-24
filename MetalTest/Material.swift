//
//  Material.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 24/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

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
        guard let sourceTexture = materialProperty.textureSamplerValue?.texture else { return nil }
        let wantMips = materialProperty.semantic != .tangentSpaceNormal
        let options: [MTKTextureLoader.Option : Any] = [ .generateMipmaps : wantMips ]
        return try? textureLoader.newTexture(texture: sourceTexture, options: options)
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
