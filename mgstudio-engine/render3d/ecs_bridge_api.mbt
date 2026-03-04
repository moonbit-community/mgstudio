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
pub(open) trait Has_Hdr {
  get_hdr_store(self : Self) -> @ecs.ComponentAccess[Hdr]
}

///|
pub(open) trait Has_Fxaa {
  get_fxaa_store(self : Self) -> @ecs.ComponentAccess[Fxaa]
}

///|
pub(open) trait Has_Msaa {
  get_msaa_store(self : Self) -> @ecs.ComponentAccess[Msaa]
}

///|
pub(open) trait Has_Bloom {
  get_bloom_store(self : Self) -> @ecs.ComponentAccess[Bloom]
}

///|
pub(open) trait Has_Mesh3d {
  get_mesh3d_store(self : Self) -> @ecs.ComponentAccess[Mesh3d]
}

///|
pub(open) trait Has_Skybox {
  get_skybox_store(self : Self) -> @ecs.ComponentAccess[Skybox]
}

///|
pub(open) trait Has_Camera3d {
  get_camera3d_store(self : Self) -> @ecs.ComponentAccess[Camera3d]
}

///|
pub(open) trait Has_Exposure {
  get_exposure_store(self : Self) -> @ecs.ComponentAccess[Exposure]
}

///|
pub(open) trait Has_Vignette {
  get_vignette_store(self : Self) -> @ecs.ComponentAccess[Vignette]
}

///|
pub(open) trait Has_SpotLight {
  get_spot_light_store(self : Self) -> @ecs.ComponentAccess[SpotLight]
}

///|
pub(open) trait Has_Wireframe {
  get_wireframe_store(self : Self) -> @ecs.ComponentAccess[Wireframe]
}

///|
pub(open) trait Has_FreeCamera {
  get_free_camera_store(self : Self) -> @ecs.ComponentAccess[FreeCamera]
}

///|
pub(open) trait Has_LightProbe {
  get_light_probe_store(self : Self) -> @ecs.ComponentAccess[LightProbe]
}

///|
pub(open) trait Has_MotionBlur {
  get_motion_blur_store(self : Self) -> @ecs.ComponentAccess[MotionBlur]
}

///|
pub(open) trait Has_PointLight {
  get_point_light_store(self : Self) -> @ecs.ComponentAccess[PointLight]
}

///|
pub(open) trait Has_NoWireframe {
  get_no_wireframe_store(self : Self) -> @ecs.ComponentAccess[NoWireframe]
}

///|
pub(open) trait Has_Tonemapping {
  get_tonemapping_store(self : Self) -> @ecs.ComponentAccess[Tonemapping]
}

///|
pub(open) trait Has_ColorGrading {
  get_color_grading_store(self : Self) -> @ecs.ComponentAccess[ColorGrading]
}

///|
pub(open) trait Has_DebandDither {
  get_deband_dither_store(self : Self) -> @ecs.ComponentAccess[DebandDither]
}

///|
pub(open) trait Has_DepthPrepass {
  get_depth_prepass_store(self : Self) -> @ecs.ComponentAccess[DepthPrepass]
}

///|
pub(open) trait Has_ForwardDecal {
  get_forward_decal_store(self : Self) -> @ecs.ComponentAccess[ForwardDecal]
}

///|
pub(open) trait Has_NormalPrepass {
  get_normal_prepass_store(self : Self) -> @ecs.ComponentAccess[NormalPrepass]
}

///|
pub(open) trait Has_ClusteredDecal {
  get_clustered_decal_store(self : Self) -> @ecs.ComponentAccess[ClusteredDecal]
}

///|
pub(open) trait Has_ContactShadows {
  get_contact_shadows_store(self : Self) -> @ecs.ComponentAccess[ContactShadows]
}

///|
pub(open) trait Has_MeshMaterial3d {
  get_mesh_material3d_store(self : Self) -> @ecs.ComponentAccess[MeshMaterial3d]
}

