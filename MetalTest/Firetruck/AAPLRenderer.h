/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for renderer class which performs Metal setup and per frame rendering
*/

@import Metal;
@import MetalKit;

// Our platform independent renderer class
@interface AAPLRenderer : NSObject<MTKViewDelegate>

@property (atomic) matrix_float4x4 projectionMatrix;
@property (atomic) matrix_float4x4 viewMatrix;
@property (atomic) vector_float3 cameraPos;

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
- (void)drawInMTKView:(nonnull MTKView *)view withCommandEncoder:(nonnull id)renderEncoder;

@end
