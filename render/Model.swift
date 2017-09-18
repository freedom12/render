//
//  Model.swift
//  render
//
//  Created by wanghuai on 2017/9/17.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import MetalKit

class Model:NSObject  {
    var index1:Int = 0
    var index2:Int = 0
    weak var renderEngine:RenderEngine!
    
    var library: MTLLibrary!
    var uniformsBuffer: MTLBuffer!
    var vertexDescriptor: MTLVertexDescriptor!
    
    var depthStencilState: MTLDepthStencilState!
    var renderPipelineState: MTLRenderPipelineState!
    
    var meshes: [MTKMesh]!
    
    
    init(index1:Int, index2:Int) {
        self.index1 = index1
        self.index2 = index2
        super.init()
    }
    
    public func setRender(renderEngine:RenderEngine) {
        self.renderEngine = renderEngine
        let device = renderEngine.device!
        
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: descriptor)
        
        uniformsBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: [])
        guard let uniformsBuffer = uniformsBuffer else {
            fatalError("Buffer cannot be created.")
        }
        
        let scaled = scalingMatrix(1)
        let rotated = rotationMatrix(0, float3(0, 1, 0))
        let d:Float = 30.0
        let translated = translationMatrix(float3(-4.5*d+Float(index1-1)*d, -4.5*d+Float(index2-1)*d, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(translated, rotated), scaled)
        
        var params = float4(0.0)
        params.x = 1-Float(index1)/10.0
        params.y = 1-Float(index2)/10.0
        
        let uniforms = Uniforms(
            modelMatrix: modelMatrix,
            viewMatrix: renderEngine.viewMatrix,
            projMatrix: renderEngine.projMatrix,
            lightPos: renderEngine.lightPos,
            viewPos: renderEngine.viewPos,
            params: params
        )
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
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = renderEngine.view.colorPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = renderEngine.view.depthStencilPixelFormat
        renderPipelineDescriptor.stencilAttachmentPixelFormat = renderEngine.view.depthStencilPixelFormat
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
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
        let mtkBufferAllocator = MTKMeshBufferAllocator(device: device)
        guard let url = Bundle.main.url(forResource: "res.bundle/ball", withExtension: "obj") else {
            fatalError("Resource not found.")
        }
        let asset = MDLAsset(url: url, vertexDescriptor: desc, bufferAllocator: mtkBufferAllocator)
//        guard let mesh = asset.object(at: 0) as? MDLMesh else {
//            fatalError("Mesh not found.")
//        }
//        mesh.generateAmbientOcclusionVertexColors(withQuality: 1, attenuationFactor: 0.98, objectsToConsider: [mesh], vertexAttributeNamed: MDLVertexAttributeOcclusionValue)
        do {
            meshes = try MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes
        }
        catch let error {
            fatalError("\(error)")
        }
        
    }
    
    public func render(commandEncoder:MTLRenderCommandEncoder) {
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setCullMode(.back)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        
        guard let mesh = meshes?.first else {
            fatalError("Mesh not found.")
        }
        let vertexBuffer = mesh.vertexBuffers[0]
        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
        guard let submesh = mesh.submeshes.first else {
            fatalError("Submesh not found.")
        }
        commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
    }
}
