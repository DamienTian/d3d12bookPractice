//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************

cbuffer cbPerObject : register(b0)
{
	float4x4 gWorldViewProj; 
    float4 gPulseColor;
    float gTime;
};

//struct VertexIn
//{
//    float3 Pos : POSITION;
//    //float3 Tangent : TANGENT;
//    //float3 Normal : NORMAL;
//    //float2 Tex0 : TEX0;
//    //float2 Tex1 : TEX1;
//    float4 Color : COLOR;
//};

// EX 11 (b)
//  Explaination: still works because as long as it match the Input Layout names
struct VertexIn
{
    float4 Color : COLOR;
    float3 PosL : POSITION;
};

struct VertexOut
{
	float4 PosH  : SV_POSITION;
    float4 Color : COLOR;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;
	
    // Ex 6
    //vin.PosL.xy += 0.5f * sin(vin.PosL.x) * sin(3.0f * gTime);
    //vin.PosL.z *= 0.6f + 0.4f * sin(2.0f * gTime);
    
	// Transform to homogeneous clip space.
	vout.PosH = mul(float4(vin.PosL, 1.0f), gWorldViewProj);
	
	// Just pass vertex color into the pixel shader.
    vout.Color = vin.Color;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    // return pin.Color;

    // Ex 14
    // float4 finalColor = pin.Color * sin(gTime);
	// return finalColor;

    // Ex 15
    // clip(pin.Color.r - 0.4f);
    // return pin.Color;

    const float pi = 3.14159;
    // Oscillate a value in [0,1] over time using a sine function.
    float s = 0.5f*sin(2*gTime - 0.25f*pi)+0.5f;
    // Linearly interpolate between pin.Color and gPulseColor based on parameter s.
    float4 c = lerp(pin.Color, gPulseColor, s);
    return c;
}


