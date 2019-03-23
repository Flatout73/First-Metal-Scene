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
    
    var metalView: MainMetalView {
        return view as! MainMetalView
    }
    var mouseLocation: NSPoint {
        return NSEvent.mouseLocation
    }

    var renderer: Renderer?
    
    var trackingArea: NSTrackingArea?
    
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
        metalView.colorPixelFormat = .bgra8Unorm_srgb
        metalView.depthStencilPixelFormat = .depth32Float
        renderer = Renderer(view: metalView, device: device)
        metalView.delegate = renderer
        metalView.renderer = renderer
        
//        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
//            print("mouseLocation:", String(format: "%.1f, %.1f", self.mouseLocation.x, self.mouseLocation.y))
//           // print("windowLocation:", String(format: "%.1f, %.1f", self.location.x, self.location.y))
//            return $0
//        }
        
        trackingArea = NSTrackingArea(rect: self.view.bounds, options: [.activeAlways, .inVisibleRect,
            .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        
        self.view.addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
       
        renderer?.currentCameraRotation = (Float(event.deltaX), Float(event.deltaY))
    }
}

