// This shader file is for multiple exercises

// EX2 ref: https://ask.csdn.net/questions/7604699?weChatOA=weChatOA1

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

//#define EX2
#define EX3

Texture2DArray gTreeMapArray : register(t0);

SamplerState gsamPointWrap : register(s0);
SamplerState gsamPointClamp : register(s1);
SamplerState gsamLinearWrap : register(s2);
SamplerState gsamLinearClamp : register(s3);
SamplerState gsamAnisotropicWrap : register(s4);
SamplerState gsamAnisotropicClamp : register(s5);

// Constant data that varies per frame.
cbuffer cbPerObject : register(b0)
{
    float4x4 gWorld;
    float4x4 gWorldInvTranspose;
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

    float4 gFogColor;
    float gFogStart;
    float gFogRange;
    float2 cbPerObjectPad2;

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
    float gRoughness;
    float4x4 gMatTransform;
};

struct VertexIn
{
    float3 PosL : POSITION;
    float3 NormalL : NORMAL;
    float2 TexC : TEXCOORD;
};

struct VertexOut
{
    float4 PosH : SV_POSITION;
    float3 PosL : POSITION;
    float3 NormalL : NORMAL;
    float2 TexC : TEXCOORD;
};

struct GeoOut
{
    float4 PosH : SV_POSITION;
    float3 PosW : POSITION;
    float3 NormalW : NORMAL;
    float2 TexC : TEXCOORD;
    uint PrimID : SV_PrimitiveID;
};

VertexOut VS(VertexIn vin)
{
    VertexOut vout;

    // Just pass data over to geometry shader.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosH = mul(posW, gViewProj);
    vout.PosL = vin.PosL;
    vout.NormalL = vin.NormalL;
    vout.TexC = vin.TexC;

    return vout;
}

VertexOut MidPoint(VertexOut lhs, VertexOut rhs)
{
    lhs.PosL = normalize(lhs.PosL);
    rhs.PosL = normalize(rhs.PosL);
    
    VertexOut m;

    m.PosL = 0.5f * (lhs.PosL + rhs.PosL) * 3.0f; // 乘以球的半径
   // m.PosL = normalize(m.PosL);
    m.NormalL = m.PosL;
    m.TexC = 0.5f * (lhs.TexC + rhs.TexC);

    return m;
}

GeoOut ToGeoOut(VertexOut inVert, uint primID)
{
    GeoOut gout;

    // 将顶点变换到世界空间
    gout.PosW = mul(float4(inVert.PosL, 1.0f), gWorld).xyz;
    gout.NormalW = mul(inVert.NormalL, (float3x3) gWorldInvTranspose);

    // 把顶点变换到齐次裁剪空间
    gout.PosH = mul(float4(gout.PosW, 1.0f), gViewProj);
    gout.TexC = inVert.TexC;

    gout.PrimID = primID;
    return gout;
}

void SubdivideAndOutput(VertexOut inVerts[3], int subCnt, inout TriangleStream<GeoOut> triStream, uint primID)
{
    VertexOut m[10][10], t[10][10];
    int row = 2, col = 2, i = 0, j = 0;
    m[0][0] = inVerts[0];
    m[1][0] = inVerts[1];
    m[0][1] = inVerts[2];

    while (subCnt--)
    {
        for (i = 0; i < row; ++i)
        {
            int cur_col = col - i; // 当前行的列数
            for (j = 0; j < cur_col; ++j)
            {
                int targetRow = 2 * i, targetCol = 2 * j;
                t[targetRow][targetCol] = m[i][j];

                if (j < cur_col - 1)
                {
                    // 向上寻找中点
                    t[targetRow + 1][targetCol] = MidPoint(m[i][j], m[i + 1][j]);
                    // 向右寻找中点
                    t[targetRow][targetCol + 1] = MidPoint(m[i][j], m[i][j + 1]);
                }
                if (i > 0)
                {
                    // 当非三角形最上方顶点时，向斜下方寻找中点
                    t[targetRow - 1][targetCol + 1] = MidPoint(m[i][j], m[i - 1][j + 1]);
                }
            }
        }
        row = 2 * row - 1;
        col = 2 * col - 1;
        // 拷贝t->m
        for (i = 0; i < row; ++i)
            for (j = 0; j < col - i; ++j)
                m[i][j] = t[i][j];
    }

    // 将顶点按三角形带加入输出流
    for (i = 0; i < row; ++i)
    {
        int cur_col = col - i;
        for (j = 0; j < cur_col - 1; ++j)
        {
            triStream.Append(ToGeoOut(m[i][j], primID));
            triStream.Append(ToGeoOut(m[i + 1][j], primID));
        }
        if (i + 1 != row)
            triStream.Append(ToGeoOut(m[i][cur_col - 1], primID));
        triStream.RestartStrip(); // 记录完一行三角形，重新开始记录下一行
    }
}

#if defined(EX2)
[maxvertexcount(75)]
void GS(triangle VertexOut gin[3], uint primID : SV_PrimitiveID, inout TriangleStream<GeoOut> triStream)
{
    float3 posW = float3(gWorld._m30, gWorld._m31, gWorld._m32);
    float dis = distance(posW, gEyePosW);
    int subCnt = 0;

    if (dis < 15)
        subCnt = 2;
    else if (dis < 30)
        subCnt = 1;
    else
        subCnt = 0;

    SubdivideAndOutput(gin, subCnt, triStream, primID);
}
#elif defined(EX3)
[maxvertexcount(3)]
void GS(triangle VertexOut gin[3], uint primID : SV_PrimitiveID, inout TriangleStream<GeoOut> triStream)
{
    // compute face normal
    float3 v1 = gin[1].PosL - gin[0].PosL;
    float3 v2 = gin[2].PosL - gin[0].PosL;
    float3 faceNormal = normalize(cross(v1, v2)) * primID;
    
    GeoOut gout;
	[unroll]
    for (int i = 0; i < 3; ++i)
    {
        gout.PosW = mul(float4(gin[i].PosL + gTotalTime * faceNormal, 1.0f), gWorld).xyz;
        gout.PosH = mul(float4(gout.PosW, 1.0f), gViewProj);
        gout.NormalW = mul(float4(gin[i].NormalL, 0.0f), gInvViewProj);
        gout.TexC = gin[i].TexC;
        gout.PrimID = primID;
		
        triStream.Append(gout);
    }
}
#else
[maxvertexcount(3)]
void GS(triangle VertexOut gin[3], uint primID : SV_PrimitiveID, inout TriangleStream<GeoOut> triStream)
{
    GeoOut gout;
	[unroll]
    for (int i = 0; i < 3; ++i)
    {
        gout.PosH = mul(float4(gin[i].PosL, 1.0f), gViewProj);
        gout.PosW = mul(float4(gin[i].PosL, 1.0f), gWorld).xyz;
        gout.NormalW = normalize(mul(float4(gin[i].NormalL, 0.0f), gInvViewProj));
        gout.TexC = gin[i].TexC;
        gout.PrimID = primID;
		
        triStream.Append(gout);
    }
}
#endif

float4 PS(VertexOut pin) : SV_Target
{
    return float4(1.0f, 1.0f, 1.0f, 1.0f);
}