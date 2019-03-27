//
//  SkyboxHeader.h
//  MetalTest
//
//  Created by Леонид Лядвейкин on 27/03/2019.
//  Copyright © 2019 Леонид Лядвейкин. All rights reserved.
//

#ifndef SkyboxHeader_h
#define SkyboxHeader_h

#import <simd/simd.h>

#ifdef __cplusplus

#define QUAD_VERTEX_BUFFER 0
#define QUAD_VERTEX_CONSTANT_BUFFER 1
#define QUAD_FRAGMENT_CONSTANT_BUFFER 0

#define QUAD_ENVMAP_TEXTURE 0
#define QUAD_IMAGE_TEXTURE 1

#define SKYBOX_VERTEX_BUFFER 0
#define SKYBOX_TEXCOORD_BUFFER 1
#define SKYBOX_CONSTANT_BUFFER 2
#define SKYBOX_IMAGE_TEXTURE 0


namespace AAPL
{
    struct VertexUniforms {
        simd::float4x4 viewProjectionMatrix;
        simd::float4x4 modelMatrix;
        simd::float3x3 normalMatrix;
        simd::float4x4 viewMatrix;
    };
}

#endif // cplusplus

#endif /* SkyboxHeader_h */