///|
pub(open) trait Has_TemporalJitter {
  get_temporal_jitter_store(self : Self) -> @ecs.ComponentAccess[TemporalJitter]
}

///|
pub(open) trait Has_WireframeColor {
  get_wireframe_color_store(self : Self) -> @ecs.ComponentAccess[WireframeColor]
}

///|
pub(open) trait Has_DeferredPrepass {
  get_deferred_prepass_store(self : Self) -> @ecs.ComponentAccess[
    DeferredPrepass,
  ]
}

///|
pub(open) trait Has_FreeCameraState {
  get_free_camera_state_store(self : Self) -> @ecs.ComponentAccess[
    FreeCameraState,
  ]
}

///|
pub(open) trait Has_NotShadowCaster {
  get_not_shadow_caster_store(self : Self) -> @ecs.ComponentAccess[
    NotShadowCaster,
  ]
}

///|
pub(open) trait Has_SubCameraView3d {
  get_sub_camera_view3d_store(self : Self) -> @ecs.ComponentAccess[
    SubCameraView3d,
  ]
}

///|
pub(open) trait Has_DirectionalLight {
  get_directional_light_store(self : Self) -> @ecs.ComponentAccess[
    DirectionalLight,
  ]
}

///|
pub(open) trait Has_IrradianceVolume {
  get_irradiance_volume_store(self : Self) -> @ecs.ComponentAccess[
    IrradianceVolume,
  ]
}

///|
pub(open) trait Has_OcclusionCulling {
  get_occlusion_culling_store(self : Self) -> @ecs.ComponentAccess[
    OcclusionCulling,
  ]
}

///|
pub(open) trait Has_SpotLightTexture {
  get_spot_light_texture_store(self : Self) -> @ecs.ComponentAccess[
    SpotLightTexture,
  ]
}

///|
pub(open) trait Has_NotShadowReceiver {
  get_not_shadow_receiver_store(self : Self) -> @ecs.ComponentAccess[
    NotShadowReceiver,
  ]
}

///|
pub(open) trait Has_PointLightTexture {
  get_point_light_texture_store(self : Self) -> @ecs.ComponentAccess[
    PointLightTexture,
  ]
}

///|
pub(open) trait Has_CameraProjection3d {
  get_camera_projection3d_store(self : Self) -> @ecs.ComponentAccess[
    CameraProjection3d,
  ]
}

///|
pub(open) trait Has_ParallaxCorrection {
  get_parallax_correction_store(self : Self) -> @ecs.ComponentAccess[
    ParallaxCorrection,
  ]
}

///|
pub(open) trait Has_ChromaticAberration {
  get_chromatic_aberration_store(self : Self) -> @ecs.ComponentAccess[
    ChromaticAberration,
  ]
}

///|
pub(open) trait Has_EnvironmentMapLight {
  get_environment_map_light_store(self : Self) -> @ecs.ComponentAccess[
    EnvironmentMapLight,
  ]
}

///|
pub(open) trait Has_MotionVectorPrepass {
  get_motion_vector_prepass_store(self : Self) -> @ecs.ComponentAccess[
    MotionVectorPrepass,
  ]
}

///|
pub(open) trait Has_TemporalAntiAliasing {
  get_temporal_anti_aliasing_store(self : Self) -> @ecs.ComponentAccess[
    TemporalAntiAliasing,
  ]
}

///|
pub(open) trait Has_ShadowFilteringMethod {
  get_shadow_filtering_method_store(self : Self) -> @ecs.ComponentAccess[
    ShadowFilteringMethod,
  ]
}

///|
pub(open) trait Has_ScreenSpaceReflections {
  get_screen_space_reflections_store(self : Self) -> @ecs.ComponentAccess[
    ScreenSpaceReflections,
  ]
}

///|
pub(open) trait Has_DirectionalLightTexture {
  get_directional_light_texture_store(self : Self) -> @ecs.ComponentAccess[
    DirectionalLightTexture,
  ]
}

