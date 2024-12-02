#version 460

#extension GL_GOOGLE_include_directive: require

#include "math.h"

#define RAYTRACE 1

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

struct ShadeData
{
	vec3 cameraPosition;
	vec3 sunDirection;

	mat4 inverseViewProjection;

	vec2 imageSize;
};

layout(push_constant) uniform block
{
	ShadeData shadeData;
};

layout(binding = 0) uniform writeonly image2D outImage;
layout(binding = 1) uniform sampler2D gbufferImage0;
layout(binding = 2) uniform sampler2D gbufferImage1;
layout(binding = 3) uniform sampler2D depthImage;

#if RAYTRACE
#extension GL_EXT_ray_query: require

layout(binding = 4) uniform accelerationStructureEXT tlas;
#endif

void main()
{
	uvec2 pos = gl_GlobalInvocationID.xy;
	vec2 uv = (vec2(pos) + 0.5) / shadeData.imageSize;

	vec4 gbuffer0 = texture(gbufferImage0, uv);
	vec4 gbuffer1 = texture(gbufferImage1, uv);
	float depth = texture(depthImage, uv).r;

	vec3 albedo = fromsrgb(gbuffer0.rgb);
	vec3 emissive = vec3(albedo * (gbuffer0.a * gbuffer0.a * 10));
	vec3 normal = decodeOct(gbuffer1.rg * 2 - 1);

	float ndotl = max(dot(normal, shadeData.sunDirection), 0.0);

	vec4 clip = vec4(uv.x * 2 - 1, 1 - uv.y * 2, depth, 1);
	vec4 wposh = shadeData.inverseViewProjection * clip;
	vec3 wpos = wposh.xyz / wposh.w;

	vec3 view = normalize(shadeData.cameraPosition - wpos);
	vec3 halfv = normalize(view + shadeData.sunDirection);
	float ndoth = max(dot(normal, halfv), 0.0);
	float specular = pow(ndoth, 64 * gbuffer1.b) * gbuffer1.b;

	float shadow = 1;

#if RAYTRACE
	uint rayflags = gl_RayFlagsTerminateOnFirstHitEXT | gl_RayFlagsCullNoOpaqueEXT;
	uint cullmask = 0xff; // note: 0xff is faster on amdvlk but 1 is faster on radv

	rayQueryEXT rq;
	rayQueryInitializeEXT(rq, tlas, rayflags, cullmask, wpos, 1e-2, shadeData.sunDirection, 1e3);
	rayQueryProceedEXT(rq);

	shadow = (rayQueryGetIntersectionTypeEXT(rq, true) == gl_RayQueryCommittedIntersectionNoneEXT) ? 1.0 : 0.0;
#endif

	float ambient = 0.05;

	vec3 final = albedo.rgb * (ndotl * shadow + ambient) + vec3(specular * shadow) + emissive;
	vec3 outputColor = tosrgb(final);

	imageStore(outImage, ivec2(pos), vec4(outputColor, 1.0));
}