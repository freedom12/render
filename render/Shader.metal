
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
    float3 lightDir;
    float3 normal;
    float3 halfVect;
    
    float4 color;
    float2 texCoords;};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projMatrix;
    float4 lightPos;
};

vertex VertexOut vertex_func(const VertexIn vertices [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]],
                             uint vertexId [[vertex_id]])
{
    float4 position = vertices.position;
    VertexOut out;
    out.position = uniforms.projMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position;
    out.color = float4(1);
    out.texCoords = vertices.texCoords;
    out.normal = normalize(vertices.normal).xyz;
    
    float4 lightPos = uniforms.lightPos;
    out.lightDir = normalize((lightPos - position).xyz);
    
    float4 viewPos = float4(0.0, 0.0, 50.0, 1);
    float3 eyeDir = normalize((viewPos - position).xyz);
    out.halfVect = normalize(eyeDir + out.lightDir);
    return out;
}

fragment half4 fragment_func(VertexOut fragments [[stage_in]],
                             texture2d<float> textures [[texture(0)]])
{
    float3 ambientColor = float3(0.7, 0, 0);
    float3 diffuseColor = float3(0.7, 0, 0);
    float3 specularColor = float3(0.4, 0, 0);
    
    float3 lightColor = float3(0.9, 0.9, 0.9);
    
    float3 normal = normalize(fragments.normal);
    float3 lightDir = normalize(fragments.lightDir);
    float3 halfVect = normalize(fragments.halfVect);
    
    float3 ambient = ambientColor * 0.2;
    float3 diffuse = diffuseColor * lightColor * saturate(dot(lightDir, normal));
    float k = 0;
    if (dot(lightDir, normal) > 0)
    {
        k = 1;
    }
    float3 specular = specularColor * lightColor * pow(saturate(dot(normal, halfVect)), 40);
    float3 color = ambient + diffuse + specular;
    return half4(color.x, color.y, color.z, 1.0);
//    constexpr sampler samplers;
//    float4 texture = textures.sample(samplers, fragments.texCoords);
    
//    return half4(baseColor);
//    return half4(baseColor * occlusion);
//    return half4(baseColor * texture);
//    return half4(baseColor * occlusion * texture);
}

