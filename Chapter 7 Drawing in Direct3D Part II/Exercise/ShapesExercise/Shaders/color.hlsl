//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************
 
// REMEMBER to change the macro in sources too
//#define EX2

#ifndef EX2
cbuffer cbPerObject : register(b0)
{
	float4x4 gWorld; 
};
#else
// Ex 2
cbuffer cbPerObject : register(b0)
{
	float w0; 
	float w1; 
	float w2; 
	float w3; 
	float w4; 
	float w5; 
	float w6; 
	float w7; 
	float w8; 
	float w9; 
	float w10; 
	float w11; 
	float w12; 
	float w13; 
	float w14; 
	float w15; 
};
#endif // !EX2

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
};

struct VertexIn
{
	float3 PosL  : POSITION;
    float4 Color : COLOR;
};

struct VertexOut
{
	float4 PosH  : SV_POSITION;
    float4 Color : COLOR;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;
	
#if defined(EX2)
    float4x4 gWorld =
    {
        { w0, w1, w2, w3 },
        { w4, w5, w6, w7 },
        { w8, w9, w10, w11 },
        { w12, w13, w14, w15 }
    };
#endif // EX2

	// Transform to homogeneous clip space.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosH = mul(posW, gViewProj);
	
	// Just pass vertex color into the pixel shader.
    vout.Color = vin.Color;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    return pin.Color;
}


