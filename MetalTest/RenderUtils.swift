//
//  RenderUtils.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 18/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

class RenderUtils {
    static let shared = RenderUtils()
    public let device: MTLDevice
    public let textureLoader: MTKTextureLoader
    
    public var flyingCamera = FlyingCamera()
    
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        textureLoader = MTKTextureLoader(device: device)
    }
    
    class func createPipelineStateDescriptor(vertex: String, fragment: String, device: MTLDevice, view: MTKView) -> MTLRenderPipelineDescriptor {
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: vertex)!
        let fragmentProgram = defaultLibrary.makeFunction(name: fragment)!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.sampleCount = view.sampleCount
        pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        //pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat
        
        return pipelineStateDescriptor
    }
    
    class func createPipeLineStateWithDescriptor(device: MTLDevice, pipelineStateDescriptor: MTLRenderPipelineDescriptor) -> MTLRenderPipelineState {
        var pipelineState: MTLRenderPipelineState! = nil
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        return pipelineState
    }
}
