
#include <metal_stdlib>
using namespace metal;

enum {
    textureIndexBaseColor,
    textureIndexMetallic,
    textureIndexRoughness,
    textureIndexNormal,
    textureIndexEmissive,
    textureIndexIrradiance = 9
};

enum {
    vertexBufferIndexUniforms = 1
};

enum {
    fragmentBufferIndexUniforms = 0
};
    
    struct FogParameters {
        float3 color;
        float fStart;
        float fEnd;
        float fDensity;
        
        int iEquation;
    };

struct Vertex {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float3 tangent   [[attribute(2)]];
    float2 texCoords [[attribute(3)]];
};

struct VertexCarOut {
    float4 position [[position]];
    float2 texCoords;
    float3 worldPos;
    float3 normal;
    float3 bitangent;
    float3 tangent;
    
    float distance_to_object;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
    
    float3 cameraPos;
    float3 directionalLightInvDirection;
    float3 lightPosition;
};

struct LightingParameters {
    float3 lightDir;
    float3 viewDir;
    float3 halfVector;
    float3 reflectedVector;
    float3 normal;
    float3 reflectedColor;
    float3 irradiatedColor;
    float3 baseColor;
    float3 diffuseLightColor;
    float  NdotH;
    float  NdotV;
    float  NdotL;
    float  HdotL;
    float  metalness;
    float  roughness;
};
    
#define SRGB_ALPHA 0.055
    
    float getFogFactor1(FogParameters params, float fFogCoord)
    {
        float fResult = 0.0;
        if(params.iEquation == 0) // линейный туман
            fResult = (params.fEnd - fFogCoord)/(params.fEnd - params.fStart);
        else if(params.iEquation == 1) // экспоненциальный туман
            fResult = exp(-params.fDensity * fFogCoord);
        else if(params.iEquation == 2) // экспоненциальный туман 2
            fResult = exp(-pow(params.fDensity * fFogCoord, 2.0));
        fResult = 1.0 - clamp(fResult, 0.0, 1.0);
        return fResult;
    }

float linear_from_srgb(float x) {
    if (x <= 0.04045)
        return x / 12.92;
    else
        return powr((x + SRGB_ALPHA) / (1.0 + SRGB_ALPHA), 2.4);
}

float3 linear_from_srgb(float3 rgb) {
    return float3(linear_from_srgb(rgb.r), linear_from_srgb(rgb.g), linear_from_srgb(rgb.b));
}

vertex VertexCarOut vertex_helmet(Vertex in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(vertexBufferIndexUniforms)]])
{
    VertexCarOut out;
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    out.normal = uniforms.normalMatrix * in.normal;
    out.tangent = uniforms.normalMatrix * in.tangent;
    out.bitangent = uniforms.normalMatrix * cross(in.normal, in.tangent);
    out.worldPos = (uniforms.modelMatrix * float4(in.position, 1.0)).xyz;
    
    // Calculate the distance to the object which is used for how much fog obsures the object
    float4 position_modelviewspace = uniforms.modelViewMatrix * float4(in.position, 1);
    out.distance_to_object = abs(position_modelviewspace.z/position_modelviewspace.w);
    return out;
}

static float3 diffuseTerm(LightingParameters parameters) {
    float3 diffuseColor = (parameters.baseColor.rgb / M_PI_F) * (1.0 - parameters.metalness);
    return diffuseColor * parameters.NdotL * parameters.diffuseLightColor;
}

static float SchlickFresnel(float dotProduct) {
    return pow(clamp(1.0 - dotProduct, 0.0, 1.0), 5.0);
}

static float Geometry(float NdotV, float alphaG) {
    float a = alphaG * alphaG;
    float b = NdotV * NdotV;
    return 1.0 / (NdotV + sqrt(a + b - a * b));
}

static float TrowbridgeReitzNDF(float NdotH, float roughness) {
    if (roughness >= 1.0)
        return 1.0 / M_PI_F;
    
    float roughnessSqr = roughness * roughness;
    
    float d = (NdotH * roughnessSqr - NdotH) * NdotH + 1;
    return roughnessSqr / (M_PI_F * d * d);
}

