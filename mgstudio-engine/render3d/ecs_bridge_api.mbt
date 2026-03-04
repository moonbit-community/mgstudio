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
  "Hdr", "Fxaa", "Msaa", "Bloom", "Mesh3d", "Skybox", "Camera3d", "Exposure", "Vignette",
  "SpotLight", "Wireframe", "FreeCamera", "LightProbe", "MotionBlur", "PointLight",
  "NoWireframe", "Tonemapping", "ColorGrading", "DebandDither", "DepthPrepass", "ForwardDecal",
  "NormalPrepass", "ClusteredDecal", "ContactShadows", "MeshMaterial3d", "TemporalJitter",
  "WireframeColor", "DeferredPrepass", "FreeCameraState", "NotShadowCaster", "SubCameraView3d",
  "DirectionalLight", "IrradianceVolume", "OcclusionCulling", "SpotLightTexture",
  "NotShadowReceiver", "PointLightTexture", "CameraProjection3d", "ParallaxCorrection",
  "ChromaticAberration", "EnvironmentMapLight", "MotionVectorPrepass", "TemporalAntiAliasing",
  "ShadowFilteringMethod", "ScreenSpaceReflections", "DirectionalLightTexture", "ForwardDecalMaterialExt",
  "ScreenSpaceTransmission", "TransmittedShadowReceiver", "ScreenSpaceAmbientOcclusion",
  "GeneratedEnvironmentMapLight", "OrderIndependentTransparencySettings",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = [
  "WireframeConfig", "GlobalAmbientLight", "PointLightShadowMap", "DirectionalLightShadowMap",
  "DefaultOpaqueRendererMethod",
]

///|
pub fn get_hdr_store(world : @ecs.World) -> @ecs.ComponentAccess[Hdr] {
  world.component(ecs_key_hdr)
}

///|
pub fn get_fxaa_store(world : @ecs.World) -> @ecs.ComponentAccess[Fxaa] {
  world.component(ecs_key_fxaa)
}

///|
pub fn get_msaa_store(world : @ecs.World) -> @ecs.ComponentAccess[Msaa] {
  world.component(ecs_key_msaa)
}

///|
pub fn get_bloom_store(world : @ecs.World) -> @ecs.ComponentAccess[Bloom] {
  world.component(ecs_key_bloom)
}

///|
pub fn get_mesh3d_store(world : @ecs.World) -> @ecs.ComponentAccess[Mesh3d] {
  world.component(ecs_key_mesh3d)
}

///|
pub fn get_skybox_store(world : @ecs.World) -> @ecs.ComponentAccess[Skybox] {
  world.component(ecs_key_skybox)
}

///|
pub fn get_camera3d_store(world : @ecs.World) -> @ecs.ComponentAccess[Camera3d] {
  world.component(ecs_key_camera3d)
}

///|
pub fn get_exposure_store(world : @ecs.World) -> @ecs.ComponentAccess[Exposure] {
  world.component(ecs_key_exposure)
}

///|
pub fn get_vignette_store(world : @ecs.World) -> @ecs.ComponentAccess[Vignette] {
  world.component(ecs_key_vignette)
}

///|
pub fn get_spot_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SpotLight] {
  world.component(ecs_key_spot_light)
}

///|
pub fn get_wireframe_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Wireframe] {
  world.component(ecs_key_wireframe)
}

///|
pub fn get_free_camera_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[FreeCamera] {
  world.component(ecs_key_free_camera)
}

///|
pub fn get_light_probe_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[LightProbe] {
  world.component(ecs_key_light_probe)
}

///|
pub fn get_motion_blur_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[MotionBlur] {
  world.component(ecs_key_motion_blur)
}

///|
pub fn get_point_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[PointLight] {
  world.component(ecs_key_point_light)
}

///|
pub fn get_no_wireframe_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NoWireframe] {
  world.component(ecs_key_no_wireframe)
}

///|
pub fn get_tonemapping_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Tonemapping] {
  world.component(ecs_key_tonemapping)
}

///|
pub fn get_color_grading_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ColorGrading] {
  world.component(ecs_key_color_grading)
}

///|
pub fn get_deband_dither_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DebandDither] {
  world.component(ecs_key_deband_dither)
}

///|
pub fn get_depth_prepass_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DepthPrepass] {
  world.component(ecs_key_depth_prepass)
}

///|
pub fn get_forward_decal_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ForwardDecal] {
  world.component(ecs_key_forward_decal)
}

///|
pub fn get_normal_prepass_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NormalPrepass] {
  world.component(ecs_key_normal_prepass)
}

