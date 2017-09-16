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
    var library: MTLLibrary!
    var renderPipelineState: MTLRenderPipelineState!
    var uniformsBuffer: MTLBuffer!
    var meshes: [MTKMesh]!
    var texture: MTLTexture!
    var sampler:MTLSamplerState!
    var depthStencilState: MTLDepthStencilState!
    var vertexDescriptor: MTLVertexDescriptor!
    
    init(view _view:MTKView) {
        super.init()
        view = _view
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: descriptor)
        
        let lightPos = float4(50, 50, 50, 1)
        let viewPos = float4(0, 0, 30, 1)
        
        let viewMatrix = translationMatrix(float3(viewPos.x, viewPos.y, -viewPos.z))
        
        let scaled = scalingMatrix(1)
        let rotated = rotationMatrix(0, float3(0, 1, 0))
        let translated = translationMatrix(float3(0, 0, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(translated, rotated), scaled)
        
        let aspect = Float(view.frame.width / view.frame.height)
        let projMatrix = projectionMatrix(0.1, far: 100, aspect: aspect, fovy: 1)
        
        uniformsBuffer = device!.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [])
        guard let uniformsBuffer = uniformsBuffer else {
            fatalError("Buffer cannot be created.")
        }
        let uniforms = Uniforms(modelMatrix: modelMatrix, viewMatrix: viewMatrix, projMatrix: projMatrix, lightPos: lightPos, viewPos: viewPos)
        uniformsBuffer.contents().storeBytes(of: uniforms, toByteOffset: 0, as: Uniforms.self)
        
        
        library = device.makeDefaultLibrary()
        let vert_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        
        
        vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float3 // position
        vertexDescriptor.attributes[1].offset = 12
        vertexDescriptor.attributes[1].format = MTLVertexFormat.float3 // normal
        vertexDescriptor.attributes[2].offset = 24
        vertexDescriptor.attributes[2].format = MTLVertexFormat.uchar4 // color
        vertexDescriptor.attributes[3].offset = 28
        vertexDescriptor.attributes[3].format = MTLVertexFormat.half2 // texture
        vertexDescriptor.attributes[4].offset = 32
        vertexDescriptor.attributes[4].format = MTLVertexFormat.float // occlusion
        vertexDescriptor.layouts[0].stride = 36
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.vertexFunction = vert_func
        renderPipelineDescriptor.fragmentFunction = frag_func
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        renderPipelineDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat
        do {
            renderPipelineState = try device!.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }
        catch let error {
            fatalError("\(error)")
        }
        
        
        let desc = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        var attribute = desc.attributes[0] as! MDLVertexAttribute
        attribute.name = MDLVertexAttributePosition
        attribute = desc.attributes[1] as! MDLVertexAttribute
        attribute.name = MDLVertexAttributeNormal
        attribute = desc.attributes[2] as! MDLVertexAttribute
        attribute.name = MDLVertexAttributeColor
        attribute = desc.attributes[3] as! MDLVertexAttribute
        attribute.name = MDLVertexAttributeTextureCoordinate
        attribute = desc.attributes[4] as! MDLVertexAttribute
        attribute.name = MDLVertexAttributeOcclusionValue
        let mtkBufferAllocator = MTKMeshBufferAllocator(device: device!)
        guard let url = Bundle.main.url(forResource: "res.bundle/ball", withExtension: "obj") else {
            fatalError("Resource not found.")
        }
        let asset = MDLAsset(url: url, vertexDescriptor: desc, bufferAllocator: mtkBufferAllocator)
        guard let mesh = asset.object(at: 0) as? MDLMesh else {
            fatalError("Mesh not found.")
        }
        mesh.generateAmbientOcclusionVertexColors(withQuality: 1, attenuationFactor: 0.98, objectsToConsider: [mesh], vertexAttributeNamed: MDLVertexAttributeOcclusionValue)
        do {
            meshes = try MTKMesh.newMeshes(asset: asset, device: device!).metalKitMeshes
        }
        catch let error {
            fatalError("\(error)")
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
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setCullMode(.back)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        
        guard let mesh = meshes?.first else {
            fatalError("Mesh not found.")
        }
        let vertexBuffer = mesh.vertexBuffers[0]
        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
        guard let submesh = mesh.submeshes.first else {
            fatalError("Submesh not found.")
        }
        commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

