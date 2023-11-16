#include "MathHelper.h"
#include "UploadBuffer.h"

using namespace DirectX;
using namespace DirectX::PackedVector;

struct Vertex
{
    XMFLOAT3 Pos;
    XMFLOAT4 Color;
};

// Ex 1
//struct Vertex
//{
//	XMFLOAT3 Pos;
//	XMFLOAT3 Tangent;
//	XMFLOAT3 Normal;
//	XMFLOAT2 Tex0;
//	XMFLOAT2 Tex1;
//	XMFLOAT4 Color; // XMCOLOR Color; in Ex 1 will cause color info lost, which makes the box not render correctlly
//
//	Vertex(XMFLOAT3 pos, XMFLOAT4 color) : Pos(pos), Color(color) {
//		Tangent = XMFLOAT3(0.0f, 0.0f, 0.0f);
//		Normal = XMFLOAT3(0.0f, 0.0f, 0.0f);
//		Tex0 = XMFLOAT2(0.0f, 0.0f);
//		Tex1 = XMFLOAT2(0.0f, 0.0f);
//	}
//};

// Ex 2
struct VPosData
{
	XMFLOAT3 Pos;
};
struct VColorData
{
	XMFLOAT4 Color;
};

// Ex 10
//struct Vertex 
//{
//	XMFLOAT3 Pos;
//	XMCOLOR Color;
//};

Vertex v1({ XMFLOAT3(-1.0f, -1.0f, -1.0f), XMFLOAT4(Colors::White) });
Vertex v2({ XMFLOAT3(-1.0f, +1.0f, -1.0f), XMFLOAT4(Colors::Black) });
Vertex v3({ XMFLOAT3(+1.0f, +1.0f, -1.0f), XMFLOAT4(Colors::Red) });
Vertex v4({ XMFLOAT3(+1.0f, -1.0f, -1.0f), XMFLOAT4(Colors::Green) });
Vertex v5({ XMFLOAT3(-1.0f, -1.0f, +1.0f), XMFLOAT4(Colors::Blue) });
Vertex v6({ XMFLOAT3(-1.0f, +1.0f, +1.0f), XMFLOAT4(Colors::Yellow) });
Vertex v7({ XMFLOAT3(+1.0f, +1.0f, +1.0f), XMFLOAT4(Colors::Cyan) });
Vertex v8({ XMFLOAT3(+1.0f, -1.0f, +1.0f), XMFLOAT4(Colors::Magenta) });

//Vertex v1({ XMFLOAT3(-1.0f, -1.0f, -1.0f), XMCOLOR(Colors::White) });
//Vertex v2({ XMFLOAT3(-1.0f, +1.0f, -1.0f), XMCOLOR(Colors::Black) });
//Vertex v3({ XMFLOAT3(+1.0f, +1.0f, -1.0f), XMCOLOR(Colors::Red) });
//Vertex v4({ XMFLOAT3(+1.0f, -1.0f, -1.0f), XMCOLOR(Colors::Green) });
//Vertex v5({ XMFLOAT3(-1.0f, -1.0f, +1.0f), XMCOLOR(Colors::Blue) });
//Vertex v6({ XMFLOAT3(-1.0f, +1.0f, +1.0f), XMCOLOR(Colors::Yellow) });
//Vertex v7({ XMFLOAT3(+1.0f, +1.0f, +1.0f), XMCOLOR(Colors::Cyan) });
//Vertex v8({ XMFLOAT3(+1.0f, -1.0f, +1.0f), XMCOLOR(Colors::Magenta) });

Vertex v9({ XMFLOAT3(+1.0f, +0.0f, -1.0f), XMFLOAT4(Colors::Green) });
Vertex v10({ XMFLOAT3(-1.0f, +0.0f, -1.0f), XMFLOAT4(Colors::Green) });
Vertex v11({ XMFLOAT3(+1.0f, +0.0f, +1.0f), XMFLOAT4(Colors::Green) });
Vertex v12({ XMFLOAT3(-1.0f, +0.0f, +1.0f), XMFLOAT4(Colors::Green) });
Vertex v13({ XMFLOAT3(+0.0f, sqrtf(2), +0.0f), XMFLOAT4(Colors::Red) });

//Vertex v9({ XMFLOAT3(+1.0f, +0.0f, -1.0f), XMCOLOR(Colors::Green) });
//Vertex v10({ XMFLOAT3(-1.0f, +0.0f, -1.0f), XMCOLOR(Colors::Green) });
//Vertex v11({ XMFLOAT3(+1.0f, +0.0f, +1.0f), XMCOLOR(Colors::Green) });
//Vertex v12({ XMFLOAT3(-1.0f, +0.0f, +1.0f), XMCOLOR(Colors::Green) });
//Vertex v13({ XMFLOAT3(+0.0f, sqrtf(2), +0.0f), XMCOLOR(Colors::Red) });

