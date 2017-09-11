
#include <metal_stdlib>

using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 texCoords [[attribute(3)]];
    float occlusion [[attribute(4)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 texCoords;
    float occlusion;
};

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
};

vertex VertexOut vertex_func(const VertexIn vertices [[stage_in]],
                             constant float4x4& projMat [[buffer(1)]],
                             uint vertexId [[vertex_id]])
{
    float4 position = vertices.position;
    VertexOut out;
    out.position = projMat * position;
    out.color = float4(1);
    out.texCoords = vertices.texCoords;
    out.occlusion = vertices.occlusion;
    return out;
}

fragment half4 fragment_func(VertexOut fragments [[stage_in]],
                             texture2d<float> textures [[texture(0)]])
{
    float4 baseColor = fragments.color;
    float4 occlusion = fragments.occlusion;
    constexpr sampler samplers;
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
//        return half4(baseColor);
//    return half4(baseColor * occlusion);
//    return half4(baseColor * texture);
    return half4(baseColor * occlusion * texture);
}

