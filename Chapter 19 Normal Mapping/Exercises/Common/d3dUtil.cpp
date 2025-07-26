
#include "d3dUtil.h"
#include <atlbase.h>
#include <codecvt>
#include <comdef.h>
#include <fstream>

using Microsoft::WRL::ComPtr;

DxException::DxException(HRESULT hr, const std::wstring& functionName, const std::wstring& filename, int lineNumber) :
    ErrorCode(hr),
    FunctionName(functionName),
    Filename(filename),
    LineNumber(lineNumber)
{
}

bool d3dUtil::IsKeyDown(int vkeyCode)
{
    return (GetAsyncKeyState(vkeyCode) & 0x8000) != 0;
}

ComPtr<ID3DBlob> d3dUtil::LoadBinary(const std::wstring& filename)
{
    std::ifstream fin(filename, std::ios::binary);

    fin.seekg(0, std::ios_base::end);
    std::ifstream::pos_type size = (int)fin.tellg();
    fin.seekg(0, std::ios_base::beg);

    ComPtr<ID3DBlob> blob;
    ThrowIfFailed(D3DCreateBlob(size, blob.GetAddressOf()));

    fin.read((char*)blob->GetBufferPointer(), size);
    fin.close();

    return blob;
}

Microsoft::WRL::ComPtr<ID3D12Resource> d3dUtil::CreateDefaultBuffer(
    ID3D12Device* device,
    ID3D12GraphicsCommandList* cmdList,
    const void* initData,
    UINT64 byteSize,
    Microsoft::WRL::ComPtr<ID3D12Resource>& uploadBuffer)
{
    ComPtr<ID3D12Resource> defaultBuffer;

    // Create the actual default buffer resource.
    ThrowIfFailed(device->CreateCommittedResource(
        &CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_DEFAULT),
        D3D12_HEAP_FLAG_NONE,
        &CD3DX12_RESOURCE_DESC::Buffer(byteSize),
		D3D12_RESOURCE_STATE_COMMON,
        nullptr,
        IID_PPV_ARGS(defaultBuffer.GetAddressOf())));

    // In order to copy CPU memory data into our default buffer, we need to create
    // an intermediate upload heap. 
    ThrowIfFailed(device->CreateCommittedResource(
        &CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD),
		D3D12_HEAP_FLAG_NONE,
        &CD3DX12_RESOURCE_DESC::Buffer(byteSize),
		D3D12_RESOURCE_STATE_GENERIC_READ,
        nullptr,
        IID_PPV_ARGS(uploadBuffer.GetAddressOf())));


    // Describe the data we want to copy into the default buffer.
    D3D12_SUBRESOURCE_DATA subResourceData = {};
    subResourceData.pData = initData;
    subResourceData.RowPitch = byteSize;
    subResourceData.SlicePitch = subResourceData.RowPitch;

    // Schedule to copy the data to the default buffer resource.  At a high level, the helper function UpdateSubresources
    // will copy the CPU memory into the intermediate upload heap.  Then, using ID3D12CommandList::CopySubresourceRegion,
    // the intermediate upload heap data will be copied to mBuffer.
	cmdList->ResourceBarrier(1, &CD3DX12_RESOURCE_BARRIER::Transition(defaultBuffer.Get(), 
		D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_COPY_DEST));
    UpdateSubresources<1>(cmdList, defaultBuffer.Get(), uploadBuffer.Get(), 0, 0, 1, &subResourceData);
	cmdList->ResourceBarrier(1, &CD3DX12_RESOURCE_BARRIER::Transition(defaultBuffer.Get(),
		D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_GENERIC_READ));

    // Note: uploadBuffer has to be kept alive after the above function calls because
    // the command list has not been executed yet that performs the actual copy.
    // The caller can Release the uploadBuffer after it knows the copy has been executed.


    return defaultBuffer;
}

ComPtr<ID3DBlob> d3dUtil::CompileShader(
    const std::wstring& filename,
    const D3D_SHADER_MACRO* defines,
    const std::string& entrypoint,
    const std::string& target)
{
    UINT compileFlags = 0;
#if defined(DEBUG) || defined(_DEBUG)  
    compileFlags = D3DCOMPILE_DEBUG | D3DCOMPILE_SKIP_OPTIMIZATION;
#endif

    HRESULT hr = S_OK;

    std::wstring printFilePath = L"Trying to compile: " + filename + L"\n";
    OutputDebugStringW(printFilePath.c_str());

	ComPtr<ID3DBlob> byteCode = nullptr;
	ComPtr<ID3DBlob> errors;
	hr = D3DCompileFromFile(filename.c_str(), defines, D3D_COMPILE_STANDARD_FILE_INCLUDE,
		entrypoint.c_str(), target.c_str(), compileFlags, 0, &byteCode, &errors);

	if(errors != nullptr)
		OutputDebugStringA((char*)errors->GetBufferPointer());

	ThrowIfFailed(hr);

	return byteCode;
}

