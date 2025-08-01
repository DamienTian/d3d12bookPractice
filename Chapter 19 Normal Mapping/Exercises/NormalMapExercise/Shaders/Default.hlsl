//***************************************************************************************
// Default.hlsl by Frank Luna (C) 2015 All Rights Reserved.
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

// Include common HLSL code.
#include "Common.hlsl"

struct VertexIn
{
	float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
	float3 TangentU : TANGENT;
};

struct VertexOut
{
	float4 PosH    : SV_POSITION;
    float3 PosW    : POSITION;
    float3 NormalW : NORMAL;
	float3 TangentW : TANGENT;
	float2 TexC    : TEXCOORD;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout = (VertexOut)0.0f;

	// Fetch the material data.
	MaterialData matData = gMaterialData[gMaterialIndex];
	
#ifdef EX2
	if (gDisplacementMapIndex >= 0)
	{
		float height = gDisplacementMaps[gDisplacementMapIndex].SampleLevel(gsamLinearWrap, vin.TexC, 0).r;
		vin.PosL.y += height;
	}
#endif

	float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
	
    // Transform to world space.
    vout.PosW = posW.xyz;

    // Assumes nonuniform scaling; otherwise, need to use inverse-transpose of world matrix.
    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);
	
	vout.TangentW = mul(vin.TangentU, (float3x3)gWorld);

    // Transform to homogeneous clip space.
    vout.PosH = mul(posW, gViewProj);
	
	// Output vertex attributes for interpolation across triangle.
	float4 texC = mul(float4(vin.TexC, 0.0f, 1.0f), gTexTransform);
	vout.TexC = mul(texC, matData.MatTransform).xy;
	
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
	// Fetch the material data.
	MaterialData matData = gMaterialData[gMaterialIndex];
	float4 diffuseAlbedo = matData.DiffuseAlbedo;
	float3 fresnelR0 = matData.FresnelR0;
	float  roughness = matData.Roughness;
	uint diffuseMapIndex = matData.DiffuseMapIndex;
	uint normalMapIndex = matData.NormalMapIndex;
	
	// Interpolating normal can unnormalize it, so renormalize it.
    pin.NormalW = normalize(pin.NormalW);
	
	float4 normalMapSample = gTextureMaps[normalMapIndex].Sample(gsamAnisotropicWrap, pin.TexC);

	// Dynamically look up the texture in the array.
	diffuseAlbedo *= gTextureMaps[diffuseMapIndex].Sample(gsamAnisotropicWrap, pin.TexC);

    // Vector from point being lit to eye. 
    float3 toEyeW = normalize(gEyePosW - pin.PosW);

    // Light terms.
    float4 ambient = gAmbientLight*diffuseAlbedo;

    const float shininess = (1.0f - roughness) * normalMapSample.a;
    Material mat = { diffuseAlbedo, fresnelR0, shininess };
    float3 shadowFactor = 1.0f;
	
	float3 bumpedNormalW = NormalSampleToWorldSpace(normalMapSample.rgb, pin.NormalW, pin.TangentW);
	
#ifdef EX4
	float3x3 invTBN = TransferFormWorldToTangentMatrix(normalMapSample.rgb, pin.NormalW, pin.TangentW);
	float3 posT = mul(pin.PosW, invTBN);
	float3 normalT = normalize(2.0f * normalMapSample.rgb - 1.0f); // uncompress and normalized
	float3 eyePosT = mul(gEyePosW, invTBN);
	float3 toEyeT = normalize(eyePosT - posT);
	
	float3 result = 0.0f;
	
	// Since only directional lights involved, this would only include directional lights
	for (int i = 0; i < NUM_DIR_LIGHTS; ++i)
	{
		Light lightT = gLights[i];
		lightT.Direction = normalize(mul(gLights[i].Direction, invTBN));
		result += shadowFactor[i] * ComputeDirectionalLight(lightT, mat, normalT, toEyeT);
	}
	
	float4 directLight = float4(result, 0.0f);
	
	float4 litColor = ambient + directLight;
	
#else
	
	//bumpedNormalW = pin.NormalW; // Uncomment to turn off normal mapping.
	
    float4 directLight = ComputeLighting(gLights, mat, pin.PosW,
        bumpedNormalW, toEyeW, shadowFactor);
		
	float4 litColor = ambient + directLight;
#endif//EX4

	// Add in specular reflections. 
	float3 r = reflect(-toEyeW, bumpedNormalW);
	float4 reflectionColor = gCubeMap.Sample(gsamLinearWrap, r); // EX4 note: cannot do gCubeMap.Sample in tangent space because tangent space is in world space
	float3 fresnelFactor = SchlickFresnel(fresnelR0, bumpedNormalW, r);
	litColor.rgb += shininess * fresnelFactor * reflectionColor.rgb;

    // Common convention to take alpha from diffuse albedo.
    litColor.a = diffuseAlbedo.a;

    return litColor;
}


