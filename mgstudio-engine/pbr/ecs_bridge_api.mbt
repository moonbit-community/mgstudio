// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// ECS component bridge types.
pub let ecs_components : Array[String] = [
  "Hdr", "Fxaa", "Msaa", "Bloom", "CustomPostProcess3d", "Mesh3d", "Skybox", "Camera3d",
  "Exposure", "Vignette", "SpotLight", "Wireframe", "FreeCamera", "LightProbe", "MotionBlur",
  "PointLight", "NoWireframe", "Tonemapping", "ColorGrading", "DebandDither", "DepthPrepass",
  "ForwardDecal", "NormalPrepass", "ClusteredDecal", "ContactShadows", "MeshMaterial3d",
  "TemporalJitter", "WireframeColor", "DeferredPrepass", "FreeCameraState", "NotShadowCaster",
  "SubCameraView3d", "DirectionalLight", "IrradianceVolume", "OcclusionCulling",
  "NoIndirectDrawing", "SpotLightTexture", "NotShadowReceiver", "PointLightTexture",
  "Projection", "Frustum", "ParallaxCorrection", "ChromaticAberration", "EnvironmentMapLight",
  "MotionVectorPrepass", "TemporalAntiAliasing", "ShadowFilteringMethod", "ScreenSpaceReflections",
  "DirectionalLightTexture", "ForwardDecalMaterialExt", "ScreenSpaceTransmission",
  "TransmittedShadowReceiver", "ScreenSpaceAmbientOcclusion", "GeneratedEnvironmentMapLight",
  "OrderIndependentTransparencySettings",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = [
  "WireframeConfig", "GlobalAmbientLight", "PointLightShadowMap", "DirectionalLightShadowMap",
  "DefaultOpaqueRendererMethod",
]

///|
pub fn get_wireframe_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[WireframeConfig] {
  world.resource(ecs_key_wireframe_config)
}

///|
pub fn get_global_ambient_light_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[GlobalAmbientLight] {
  @light.get_global_ambient_light_resource(world)
}

///|
pub fn get_point_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointLightShadowMap] {
  @light.get_point_light_shadow_map_resource(world)
}

///|
pub fn get_directional_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DirectionalLightShadowMap] {
  @light.get_directional_light_shadow_map_resource(world)
}

///|
pub fn get_default_opaque_renderer_method_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DefaultOpaqueRendererMethod] {
  @material.get_default_opaque_renderer_method_resource(world)
}
