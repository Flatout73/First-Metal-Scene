//
//  Renderer.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 27/02/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit
import ModelIO
import simd

struct VertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
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

class Renderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var pipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    var vertexBuffer: MTLBuffer?
    
    let samplerState: MTLSamplerState
    let scene: Scene
    let vertexDescriptor: MDLVertexDescriptor
    
    var time: Float = 0
    var cameraWorldPosition = float3(0, 0, 2)
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    
    init(view: MTKView, device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        samplerState = Renderer.buildSamplerState(device: device)
        vertexDescriptor = Renderer.buildVertexDescriptor()
        scene = Renderer.buildScene(device: device, vertexDescriptor: vertexDescriptor)
        super.init()
        buildPipelineState(view: view)
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    static func buildScene(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) -> Scene {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        
        let scene = Scene()
        
        scene.ambientLightColor = float3(0.01, 0.01, 0.01)
        let light0 = Light(worldPosition: float3( 2,  2, 2), color: float3(1, 0, 0))
        let light1 = Light(worldPosition: float3(-2,  2, 2), color: float3(0, 1, 0))
        let light2 = Light(worldPosition: float3( 0, -2, 2), color: float3(0, 0, 1))
        scene.lights = [ light0, light1, light2 ]
        
        let teapot = Node(name: "Teapot")
        
        let modelURL = Bundle.main.url(forResource: "teapot", withExtension: "obj")!
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        teapot.mesh = try! MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes.first
        teapot.material.baseColorTexture = try? textureLoader.newTexture(name: "tiles_baseColor", scaleFactor: 1.0, bundle: nil, options: options)
        teapot.material.specularPower = 200
        teapot.material.specularColor = float3(0.8, 0.8, 0.8)
        scene.rootNode.children.append(teapot)
        
        return scene
    }
    
    static func buildVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        return vertexDescriptor
    }
    
    private func buildPipelineState(view: MTKView) {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true

        self.depthStencilState = self.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func update(_ view: MTKView) {
        time += 1 / Float(view.preferredFramesPerSecond)
        
        cameraWorldPosition = float3(0, 0, 2)
        viewMatrix = float4x4(translationBy: -cameraWorldPosition)
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
        
        let angle = -time
        scene.rootNode.modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle) *  float4x4(scaleBy: 1.5)
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.modelMatrix
        
        defer {
            for child in node.children {
                drawNodeRecursive(child, parentTransform: modelMatrix, commandEncoder: commandEncoder)
            }
        }
        
        guard let mesh = node.mesh, let baseColorTexture = node.material.baseColorTexture else { return }
        
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        var vertexUniforms = VertexUniforms(viewProjectionMatrix: viewProjectionMatrix,
                                            modelMatrix: modelMatrix,
                                            normalMatrix: modelMatrix.normalMatrix)
        commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 1)
        
//        let material = Material()
//        material.specularPower = 200
//        material.specularColor = float3(0.8, 0.8, 0.8)
//
//        let light0 = Light(worldPosition: float3( 2,  2, 2), color: float3(1, 0, 0))
//        let light1 = Light(worldPosition: float3(-2,  2, 2), color: float3(0, 1, 0))
//        let light2 = Light(worldPosition: float3( 0, -2, 2), color: float3(0, 0, 1))
        
        var fragmentUniforms = FragmentUniforms(cameraWorldPosition: cameraWorldPosition,
                                                ambientLightColor: float3(0.1, 0.1, 0.1),
                                                specularColor: node.material.specularColor,
                                                specularPower: node.material.specularPower,
                                                light0: scene.lights[0],
                                                light1: scene.lights[1],
                                                light2: scene.lights[2])
        commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
        
        commandEncoder.setDepthStencilState(depthStencilState)
        
        commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        
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
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let pipelineState = pipelineState,
            let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        update(view)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            commandEncoder.setFrontFacing(.counterClockwise)
            commandEncoder.setCullMode(.back)
            commandEncoder.setDepthStencilState(depthStencilState)
            commandEncoder.setRenderPipelineState(pipelineState)
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
            drawNodeRecursive(scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
    }
}
