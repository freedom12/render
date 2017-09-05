//
//  Shader.metal
//  render
//
//  Created by wanghuai on 2017/9/5.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;



struct VertexInput {
    float3 translation [[attribute(0)]];
    float2 texcoord0 [[attribute(1)]];
    //    float2 texcoord1 [[attribute(2)]];
    //    float2 texcoord2 [[attribute(3)]];
    uchar4 boneIndex [[attribute(2)]];
    float4 boneWeight [[attribute(3)]];
};

struct ShaderInOut {
    float4 translation [[position]];
    float2 texcoord0;
    //    float2 texcoord1;
    //    float2 texcoord2;
};


vertex ShaderInOut basic_vertex(
                                VertexInput in [[stage_in]],
                                constant float4x4& projMat [[buffer(1)]],
                                constant float4x4& mvMat [[buffer(2)]],
                                constant packed_float3* matetialMatArr [[buffer(3)]],
                                constant float4x4* transformArr [[buffer(4)]],
                                unsigned int vid [[ vertex_id ]]) {
    ShaderInOut out;
    int b0, b1, b2, b3;
    b0 = int(in.boneIndex[0]) & 0x1f;
    b1 = int(in.boneIndex[1]) & 0x1f;
    b2 = int(in.boneIndex[2]) & 0x1f;
    b3 = int(in.boneIndex[3]) & 0x1f;
    //    float4 pos = float4(in.translation, 1.0);
    float4 pos = transformArr[b0] * float4(in.translation, 1.0) * in.boneWeight[0];
    pos += transformArr[b1] * float4(in.translation, 1.0) * in.boneWeight[1];
    pos += transformArr[b2] * float4(in.translation, 1.0) * in.boneWeight[2];
    pos += transformArr[b3] * float4(in.translation, 1.0) * in.boneWeight[3];
    out.translation = projMat * mvMat * pos;
    
    float3x3 matetialMat = float3x3(matetialMatArr[0], matetialMatArr[1], matetialMatArr[2]);
    out.texcoord0.xy = (matetialMat * float3(in.texcoord0, 1.0)).xy;
    //    out.texcoord1.xy = float2(in.texcoord1).xy;
    //    out.texcoord2.xy = float2(in.texcoord2).xy;
    return out;
}

fragment half4 basic_fragment(
                              ShaderInOut in [[stage_in]],
                              sampler smp [[sampler(0)]],
                              texture2d<uint> diffuseTexture [[texture(0)]]) {
    uint4 color = diffuseTexture.sample(smp, float2(in.texcoord0));
    half4 ret = half4(color)/255.0;
    return half4(ret);
}
