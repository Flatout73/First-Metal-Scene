/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal skybox shader
 */

#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>
#include <metal_stdlib>

#include "SkyboxHeader.h"

using namespace metal;

struct CubeVertexOutput
{
    float4 position [[position]];
    float3 texCoords;
};

vertex CubeVertexOutput skyboxVertex(constant float4 *pos_data [[ buffer(SKYBOX_VERTEX_BUFFER) ]],
                                     constant float4 *texcoord [[ buffer(SKYBOX_TEXCOORD_BUFFER) ]],
                                     constant AAPL::VertexUniforms& uniforms [[ buffer(SKYBOX_CONSTANT_BUFFER) ]],
                                     uint vid [[vertex_id]])
{
    CubeVertexOutput out;
    float4 worldPosition = uniforms.modelMatrix * pos_data[vid];
    out.position = uniforms.viewProjectionMatrix * worldPosition;
    out.texCoords = texcoord[vid].xyz;
    return out;
}

fragment half4 skyboxFragment(CubeVertexOutput in [[stage_in]],
                               texturecube<half> skybox_texture [[texture(SKYBOX_IMAGE_TEXTURE)]])
{
    constexpr sampler s_cube(filter::linear, mip_filter::linear);
    return skybox_texture.sample(s_cube, in.texCoords);
}
