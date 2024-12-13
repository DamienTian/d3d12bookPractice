//***************************************************************************************
// SobelOperation.h by Hao Tian (C) 2024 All Rights Reserved.
//
// Performs the sobel operation to high light edges using the ComputeShader on the GPU.  
// The solution is saved to a floating-point texture. The resule texture will be used in
// main pixel shader to modifer final render style.
// 
// NOTE: This class was modeled after BlurFilter in BlurApp
//***************************************************************************************

#pragma once

#include "../Common/d3dUtil.h"

class SobelOperation
{
public:
	///<summary>
	/// The width and height should match the dimensions of the input texture to do sobel operation.
	/// Recreate when the screen is resized. 
	///</summary>
	SobelOperation(ID3D12Device* device, UINT width, UINT height, DXGI_FORMAT format);

	SobelOperation(const SobelOperation& rhs) = delete;
	SobelOperation& operator=(const SobelOperation& rhs) = delete;
	~SobelOperation() = default;

	ID3D12Resource* Output();

	void BuildDescriptors(CD3DX12_CPU_DESCRIPTOR_HANDLE hCpuDescriptor,CD3DX12_GPU_DESCRIPTOR_HANDLE hGpuDescriptor, UINT descriptorSize);

	void OnResize(UINT newWidth, UINT newHeight);

	///<summary>
	/// Perform sobel operation.
	///</summary>
	void Execute(ID3D12GraphicsCommandList* cmdList, ID3D12RootSignature* rootSig, 
		ID3D12PipelineState* sobelOpPSO, ID3D12Resource* input);

private:
	void BuildDescriptors();
	void BuildResources();

	ID3D12Device* md3dDevice = nullptr;

	UINT mWidth = 0;
	UINT mHeight = 0;
	DXGI_FORMAT mFormat = DXGI_FORMAT_R8G8B8A8_UNORM;

	CD3DX12_CPU_DESCRIPTOR_HANDLE mInputCpuSrv;
	CD3DX12_GPU_DESCRIPTOR_HANDLE mInputGpuSrv;

	CD3DX12_CPU_DESCRIPTOR_HANDLE mOutputCpuUav;
	CD3DX12_GPU_DESCRIPTOR_HANDLE mOutputGpuUav;

	Microsoft::WRL::ComPtr<ID3D12Resource> mInput = nullptr;
	Microsoft::WRL::ComPtr<ID3D12Resource> mOutput = nullptr;

};

