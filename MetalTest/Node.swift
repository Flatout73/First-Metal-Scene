//
//  Node.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 05/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import simd
import MetalKit

class Material {
    var specularColor = float3(1, 1, 1)
    var specularPower = Float(1)
    var baseColorTexture: MTLTexture?
}

class Node {
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    var meshes: [MTKMesh] = []
    //var terrainMesh: TerrainMesh?
    var material = Material()
    
    let vertexDescriptor: MTLVertexDescriptor = MTLVertexDescriptor()
    var pipelineState: MTLRenderPipelineState?
    
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
    
    open func loadAssets(_ device: MTLDevice, view: MTKView) { }
}
