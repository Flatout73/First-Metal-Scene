//
//  MainMetalView.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 23/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import MetalKit

let A_KEY: UInt16 = 0
let S_KEY: UInt16 = 1
let D_KEY: UInt16 = 2
let W_KEY: UInt16 = 13

let K1_KEY: UInt16 = 18
let K2_KEY: UInt16 = 19
let K3_KEY: UInt16 = 20

let K5_KEY: UInt16 = 23

enum Dimension: Int {
    case x = 0
    case y
    case z
}

class MainMetalView: MTKView {
    
    var renderer: Renderer!
    
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case W_KEY:
            moveCamera(dimension: .z, modifier: -1.0)
            break
        case S_KEY:
            moveCamera(dimension: .z)
            break
        case D_KEY:
            moveCamera(dimension: .x)
            break
        case A_KEY:
            moveCamera(dimension: .x, modifier: -1.0)
            break
        default:
            break
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case W_KEY:
            moveCamera(dimension: .z, modifier: 0)
            break
        case S_KEY:
            moveCamera(dimension: .z, modifier: 0)
            break
        case D_KEY:
            moveCamera(dimension: .x, modifier: 0)
            break
        case A_KEY:
            moveCamera(dimension: .x, modifier: 0)
            break
        case K1_KEY:
            RenderUtils.shared.fog.iEquation = 0
        case K2_KEY:
            RenderUtils.shared.fog.iEquation = 1
        case K3_KEY:
            RenderUtils.shared.fog.iEquation = 2
//        case K5_KEY:
//            RenderUtils.shared.moveSpeedX = 2.0
        default:
            break
        }
    }
    
    private func moveCamera(dimension: Dimension, modifier: Float32 = 1.0) {
        
        switch dimension {
        case .x:
            renderer.currentCameraTranslation = (modifier, renderer.currentCameraTranslation.z)
        case .z:
            renderer.currentCameraTranslation = (renderer.currentCameraTranslation.x, modifier)
        default:
            break
        }
    }
}
