//
//  TextNode.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 24/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit


struct TextUniform {
    let projectionMatrix: simd_float4x4
    let modelViewMatrix: simd_float4x4
}

class TextNode: Node {
    
    override func loadAssets(_ device: MTLDevice, view: MTKView) {
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float3,
                                                            offset: MemoryLayout<Float>.size * 3,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                            format: .float2,
                                                            offset: MemoryLayout<Float>.size * 6,
                                                            bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        
        let pipelineStateDescriptor = RenderUtils.createPipelineStateDescriptor(vertex: "vertex_text", fragment: "fragment_text", device: device, view: view)
        pipelineStateDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineState = RenderUtils.createPipeLineStateWithDescriptor(device: device, pipelineStateDescriptor: pipelineStateDescriptor)
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let font = CTFontCreateWithName("HoeflerText-Black" as CFString, 30, nil)
        let textMesh = MBETextMesh.mesh(with: "Hello", font: font, extrusionDepth: 16.0, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)!
        
        self.meshes.append(textMesh)
        
        let material = Material(baseColorTexture: try! RenderUtils.shared.textureLoader.newTexture(name: "wood", scaleFactor: 1.0, bundle: nil, options: [.generateMipmaps : true, .SRGB : true]))
        self.materials.append(material)
    }
    
    override func render(_ commandEncoder: MTLRenderCommandEncoder, projectionMatrix: float4x4, viewMatrix: float4x4) {
        super.render(commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)

        var uniformBuffer = TextUniform(projectionMatrix: projectionMatrix, modelViewMatrix: viewMatrix * modelMatrix)
        commandEncoder.setVertexBytes(&uniformBuffer, length: MemoryLayout<TextUniform>.size, index: 1)
        
        guard let mesh = self.meshes.first else {
            return
        }
        for (bufferIndex, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: bufferIndex)
            
        }
        commandEncoder.setFragmentTexture(self.materials.first!.baseColorTexture, index: 0)
        
        for (submeshIndex, submesh) in mesh.submeshes.enumerated() {
            let indexBuffer = submesh.indexBuffer
            commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                 indexCount: submesh.indexCount,
                                                 indexType: submesh.indexType,
                                                 indexBuffer: indexBuffer.buffer,
                                                 indexBufferOffset: indexBuffer.offset)
        }
    }
    
    
}