///|
pub(open) trait Has_ForwardDecalMaterialExt {
  get_forward_decal_material_ext_store(self : Self) -> @ecs.ComponentAccess[
    ForwardDecalMaterialExt,
  ]
}

///|
pub(open) trait Has_ScreenSpaceTransmission {
  get_screen_space_transmission_store(self : Self) -> @ecs.ComponentAccess[
    ScreenSpaceTransmission,
  ]
}

///|
pub(open) trait Has_TransmittedShadowReceiver {
  get_transmitted_shadow_receiver_store(self : Self) -> @ecs.ComponentAccess[
    TransmittedShadowReceiver,
  ]
}

///|
pub(open) trait Has_ScreenSpaceAmbientOcclusion {
  get_screen_space_ambient_occlusion_store(self : Self) -> @ecs.ComponentAccess[
    ScreenSpaceAmbientOcclusion,
  ]
}

///|
pub(open) trait Has_GeneratedEnvironmentMapLight {
  get_generated_environment_map_light_store(self : Self) -> @ecs.ComponentAccess[
    GeneratedEnvironmentMapLight,
  ]
}

///|
pub(open) trait Has_OrderIndependentTransparencySettings {
  get_order_independent_transparency_settings_store(self : Self) -> @ecs.ComponentAccess[
    OrderIndependentTransparencySettings,
  ]
}

///|
pub fn[W : Has_Hdr] get_hdr_store(world : W) -> @ecs.ComponentAccess[Hdr] {
  world.get_hdr_store()
}

///|
pub fn[W : Has_Fxaa] get_fxaa_store(world : W) -> @ecs.ComponentAccess[Fxaa] {
  world.get_fxaa_store()
}

///|
pub fn[W : Has_Msaa] get_msaa_store(world : W) -> @ecs.ComponentAccess[Msaa] {
  world.get_msaa_store()
}

///|
pub fn[W : Has_Bloom] get_bloom_store(world : W) -> @ecs.ComponentAccess[Bloom] {
  world.get_bloom_store()
}

///|
pub fn[W : Has_Mesh3d] get_mesh3d_store(
  world : W,
) -> @ecs.ComponentAccess[Mesh3d] {
  world.get_mesh3d_store()
}

///|
pub fn[W : Has_Skybox] get_skybox_store(
  world : W,
) -> @ecs.ComponentAccess[Skybox] {
  world.get_skybox_store()
}

///|
pub fn[W : Has_Camera3d] get_camera3d_store(
  world : W,
) -> @ecs.ComponentAccess[Camera3d] {
  world.get_camera3d_store()
}

///|
pub fn[W : Has_Exposure] get_exposure_store(
  world : W,
) -> @ecs.ComponentAccess[Exposure] {
  world.get_exposure_store()
}

///|
pub fn[W : Has_Vignette] get_vignette_store(
  world : W,
) -> @ecs.ComponentAccess[Vignette] {
  world.get_vignette_store()
}

///|
pub fn[W : Has_SpotLight] get_spot_light_store(
  world : W,
) -> @ecs.ComponentAccess[SpotLight] {
  world.get_spot_light_store()
}

///|
pub fn[W : Has_Wireframe] get_wireframe_store(
  world : W,
) -> @ecs.ComponentAccess[Wireframe] {
  world.get_wireframe_store()
}

///|
pub fn[W : Has_FreeCamera] get_free_camera_store(
  world : W,
) -> @ecs.ComponentAccess[FreeCamera] {
  world.get_free_camera_store()
}

///|
pub fn[W : Has_LightProbe] get_light_probe_store(
  world : W,
) -> @ecs.ComponentAccess[LightProbe] {
  world.get_light_probe_store()
}

///|
pub fn[W : Has_MotionBlur] get_motion_blur_store(
  world : W,
) -> @ecs.ComponentAccess[MotionBlur] {
  world.get_motion_blur_store()
}

///|
pub fn[W : Has_PointLight] get_point_light_store(
  world : W,
) -> @ecs.ComponentAccess[PointLight] {
  world.get_point_light_store()
}

