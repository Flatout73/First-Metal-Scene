//
//  Scene.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 05/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import simd
import MetalKit

struct Light {
    var worldPosition = float3(0, 0, 0)
    var color = float3(0, 0, 0)
}

class Scene {
    var rootNode = Node(name: "Root")
    var ambientLightColor = float3(0, 0, 0)
    var lights = [Light]()
    
    func nodeNamed(_ name: String) -> Node? {
        if rootNode.name == name {
            return rootNode
        } else {
            return rootNode.nodeNamedRecursive(name)
        }
    }
}
