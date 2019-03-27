//
//  Skybox.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 26/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

class SkyBox {
    let cubeVertexData: [float4] =
[
    // posx
    float4(arrayLiteral:  -1.0,  1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  -1.0, -1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  -1.0,  1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  -1.0, -1.0, -1.0, 1.0 ),
    
    // negz
    float4(arrayLiteral:  -1.0,  1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  -1.0, -1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  1.0,  1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  1.0, -1.0, -1.0, 1.0 ),
    
    // negx
    float4(arrayLiteral:  1.0,  1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  1.0, -1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  1.0,  1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  1.0, -1.0,  1.0, 1.0 ),
    
    // posz
    float4(arrayLiteral:  1.0,  1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  1.0, -1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  -1.0,  1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  -1.0, -1.0,  1.0, 1.0 ),

    // posy
    float4(arrayLiteral:  -1.0,  1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  -1.0,  1.0, -1.0, 1.0 ),
    float4(arrayLiteral: 1.0,  1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  1.0,  1.0, -1.0, 1.0 ),

    // negy
    float4(arrayLiteral:  1.0, -1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  1.0, -1.0, -1.0, 1.0 ),
    float4(arrayLiteral:  -1.0, -1.0,  1.0, 1.0 ),
    float4(arrayLiteral:  -1.0, -1.0, -1.0, 1.0 ),
]
    
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    
    var baseColorTexture: MTLTexture!
    
    let modelMatrix = matrix_identity_float4x4 * float4x4(scaleBy: 1000)
    
    var scene: Scene!
    
    init() {
    
    }
    
    // assumes png file
    func loadIntoTextureWithDevice(device: MTLDevice) -> Bool {
        let image = #imageLiteral(resourceName: "skybox")
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        
        let width = cgImage.width// CGImageGetWidth(image.cgImage);
        let height = cgImage.height //CGImageGetHeight(image.cgImage);
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(4 * width), space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let Npixels = width * width;
        let texDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm, size: Int(width), mipmapped: false)
        let target = texDesc.textureType
        baseColorTexture = device.makeTexture(descriptor: texDesc)
        
        guard let imageData = context?.data else { return false }
        for i in 0..<6 {
            baseColorTexture.replace(region: MTLRegionMake2D(0, 0, width, width), mipmapLevel: 0, slice: i, withBytes: imageData + (i * Npixels * 4), bytesPerRow: 4 * width, bytesPerImage:Npixels * 4)
            
        }
        return true
    }
    
    func loadAssets(_ device: MTLDevice, view: MTKView) {
        let pipelineDescriptor = RenderUtils.createPipelineStateDescriptor(vertex: "skyboxVertex", fragment: "skyboxFragment", device: device, view: view)
        
        pipelineState = RenderUtils.createPipeLineStateWithDescriptor(device: device, pipelineStateDescriptor: pipelineDescriptor)
        
        vertexBuffer = device.makeBuffer(bytes: cubeVertexData, length: MemoryLayout<float4>.size * cubeVertexData.count)!
        
        loadIntoTextureWithDevice(device: device)
    }
    
    func render(_ commandEncoder: MTLRenderCommandEncoder, projectionMatrix: float4x4, viewMatrix: float4x4) {
        commandEncoder.pushDebugGroup("skybox")
        
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 1)
        
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        var vertexUniforms = VertexUniforms(viewProjectionMatrix: viewProjectionMatrix,
                                            modelMatrix: modelMatrix,
                                            normalMatrix: modelMatrix.normalMatrix, viewMatrix: viewMatrix)
        commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 2)
//
//        var fragmentUniforms = FragmentUniforms(cameraWorldPosition: RenderUtils.shared.flyingCamera.vEye,
//                                                ambientLightColor: float3(0.1, 0.1, 0.1),
//                                                specularColor: float3(0.8, 0.8, 0.8),
//                                                specularPower: 200,
//                                                light0: scene.lights[0],
//                                                light1: scene.lights[1],
//                                                light2: scene.lights[2])
//        commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
//
//        var fog = FogParameters(color: float3(0.5, 0.5, 0.5), start: 10, end: 75, demsity: 0.04, iEquataion: 0)
//        commandEncoder.setFragmentBytes(&fog, length: MemoryLayout<FogParameters>.size, index: 1)
//
        commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
        
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: cubeVertexData.count)
        
        commandEncoder.popDebugGroup()
    }
}
