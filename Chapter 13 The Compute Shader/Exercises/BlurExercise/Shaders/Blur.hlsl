//=============================================================================
// Performs a separable Guassian blur with a blur radius up to 5 pixels.
//=============================================================================

#define EX4 // same macro in BlurFilter.cpp
// ref: https://blog.csdn.net/juwell0512/article/details/52276193

cbuffer cbSettings : register(b0)
{
	// We cannot have an array entry in a constant buffer that gets mapped onto
	// root constants, so list each element.  
	
	int gBlurRadius;

	// Support up to 11 blur weights.
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
};

static const int gMaxBlurRadius = 5;
static const float bilateralSigma = 25.0f;

Texture2D gInput            : register(t0);
RWTexture2D<float4> gOutput : register(u0);

#define N 256
#define CacheSize (N + 2*gMaxBlurRadius)
groupshared float4 gCache[CacheSize];

float pixelDiffWeight(float4 p1, float4 p2)
{
    return -pow((p1.r * 255 + p1.g * 255 + p1.b * 255) - (p2.r * 255 + p2.g * 255 + p2.b * 255), 2);
}

void BilateralWeightPixel(float center, out float result[11])
{
    float twoSigma2 = 2.0f * bilateralSigma * bilateralSigma;
    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
    {
        int k = center + i;
        result[i + gBlurRadius] = pixelDiffWeight(gCache[center], gCache[k]) / twoSigma2;
    }
}

[numthreads(N, 1, 1)]
void HorzBlurCS(int3 groupThreadID : SV_GroupThreadID,
				int3 dispatchThreadID : SV_DispatchThreadID)
{
	// Put in an array for each indexing.
	float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

	//
	// Fill local thread storage to reduce bandwidth.  To blur 
	// N pixels, we will need to load N + 2*BlurRadius pixels
	// due to the blur radius.
	//
	
	// This thread group runs N threads.  To get the extra 2*BlurRadius pixels, 
	// have 2*BlurRadius threads sample an extra pixel.
	if(groupThreadID.x < gBlurRadius)
	{
		// Clamp out of bound samples that occur at image borders.
		int x = max(dispatchThreadID.x - gBlurRadius, 0);
		gCache[groupThreadID.x] = gInput[int2(x, dispatchThreadID.y)];
	}
	if(groupThreadID.x >= N-gBlurRadius)
	{
		// Clamp out of bound samples that occur at image borders.
		int x = min(dispatchThreadID.x + gBlurRadius, gInput.Length.x-1);
		gCache[groupThreadID.x+2*gBlurRadius] = gInput[int2(x, dispatchThreadID.y)];
	}

	// Clamp out of bound samples that occur at image borders.
	gCache[groupThreadID.x+gBlurRadius] = gInput[min(dispatchThreadID.xy, gInput.Length.xy-1)];

	// Wait for all threads to finish.
	GroupMemoryBarrierWithGroupSync();
	
	//
	// Now blur each pixel.
	//

	float4 blurColor = float4(0, 0, 0, 0);
#if defined(EX4)
    float weightTotal = 0.0f;
    float bilateralWeights[11];
    float center = groupThreadID.x + gBlurRadius;
    BilateralWeightPixel(center, bilateralWeights);
#endif
	
	for(int i = -gBlurRadius; i <= gBlurRadius; ++i)
	{
		int k = groupThreadID.x + gBlurRadius + i;
		
#if defined(EX4)
        float wp_i = exp(weights[i + gBlurRadius] + bilateralWeights[gBlurRadius + i]);
        blurColor += wp_i * gCache[k];
        weightTotal += wp_i;
#else
		blurColor += weights[i+gBlurRadius]*gCache[k];
#endif
    }

#if defined(EX4)
    blurColor.r /= (weightTotal);
    blurColor.g /= (weightTotal);
    blurColor.b /= (weightTotal);
#endif
	
	gOutput[dispatchThreadID.xy] = blurColor ;
}


// Q: why different numthreads?
[numthreads(1, N, 1)]
void VertBlurCS(int3 groupThreadID : SV_GroupThreadID,
				int3 dispatchThreadID : SV_DispatchThreadID)
{
	// Put in an array for each indexing.
	float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

	//
	// Fill local thread storage to reduce bandwidth.  To blur 
	// N pixels, we will need to load N + 2*BlurRadius pixels
	// due to the blur radius.
	//
	
	// This thread group runs N threads.  To get the extra 2*BlurRadius pixels, 
	// have 2*BlurRadius threads sample an extra pixel.
	if(groupThreadID.y < gBlurRadius)
	{
		// Clamp out of bound samples that occur at image borders.
		int y = max(dispatchThreadID.y - gBlurRadius, 0);
		gCache[groupThreadID.y] = gInput[int2(dispatchThreadID.x, y)];
	}
	if(groupThreadID.y >= N-gBlurRadius)
	{
		// Clamp out of bound samples that occur at image borders.
		int y = min(dispatchThreadID.y + gBlurRadius, gInput.Length.y-1);
		gCache[groupThreadID.y+2*gBlurRadius] = gInput[int2(dispatchThreadID.x, y)];
	}
	
	// Clamp out of bound samples that occur at image borders.
	gCache[groupThreadID.y+gBlurRadius] = gInput[min(dispatchThreadID.xy, gInput.Length.xy-1)];


	// Wait for all threads to finish.
	GroupMemoryBarrierWithGroupSync();
	
	//
	// Now blur each pixel.
	//

	float4 blurColor = float4(0, 0, 0, 0);
#if defined(EX4)
    float weightTotal = 0.0f;
    float bilateralWeights[11];
    float center = groupThreadID.y + gBlurRadius;
    BilateralWeightPixel(center, bilateralWeights);
#endif
    
	for(int i = -gBlurRadius; i <= gBlurRadius; ++i)
	{
		int k = groupThreadID.y + gBlurRadius + i;
		
#if defined(EX4)
        float wp_i = exp(weights[i + gBlurRadius] + bilateralWeights[gBlurRadius + i]);
        blurColor += wp_i * gCache[k];
        weightTotal += wp_i;
#else
		blurColor += weights[i+gBlurRadius]*gCache[k];
#endif
    }
	
#if defined(EX4)
    blurColor.r /= (weightTotal);
    blurColor.g /= (weightTotal);
    blurColor.b /= (weightTotal);
#endif
	
	gOutput[dispatchThreadID.xy] = blurColor;
}
