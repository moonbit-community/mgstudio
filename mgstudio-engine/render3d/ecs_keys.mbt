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
pub let ecs_key_mesh3d : @ecs.ComponentKey[Mesh3d] = @ecs.register_component(
  debug_name="render3d.mesh3d",
)

///|
pub let ecs_key_mesh_material3d : @ecs.ComponentKey[MeshMaterial3d] = @ecs.register_component(
  debug_name="render3d.mesh_material3d",
)

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @ecs.register_component(
  debug_name="render3d.hdr",
)

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @ecs.register_component(
  debug_name="render3d.fxaa",
)

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @ecs.register_component(
  debug_name="render3d.msaa",
)

///|
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @ecs.register_component(
  debug_name="render3d.bloom",
)

///|
pub let ecs_key_skybox : @ecs.ComponentKey[Skybox] = @ecs.register_component(
  debug_name="render3d.skybox",
)

///|
pub let ecs_key_camera3d : @ecs.ComponentKey[Camera3d] = @ecs.register_component(
  debug_name="render3d.camera3d",
)

///|
pub let ecs_key_exposure : @ecs.ComponentKey[Exposure] = @ecs.register_component(
  debug_name="render3d.exposure",
)

///|
pub let ecs_key_vignette : @ecs.ComponentKey[Vignette] = @ecs.register_component(
  debug_name="render3d.vignette",
)

///|
pub let ecs_key_spot_light : @ecs.ComponentKey[SpotLight] = @ecs.register_component(
  debug_name="render3d.spot_light",
)

///|
pub let ecs_key_wireframe : @ecs.ComponentKey[Wireframe] = @ecs.register_component(
  debug_name="render3d.wireframe",
)

///|
pub let ecs_key_free_camera : @ecs.ComponentKey[FreeCamera] = @ecs.register_component(
  debug_name="render3d.free_camera",
)

///|
pub let ecs_key_light_probe : @ecs.ComponentKey[LightProbe] = @ecs.register_component(
  debug_name="render3d.light_probe",
)

///|
pub let ecs_key_motion_blur : @ecs.ComponentKey[MotionBlur] = @ecs.register_component(
  debug_name="render3d.motion_blur",
)

///|
pub let ecs_key_point_light : @ecs.ComponentKey[PointLight] = @ecs.register_component(
  debug_name="render3d.point_light",
)

///|
pub let ecs_key_no_wireframe : @ecs.ComponentKey[NoWireframe] = @ecs.register_component(
  debug_name="render3d.no_wireframe",
)

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @ecs.register_component(
  debug_name="render3d.tonemapping",
)

///|
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @ecs.register_component(
  debug_name="render3d.color_grading",
)

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @ecs.register_component(
  debug_name="render3d.deband_dither",
)

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @ecs.register_component(
  debug_name="render3d.depth_prepass",
)

///|
pub let ecs_key_forward_decal : @ecs.ComponentKey[ForwardDecal] = @ecs.register_component(
  debug_name="render3d.forward_decal",
)

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @ecs.register_component(
  debug_name="render3d.normal_prepass",
)

///|
pub let ecs_key_clustered_decal : @ecs.ComponentKey[ClusteredDecal] = @ecs.register_component(
  debug_name="render3d.clustered_decal",
)

///|
pub let ecs_key_contact_shadows : @ecs.ComponentKey[ContactShadows] = @ecs.register_component(
  debug_name="render3d.contact_shadows",
)

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @ecs.register_component(
  debug_name="render3d.temporal_jitter",
)

///|
pub let ecs_key_wireframe_color : @ecs.ComponentKey[WireframeColor] = @ecs.register_component(
  debug_name="render3d.wireframe_color",
)

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @ecs.register_component(
  debug_name="render3d.deferred_prepass",
)

///|
pub let ecs_key_free_camera_state : @ecs.ComponentKey[FreeCameraState] = @ecs.register_component(
  debug_name="render3d.free_camera_state",
)

///|
pub let ecs_key_not_shadow_caster : @ecs.ComponentKey[NotShadowCaster] = @ecs.register_component(
  debug_name="render3d.not_shadow_caster",
)

///|
pub let ecs_key_sub_camera_view3d : @ecs.ComponentKey[SubCameraView3d] = @ecs.register_component(
  debug_name="render3d.sub_camera_view3d",
)

///|
pub let ecs_key_directional_light : @ecs.ComponentKey[DirectionalLight] = @ecs.register_component(
  debug_name="render3d.directional_light",
)

///|
pub let ecs_key_irradiance_volume : @ecs.ComponentKey[IrradianceVolume] = @ecs.register_component(
  debug_name="render3d.irradiance_volume",
)

///|
pub let ecs_key_occlusion_culling : @ecs.ComponentKey[OcclusionCulling] = @ecs.register_component(
  debug_name="render3d.occlusion_culling",
)

///|
pub let ecs_key_spot_light_texture : @ecs.ComponentKey[SpotLightTexture] = @ecs.register_component(
  debug_name="render3d.spot_light_texture",
)