///|
pub fn[W : Has_NoWireframe] get_no_wireframe_store(
  world : W,
) -> @ecs.ComponentAccess[NoWireframe] {
  world.get_no_wireframe_store()
}

///|
pub fn[W : Has_Tonemapping] get_tonemapping_store(
  world : W,
) -> @ecs.ComponentAccess[Tonemapping] {
  world.get_tonemapping_store()
}

///|
pub fn[W : Has_ColorGrading] get_color_grading_store(
  world : W,
) -> @ecs.ComponentAccess[ColorGrading] {
  world.get_color_grading_store()
}

///|
pub fn[W : Has_DebandDither] get_deband_dither_store(
  world : W,
) -> @ecs.ComponentAccess[DebandDither] {
  world.get_deband_dither_store()
}

///|
pub fn[W : Has_DepthPrepass] get_depth_prepass_store(
  world : W,
) -> @ecs.ComponentAccess[DepthPrepass] {
  world.get_depth_prepass_store()
}

///|
pub fn[W : Has_ForwardDecal] get_forward_decal_store(
  world : W,
) -> @ecs.ComponentAccess[ForwardDecal] {
  world.get_forward_decal_store()
}

///|
pub fn[W : Has_NormalPrepass] get_normal_prepass_store(
  world : W,
) -> @ecs.ComponentAccess[NormalPrepass] {
  world.get_normal_prepass_store()
}

///|
pub fn[W : Has_ClusteredDecal] get_clustered_decal_store(
  world : W,
) -> @ecs.ComponentAccess[ClusteredDecal] {
  world.get_clustered_decal_store()
}

///|
pub fn[W : Has_ContactShadows] get_contact_shadows_store(
  world : W,
) -> @ecs.ComponentAccess[ContactShadows] {
  world.get_contact_shadows_store()
}

///|
pub fn[W : Has_MeshMaterial3d] get_mesh_material3d_store(
  world : W,
) -> @ecs.ComponentAccess[MeshMaterial3d] {
  world.get_mesh_material3d_store()
}

///|
pub fn[W : Has_TemporalJitter] get_temporal_jitter_store(
  world : W,
) -> @ecs.ComponentAccess[TemporalJitter] {
  world.get_temporal_jitter_store()
}

///|
pub fn[W : Has_WireframeColor] get_wireframe_color_store(
  world : W,
) -> @ecs.ComponentAccess[WireframeColor] {
  world.get_wireframe_color_store()
}

///|
pub fn[W : Has_DeferredPrepass] get_deferred_prepass_store(
  world : W,
) -> @ecs.ComponentAccess[DeferredPrepass] {
  world.get_deferred_prepass_store()
}

///|
pub fn[W : Has_FreeCameraState] get_free_camera_state_store(
  world : W,
) -> @ecs.ComponentAccess[FreeCameraState] {
  world.get_free_camera_state_store()
}

///|
pub fn[W : Has_NotShadowCaster] get_not_shadow_caster_store(
  world : W,
) -> @ecs.ComponentAccess[NotShadowCaster] {
  world.get_not_shadow_caster_store()
}

///|
pub fn[W : Has_SubCameraView3d] get_sub_camera_view3d_store(
  world : W,
) -> @ecs.ComponentAccess[SubCameraView3d] {
  world.get_sub_camera_view3d_store()
}

///|
pub fn[W : Has_DirectionalLight] get_directional_light_store(
  world : W,
) -> @ecs.ComponentAccess[DirectionalLight] {
  world.get_directional_light_store()
}

///|
pub fn[W : Has_IrradianceVolume] get_irradiance_volume_store(
  world : W,
) -> @ecs.ComponentAccess[IrradianceVolume] {
  world.get_irradiance_volume_store()
}

///|
pub fn[W : Has_OcclusionCulling] get_occlusion_culling_store(
  world : W,
) -> @ecs.ComponentAccess[OcclusionCulling] {
  world.get_occlusion_culling_store()
}

