//
//  ShapeNode.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 24/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

enum Shape {
    case Plane
    case Simple(url: URL)
    case Cube
    case SkyBox
}

struct VertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
    var viewMatrix: float4x4
}

struct FragmentUniforms {
    var cameraWorldPosition = float3(0, 0, 0)
    var ambientLightColor = float3(0, 0, 0)
    var specularColor = float3(1, 1, 1)
    var specularPower = Float(1)
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
}

struct FogParameters {
    var color: float3
    var start: Float
    var end: Float
    var density: Float
    
    var iEquation: Int32
}

class ShapeNode: Node {
    var scene: Scene!
    
    var isFogged = true
    
    let shape: Shape
    init(name: String, shape: Shape) {
        self.shape = shape
        super.init(name: name)
    }
    
    func buildVertexDescriptor() {
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
    }
    
    override func loadAssets(_ device: MTLDevice, view: MTKView) {
        buildVertexDescriptor()
        
        let pipelineDescriptor = RenderUtils.createPipelineStateDescriptor(vertex: "vertex_main", fragment: "fragment_main", device: device, view: view)
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        
        pipelineState = RenderUtils.createPipeLineStateWithDescriptor(device: device, pipelineStateDescriptor: pipelineDescriptor)
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        
        switch shape {
        case .Plane:
            let dimension: Float = 8.0
            meshes = [try! MTKMesh(mesh: MDLMesh.newPlane(withDimensions: float2(dimension, dimension), segments: vector_uint2(1, 1), geometryType: .quads, allocator: bufferAllocator), device: device)]
            isFogged = false
        case .Simple(let modelURL):
            let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
            meshes = try! MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes
        case .Cube:
            let dimension: Float = 8.0
            meshes = [try! MTKMesh(mesh: MDLMesh.newBox(withDimensions: float3(dimension, dimension, dimension), segments: vector_uint3(1, 1, 1), geometryType: .triangles, inwardNormals: true, allocator: bufferAllocator), device: device)]
        case .SkyBox:
            let dimension: Float = 3000.0
            for i in 0..<6 {
                meshes.append(try! MTKMesh(mesh: MDLMesh.newPlane(withDimensions: float2(dimension, dimension), segments: vector_uint2(1, 1), geometryType: .triangles, allocator: bufferAllocator), device: device))
            }
            for side in ["up", "rt", "lf", "dn", "bk", "ft"] {
                materials.append(Material(baseColorTexture: try! RenderUtils.shared.textureLoader.newTexture(name: "alpha-island_\(side)", scaleFactor: 1, bundle: nil, options: [.generateMipmaps : true, .SRGB : true])))
            }
        }
    }
    
    override func render(_ commandEncoder: MTLRenderCommandEncoder, projectionMatrix: float4x4, viewMatrix: float4x4) {
        super.render(commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
        
        guard let material = materials.first, let baseColorTexture = material.baseColorTexture else { return }
        
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        var vertexUniforms = VertexUniforms(viewProjectionMatrix: viewProjectionMatrix,
                                            modelMatrix: modelMatrix,
                                            normalMatrix: modelMatrix.normalMatrix, viewMatrix: viewMatrix)
        commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 1)
        
        var fragmentUniforms = FragmentUniforms(cameraWorldPosition: RenderUtils.shared.flyingCamera.vEye,
                                                ambientLightColor: float3(0.1, 0.1, 0.1),
                                                specularColor: material.specularColor,
                                                specularPower: material.specularPower,
                                                light0: scene.lights[0],
                                                light1: scene.lights[1],
                                                light2: scene.lights[2])
        commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
        
        if isFogged {
            commandEncoder.setFragmentBytes(&RenderUtils.shared.fog, length: MemoryLayout<FogParameters>.size, index: 1)
        } else {
            var fog: FogParameters = RenderUtils.shared.fog
            fog.density = 0.1
            fog.iEquation = 4
            commandEncoder.setFragmentBytes(&fog, length: MemoryLayout<FogParameters>.size, index: 1)
        }
    
        commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
        
        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers.first!
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
        
 //       else if let terrain = node.terrainMesh {
//            commandEncoder.setVertexBuffer(terrain.vertexBuffer, offset: 0, index: 0)
//            commandEncoder.drawIndexedPrimitives(type: .triangle,
//                                                 indexCount: terrain.indexCount,
//                                                 indexType: .uint16,
//                                                 indexBuffer: terrain.indexBuffer,
//                                                 indexBufferOffset: 0,
//                                                 instanceCount: 1)
//        }
    }
}
