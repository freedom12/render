//
//  RenderEngine.swift
//  pm_ios
//
//  Created by wanghuai on 2017/6/28.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import MetalKit

class RenderEngine:NSObject, MTKViewDelegate {
//    static let sharedInstance = RenderEngine()
    
    weak var view:MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    var lightPos:float4!
    var viewPos:float4!
    var viewMatrix:matrix_float4x4!
    var projMatrix:matrix_float4x4!
    
    var texture: MTLTexture!
    var sampler:MTLSamplerState!
    
    var models:[Model] = []
    
    init(view _view:MTKView) {
        super.init()
        view = _view
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        lightPos = float4(300, 300, 300, 1)
        viewPos = float4(0, 0, 280, 1)
        
        viewMatrix = translationMatrix(float3(viewPos.x, viewPos.y, -viewPos.z))
        
        let aspect = Float(view.frame.width / view.frame.height)
        projMatrix = projectionMatrix(0.1, far: 1000, aspect: aspect, fovy: 1)
        
        for var i in 1 ... 10 {
            for var j in 1 ... 10 {
                let model = Model(index1: i, index2: j)
                model.setRender(renderEngine: self)
                models.append(model)
            }
        }
        
        let loader = MTKTextureLoader(device: device)
        let textureURL = URL(fileURLWithPath: Bundle.main.path(forResource: "res.bundle/cubemap", ofType: "png")!)
        let options = [
            MTKTextureLoader.Option.cubeLayout:MTKTextureLoader.CubeLayout.vertical,
            MTKTextureLoader.Option.allocateMipmaps:true,
            MTKTextureLoader.Option.generateMipmaps:true
            ] as [MTKTextureLoader.Option : Any]
        texture = try! loader.newTexture(URL: textureURL, options: options)
        
        let samplerDesc = MTLSamplerDescriptor()
        samplerDesc.minFilter = .linear
        samplerDesc.magFilter = .linear
        samplerDesc.mipFilter = .linear
        samplerDesc.lodMinClamp = 0
        samplerDesc.lodMaxClamp = 10
        sampler = device.makeSamplerState(descriptor: samplerDesc)

    }

    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView ) {
        guard let drawable = view.currentDrawable, let descriptor = view.currentRenderPassDescriptor else {
            fatalError("The MTKView resources are not available.")
        }
        
        let commandBuffer = commandQueue!.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        
        for model in models {
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.setFragmentSamplerState(sampler, index: 0)
            model.render(commandEncoder: commandEncoder)
        }
        
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        
        commandBuffer.commit()
    }
}