///|
pub fn[W : Has_SpotLightTexture] get_spot_light_texture_store(
  world : W,
) -> @ecs.ComponentAccess[SpotLightTexture] {
  world.get_spot_light_texture_store()
}

///|
pub fn[W : Has_NotShadowReceiver] get_not_shadow_receiver_store(
  world : W,
) -> @ecs.ComponentAccess[NotShadowReceiver] {
  world.get_not_shadow_receiver_store()
}

///|
pub fn[W : Has_PointLightTexture] get_point_light_texture_store(
  world : W,
) -> @ecs.ComponentAccess[PointLightTexture] {
  world.get_point_light_texture_store()
}

///|
pub fn[W : Has_CameraProjection3d] get_camera_projection3d_store(
  world : W,
) -> @ecs.ComponentAccess[CameraProjection3d] {
  world.get_camera_projection3d_store()
}

///|
pub fn[W : Has_ParallaxCorrection] get_parallax_correction_store(
  world : W,
) -> @ecs.ComponentAccess[ParallaxCorrection] {
  world.get_parallax_correction_store()
}

///|
pub fn[W : Has_ChromaticAberration] get_chromatic_aberration_store(
  world : W,
) -> @ecs.ComponentAccess[ChromaticAberration] {
  world.get_chromatic_aberration_store()
}

///|
pub fn[W : Has_EnvironmentMapLight] get_environment_map_light_store(
  world : W,
) -> @ecs.ComponentAccess[EnvironmentMapLight] {
  world.get_environment_map_light_store()
}

///|
pub fn[W : Has_MotionVectorPrepass] get_motion_vector_prepass_store(
  world : W,
) -> @ecs.ComponentAccess[MotionVectorPrepass] {
  world.get_motion_vector_prepass_store()
}

///|
pub fn[W : Has_TemporalAntiAliasing] get_temporal_anti_aliasing_store(
  world : W,
) -> @ecs.ComponentAccess[TemporalAntiAliasing] {
  world.get_temporal_anti_aliasing_store()
}

///|
pub fn[W : Has_ShadowFilteringMethod] get_shadow_filtering_method_store(
  world : W,
) -> @ecs.ComponentAccess[ShadowFilteringMethod] {
  world.get_shadow_filtering_method_store()
}

///|
pub fn[W : Has_ScreenSpaceReflections] get_screen_space_reflections_store(
  world : W,
) -> @ecs.ComponentAccess[ScreenSpaceReflections] {
  world.get_screen_space_reflections_store()
}

///|
pub fn[W : Has_DirectionalLightTexture] get_directional_light_texture_store(
  world : W,
) -> @ecs.ComponentAccess[DirectionalLightTexture] {
  world.get_directional_light_texture_store()
}

///|
pub fn[W : Has_ForwardDecalMaterialExt] get_forward_decal_material_ext_store(
  world : W,
) -> @ecs.ComponentAccess[ForwardDecalMaterialExt] {
  world.get_forward_decal_material_ext_store()
}

///|
pub fn[W : Has_ScreenSpaceTransmission] get_screen_space_transmission_store(
  world : W,
) -> @ecs.ComponentAccess[ScreenSpaceTransmission] {
  world.get_screen_space_transmission_store()
}

///|
pub fn[W : Has_TransmittedShadowReceiver] get_transmitted_shadow_receiver_store(
  world : W,
) -> @ecs.ComponentAccess[TransmittedShadowReceiver] {
  world.get_transmitted_shadow_receiver_store()
}

///|
pub fn[W : Has_ScreenSpaceAmbientOcclusion] get_screen_space_ambient_occlusion_store(
  world : W,
) -> @ecs.ComponentAccess[ScreenSpaceAmbientOcclusion] {
  world.get_screen_space_ambient_occlusion_store()
}

///|
pub fn[W : Has_GeneratedEnvironmentMapLight] get_generated_environment_map_light_store(
  world : W,
) -> @ecs.ComponentAccess[GeneratedEnvironmentMapLight] {
  world.get_generated_environment_map_light_store()
}