#ifdef ENABLE_DXCOMPILER
ComPtr<ID3DBlob> d3dUtil::DxcCompileShader(const std::wstring& filename, const D3D_SHADER_MACRO* defines, const UINT32 definesCount, const std::wstring& entrypoint, const std::wstring& target, const std::wstring& shaderIncludePath)
{
	// ref: 
	// - https://simoncoenen.com/blog/programming/graphics/DxcCompiling
	// - https://posts.tanki.ninja/2019/07/11/Using-DXC-In-Practice/
	// - https://zhuanlan.zhihu.com/p/719575300

	ComPtr<IDxcUtils> pUtils;
	DxcCreateInstance(CLSID_DxcUtils, IID_PPV_ARGS(pUtils.GetAddressOf()));
	ComPtr<IDxcBlobEncoding> pSource;
	auto fullFileAddress = shaderIncludePath + L"\\" + filename;
	pUtils->LoadFile(fullFileAddress.c_str(), NULL, pSource.GetAddressOf());

	// Include 
	ComPtr<IDxcIncludeHandler> pIncludeHandler;
	pUtils->CreateDefaultIncludeHandler(pIncludeHandler.GetAddressOf());

	// Build Argument
	std::vector<LPCWSTR> selfBuildarguments;
	DxcGenerateArgements(selfBuildarguments, defines, definesCount, shaderIncludePath);

	ComPtr<IDxcCompilerArgs> args;
	pUtils->BuildArguments(
		filename.c_str(), entrypoint.c_str(), target.c_str(),
		selfBuildarguments.data(), selfBuildarguments.size(), nullptr, 0, args.GetAddressOf()
	);

	// print args to check
	auto argsP = args.Get();
	for (int i = 0; i < argsP->GetCount(); ++i) {
		OutputDebugString(argsP->GetArguments()[i]);
		OutputDebugString(L" ");
	}
	OutputDebugString(L"\n");

	ComPtr<IDxcCompiler3> dxcCompiler;
	HRESULT hr = DxcCreateInstance(CLSID_DxcCompiler, IID_PPV_ARGS(dxcCompiler.GetAddressOf()));
	ThrowIfFailed(hr);

	DxcBuffer sourceBuffer;
	sourceBuffer.Ptr = pSource->GetBufferPointer();
	sourceBuffer.Size = pSource->GetBufferSize();
	sourceBuffer.Encoding = 0;

	ComPtr<IDxcBlob> pDxilBlob;

	// compile & return & msg handling:
	//  version 1:
	// -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
	//ComPtr<IDxcOperationResult> pOperationResult;
	//hr = dxcCompiler->Compile(
	//    &sourceBuffer, args.Get()->GetArguments(), args.Get()->GetCount(), 
	//    pIncludeHandler.Get(), IID_PPV_ARGS(pOperationResult.GetAddressOf())
	//);

	//if (SUCCEEDED(hr)) {
	//    pOperationResult->GetResult(pDxilBlob.GetAddressOf());
	//}
	//else {
	//    ID3DBlob** ppErrorMsgs;
	//    pOperationResult->GetErrorBuffer((IDxcBlobEncoding**)ppErrorMsgs);
	//    LPCWSTR errorMsg = static_cast<LPCWSTR>((*ppErrorMsgs)->GetBufferPointer());
	//    OutputDebugString(errorMsg);
	//}
	// 
	// 
	// ComPtr<ID3DBlob> pOutput = reinterpret_cast<ID3DBlob*>(pDxilBlob.Get());
	// return pOutput;
	// -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   

	//  version 2:
	// -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
	ComPtr<IDxcResult> pCompileResult;
	hr = dxcCompiler->Compile(
		&sourceBuffer, args.Get()->GetArguments(), args.Get()->GetCount(),
		pIncludeHandler.Get(), IID_PPV_ARGS(pCompileResult.GetAddressOf())
	);

	ComPtr<IDxcBlobUtf8> pErrors;
	pCompileResult->GetOutput(DXC_OUT_ERRORS, IID_PPV_ARGS(pErrors.GetAddressOf()), nullptr);
	if (pErrors && pErrors->GetStringLength() > 0)
	{
		LPCSTR ansiStr = static_cast<LPCSTR>(pErrors->GetBufferPointer());
		int wideSize = MultiByteToWideChar(CP_ACP, 0, ansiStr, -1, nullptr, 0);
		std::wstring wideStr(wideSize, L'\0');
		MultiByteToWideChar(CP_ACP, 0, ansiStr, -1, &wideStr[0], wideSize);
		OutputDebugString(wideStr.c_str());
		OutputDebugString(L"\n");
		ThrowIfFailed(hr);
	}

	pCompileResult->GetOutput(DXC_OUT_OBJECT, IID_PPV_ARGS(pDxilBlob.GetAddressOf()), nullptr);
	return reinterpret_cast<ID3DBlob*>(pDxilBlob.Get());
	// -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
}

void d3dUtil::DxcGenerateArgements(std::vector<LPCWSTR>& arguments, const D3D_SHADER_MACRO* defines, const UINT32 definesCount, const std::wstring& shaderIncludePath)
{

    // -I for includes
    arguments.push_back(L"-I");
    arguments.push_back(shaderIncludePath.c_str());
    //arguments.push_back(L" ");

    arguments.push_back(L"-Qstrip_debug");
    arguments.push_back(L"-Qstrip_reflect");

    arguments.push_back(DXC_ARG_WARNINGS_ARE_ERRORS); //-WX
    arguments.push_back(DXC_ARG_DEBUG); //-Zi


    if (defines) {
        for (size_t i = 0; defines[i].Name != NULL; ++i)
        {
            arguments.push_back(L"-D");
            auto d = (LPCWSTR)defines[i].Name;
            arguments.push_back(d);
            //arguments.push_back(L" ");
        }
    }

    // log output
    //LPCWSTR* pArgs = arguments.data();
    //for (size_t i = 0; i < arguments.size(); ++i) {
    //    OutputDebugString(pArgs[i]);
    //    OutputDebugString(L" ");
    //}
    //OutputDebugString(L"\n");
}
#endif // ENABLE_DXCOMPILER


std::wstring DxException::ToString()const
{
    // Get the string description of the error code.
    _com_error err(ErrorCode);
    std::wstring msg = err.ErrorMessage();

    return FunctionName + L" failed in " + Filename + L"; line " + std::to_wstring(LineNumber) + L"; error: " + msg;
}


