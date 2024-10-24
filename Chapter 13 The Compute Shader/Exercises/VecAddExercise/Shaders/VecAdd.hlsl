#define EX1
//#define EX2

#if defined(EX1)
struct DataIn
{
    float3 v;
    float mag;
};

struct DataOut
{
    float3 v;
    float mag;
    float calMag;
};

StructuredBuffer<DataIn> gInput : register(t0);
RWStructuredBuffer<DataOut> gOutput : register(u0);

[numthreads(64, 1, 1)]
void CS(int3 dtid : SV_DispatchThreadID)
{
	// Use dispatch thread ID to index into output and input textures
    gOutput[dtid.x].v = gInput[dtid.x].v;
    gOutput[dtid.x].mag = gInput[dtid.x].mag;
    gOutput[dtid.x].calMag = length(gInput[dtid.x].v);

}
#elif defined(EX2)
StructuredBuffer<float3> gInput : register(t0);
RWStructuredBuffer<float> gOutput : register(u0);

[numthreads(64, 1, 1)]
void CS(int3 dtid : SV_DispatchThreadID)
{
    gOutput[dtid.x] = length(gInput[dtid.x]);
}
#else // origin
struct Data
{
	float3 v1;
	float2 v2;
};

StructuredBuffer<Data> gInputA : register(t0);
StructuredBuffer<Data> gInputB : register(t1);
RWStructuredBuffer<Data> gOutput : register(u0);


[numthreads(32, 1, 1)]
void CS(int3 dtid : SV_DispatchThreadID)
{
	// Use dispatch thread ID to index into output and input textures
	gOutput[dtid.x].v1 = gInputA[dtid.x].v1 + gInputB[dtid.x].v1;
	gOutput[dtid.x].v2 = gInputA[dtid.x].v2 + gInputB[dtid.x].v2;
}

#endif