///|
pub let ecs_key_not_shadow_receiver : @ecs.ComponentKey[NotShadowReceiver] = @ecs.register_component(
  debug_name="render3d.not_shadow_receiver",
)

///|
pub let ecs_key_point_light_texture : @ecs.ComponentKey[PointLightTexture] = @ecs.register_component(
  debug_name="render3d.point_light_texture",
)

///|
pub let ecs_key_camera_projection3d : @ecs.ComponentKey[CameraProjection3d] = @ecs.register_component(
  debug_name="render3d.camera_projection3d",
)

///|
pub let ecs_key_parallax_correction : @ecs.ComponentKey[ParallaxCorrection] = @ecs.register_component(
  debug_name="render3d.parallax_correction",
)

///|
pub let ecs_key_chromatic_aberration : @ecs.ComponentKey[ChromaticAberration] = @ecs.register_component(
  debug_name="render3d.chromatic_aberration",
)

///|
pub let ecs_key_environment_map_light : @ecs.ComponentKey[EnvironmentMapLight] = @ecs.register_component(
  debug_name="render3d.environment_map_light",
)

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @ecs.register_component(
  debug_name="render3d.motion_vector_prepass",
)

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @ecs.register_component(
  debug_name="render3d.temporal_anti_aliasing",
)

///|
pub let ecs_key_shadow_filtering_method : @ecs.ComponentKey[
  ShadowFilteringMethod,
] = @ecs.register_component(debug_name="render3d.shadow_filtering_method")

///|
pub let ecs_key_screen_space_reflections : @ecs.ComponentKey[
  ScreenSpaceReflections,
] = @ecs.register_component(debug_name="render3d.screen_space_reflections")

///|
pub let ecs_key_directional_light_texture : @ecs.ComponentKey[
  DirectionalLightTexture,
] = @ecs.register_component(debug_name="render3d.directional_light_texture")

///|
pub let ecs_key_forward_decal_material_ext : @ecs.ComponentKey[
  ForwardDecalMaterialExt,
] = @ecs.register_component(debug_name="render3d.forward_decal_material_ext")

///|
pub let ecs_key_screen_space_transmission : @ecs.ComponentKey[
  ScreenSpaceTransmission,
] = @ecs.register_component(debug_name="render3d.screen_space_transmission")

///|
pub let ecs_key_transmitted_shadow_receiver : @ecs.ComponentKey[
  TransmittedShadowReceiver,
] = @ecs.register_component(debug_name="render3d.transmitted_shadow_receiver")

///|
pub let ecs_key_screen_space_ambient_occlusion : @ecs.ComponentKey[
  ScreenSpaceAmbientOcclusion,
] = @ecs.register_component(
  debug_name="render3d.screen_space_ambient_occlusion",
)

///|
pub let ecs_key_generated_environment_map_light : @ecs.ComponentKey[
  GeneratedEnvironmentMapLight,
] = @ecs.register_component(
  debug_name="render3d.generated_environment_map_light",
)

///|
pub let ecs_key_order_independent_transparency_settings : @ecs.ComponentKey[
  OrderIndependentTransparencySettings,
] = @ecs.register_component(
  debug_name="render3d.order_independent_transparency_settings",
)

///|
pub impl @ecs.Component for Mesh3d with component() {
  ecs_key_mesh3d
}

///|
pub impl @ecs.Component for MeshMaterial3d with component() {
  ecs_key_mesh_material3d
}

///|
pub impl @ecs.Component for Hdr with component() {
  ecs_key_hdr
}

///|
pub impl @ecs.Component for Fxaa with component() {
  ecs_key_fxaa
}

///|
pub impl @ecs.Component for Msaa with component() {
  ecs_key_msaa
}

///|
pub impl @ecs.Component for Bloom with component() {
  ecs_key_bloom
}

///|
pub impl @ecs.Component for Skybox with component() {
  ecs_key_skybox
}

///|
pub impl @ecs.Component for Camera3d with component() {
  ecs_key_camera3d
}

///|
pub impl @ecs.Component for Exposure with component() {
  ecs_key_exposure
}

///|
pub impl @ecs.Component for Vignette with component() {
  ecs_key_vignette
}

///|
pub impl @ecs.Component for SpotLight with component() {
  ecs_key_spot_light
}

///|
pub impl @ecs.Component for Wireframe with component() {
  ecs_key_wireframe
}

///|
pub impl @ecs.Component for FreeCamera with component() {
  ecs_key_free_camera
}

///|
pub impl @ecs.Component for LightProbe with component() {
  ecs_key_light_probe
}

///|
pub impl @ecs.Component for MotionBlur with component() {
  ecs_key_motion_blur
}

///|
pub impl @ecs.Component for PointLight with component() {
  ecs_key_point_light
}

///|
pub impl @ecs.Component for NoWireframe with component() {
  ecs_key_no_wireframe
}

///|
pub impl @ecs.Component for Tonemapping with component() {
  ecs_key_tonemapping
}

