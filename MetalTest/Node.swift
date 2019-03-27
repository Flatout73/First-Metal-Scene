//
//  Node.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 05/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import simd
import MetalKit

class Node {
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    var meshes: [MTKMesh] = []
    //var terrainMesh: TerrainMesh?
    var materials: [Material] = []
    
    let vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor()
    var pipelineState: MTLRenderPipelineState!
    
    init(name: String) {
        self.name = name
    }
    
    func nodeNamedRecursive(_ name: String) -> Node? {
        for node in children {
            if node.name == name {
                return node
            } else if let matchingGrandchild = node.nodeNamedRecursive(name) {
                return matchingGrandchild
            }
        }
        return nil
    }
    
    func loadAssets(_ device: MTLDevice, view: MTKView) { }
    
    func render(_ commandEncoder: MTLRenderCommandEncoder, projectionMatrix: float4x4, viewMatrix: float4x4) {
        defer {
            commandEncoder.popDebugGroup()
        }
        guard let pipelineState = pipelineState else { return }
        commandEncoder.label = "\(name) render encoder"
        commandEncoder.pushDebugGroup("draw \(name)")
        commandEncoder.setRenderPipelineState(pipelineState)
    }
}
