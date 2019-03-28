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
    let tank = HelmetNode(name: "tank")
    
    func buildScene(device: MTLDevice) -> Scene {
        let textureLoader = RenderUtils.shared.textureLoader
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        
        let scene = Scene()
        
        scene.ambientLightColor = float3(0.1, 0.1, 0.1)
        let light0 = Light(worldPosition: float3( 2,  3, 0), color: float3(1, 0, 0))
        let light1 = Light(worldPosition: float3(-2,  3, 3), color: float3(0, 1, 0))
        let light2 = Light(worldPosition: float3( 0,  3, -3), color: float3(0, 0, 1))
        scene.lights = [ light0, light1, light2 ]
        
        for x in stride(from: -100, to: 100, by: 10) {
            for z in stride(from: -40, to: 40, by: 40) {
                let cube = ShapeNode(name: "Cube", shape: .Cube)
                cube.loadAssets(device, view: view)
                let cubematerial = Material(baseColorTexture: try? textureLoader.newTexture(name: "brick", scaleFactor: 1.0, bundle: nil, options: options))
                ///cubematerial.specularPower = 50
                //cubematerial.specularColor = float3(0.8, 0.8, 0.8)
                cube.scene = scene
                cube.modelMatrix = float4x4(translationBy: float3(Float(x), -1, Float(z))) * float4x4(rotationAbout: float3(0, 1, 0), by: Float(x)) * float4x4(scaleBy: 0.5)
                cube.materials = [cubematerial]
                scene.rootNode.children.append(cube)
            }
        }
        
        for x in stride(from: -300, to: 300, by: 30) {
            for z in stride(from: -300, to: 300, by: 30) {
                
                if (x < 160 && x > -160) && (z < 70 && z > -70) {
                    continue
                }
                let cube = ShapeNode(name: "Cube", shape: .Cube)
                cube.loadAssets(device, view: view)
                let cubematerial = Material(baseColorTexture: try? textureLoader.newTexture(name: "brick", scaleFactor: 1.0, bundle: nil, options: options))
                ///cubematerial.specularPower = 50
                //cubematerial.specularColor = float3(0.8, 0.8, 0.8)
                cube.scene = scene
                cube.modelMatrix = float4x4(translationBy: float3(Float(x + (z/10 % 2 == 0 ? 8 : -8)), 5, Float(z + (x/10 % 2 == 0 ? 8 : -8)))) * float4x4(rotationAbout: float3(0, 1, 0), by: Float(x)) * float4x4(scaleBy: 2.5)
                cube.materials = [cubematerial]
                scene.rootNode.children.append(cube)
            }
        }
        
        let modelURL = Bundle.main.url(forResource: "blub", withExtension: "obj")!
        let blub = ShapeNode(name: "blub", shape: .Simple(url: modelURL))
        blub.loadAssets(device, view: view)
        let material = Material(baseColorTexture: try? textureLoader.newTexture(name: "blub_baseColor", scaleFactor: 1.0, bundle: nil, options: options))
        material.specularPower = 100
        material.specularColor = float3(0.8, 0.8, 0.8)
        blub.materials.append(material)
        blub.scene = scene
        blub.modelMatrix = float4x4(translationBy: float3(-120, -1, -20)) * float4x4(rotationAbout: float3(0, 0 , 1), by: Float.pi/2) * float4x4(scaleBy: 10)
        scene.rootNode.children.append(blub)
        
        let surface = ShapeNode(name: "Surface", shape: .Plane)
        let material2 = Material(baseColorTexture: try? textureLoader.newTexture(name: "marsTexture", scaleFactor: 1.0, bundle: nil, options: options))
        surface.loadAssets(device, view: view)
        material2.specularColor = float3(0.8, 0.8, 0.8)
        surface.materials.append(material2)
        surface.modelMatrix = float4x4(translationBy: float3(0, -3, 0)) * float4x4(scaleBy: 100) //* float4x4(rotationAbout: float3(1, 0, 0), by: Float.pi)
        surface.scene = scene
        scene.rootNode.children.append(surface)
        
        skybox.loadAssets(device, view: view)
        skybox.scene = scene
        
        let treasure = HelmetNode(name: "treasure_chest")
        treasure.loadAssets(device, view: view)
        treasure.modelMatrix = float4x4(translationBy: float3(130, -3, -20)) * float4x4(rotationAbout: float3(0, 1, 0), by: Float.pi/2)
        scene.rootNode.children.append(treasure)
        
        let text = TextNode(name: "Easter egg")
        text.loadAssets(device, view: view)
        text.modelMatrix = float4x4(translationBy: float3(0, -100, -50))
        scene.rootNode.children.append(text)
        
        let text2 = TextNode(name: "Text")
        text2.loadAssets(device, view: view)
        text2.modelMatrix = float4x4(translationBy: float3(50, -100, -50))
        scene.rootNode.children.append(text2)
        
    
        tank.loadAssets(device, view: view)
        tank.modelMatrix = float4x4(translationBy: float3(-99, -3, -20)) * float4x4(scaleBy: 2) * float4x4(rotationAbout: float3(0, 1, 0), by: Float.pi)
        scene.rootNode.children.append(tank)
        
//        let terrainMesh = TerrainMesh(width: 64, height: 3, iterations: 6, smoothness: 0.95, device: device)
//        let terrainNode = Node(name: "Terrain")
//        terrainNode.terrainMesh = terrainMesh
//        terrainNode.material.baseColorTexture = try? textureLoader.newTexture(name: "sand", scaleFactor: 1.0, bundle: nil, options: options)
//        terrainNode.modelMatrix = float4x4(translationBy: float3(-1, -1, 0))
//        scene.rootNode.children.append(terrainNode)
        
        return scene
    }
    
    let updateCameraY = float3([0, 1, 0])
    
    let velocity: Float = 0.01
    
    var currentCameraTranslation: (x: Float, z: Float) = (0, 0)
    var currentCameraRotation: (x: Float, y: Float) = (0, 0)
    func updateCamera() {
        RenderUtils.shared.flyingCamera.update(deltaX: currentCameraRotation.x, deltaY: currentCameraRotation.y, cameraTranslation: currentCameraTranslation)

        currentCameraRotation = (0, 0)
    }

    var reversed = false
    func update(_ view: MTKView) {
        time += 1 / Float(view.preferredFramesPerSecond)
        updateCamera()
        viewMatrix = RenderUtils.shared.flyingCamera.Look()//float4x4(translationBy: -cameraWorldPosition)
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 10000)
        
     //   let angle = -time
        if tank.modelMatrix[3].x < 100 && !reversed {
            tank.modelMatrix = tank.modelMatrix * float4x4(translationBy: float3(-time * velocity, 0, 0))
        } else {
            if !reversed {
                reversed = true
            }
            if tank.modelMatrix[3].x > -100 {
                tank.modelMatrix = tank.modelMatrix * float4x4(translationBy: float3(time * velocity, 0, 0))
            } else {
                reversed = false
            }
        }
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
         commandEncoder.setFrontFacing(.counterClockwise)
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
