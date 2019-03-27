//
//  CarNode.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 24/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import Foundation

class CarNode: Node {
    let defaultTexture: MTLTexture
    let defaultNormalMap: MTLTexture
    
    override init(name: String) {
        (defaultTexture, defaultNormalMap) = HelmetNode.buildDefaultTextures(device: RenderUtils.shared.device)
        super.init(name: name)
    }
    
//    func functionConstantsForQualityLevel(quality: Int) -> MTLFunctionConstantValues
//    {
//
//    let constantValues = MTLFunctionConstantValues()
//        constantValues
//    [constantValues setConstantValue:&has_normal_map type:MTLDataTypeBool atIndex:AAPLFunctionConstantNormalMapIndex];
//    [constantValues setConstantValue:&hasBaseColorMap type:MTLDataTypeBool atIndex:AAPLFunctionConstantBaseColorMapIndex];
//    [constantValues setConstantValue:&has_metallic_map type:MTLDataTypeBool atIndex:AAPLFunctionConstantMetallicMapIndex];
//    [constantValues setConstantValue:&has_ambient_occlusion_map type:MTLDataTypeBool atIndex:AAPLFunctionConstantAmbientOcclusionMapIndex];
//    [constantValues setConstantValue:&has_roughness_map type:MTLDataTypeBool atIndex:AAPLFunctionConstantRoughnessMapIndex];
//    [constantValues setConstantValue:&has_irradiance_map type:MTLDataTypeBool atIndex:AAPLFunctionConstantIrradianceMapIndex];
//
//    return constantValues;
//    }
    
    var customRenderer: AAPLRenderer!
    var view: MTKView!
    override func loadAssets(_ device: MTLDevice, view: MTKView) {
        self.view = view
        customRenderer = AAPLRenderer(metalKitView: view)
    }
    
    func loadCar(device: MTLDevice, pipelineStateDescriptor: MTLRenderPipelineDescriptor) {
        guard let modelURL = Bundle.main.url(forResource: "firetruck", withExtension: "obj") else {
            fatalError("Could not find model file in app bundle")
        }
        
//        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
//                                                            format: .float3,
//                                                            offset: 0,
//                                                            bufferIndex: 0)
//        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
//                                                            format: .float2,
//                                                            offset: 0,
//                                                            bufferIndex: 1)
//        vertexDescriptor.attributes[3] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
//                                                            format: .half4,
//                                                            offset: 8,
//                                                            bufferIndex: 1)
//        vertexDescriptor.attributes[4] = MDLVertexAttribute(name: MDLVertexAttributeTangent,
//                                                            format: .half4,
//                                                            offset: 16,
//                                                            bufferIndex: 1)
//        vertexDescriptor.attributes[5] = MDLVertexAttribute(name: MDLVertexAttributeBitangent,
//                                                            format: .half4,
//                                                            offset: 24,
//                                                            bufferIndex: 1)
        
 //       vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 12)
 //       vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 32)
     
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: VertexBufferIndex.attributes.rawValue)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float3,
                                                            offset: MemoryLayout<Float>.size * 3,
                                                            bufferIndex: VertexBufferIndex.attributes.rawValue)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTangent,
                                                            format: .float3,
                                                            offset: MemoryLayout<Float>.size * 6,
                                                            bufferIndex: VertexBufferIndex.attributes.rawValue)
        vertexDescriptor.attributes[3] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                            format: .float2,
                                                            offset: MemoryLayout<Float>.size * 9,
                                                            bufferIndex: VertexBufferIndex.attributes.rawValue)
        vertexDescriptor.layouts[VertexBufferIndex.attributes.rawValue] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 11)
        
        pipelineStateDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: modelURL, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        asset.loadTextures()
        
        for sourceMesh in asset.childObjects(of: MDLMesh.self) as! [MDLMesh] {
            sourceMesh.addOrthTanBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                       normalAttributeNamed: MDLVertexAttributeNormal,
                                       tangentAttributeNamed: MDLVertexAttributeTangent)
            sourceMesh.vertexDescriptor = vertexDescriptor
        }
        
        guard let (sourceMeshes, meshes) = try? MTKMesh.newMeshes(asset: asset, device: device) else {
            fatalError("Could not convert ModelIO meshes to MetalKit meshes")
        }
        
        for (sourceMesh, mesh) in zip(sourceMeshes, meshes) {
            var materials = [Material]()
            for sourceSubmesh in sourceMesh.submeshes as! [MDLSubmesh] {
                let material = Material(material: sourceSubmesh.material, textureLoader: RenderUtils.shared.textureLoader)
                materials.append(material)
            }
            
            self.meshes.append(mesh)
            self.materials = materials
        }
    }
    
    override func render(_ commandEncoder: MTLRenderCommandEncoder, projectionMatrix: float4x4, viewMatrix: float4x4) {
   //     super.render(commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
        customRenderer.projectionMatrix = projectionMatrix
        customRenderer.viewMatrix = viewMatrix
        customRenderer.cameraPos = RenderUtils.shared.flyingCamera.vEye
        customRenderer.draw(in: view, withCommandEncoder: commandEncoder)
    }
    
    func bindTextures(_ material: Material, _ commandEncoder: MTLRenderCommandEncoder) {
        commandEncoder.setFragmentTexture(material.baseColorTexture ?? defaultTexture, index: TextureIndex.baseColor.rawValue)
        commandEncoder.setFragmentTexture(material.metallic ?? defaultTexture, index: TextureIndex.metallic.rawValue)
        commandEncoder.setFragmentTexture(material.roughness ?? defaultTexture, index: TextureIndex.roughness.rawValue)
        commandEncoder.setFragmentTexture(material.normal ?? defaultNormalMap, index: TextureIndex.normal.rawValue)
        commandEncoder.setFragmentTexture(material.emissive ?? defaultTexture, index: TextureIndex.emissive.rawValue)
    }
}
