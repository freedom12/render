//
//  ViewController.swift
//  render_mac
//
//  Created by wanghuai on 2017/9/5.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

    var mtkView:MTKView! = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView = MTKView()
        mtkView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        mtkView.delegate = RenderEngine.sharedInstance
        mtkView.device = RenderEngine.sharedInstance.device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        mtkView.clearDepth = 1
        mtkView.clearStencil = 0
        self.view.addSubview(mtkView)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

