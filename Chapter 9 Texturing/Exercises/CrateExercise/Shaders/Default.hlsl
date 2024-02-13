//***************************************************************************************
// Default.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Default shader, currently supports lighting.
//***************************************************************************************

// Defaults for number of lights.
#ifndef NUM_DIR_LIGHTS
    #define NUM_DIR_LIGHTS 3
#endif

#ifndef NUM_POINT_LIGHTS
    #define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
    #define NUM_SPOT_LIGHTS 0
#endif

// Include structures and functions for lighting.
#include "LightingUtil.hlsl"

//#define EX1
#define EX3_4

#if defined(EX3_4)
Texture2D gTexture[2] : register(t0);
#else
Texture2D gDiffuseMap : register(t0);
#endif

#ifdef EX1
//SamplerState gsamLinear : register(s2); // linearWrap
//SamplerState gsamLinear : register(s3); // linearClamp
//SamplerState gsamLinear : register(s6); // linearBorder
SamplerState gsamLinear : register(s7); // linearMirror
#else
SamplerState gsamLinear  : register(s0);
//SamplerState gsamLinear  : register(s4);
#endif // EX1


// Constant data that varies per frame.
cbuffer cbPerObject : register(b0)
{
    float4x4 gWorld;
    float4x4 gTexTransform;
};

// Constant data that varies per material.
cbuffer cbPass : register(b1)
{
    float4x4 gView;
    float4x4 gInvView;
    float4x4 gProj;
    float4x4 gInvProj;
    float4x4 gViewProj;
    float4x4 gInvViewProj;
    float3 gEyePosW;
    float cbPerObjectPad1;
    float2 gRenderTargetSize;
    float2 gInvRenderTargetSize;
    float gNearZ;
    float gFarZ;
    float gTotalTime;
    float gDeltaTime;
    float4 gAmbientLight;

    // Indices [0, NUM_DIR_LIGHTS) are directional lights;
    // indices [NUM_DIR_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHTS) are point lights;
    // indices [NUM_DIR_LIGHTS+NUM_POINT_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHT+NUM_SPOT_LIGHTS)
    // are spot lights for a maximum of MaxLights per object.
    Light gLights[MaxLights];
};

cbuffer cbMaterial : register(b2)
{
	float4 gDiffuseAlbedo;
    float3 gFresnelR0;
    float  gRoughness;
    float4x4 gMatTransform;
};

struct VertexIn
{
	float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
};

struct VertexOut
{
	float4 PosH    : SV_POSITION;
    float3 PosW    : POSITION;
    float3 NormalW : NORMAL;
	float2 TexC    : TEXCOORD;
};

VertexOut VS(VertexIn vin)
{
#if defined(EX3_4)
    // EX4
    // change the UV sample range to (-0.5, 0.5), which makes the texture coordinate origin at the center of the texture
    //  math here: UV Range (0, 1) - (0.5f, 0.5f) = (-0.5, 0.5)
    vin.TexC -= float2(0.5f, 0.5f);
#endif
    
	VertexOut vout = (VertexOut)0.0f;
	
    // Transform to world space.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosW = posW.xyz;

    // Assumes nonuniform scaling; otherwise, need to use inverse-transpose of world matrix.
    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);

    // Transform to homogeneous clip space.
    vout.PosH = mul(posW, gViewProj);
    
    // Output vertex attributes for interpolation across triangle.
    float4 texC = mul(float4(vin.TexC, 0.0f, 1.0f), gTexTransform);
    vout.TexC = mul(texC, gMatTransform).xy;
    
#if defined(EX3_4)
    // EX4
    // move texture back to the center
    vout.TexC += float2(0.5f, 0.5f);
#endif

    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
#if defined(EX3_4)
    float4 diffuseAlbedo1 = gTexture[0].Sample(gsamLinear, pin.TexC) * gDiffuseAlbedo;
    float4 diffuseAlbedo2 = gTexture[1].Sample(gsamLinear, pin.TexC) * gDiffuseAlbedo;
    float4 diffuseAlbedo = diffuseAlbedo1 * diffuseAlbedo2;
#else
    float4 diffuseAlbedo = gDiffuseMap.Sample(gsamLinear, pin.TexC) * gDiffuseAlbedo;
#endif

    // Interpolating normal can unnormalize it, so renormalize it.
    pin.NormalW = normalize(pin.NormalW);

    // Vector from point being lit to eye. 
    float3 toEyeW = normalize(gEyePosW - pin.PosW);

    // Light terms.
    float4 ambient = gAmbientLight*diffuseAlbedo;

    const float shininess = 1.0f - gRoughness;
    Material mat = { diffuseAlbedo, gFresnelR0, shininess };
    float3 shadowFactor = 1.0f;
    float4 directLight = ComputeLighting(gLights, mat, pin.PosW,
        pin.NormalW, toEyeW, shadowFactor);

    float4 litColor = ambient + directLight;

    // Common convention to take alpha from diffuse material.
    litColor.a = diffuseAlbedo.a;

    return litColor;
}


