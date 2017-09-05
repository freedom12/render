//
//  RenderManager.swift
//  render
//
//  Created by wanghuai on 2017/9/5.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

import Foundation
import MetalKit

class RenderEngine:NSObject, MTKViewDelegate {
    static let sharedInstance = RenderEngine()
    
    var device:MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var defaultLibrary:MTLLibrary! = nil

    var projMat = Matrix4.identity
    var viewMat = Matrix4.identity
    
    var vertFunc:MTLFunction
    var fragFunc:MTLFunction
    
    
    var isRenderBone = false
    
    override init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        defaultLibrary = device.makeDefaultLibrary()!
        vertFunc = defaultLibrary.makeFunction(name: "basic_vertex")!
        fragFunc = defaultLibrary.makeFunction(name: "basic_fragment")!

    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView ) {
        let commandBuffer = commandQueue!.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
        
        renderEncoder.setVertexBytes(projMat.toArray(), length: 16*4, index: 1)
        renderEncoder.setVertexBytes(viewMat.toArray(), length: 16*4, index: 2)
        
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