///|
pub impl @ecs.Component for ColorGrading with component() {
  ecs_key_color_grading
}

///|
pub impl @ecs.Component for DebandDither with component() {
  ecs_key_deband_dither
}

///|
pub impl @ecs.Component for DepthPrepass with component() {
  ecs_key_depth_prepass
}

///|
pub impl @ecs.Component for ForwardDecal with component() {
  ecs_key_forward_decal
}

///|
pub impl @ecs.Component for NormalPrepass with component() {
  ecs_key_normal_prepass
}

///|
pub impl @ecs.Component for ClusteredDecal with component() {
  ecs_key_clustered_decal
}

///|
pub impl @ecs.Component for ContactShadows with component() {
  ecs_key_contact_shadows
}

///|
pub impl @ecs.Component for TemporalJitter with component() {
  ecs_key_temporal_jitter
}

///|
pub impl @ecs.Component for WireframeColor with component() {
  ecs_key_wireframe_color
}

///|
pub impl @ecs.Component for DeferredPrepass with component() {
  ecs_key_deferred_prepass
}

///|
pub impl @ecs.Component for FreeCameraState with component() {
  ecs_key_free_camera_state
}

///|
pub impl @ecs.Component for NotShadowCaster with component() {
  ecs_key_not_shadow_caster
}

///|
pub impl @ecs.Component for SubCameraView3d with component() {
  ecs_key_sub_camera_view3d
}

///|
pub impl @ecs.Component for DirectionalLight with component() {
  ecs_key_directional_light
}

///|
pub impl @ecs.Component for IrradianceVolume with component() {
  ecs_key_irradiance_volume
}

///|
pub impl @ecs.Component for OcclusionCulling with component() {
  ecs_key_occlusion_culling
}

///|
pub impl @ecs.Component for SpotLightTexture with component() {
  ecs_key_spot_light_texture
}

///|
pub impl @ecs.Component for NotShadowReceiver with component() {
  ecs_key_not_shadow_receiver
}

///|
pub impl @ecs.Component for PointLightTexture with component() {
  ecs_key_point_light_texture
}

///|
pub impl @ecs.Component for CameraProjection3d with component() {
  ecs_key_camera_projection3d
}

///|
pub impl @ecs.Component for ParallaxCorrection with component() {
  ecs_key_parallax_correction
}

///|
pub impl @ecs.Component for ChromaticAberration with component() {
  ecs_key_chromatic_aberration
}

///|
pub impl @ecs.Component for EnvironmentMapLight with component() {
  ecs_key_environment_map_light
}

///|
pub impl @ecs.Component for MotionVectorPrepass with component() {
  ecs_key_motion_vector_prepass
}

///|
pub impl @ecs.Component for TemporalAntiAliasing with component() {
  ecs_key_temporal_anti_aliasing
}

///|
pub impl @ecs.Component for ShadowFilteringMethod with component() {
  ecs_key_shadow_filtering_method
}

///|
pub impl @ecs.Component for ScreenSpaceReflections with component() {
  ecs_key_screen_space_reflections
}

///|
pub impl @ecs.Component for DirectionalLightTexture with component() {
  ecs_key_directional_light_texture
}

///|
pub impl @ecs.Component for ForwardDecalMaterialExt with component() {
  ecs_key_forward_decal_material_ext
}

///|
pub impl @ecs.Component for ScreenSpaceTransmission with component() {
  ecs_key_screen_space_transmission
}

///|
pub impl @ecs.Component for TransmittedShadowReceiver with component() {
  ecs_key_transmitted_shadow_receiver
}

///|
pub impl @ecs.Component for ScreenSpaceAmbientOcclusion with component() {
  ecs_key_screen_space_ambient_occlusion
}

///|
pub impl @ecs.Component for GeneratedEnvironmentMapLight with component() {
  ecs_key_generated_environment_map_light
}

///|
pub impl @ecs.Component for OrderIndependentTransparencySettings with component() {
  ecs_key_order_independent_transparency_settings
}

///|
pub let ecs_key_wireframe_config : @ecs.ResourceKey[WireframeConfig] = @ecs.register_resource(
  debug_name="render3d.wireframe_config",
)

///|
pub let ecs_key_global_ambient_light : @ecs.ResourceKey[GlobalAmbientLight] = @ecs.register_resource(
  debug_name="render3d.global_ambient_light",
)

///|
pub let ecs_key_point_light_shadow_map : @ecs.ResourceKey[PointLightShadowMap] = @ecs.register_resource(
  debug_name="render3d.point_light_shadow_map",
)

///|
pub let ecs_key_directional_light_shadow_map : @ecs.ResourceKey[
  DirectionalLightShadowMap,
] = @ecs.register_resource(debug_name="render3d.directional_light_shadow_map")

///|
pub let ecs_key_default_opaque_renderer_method : @ecs.ResourceKey[
  DefaultOpaqueRendererMethod,
] = @ecs.register_resource(debug_name="render3d.default_opaque_renderer_method")