static float3 specularTerm(LightingParameters parameters) {
    float specularRoughness = parameters.roughness * (1.0 - parameters.metalness) + parameters.metalness;
    
    float D = TrowbridgeReitzNDF(parameters.NdotH, specularRoughness);
    
    float Cspec0 = 0.04;
    float3 F = mix(Cspec0, 1, SchlickFresnel(parameters.HdotL));
    float alphaG = powr(specularRoughness * 0.5 + 0.5, 2);
    float G = Geometry(parameters.NdotL, alphaG) * Geometry(parameters.NdotV, alphaG);
    
    float3 specularOutput = (D * G * F * parameters.irradiatedColor) * (1.0 + parameters.metalness * parameters.baseColor) +
                                                 parameters.irradiatedColor * parameters.metalness * parameters.baseColor;
    
    return specularOutput;
}

fragment half4 fragment_helmet(VertexCarOut in                     [[stage_in]],
                             constant Uniforms &uniforms      [[buffer(fragmentBufferIndexUniforms)]],
                               constant FogParameters &fogParams [[buffer(1)]],
                             texture2d<float> baseColorMap    [[texture(textureIndexBaseColor)]],
                             texture2d<float> metallicMap     [[texture(textureIndexMetallic)]],
                             texture2d<float> roughnessMap    [[texture(textureIndexRoughness)]],
                             texture2d<float> normalMap       [[texture(textureIndexNormal)]],
                             texture2d<float> emissiveMap     [[texture(textureIndexEmissive)]],
                             texturecube<float> irradianceMap [[texture(textureIndexIrradiance)]])
{
    constexpr sampler linearSampler (mip_filter::linear, mag_filter::linear, min_filter::linear);
    constexpr sampler mipSampler(min_filter::linear, mag_filter::linear, mip_filter::linear);
    constexpr sampler normalSampler(filter::nearest);
    
    const float3 diffuseLightColor(4);

    LightingParameters parameters;

    float4 baseColor = baseColorMap.sample(linearSampler, in.texCoords);
    parameters.baseColor = linear_from_srgb(baseColor.rgb);
    parameters.roughness = roughnessMap.sample(linearSampler, in.texCoords).g;
    parameters.metalness = metallicMap.sample(linearSampler, in.texCoords).b;
    float3 mapNormal = normalMap.sample(normalSampler, in.texCoords).rgb * 2.0 - 1.0;
    //mapNormal.y = -mapNormal.y; // Flip normal map Y-axis if necessary
    float3x3 TBN(in.tangent, in.bitangent, in.normal);
    parameters.normal = normalize(TBN * mapNormal);

    parameters.diffuseLightColor = diffuseLightColor;
    parameters.lightDir = uniforms.directionalLightInvDirection;
    parameters.viewDir = normalize(uniforms.cameraPos - in.worldPos);
    parameters.halfVector = normalize(parameters.lightDir + parameters.viewDir);
    parameters.reflectedVector = reflect(-parameters.viewDir, parameters.normal);

    parameters.NdotL = saturate(dot(parameters.normal, parameters.lightDir));
    parameters.NdotH = saturate(dot(parameters.normal, parameters.halfVector));
    parameters.NdotV = saturate(dot(parameters.normal, parameters.viewDir));
    parameters.HdotL = saturate(dot(parameters.lightDir, parameters.halfVector));

    float mipLevel = parameters.roughness * irradianceMap.get_num_mip_levels();
    parameters.irradiatedColor = irradianceMap.sample(mipSampler, parameters.reflectedVector, level(mipLevel)).rgb;
    
    float3 emissiveColor = emissiveMap.sample(linearSampler, in.texCoords).rgb;

    float3 finalColor = diffuseTerm(parameters) + specularTerm(parameters) + emissiveColor;
    
    finalColor = mix(finalColor, fogParams.color, getFogFactor1(fogParams, in.distance_to_object));

    return half4(half3(finalColor), baseColor.a);
}
