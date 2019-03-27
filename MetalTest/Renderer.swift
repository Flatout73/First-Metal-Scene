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

class Renderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var depthStencilState: MTLDepthStencilState?
    var vertexBuffer: MTLBuffer?
    
    let samplerState: MTLSamplerState
    var scene: Scene!
    
    var time: Float = 0
    var cameraWorldPosition = float3(0, 0, 2)
    
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    
    let view: MTKView
    
    init(view: MTKView, device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        samplerState = Renderer.buildSamplerState(device: device)
        self.view = view
        super.init()
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        self.depthStencilState = self.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        scene = buildScene(device: device)
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    let skybox = SkyBox()
    
    func buildScene(device: MTLDevice) -> Scene {
        let textureLoader = RenderUtils.shared.textureLoader
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        
        let scene = Scene()
        
        scene.ambientLightColor = float3(0.01, 0.01, 0.01)
        let light0 = Light(worldPosition: float3( 2,  2, 2), color: float3(1, 0, 0))
        let light1 = Light(worldPosition: float3(-2,  2, 2), color: float3(0, 1, 0))
        let light2 = Light(worldPosition: float3( 0, -2, 2), color: float3(0, 0, 1))
        scene.lights = [ light0, light1, light2 ]
        
        
        let cube = ShapeNode(name: "Cube", shape: .Cube)
        cube.loadAssets(device, view: view)
        let cubematerial = Material(baseColorTexture: try? textureLoader.newTexture(name: "spot_texture", scaleFactor: 1.0, bundle: nil, options: options))
        cube.scene = scene
        cube.materials = [cubematerial]
        scene.rootNode.children.append(cube)
        
        let modelURL = Bundle.main.url(forResource: "spot_control_mesh", withExtension: "obj")!
        let teapot = ShapeNode(name: "Teapot", shape: .Simple(url: modelURL))
        
        teapot.loadAssets(device, view: view)
        let material = Material(baseColorTexture: try? textureLoader.newTexture(name: "spot_texture", scaleFactor: 1.0, bundle: nil, options: options))
        material.specularPower = 200
        material.specularColor = float3(0.8, 0.8, 0.8)
        teapot.materials.append(material)
        teapot.scene = scene
        //scene.rootNode.children.append(teapot)
        
        let surface = ShapeNode(name: "Surface", shape: .Plane)
        
        let material2 = Material(baseColorTexture: try? textureLoader.newTexture(name: "marsTexture", scaleFactor: 1.0, bundle: nil, options: options))
        surface.loadAssets(device, view: view)
        material2.specularColor = float3(0.8, 0.8, 0.8)
        surface.materials.append(material2)
        surface.modelMatrix = float4x4(translationBy: float3(0, -3, 0)) * float4x4(scaleBy: 20)
        surface.scene = scene
        scene.rootNode.children.append(surface)
        
        skybox.loadAssets(device, view: view)
        skybox.scene = scene
        
//        let helmet = HelmetNode(name: "Helmet")
//        helmet.loadAssets(device, view: view)
//        helmet.modelMatrix = float4x4(translationBy: float3(0, 0, 0))
//        scene.rootNode.children.append(helmet)

//        let car = CarNode(name: "Car")
//        car.loadAssets(device, view: view)
//        scene.rootNode.children.append(car)
        
        let text = TextNode(name: "Text")
        text.loadAssets(device, view: view)
        //scene.rootNode.children.append(text)
        
//        let terrainMesh = TerrainMesh(width: 64, height: 3, iterations: 6, smoothness: 0.95, device: device)
//        let terrainNode = Node(name: "Terrain")
//        terrainNode.terrainMesh = terrainMesh
//        terrainNode.material.baseColorTexture = try? textureLoader.newTexture(name: "sand", scaleFactor: 1.0, bundle: nil, options: options)
//        terrainNode.modelMatrix = float4x4(translationBy: float3(-1, -1, 0))
//        scene.rootNode.children.append(terrainNode)
        
        return scene
    }
    
    let updateCameraY = float3([0, 1, 0])
    
    let velocity: Float = 2
    
    var currentCameraTranslation: (x: Float, z: Float) = (0, 0)
    var currentCameraRotation: (x: Float, y: Float) = (0, 0)
    func updateCamera() {
        RenderUtils.shared.flyingCamera.update(deltaX: currentCameraRotation.x, deltaY: currentCameraRotation.y, cameraTranslation: currentCameraTranslation)
       // cameraHeading += angularVelocity * time
        
        // update camera location based on current heading
       // cameraWorldPosition.x += currentCameraTranslation.x / 10 //-sin(cameraHeading) * velocity * time
      //  cameraWorldPosition.z += currentCameraTranslation.z / 10 //-cos(cameraHeading) * velocity * time
        //cameraWorldPosition = positionConstrainedToTerrain(forPosition: cameraPosition)
        //cameraWorldPosition.y += Float(MBECameraHeight)
        currentCameraRotation = (0, 0)
    }

    
    func update(_ view: MTKView) {
        time += 1 / Float(view.preferredFramesPerSecond)
        updateCamera()
        viewMatrix = RenderUtils.shared.flyingCamera.Look()//float4x4(translationBy: -cameraWorldPosition)
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 10000)
        
        let angle = -time
       // scene.rootNode.modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle) *  float4x4(scaleBy: 1.5)
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.modelMatrix
        
        defer {
            for child in node.children {
                drawNodeRecursive(child, parentTransform: modelMatrix, commandEncoder: commandEncoder)
            }
        }
        
        node.render(commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
    }
    
    let semaphore = DispatchSemaphore(value: 1)
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        
        semaphore.wait(timeout: .distantFuture)
        guard let drawable = view.currentDrawable,
            // let pipelineState = pipelineState,
            let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        update(view)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
         //commandEncoder.setFrontFacing(.counterClockwise)
         //commandEncoder.setCullMode(.back)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        skybox.render(commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
        drawNodeRecursive(scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
        commandEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler {_ in 
            self.semaphore.signal()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
