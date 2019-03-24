//
//  CarNode.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 23/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

enum VertexBufferIndex: Int {
    case attributes
    case uniforms
}

enum TextureIndex: Int {
    case baseColor
    case metallic
    case roughness
    case normal
    case emissive
    case irradiance = 9
}

enum FragmentBufferIndex: Int {
    case uniforms
}

struct Uniforms {
    let modelMatrix: float4x4
    let modelViewProjectionMatrix: float4x4
    let normalMatrix: float3x3
    let cameraPosition: float3
    let lightDirection: float3
    let lightPosition: float3
    
    init(modelMatrix: float4x4, viewMatrix: float4x4, projectionMatrix: float4x4,
         cameraPosition: float3, lightDirection: float3, lightPosition: float3)
    {
        self.modelMatrix = modelMatrix
        self.modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
        self.normalMatrix = modelMatrix.normalMatrix
        self.cameraPosition = cameraPosition
        self.lightDirection = lightDirection
        self.lightPosition = lightPosition
    }
}

class HelmetNode: Node {
    let defaultTexture: MTLTexture
    let defaultNormalMap: MTLTexture
    
    override init(name: String) {
        (defaultTexture, defaultNormalMap) = HelmetNode.buildDefaultTextures(device: RenderUtils.shared.device)
        super.init(name: name)
    }
    
    override func loadAssets(_ device: MTLDevice, view: MTKView) {
        let pipelineStateDescriptor = RenderUtils.createPipelineStateDescriptor(vertex: "vertex_car", fragment: "fragment_car", device: device, view: view)
        loadCar(device: device, pipelineStateDescriptor: pipelineStateDescriptor)
        pipelineState = RenderUtils.createPipeLineStateWithDescriptor(device: device, pipelineStateDescriptor: pipelineStateDescriptor)
    }
    
    static func buildDefaultTextures(device: MTLDevice) -> (MTLTexture, MTLTexture) {
        let bounds = MTLRegionMake2D(0, 0, 1, 1)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                  width: bounds.size.width,
                                                                  height: bounds.size.height,
                                                                  mipmapped: false)
        descriptor.usage = .shaderRead
        let defaultTexture = device.makeTexture(descriptor: descriptor)!
        let defaultColor: [UInt8] = [ 0, 0, 0, 255 ]
        defaultTexture.replace(region: bounds, mipmapLevel: 0, withBytes: defaultColor, bytesPerRow: 4)
        let defaultNormalMap = device.makeTexture(descriptor: descriptor)!
        let defaultNormal: [UInt8] = [ 127, 127, 255, 255 ]
        defaultNormalMap.replace(region: bounds, mipmapLevel: 0, withBytes: defaultNormal, bytesPerRow: 4)
        return (defaultTexture, defaultNormalMap)
    }
    
    func loadCar(device: MTLDevice, pipelineStateDescriptor: MTLRenderPipelineDescriptor) {
        guard let modelURL = Bundle.main.url(forResource: "helmet", withExtension: "obj") else {
            fatalError("Could not find model file in app bundle")
        }
        
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
        super.render(commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
        
        for mesh in meshes {
            let cameraWorldPosition = viewMatrix.inverse[3].xyz
            let lightWorldPosition = cameraWorldPosition
            let lightWorldDirection = normalize(cameraWorldPosition)
            
            var uniforms = Uniforms(modelMatrix: self.modelMatrix,
                                    viewMatrix: viewMatrix,
                                    projectionMatrix: projectionMatrix,
                                    cameraPosition: cameraWorldPosition,
                                    lightDirection: lightWorldDirection,
                                    lightPosition: lightWorldPosition)
            commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: VertexBufferIndex.uniforms.rawValue)
            commandEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: FragmentBufferIndex.uniforms.rawValue)
            
            for (bufferIndex, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: bufferIndex)
            }
            
            for (submeshIndex, submesh) in mesh.submeshes.enumerated() {
                let material = materials[submeshIndex]
                bindTextures(material, commandEncoder)
                
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
      //  commandEncoder.popDebugGroup()
    }
    
    func bindTextures(_ material: Material, _ commandEncoder: MTLRenderCommandEncoder) {
        commandEncoder.setFragmentTexture(material.baseColorTexture ?? defaultTexture, index: TextureIndex.baseColor.rawValue)
        commandEncoder.setFragmentTexture(material.metallic ?? defaultTexture, index: TextureIndex.metallic.rawValue)
        commandEncoder.setFragmentTexture(material.roughness ?? defaultTexture, index: TextureIndex.roughness.rawValue)
        commandEncoder.setFragmentTexture(material.normal ?? defaultNormalMap, index: TextureIndex.normal.rawValue)
        commandEncoder.setFragmentTexture(material.emissive ?? defaultTexture, index: TextureIndex.emissive.rawValue)
    }
}
