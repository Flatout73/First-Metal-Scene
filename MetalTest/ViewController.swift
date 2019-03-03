//
//  ViewController.swift
//  MetalTest
//
//  Created by Леонид Лядвейкин on 27/02/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    var metalView: MTKView {
        return view as! MTKView
    }

    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        metalView.device = MTLCreateSystemDefaultDevice()
        guard let device = metalView.device else {
            fatalError("Device not created. Run on a physical device")
        }
        
        metalView.clearColor = MTLClearColor(red: 0.0,
                                             green: 0.4,
                                             blue: 0.21,
                                             alpha: 1.0)
        renderer = Renderer(device: device)
        metalView.delegate = renderer
    }


}