///|
pub fn get_clustered_decal_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ClusteredDecal] {
  world.component(ecs_key_clustered_decal)
}

///|
pub fn get_contact_shadows_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ContactShadows] {
  world.component(ecs_key_contact_shadows)
}

///|
pub fn get_mesh_material3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[MeshMaterial3d] {
  world.component(ecs_key_mesh_material3d)
}

///|
pub fn get_temporal_jitter_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[TemporalJitter] {
  world.component(ecs_key_temporal_jitter)
}

///|
pub fn get_wireframe_color_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[WireframeColor] {
  world.component(ecs_key_wireframe_color)
}

///|
pub fn get_deferred_prepass_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DeferredPrepass] {
  world.component(ecs_key_deferred_prepass)
}

///|
pub fn get_free_camera_state_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[FreeCameraState] {
  world.component(ecs_key_free_camera_state)
}

///|
pub fn get_not_shadow_caster_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NotShadowCaster] {
  world.component(ecs_key_not_shadow_caster)
}

///|
pub fn get_sub_camera_view3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SubCameraView3d] {
  world.component(ecs_key_sub_camera_view3d)
}

///|
pub fn get_directional_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DirectionalLight] {
  world.component(ecs_key_directional_light)
}

///|
pub fn get_irradiance_volume_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[IrradianceVolume] {
  world.component(ecs_key_irradiance_volume)
}

///|
pub fn get_occlusion_culling_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[OcclusionCulling] {
  world.component(ecs_key_occlusion_culling)
}

///|
pub fn get_spot_light_texture_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SpotLightTexture] {
  world.component(ecs_key_spot_light_texture)
}

///|
pub fn get_not_shadow_receiver_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NotShadowReceiver] {
  world.component(ecs_key_not_shadow_receiver)
}

///|
pub fn get_point_light_texture_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[PointLightTexture] {
  world.component(ecs_key_point_light_texture)
}

///|
pub fn get_camera_projection3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[CameraProjection3d] {
  world.component(ecs_key_camera_projection3d)
}

///|
pub fn get_parallax_correction_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ParallaxCorrection] {
  world.component(ecs_key_parallax_correction)
}

///|
pub fn get_chromatic_aberration_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ChromaticAberration] {
  world.component(ecs_key_chromatic_aberration)
}

///|
pub fn get_environment_map_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[EnvironmentMapLight] {
  world.component(ecs_key_environment_map_light)
}

///|
pub fn get_motion_vector_prepass_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[MotionVectorPrepass] {
  world.component(ecs_key_motion_vector_prepass)
}

///|
pub fn get_temporal_anti_aliasing_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[TemporalAntiAliasing] {
  world.component(ecs_key_temporal_anti_aliasing)
}

///|
pub fn get_shadow_filtering_method_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ShadowFilteringMethod] {
  world.component(ecs_key_shadow_filtering_method)
}

///|
pub fn get_screen_space_reflections_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ScreenSpaceReflections] {
  world.component(ecs_key_screen_space_reflections)
}

///|
pub fn get_directional_light_texture_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DirectionalLightTexture] {
  world.component(ecs_key_directional_light_texture)
}

///|
pub fn get_forward_decal_material_ext_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ForwardDecalMaterialExt] {
  world.component(ecs_key_forward_decal_material_ext)
}

///|
pub fn get_screen_space_transmission_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ScreenSpaceTransmission] {
  world.component(ecs_key_screen_space_transmission)
}

///|
pub fn get_transmitted_shadow_receiver_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[TransmittedShadowReceiver] {
  world.component(ecs_key_transmitted_shadow_receiver)
}

///|
pub fn get_screen_space_ambient_occlusion_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ScreenSpaceAmbientOcclusion] {
  world.component(ecs_key_screen_space_ambient_occlusion)
}

///|
pub fn get_generated_environment_map_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[GeneratedEnvironmentMapLight] {
  world.component(ecs_key_generated_environment_map_light)
}

///|
pub fn get_order_independent_transparency_settings_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[OrderIndependentTransparencySettings] {
  world.component(ecs_key_order_independent_transparency_settings)
}

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
  world.resource(ecs_key_global_ambient_light)
}

///|
pub fn get_point_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointLightShadowMap] {
  world.resource(ecs_key_point_light_shadow_map)
}

///|
pub fn get_directional_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DirectionalLightShadowMap] {
  world.resource(ecs_key_directional_light_shadow_map)
}

///|
pub fn get_default_opaque_renderer_method_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DefaultOpaqueRendererMethod] {
  world.resource(ecs_key_default_opaque_renderer_method)
}
