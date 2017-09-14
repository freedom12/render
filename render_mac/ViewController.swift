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
    var renderEngine:RenderEngine!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView = MTKView()
        mtkView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        mtkView.clearDepth = 1
        mtkView.clearStencil = 0
        
        renderEngine = RenderEngine(view:mtkView)
        mtkView.delegate = renderEngine
        mtkView.device = renderEngine.device
        
        self.view.addSubview(mtkView)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