std::vector<Vertex> vBox = { v1, v2, v3, v4, v5, v6, v7, v8 };
std::vector<Vertex> vPyramid = { v9, v10, v11, v12, v13 };

struct Box
{
	std::vector<Vertex> vertices = vBox;

	// Ex 1 COMMENT OUT
	//{
		//Vertex({ XMFLOAT3(-1.0f, -1.0f, -1.0f), XMFLOAT4(Colors::White) }),
		//Vertex({ XMFLOAT3(-1.0f, +1.0f, -1.0f), XMFLOAT4(Colors::Black) }),
		//Vertex({ XMFLOAT3(+1.0f, +1.0f, -1.0f), XMFLOAT4(Colors::Red) }),
		//Vertex({ XMFLOAT3(+1.0f, -1.0f, -1.0f), XMFLOAT4(Colors::Green) }),
		//Vertex({ XMFLOAT3(-1.0f, -1.0f, +1.0f), XMFLOAT4(Colors::Blue) }),
		//Vertex({ XMFLOAT3(-1.0f, +1.0f, +1.0f), XMFLOAT4(Colors::Yellow) }),
		//Vertex({ XMFLOAT3(+1.0f, +1.0f, +1.0f), XMFLOAT4(Colors::Cyan) }),
		//Vertex({ XMFLOAT3(+1.0f, -1.0f, +1.0f), XMFLOAT4(Colors::Magenta) })
	//};

	// Ex 2
	std::vector<VPosData> vps =
	{
		VPosData({XMFLOAT3(-1.0f, -1.0f, -1.0f)}),
		VPosData({XMFLOAT3(-1.0f, +1.0f, -1.0f)}),
		VPosData({XMFLOAT3(+1.0f, +1.0f, -1.0f)}),
		VPosData({XMFLOAT3(+1.0f, -1.0f, -1.0f)}),
		VPosData({XMFLOAT3(-1.0f, -1.0f, +1.0f)}),
		VPosData({XMFLOAT3(-1.0f, +1.0f, +1.0f)}),
		VPosData({XMFLOAT3(+1.0f, +1.0f, +1.0f)}),
		VPosData({XMFLOAT3(+1.0f, -1.0f, +1.0f)})
	};
	std::vector<VColorData> vcs =
	{
		VColorData({XMFLOAT4(Colors::White)}),
		VColorData({XMFLOAT4(Colors::Black)}),
		VColorData({XMFLOAT4(Colors::Red)}),
		VColorData({XMFLOAT4(Colors::Green)}),
		VColorData({XMFLOAT4(Colors::Blue)}),
		VColorData({XMFLOAT4(Colors::Yellow)}),
		VColorData({XMFLOAT4(Colors::Cyan)}),
		VColorData({XMFLOAT4(Colors::Magenta)})
	};

	std::vector<std::uint16_t> indices =
	{
		// front face
		0, 1, 2, 0, 2, 3,
		// back face
		4, 6, 5, 4, 7, 6,
		// left face
		4, 5, 1, 4, 1, 0,
		// right face
		3, 2, 6, 3, 6, 7,
		// top face
		1, 5, 6, 1, 6, 2,
		// bottom face
		4, 0, 3, 4, 3, 7
	};
};

struct Pyramid {
	std::vector<Vertex> vertices = vPyramid;

	// Ex 2
	std::vector<VPosData> vps = {
		VPosData({XMFLOAT3(+1.0f, +0.0f, -1.0f)}),		// 0
		VPosData({XMFLOAT3(-1.0f, +0.0f, -1.0f)}),		// 1
		VPosData({XMFLOAT3(+1.0f, +0.0f, +1.0f)}),		// 2	
		VPosData({XMFLOAT3(-1.0f, +0.0f, +1.0f)}),		// 3
		VPosData({XMFLOAT3(+0.0f, sqrtf(2), +0.0f)})	// 4
	};
	std::vector<VColorData> vcs =
	{
		VColorData({XMFLOAT4(Colors::Green)}),	// 0 
		VColorData({XMFLOAT4(Colors::Green)}),	// 1
		VColorData({XMFLOAT4(Colors::Green)}),	// 2
		VColorData({XMFLOAT4(Colors::Green)}),	// 3
		VColorData({XMFLOAT4(Colors::Red)})		// 4
	};

	std::vector<std::uint16_t> indices =
	{
		4,0,1,
		4,3,2,
		4,1,3,
		4,2,0,
		1,0,2,
		2,3,1
	};

};