///|
pub fn[W : Has_OrderIndependentTransparencySettings] get_order_independent_transparency_settings_store(
  world : W,
) -> @ecs.ComponentAccess[OrderIndependentTransparencySettings] {
  world.get_order_independent_transparency_settings_store()
}

///|
pub(open) trait HasRes_WireframeConfig {
  get_wireframe_config_resource(self : Self) -> @ecs.ResourceAccess[
    WireframeConfig,
  ]
}

///|
pub(open) trait HasRes_GlobalAmbientLight {
  get_global_ambient_light_resource(self : Self) -> @ecs.ResourceAccess[
    GlobalAmbientLight,
  ]
}

///|
pub(open) trait HasRes_PointLightShadowMap {
  get_point_light_shadow_map_resource(self : Self) -> @ecs.ResourceAccess[
    PointLightShadowMap,
  ]
}

///|
pub(open) trait HasRes_DirectionalLightShadowMap {
  get_directional_light_shadow_map_resource(self : Self) -> @ecs.ResourceAccess[
    DirectionalLightShadowMap,
  ]
}

///|
pub(open) trait HasRes_DefaultOpaqueRendererMethod {
  get_default_opaque_renderer_method_resource(self : Self) -> @ecs.ResourceAccess[
    DefaultOpaqueRendererMethod,
  ]
}

///|
pub fn[W : HasRes_WireframeConfig] get_wireframe_config_resource(
  world : W,
) -> @ecs.ResourceAccess[WireframeConfig] {
  world.get_wireframe_config_resource()
}

///|
pub fn[W : HasRes_GlobalAmbientLight] get_global_ambient_light_resource(
  world : W,
) -> @ecs.ResourceAccess[GlobalAmbientLight] {
  world.get_global_ambient_light_resource()
}

///|
pub fn[W : HasRes_PointLightShadowMap] get_point_light_shadow_map_resource(
  world : W,
) -> @ecs.ResourceAccess[PointLightShadowMap] {
  world.get_point_light_shadow_map_resource()
}

///|
pub fn[W : HasRes_DirectionalLightShadowMap] get_directional_light_shadow_map_resource(
  world : W,
) -> @ecs.ResourceAccess[DirectionalLightShadowMap] {
  world.get_directional_light_shadow_map_resource()
}

