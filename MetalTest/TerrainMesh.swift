//
//  TerrainMesh.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 05/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit
import simd

private let MBEColorWhite = [1.0, 1.0, 1.0, 1.0]
private let MBETerrainTextureScale = 50

struct MBEVertex {
    var position: packed_float4 = float4(0)
    var normal: packed_float4 = float4(0)
    //var diffuseColor: packed_float4 = float4(0)
    var texCoords: packed_float2 = float2(0)
    
    init() { }
}

class TerrainMesh {
    private let device: MTLDevice
    private var smoothness: Float = 0.0
    private var iterations: UInt16 = 0
    private var stride: Int = 0
    /* number of vertices per edge */
    var vertexCount: size_t = 0
    var indexCount: size_t = 0
    var vertices: [MBEVertex] = []
    var indices: [UInt16] = []
    
    public var width: Float
    public var depth: Float
    public var height: Float
    
    public var vertexBuffer: MTLBuffer!
    public var indexBuffer: MTLBuffer!
    
    init(width: Float, height: Float, iterations: UInt16, smoothness: Float, device: MTLDevice) {
        if iterations > 6 {
            print("Too many terrain mesh subdivisions requested. 16-bit indexing does not suffice.")
        }
        
        self.width = width
        depth = width
        self.height = height
        self.smoothness = smoothness
        self.iterations = iterations
        self.device = device
        
        generateTerrain()
    }

    
    func generateTerrain() {
        stride = (1 << iterations) + 1 // number of vertices on one side of the terrain patch
        vertexCount = stride * stride
        indexCount = (stride - 1) * (stride - 1) * 6
        
        vertices = Array(repeating: MBEVertex(), count: vertexCount) //malloc(MemoryLayout<MBEVertex>.size * vertexCount)
        indices = Array(repeating: 0, count: indexCount) //malloc(MemoryLayout<UInt16>.size * indexCount)
        
        var variance: Float = 1.0 // absolute maximum variance about mean height value
        let smoothingFactor = powf(2, -smoothness) // factor by which to decrease variance each iteration
        
        // seed corners with 0.
        vertices[0].position.y = 0.0
        vertices[stride].position.y = 0.0
        vertices[(stride - 1) * stride].position.y = 0.0
        vertices[(stride * stride) - 1].position.y = 0.0
        
        
        for i in 0..<iterations {
            let numSquares: Int = 1 << i // squares per edge at the current subdivision level (1, 2, 4, 8)
            let squareSize: Int = 1 << (iterations - i) // edge length of square at current subdivision (CHECK THIS)
            
            for y in 0..<numSquares {
                for x in 0..<numSquares {
                    let r: Int = y * squareSize
                    let c: Int = x * squareSize
                    performSquareStep(withRow: r, column: c, squareSize: squareSize, variance: variance)
                    performDiamondStep(withRow: r, column: c, squareSize: squareSize, variance: variance)
                }
            }
            
            variance *= smoothingFactor
        }
        
        computeMeshCoordinates()
        computeMeshNormals()
        generateMeshIndices()
        
        vertexBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<MBEVertex>.size * vertexCount, options: [])
        vertexBuffer.label = "Vertices (Terrain)"
        
        
        indexBuffer = device.makeBuffer(bytes: &indices, length: MemoryLayout<UInt16>.size * indexCount, options: [])
        indexBuffer.label = "Indices (Terrain)"
    }
    
    func performSquareStep(withRow row: Int, column: Int, squareSize: Int, variance: Float) {
        let r0: size_t = row
        let c0: size_t = column
        let r1 = (r0 + squareSize) % stride
        let c1 = (c0 + squareSize) % stride
        let cmid = size_t(c0 + (squareSize / 2))
        let rmid = size_t(r0 + (squareSize / 2))
        let y00 = vertices[r0 * stride + c0].position.y
        let y01 = vertices[r0 * stride + c1].position.y
        let y11 = vertices[r1 * stride + c1].position.y
        let y10 = vertices[r1 * stride + c0].position.y
        let ymean = (y00 + y01 + y11 + y10) * 0.25
        let error = (((Float(arc4random()) / Float(UINT32_MAX)) - 0.5) * 2) * variance
        let y = ymean + error
        vertices[rmid * stride + cmid].position.y = y
    }
    
    func performDiamondStep(withRow row: Int, column: Int, squareSize: Int, variance: Float) {
        let r0: size_t = row
        let c0: size_t = column
        let r1 = (r0 + squareSize) % stride
        let c1 = (c0 + squareSize) % stride
        let cmid = size_t(c0 + (squareSize / 2))
        let rmid = size_t(r0 + (squareSize / 2))
        let y00 = vertices[r0 * stride + c0].position.y
        let y01 = vertices[r0 * stride + c1].position.y
        let y11 = vertices[r1 * stride + c1].position.y
        let y10 = vertices[r1 * stride + c0].position.y
        var error: Float = 0
        error = (((Float(arc4random()) / Float(UINT32_MAX)) - 0.5) * 2) * variance
        vertices[r0 * stride + cmid].position.y = (y00 + y01) * 0.5 + error
        error = (((Float(arc4random()) / Float(UINT32_MAX)) - 0.5) * 2) * variance
        vertices[rmid * stride + c0].position.y = (y00 + y10) * 0.5 + error
        error = (((Float(arc4random()) / Float(UINT32_MAX)) - 0.5) * 2) * variance
        vertices[rmid * stride + c1].position.y = (y01 + y11) * 0.5 + error
        error = (((Float(arc4random()) / Float(UINT32_MAX)) - 0.5) * 2) * variance
        vertices[r1 * stride + cmid].position.y = (y01 + y11) * 0.5 + error
    }

    func computeMeshCoordinates() {
        for r in 0..<stride {
            for c in 0..<stride {
                let i: size_t = r * stride + c
                let x = (Float(c / (stride - 1)) - 0.5) * width
                let y: Float = vertices[r * stride + c].position.y * height
                let z = (Float(r / (stride - 1)) - 0.5) * depth
                vertices[i].position = [x, y, z, 1.0]
                
                let s = Float(c / (stride - 1)) * Float(MBETerrainTextureScale)
                let t = Float(r / (stride - 1)) * Float(MBETerrainTextureScale)
                vertices[i].texCoords = [s, t]
                
                //vertices[i].diffuseColor = MBEColorWhite
            }
        }
    }
    
    func computeMeshNormals() {
        let yScale: Float = 4
        for r in 0..<stride {
            for c in 0..<stride {
                if r > 0 && c > 0 && r < stride - 1 && c < stride - 1 {
                    let L: vector_float4 = vertices[r * stride + (c - 1)].position
                    let R: vector_float4 = vertices[r * stride + (c + 1)].position
                    let U: vector_float4 = vertices[(r - 1) * stride + c].position
                    let D: vector_float4 = vertices[(r + 1) * stride + c].position
                    let T: vector_float3 = [R.x - L.x, (R.y - L.y) * yScale, 0]
                    let B: vector_float3 = [0, (D.y - U.y) * yScale, D.z - U.z]
                    let N: vector_float3 = simd_cross(B, T)
                    var normal: vector_float4 = [N.x, N.y, N.z, 0]
                    normal = simd_normalize(normal)
                    vertices[r * stride + c].normal = normal
                } else {
                    let N = float4([0, 1, 0, 0])
                    vertices[r * stride + c].normal = N
                }
            }
        }
    }
    
    func generateMeshIndices() {
        var i: Int = 0
        for r in 0..<stride - 1 {
            for c in 0..<stride - 1 {
                indices[i] = UInt16(r * stride + c)
                i += 1
                indices[i] = UInt16((r + 1) * stride + c)
                i += 1
                indices[i] = UInt16((r + 1) * stride + (c + 1))
                i += 1
                indices[i] = UInt16((r + 1) * stride + (c + 1))
                i += 1
                indices[i] = UInt16(r * stride + c + 1)
                i += 1
                indices[i] = UInt16(r * stride + c)
                i += 1
            }
        }
    }
    
    func height(atPositionX x: Float, z: Float) -> Float {
        let halfSize: Float = width / 2
        
        if x < -halfSize || x > halfSize || z < -halfSize || z > halfSize {
            return 0.0
        }
        
        // Normalize x and z between 0 and 1
        let nx: Float = (x / width) + 0.5
        let nz: Float = (z / depth) + 0.5
        
        // Compute fractional indices of nearest vertices
        let fx: Float = nx * Float(stride - 1)
        let fz: Float = nz * Float(stride - 1)
        
        // Compute index of nearest vertices that are "up" and to the left
        let ix = floorf(fx)
        let iz = floorf(fz)
        
        // Compute fractional offsets in the direction of next nearest vertices
        let dx = fx - Float(ix)
        let dz = fz - Float(iz)
        
        // Get heights of nearest vertices
        let y00 = vertices[Int(iz) * stride + Int(ix)].position.y
        let y01 = vertices[Int(iz) * stride + Int(ix + 1)].position.y
        let y10 = vertices[Int(iz + 1) * stride + Int(ix)].position.y
        let y11 = vertices[Int(iz + 1) * stride + Int(ix + 1)].position.y
        
        // Perform bilinear interpolation to get approximate height at point
        let ytop: Float = ((1 - dx) * y00) + (dx * y01)
        let ybot: Float = ((1 - dx) * y10) + (dx * y11)
        let y: Float = ((1 - dz) * ytop) + (dz * ybot)
        
        return y
    }
}
