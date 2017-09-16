
#include <metal_stdlib>

using namespace metal;

#define PI 3.1415926
#define GAMMA 2.2

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 texCoords [[attribute(3)]];
    float occlusion [[attribute(4)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 fragPos;
    float3 normal;
    float2 texCoords;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projMatrix;
    float4 lightPos;
    float4 viewPos;
};

vertex VertexOut vertex_func(const VertexIn vertices [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]],
                             uint vertexId [[vertex_id]])
{
    VertexOut out;
    
    float4 position = uniforms.modelMatrix * vertices.position;
    out.position = uniforms.projMatrix * uniforms.viewMatrix * position;
    out.texCoords = vertices.texCoords;
    out.normal = normalize(uniforms.modelMatrix * vertices.normal).xyz;
    out.fragPos = position.xyz;
    
    return out;
}

float distributionGGX(float3 n, float3 h, float roughness)
{
    float a = max(roughness * roughness, 0.0001);
//    a = roughness;
    float a2 = a * a;
    float nh = max(dot(n, h), 0.0);
    float nh2 = nh * nh;
    
    float nom =  a2;
    float denom = nh2 * (a2 - 1.0) + 1.0;
//    float denom = nh2 * (a2 + (1 - nh2) / nh2);
    denom = PI * denom * denom;
    
    return nom / denom;
}

float geometrySchlickGGX(float nv, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    k = roughness;
    float nom = nv;
    float denom = nv * (1.0 - k) + k;
    
    return nom / denom;
}

float geometrySmith(float3 n, float3 v, float3 l, float roughness)
{
    float nv = max(dot(n, v), 0.0);
    float nl = max(dot(n, l), 0.0);
    float ggx1 = geometrySchlickGGX(nv, roughness);
    float ggx2 = geometrySchlickGGX(nl, roughness);
    return ggx1 * ggx2;
}

float3 fresnelSchlick(float cosTheta, float3 f0)
{
    return f0 + (float3(1.0) - f0) * pow((1.0 - cosTheta), 5.0);
}

fragment half4 fragment_func(VertexOut fragments [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]],
                             texturecube<float> cubeTexture [[texture(0)]],
                             sampler cubeSampler [[sampler(0)]])
{
    float metallic = 1;
    float roughness = 0;
    float reflectivity = 0.7;
    float specular = 0.04;
    float3 albedo = float3(1, 0, 0);
    float3 lightColor = float3(1);
    
    float3 f0 = mix(float3(specular), albedo, metallic);
    
    float3 color = float3(0);
    
    float3 fragPos = fragments.fragPos;
    float3 viewPos = uniforms.viewPos.xyz;
    float3 lightPos = uniforms.lightPos.xyz;
    
    float3 n = normalize(fragments.normal);
    float3 v = normalize(viewPos - fragPos);
    
//    for (int i = 0; i < 4; i++)
//    {
//        if (i == 0)
//        {
//            lightPos = float3(50, 50, 50);
//        }
//        else if (i == 1)
//        {
//            lightPos = float3(50, -50, 50);
//        }
//        else if (i == 2)
//        {
//            lightPos = float3(-50, 50, 50);
//        }
//        else if (i == 3)
//        {
//            lightPos = float3(-50, -50, 50);
//        }
    
        
        float3 l = normalize(lightPos - fragPos);
        float3 h = normalize(v + l);
    
    
        float NDF = distributionGGX(n, h, roughness);
        float G = geometrySmith(n, v, l, roughness);
        float3 F = fresnelSchlick(max(dot(v, h), 0.0), f0);
        
        float3 kS = F;
        float3 kD = (float3(1.0) - kS) * (1.0 - metallic);
        
        float3 nom = NDF * G * F;
        float denom = 4 * max(dot(n, v), 0.0) * max(dot(n, l), 0.0) + 0.0001;
        float3 BRDF = nom / denom;
        color = color + (kD * albedo/PI + BRDF) * lightColor * max(dot(n, l), 0.0);
//    }
    
    float3 ambient = float3(0.03) * albedo * (1 - metallic);//*ao;
    color = color + ambient;
    
    float3 r = reflect(-v, n);
    r.x = -r.x;
    float3 env_fresnel = f0 + (max(f0, 1.0 - roughness) - f0) * pow((1.0 - max(dot(n, v), 0.0)), 10.0);
    float3 reflection = float3(0.5);//textureCube(environment, reflect_vector, alpha * 15.0).rgb;
    reflection = cubeTexture.sample(cubeSampler, r, level(roughness * 10)).xyz;
    reflection = pow(reflection, float3(GAMMA));
    reflection = reflection * env_fresnel * reflectivity;
    color = color + reflection;
    
    
    color = color / (color + float3(1.0));
    color = pow(color, float3(1.0/GAMMA));
    
    
    return half4(color.x, color.y, color.z, 1.0);
    
    
    
//    float3 ambient = albedo * 0;
//    float3 diffuse = (1 - metallic) * albedo * lightColor * saturate(dot(l, n));
//    float3 specular = f0 * lightColor * pow(saturate(dot(n, h)), roughness) * (roughness + 2)/8;
//    float3 color = ambient + diffuse + specular;
    
//    return half4(normal.x, normal.y, normal.z, 1.0);
//    constexpr sampler samplers;
//    float4 texture = textures.sample(samplers, fragments.texCoords);
    
//    return half4(baseColor);
//    return half4(baseColor * occlusion);
//    return half4(baseColor * texture);
//    return half4(baseColor * occlusion * texture);
}

