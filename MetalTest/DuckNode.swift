//
//  DuckNode.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 18/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

class DuckNode: Node {
    
    override func loadAssets(_ device: MTLDevice, view: MTKView) {
        let pipelineStateDescriptor = RenderUtils.createPipelineStateDescriptor(vertex: "duckVertex", fragment: "duckFragment", device: device, view: view)
        loadDuck(device: device, pipelineStateDescriptor: pipelineStateDescriptor)
        pipelineState = RenderUtils.createPipeLineStateWithDescriptor(device: device, pipelineStateDescriptor: pipelineStateDescriptor)
        
    }
    

    func loadDuck(device: MTLDevice, pipelineStateDescriptor: MTLRenderPipelineDescriptor) {
        let path = Bundle.main.path(forResource: "duck", ofType: "obj", inDirectory: "Assets")
        if(path == nil) {
            print("Could not find duck.")
        } else {
            print("Found the duck.")
        }
        let assetURL = URL(fileURLWithPath: path!)
        
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 12
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perVertex;
        
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
        
        let desc = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        let attribute = desc.attributes[0] as! MDLVertexAttribute
        attribute.name = MDLVertexAttributePosition
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: desc, bufferAllocator: bufferAllocator)

        do {
            self.meshes = try MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes
        } catch let error {
            print("Unable to load mesh for duck: \(error)")
        }
//        let memory_array: NSArray? = pointer!.pointee
//        var model_meshes: [MDLMesh] = Array()
//        for data in memory_array! {
//            model_meshes.append(data as! MDLMesh)
//        }
//        print("mdlmesh \(model_meshes)")
//        materials = renderUtils.meshesToMaterialsBuffer(device: device, meshes: model_meshes)
        print("done loading meshe for duck")
    }
}
