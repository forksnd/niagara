#version 450

#extension GL_EXT_shader_16bit_storage: require
#extension GL_EXT_shader_8bit_storage: require

#extension GL_GOOGLE_include_directive: require

#extension GL_ARB_shader_draw_parameters: require

#include "mesh.h"
#include "math.h"

layout(push_constant) uniform block
{
	Globals globals;
};

layout(binding = 0) readonly buffer DrawCommands
{
	MeshDrawCommand drawCommands[];
};

layout(binding = 1) readonly buffer Draws
{
	MeshDraw draws[];
};

layout(binding = 2) readonly buffer Vertices
{
	Vertex vertices[];
};

layout(location = 0) out flat uint out_drawId;
layout(location = 1) out vec2 out_uv;
layout(location = 2) out vec3 out_normal;
layout(location = 3) out vec4 out_tangent;
layout(location = 4) out vec3 out_wpos;

void main()
{
	uint drawId = drawCommands[gl_DrawIDARB].drawId;
	MeshDraw meshDraw = draws[drawId];

	uint vi = gl_VertexIndex;
	vec3 position = vec3(vertices[vi].vx, vertices[vi].vy, vertices[vi].vz);
	vec2 texcoord = vec2(vertices[vi].tu, vertices[vi].tv);

	vec3 normal;
	vec4 tangent;
	unpackTBN(vertices[vi].np, uint(vertices[vi].tp), normal, tangent);

	normal = rotateQuat(normal, meshDraw.orientation);
	tangent.xyz = rotateQuat(tangent.xyz, meshDraw.orientation);

	vec3 wpos = rotateQuat(position, meshDraw.orientation) * meshDraw.scale + meshDraw.position;

	gl_Position = globals.projection * (globals.cullData.view * vec4(wpos, 1));
	out_drawId = drawId;
	out_uv = texcoord;
	out_normal = normal;
	out_tangent = tangent;
	out_wpos = wpos;
}