///|
pub fn[W : HasRes_DefaultOpaqueRendererMethod] get_default_opaque_renderer_method_resource(
  world : W,
) -> @ecs.ResourceAccess[DefaultOpaqueRendererMethod] {
  world.get_default_opaque_renderer_method_resource()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_Hdr for @ecs.World with get_hdr_store(self) {
  self.component(ecs_key_hdr)
}

///|
pub impl Has_Fxaa for @ecs.World with get_fxaa_store(self) {
  self.component(ecs_key_fxaa)
}

///|
pub impl Has_Msaa for @ecs.World with get_msaa_store(self) {
  self.component(ecs_key_msaa)
}

///|
pub impl Has_Bloom for @ecs.World with get_bloom_store(self) {
  self.component(ecs_key_bloom)
}

///|
pub impl Has_Mesh3d for @ecs.World with get_mesh3d_store(self) {
  self.component(ecs_key_mesh3d)
}

///|
pub impl Has_Skybox for @ecs.World with get_skybox_store(self) {
  self.component(ecs_key_skybox)
}

///|
pub impl Has_Camera3d for @ecs.World with get_camera3d_store(self) {
  self.component(ecs_key_camera3d)
}

///|
pub impl Has_Exposure for @ecs.World with get_exposure_store(self) {
  self.component(ecs_key_exposure)
}

///|
pub impl Has_Vignette for @ecs.World with get_vignette_store(self) {
  self.component(ecs_key_vignette)
}

///|
pub impl Has_SpotLight for @ecs.World with get_spot_light_store(self) {
  self.component(ecs_key_spot_light)
}

///|
pub impl Has_Wireframe for @ecs.World with get_wireframe_store(self) {
  self.component(ecs_key_wireframe)
}

///|
pub impl Has_FreeCamera for @ecs.World with get_free_camera_store(self) {
  self.component(ecs_key_free_camera)
}

///|
pub impl Has_LightProbe for @ecs.World with get_light_probe_store(self) {
  self.component(ecs_key_light_probe)
}

///|
pub impl Has_MotionBlur for @ecs.World with get_motion_blur_store(self) {
  self.component(ecs_key_motion_blur)
}

///|
pub impl Has_PointLight for @ecs.World with get_point_light_store(self) {
  self.component(ecs_key_point_light)
}

///|
pub impl Has_NoWireframe for @ecs.World with get_no_wireframe_store(self) {
  self.component(ecs_key_no_wireframe)
}

///|
pub impl Has_Tonemapping for @ecs.World with get_tonemapping_store(self) {
  self.component(ecs_key_tonemapping)
}

///|
pub impl Has_ColorGrading for @ecs.World with get_color_grading_store(self) {
  self.component(ecs_key_color_grading)
}

///|
pub impl Has_DebandDither for @ecs.World with get_deband_dither_store(self) {
  self.component(ecs_key_deband_dither)
}

///|
pub impl Has_DepthPrepass for @ecs.World with get_depth_prepass_store(self) {
  self.component(ecs_key_depth_prepass)
}

///|
pub impl Has_ForwardDecal for @ecs.World with get_forward_decal_store(self) {
  self.component(ecs_key_forward_decal)
}

///|
pub impl Has_NormalPrepass for @ecs.World with get_normal_prepass_store(self) {
  self.component(ecs_key_normal_prepass)
}

///|
pub impl Has_ClusteredDecal for @ecs.World with get_clustered_decal_store(self) {
  self.component(ecs_key_clustered_decal)
}

///|
pub impl Has_ContactShadows for @ecs.World with get_contact_shadows_store(self) {
  self.component(ecs_key_contact_shadows)
}

///|
pub impl Has_MeshMaterial3d for @ecs.World with get_mesh_material3d_store(self) {
  self.component(ecs_key_mesh_material3d)
}

///|
pub impl Has_TemporalJitter for @ecs.World with get_temporal_jitter_store(self) {
  self.component(ecs_key_temporal_jitter)
}

///|
pub impl Has_WireframeColor for @ecs.World with get_wireframe_color_store(self) {
  self.component(ecs_key_wireframe_color)
}

///|
pub impl Has_DeferredPrepass for @ecs.World with get_deferred_prepass_store(
  self,
) {
  self.component(ecs_key_deferred_prepass)
}

///|
pub impl Has_FreeCameraState for @ecs.World with get_free_camera_state_store(
  self,
) {
  self.component(ecs_key_free_camera_state)
}

///|
pub impl Has_NotShadowCaster for @ecs.World with get_not_shadow_caster_store(
  self,
) {
  self.component(ecs_key_not_shadow_caster)
}

///|
pub impl Has_SubCameraView3d for @ecs.World with get_sub_camera_view3d_store(
  self,
) {
  self.component(ecs_key_sub_camera_view3d)
}

///|
pub impl Has_DirectionalLight for @ecs.World with get_directional_light_store(
  self,
) {
  self.component(ecs_key_directional_light)
}

///|
pub impl Has_IrradianceVolume for @ecs.World with get_irradiance_volume_store(
  self,
) {
  self.component(ecs_key_irradiance_volume)
}

///|
pub impl Has_OcclusionCulling for @ecs.World with get_occlusion_culling_store(
  self,
) {
  self.component(ecs_key_occlusion_culling)
}

///|
pub impl Has_SpotLightTexture for @ecs.World with get_spot_light_texture_store(
  self,
) {
  self.component(ecs_key_spot_light_texture)
}

///|
pub impl Has_NotShadowReceiver for @ecs.World with get_not_shadow_receiver_store(
  self,
) {
  self.component(ecs_key_not_shadow_receiver)
}

///|
pub impl Has_PointLightTexture for @ecs.World with get_point_light_texture_store(
  self,
) {
  self.component(ecs_key_point_light_texture)
}

///|
pub impl Has_CameraProjection3d for @ecs.World with get_camera_projection3d_store(
  self,
) {
  self.component(ecs_key_camera_projection3d)
}

///|
pub impl Has_ParallaxCorrection for @ecs.World with get_parallax_correction_store(
  self,
) {
  self.component(ecs_key_parallax_correction)
}

///|
pub impl Has_ChromaticAberration for @ecs.World with get_chromatic_aberration_store(
  self,
) {
  self.component(ecs_key_chromatic_aberration)
}

///|
pub impl Has_EnvironmentMapLight for @ecs.World with get_environment_map_light_store(
  self,
) {
  self.component(ecs_key_environment_map_light)
}

///|
pub impl Has_MotionVectorPrepass for @ecs.World with get_motion_vector_prepass_store(
  self,
) {
  self.component(ecs_key_motion_vector_prepass)
}

///|
pub impl Has_TemporalAntiAliasing for @ecs.World with get_temporal_anti_aliasing_store(
  self,
) {
  self.component(ecs_key_temporal_anti_aliasing)
}

///|
pub impl Has_ShadowFilteringMethod for @ecs.World with get_shadow_filtering_method_store(
  self,
) {
  self.component(ecs_key_shadow_filtering_method)
}

///|
pub impl Has_ScreenSpaceReflections for @ecs.World with get_screen_space_reflections_store(
  self,
) {
  self.component(ecs_key_screen_space_reflections)
}

///|
pub impl Has_DirectionalLightTexture for @ecs.World with get_directional_light_texture_store(
  self,
) {
  self.component(ecs_key_directional_light_texture)
}

///|
pub impl Has_ForwardDecalMaterialExt for @ecs.World with get_forward_decal_material_ext_store(
  self,
) {
  self.component(ecs_key_forward_decal_material_ext)
}

///|
pub impl Has_ScreenSpaceTransmission for @ecs.World with get_screen_space_transmission_store(
  self,
) {
  self.component(ecs_key_screen_space_transmission)
}

///|
pub impl Has_TransmittedShadowReceiver for @ecs.World with get_transmitted_shadow_receiver_store(
  self,
) {
  self.component(ecs_key_transmitted_shadow_receiver)
}

///|
pub impl Has_ScreenSpaceAmbientOcclusion for @ecs.World with get_screen_space_ambient_occlusion_store(
  self,
) {
  self.component(ecs_key_screen_space_ambient_occlusion)
}

///|
pub impl Has_GeneratedEnvironmentMapLight for @ecs.World with get_generated_environment_map_light_store(
  self,
) {
  self.component(ecs_key_generated_environment_map_light)
}

///|
pub impl Has_OrderIndependentTransparencySettings for @ecs.World with get_order_independent_transparency_settings_store(
  self,
) {
  self.component(ecs_key_order_independent_transparency_settings)
}

///|
pub impl HasRes_WireframeConfig for @ecs.World with get_wireframe_config_resource(
  self,
) {
  self.resource(ecs_key_wireframe_config)
}

///|
pub impl HasRes_GlobalAmbientLight for @ecs.World with get_global_ambient_light_resource(
  self,
) {
  self.resource(ecs_key_global_ambient_light)
}

///|
pub impl HasRes_PointLightShadowMap for @ecs.World with get_point_light_shadow_map_resource(
  self,
) {
  self.resource(ecs_key_point_light_shadow_map)
}

///|
pub impl HasRes_DirectionalLightShadowMap for @ecs.World with get_directional_light_shadow_map_resource(
  self,
) {
  self.resource(ecs_key_directional_light_shadow_map)
}

///|
pub impl HasRes_DefaultOpaqueRendererMethod for @ecs.World with get_default_opaque_renderer_method_resource(
  self,
) {
  self.resource(ecs_key_default_opaque_renderer_method)
}

///|
/// End ECS bridge impls.
