#pragma once

#include "math.h"

#include <stdint.h>

#include <string>
#include <vector>

struct alignas(16) Meshlet
{
	vec3 center;
	float radius;
	int8_t cone_axis[3];
	int8_t cone_cutoff;

	uint32_t dataOffset; // dataOffset..dataOffset+vertexCount-1 stores vertex indices, we store indices packed in 4b units after that
	uint32_t baseVertex;
	uint8_t vertexCount;
	uint8_t triangleCount;
	uint8_t padding[2];
};

struct alignas(16) MeshDraw
{
	vec3 position;
	float scale;
	quat orientation;

	uint32_t meshIndex;
	uint32_t meshletVisibilityOffset;
	uint32_t postPass;
	uint32_t flags;

	int albedoTexture;
	int normalTexture;
	int specularTexture;
	int emissiveTexture;

	vec4 diffuseFactor;
	vec3 specularFactor;
	float glossinessFactor;
	vec3 emissiveFactor;
	float padding;
};

struct Vertex
{
	uint16_t vx, vy, vz, vw;
	uint8_t nx, ny, nz, nw;
	uint8_t tx, ty, tz, tw;
	uint16_t tu, tv;
};

struct MeshLod
{
	uint32_t indexOffset;
	uint32_t indexCount;
	uint32_t meshletOffset;
	uint32_t meshletCount;
	float error;
};

struct alignas(16) Mesh
{
	vec3 center;
	float radius;

	uint32_t vertexOffset;
	uint32_t vertexCount;

	uint32_t lodCount;
	MeshLod lods[8];
};

struct Geometry
{
	// TODO: remove these vectors - they are just scratch copies that waste space
	std::vector<Vertex> vertices;
	std::vector<uint32_t> indices;
	std::vector<Meshlet> meshlets;
	std::vector<uint32_t> meshletdata;
	std::vector<Mesh> meshes;
};

struct Camera
{
	vec3 position;
	quat orientation;
	float fovY;
};

bool loadMesh(Geometry& geometry, const char* path, bool buildMeshlets, bool fast = false);
bool loadScene(Geometry& geometry, std::vector<MeshDraw>& draws, std::vector<std::string>& texturePaths, Camera& camera, vec3& sunDirection, const char* path, bool buildMeshlets, bool fast = false);