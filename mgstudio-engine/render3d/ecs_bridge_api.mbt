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
  get_hdr_store(self : Self) -> @core.ComponentStore[Hdr]
}

///|
pub(open) trait Has_Fxaa {
  get_fxaa_store(self : Self) -> @core.ComponentStore[Fxaa]
}

///|
pub(open) trait Has_Msaa {
  get_msaa_store(self : Self) -> @core.ComponentStore[Msaa]
}

///|
pub(open) trait Has_Bloom {
  get_bloom_store(self : Self) -> @core.ComponentStore[Bloom]
}

///|
pub(open) trait Has_Mesh3d {
  get_mesh3d_store(self : Self) -> @core.ComponentStore[Mesh3d]
}

///|
pub(open) trait Has_Skybox {
  get_skybox_store(self : Self) -> @core.ComponentStore[Skybox]
}

///|
pub(open) trait Has_Camera3d {
  get_camera3d_store(self : Self) -> @core.ComponentStore[Camera3d]
}

///|
pub(open) trait Has_Exposure {
  get_exposure_store(self : Self) -> @core.ComponentStore[Exposure]
}

///|
pub(open) trait Has_Vignette {
  get_vignette_store(self : Self) -> @core.ComponentStore[Vignette]
}

///|
pub(open) trait Has_SpotLight {
  get_spot_light_store(self : Self) -> @core.ComponentStore[SpotLight]
}

///|
pub(open) trait Has_Wireframe {
  get_wireframe_store(self : Self) -> @core.ComponentStore[Wireframe]
}

///|
pub(open) trait Has_FreeCamera {
  get_free_camera_store(self : Self) -> @core.ComponentStore[FreeCamera]
}

///|
pub(open) trait Has_LightProbe {
  get_light_probe_store(self : Self) -> @core.ComponentStore[LightProbe]
}

///|
pub(open) trait Has_MotionBlur {
  get_motion_blur_store(self : Self) -> @core.ComponentStore[MotionBlur]
}

///|
pub(open) trait Has_PointLight {
  get_point_light_store(self : Self) -> @core.ComponentStore[PointLight]
}

///|
pub(open) trait Has_NoWireframe {
  get_no_wireframe_store(self : Self) -> @core.ComponentStore[NoWireframe]
}

///|
pub(open) trait Has_Tonemapping {
  get_tonemapping_store(self : Self) -> @core.ComponentStore[Tonemapping]
}

///|
pub(open) trait Has_ColorGrading {
  get_color_grading_store(self : Self) -> @core.ComponentStore[ColorGrading]
}

///|
pub(open) trait Has_DebandDither {
  get_deband_dither_store(self : Self) -> @core.ComponentStore[DebandDither]
}

///|
pub(open) trait Has_DepthPrepass {
  get_depth_prepass_store(self : Self) -> @core.ComponentStore[DepthPrepass]
}

///|
pub(open) trait Has_ForwardDecal {
  get_forward_decal_store(self : Self) -> @core.ComponentStore[ForwardDecal]
}

///|
pub(open) trait Has_NormalPrepass {
  get_normal_prepass_store(self : Self) -> @core.ComponentStore[NormalPrepass]
}

///|
pub(open) trait Has_ClusteredDecal {
  get_clustered_decal_store(self : Self) -> @core.ComponentStore[ClusteredDecal]
}

///|
pub(open) trait Has_ContactShadows {
  get_contact_shadows_store(self : Self) -> @core.ComponentStore[ContactShadows]
}

///|
pub(open) trait Has_MeshMaterial3d {
  get_mesh_material3d_store(self : Self) -> @core.ComponentStore[MeshMaterial3d]
}

///|
pub(open) trait Has_TemporalJitter {
  get_temporal_jitter_store(self : Self) -> @core.ComponentStore[TemporalJitter]
}

///|
pub(open) trait Has_WireframeColor {
  get_wireframe_color_store(self : Self) -> @core.ComponentStore[WireframeColor]
}

///|
pub(open) trait Has_DeferredPrepass {
  get_deferred_prepass_store(self : Self) -> @core.ComponentStore[
    DeferredPrepass,
  ]
}

///|
pub(open) trait Has_FreeCameraState {
  get_free_camera_state_store(self : Self) -> @core.ComponentStore[
    FreeCameraState,
  ]
}

///|
pub(open) trait Has_NotShadowCaster {
  get_not_shadow_caster_store(self : Self) -> @core.ComponentStore[
    NotShadowCaster,
  ]
}

///|
pub(open) trait Has_SubCameraView3d {
  get_sub_camera_view3d_store(self : Self) -> @core.ComponentStore[
    SubCameraView3d,
  ]
}

///|
pub(open) trait Has_DirectionalLight {
  get_directional_light_store(self : Self) -> @core.ComponentStore[
    DirectionalLight,
  ]
}

///|
pub(open) trait Has_IrradianceVolume {
  get_irradiance_volume_store(self : Self) -> @core.ComponentStore[
    IrradianceVolume,
  ]
}

///|
pub(open) trait Has_OcclusionCulling {
  get_occlusion_culling_store(self : Self) -> @core.ComponentStore[
    OcclusionCulling,
  ]
}

///|
pub(open) trait Has_SpotLightTexture {
  get_spot_light_texture_store(self : Self) -> @core.ComponentStore[
    SpotLightTexture,
  ]
}

///|
pub(open) trait Has_NotShadowReceiver {
  get_not_shadow_receiver_store(self : Self) -> @core.ComponentStore[
    NotShadowReceiver,
  ]
}

///|
pub(open) trait Has_PointLightTexture {
  get_point_light_texture_store(self : Self) -> @core.ComponentStore[
    PointLightTexture,
  ]
}

///|
pub(open) trait Has_CameraProjection3d {
  get_camera_projection3d_store(self : Self) -> @core.ComponentStore[
    CameraProjection3d,
  ]
}

///|
pub(open) trait Has_ParallaxCorrection {
  get_parallax_correction_store(self : Self) -> @core.ComponentStore[
    ParallaxCorrection,
  ]
}

///|
pub(open) trait Has_ChromaticAberration {
  get_chromatic_aberration_store(self : Self) -> @core.ComponentStore[
    ChromaticAberration,
  ]
}

///|
pub(open) trait Has_EnvironmentMapLight {
  get_environment_map_light_store(self : Self) -> @core.ComponentStore[
    EnvironmentMapLight,
  ]
}

///|
pub(open) trait Has_MotionVectorPrepass {
  get_motion_vector_prepass_store(self : Self) -> @core.ComponentStore[
    MotionVectorPrepass,
  ]
}

///|
pub(open) trait Has_TemporalAntiAliasing {
  get_temporal_anti_aliasing_store(self : Self) -> @core.ComponentStore[
    TemporalAntiAliasing,
  ]
}

///|
pub(open) trait Has_ShadowFilteringMethod {
  get_shadow_filtering_method_store(self : Self) -> @core.ComponentStore[
    ShadowFilteringMethod,
  ]
}

///|
pub(open) trait Has_ScreenSpaceReflections {
  get_screen_space_reflections_store(self : Self) -> @core.ComponentStore[
    ScreenSpaceReflections,
  ]
}

///|
pub(open) trait Has_DirectionalLightTexture {
  get_directional_light_texture_store(self : Self) -> @core.ComponentStore[
    DirectionalLightTexture,
  ]
}

///|
pub(open) trait Has_ForwardDecalMaterialExt {
  get_forward_decal_material_ext_store(self : Self) -> @core.ComponentStore[
    ForwardDecalMaterialExt,
  ]
}

///|
pub(open) trait Has_ScreenSpaceTransmission {
  get_screen_space_transmission_store(self : Self) -> @core.ComponentStore[
    ScreenSpaceTransmission,
  ]
}

///|
pub(open) trait Has_TransmittedShadowReceiver {
  get_transmitted_shadow_receiver_store(self : Self) -> @core.ComponentStore[
    TransmittedShadowReceiver,
  ]
}

///|
pub(open) trait Has_ScreenSpaceAmbientOcclusion {
  get_screen_space_ambient_occlusion_store(self : Self) -> @core.ComponentStore[
    ScreenSpaceAmbientOcclusion,
  ]
}

///|
pub(open) trait Has_GeneratedEnvironmentMapLight {
  get_generated_environment_map_light_store(self : Self) -> @core.ComponentStore[
    GeneratedEnvironmentMapLight,
  ]
}

///|
pub(open) trait Has_OrderIndependentTransparencySettings {
  get_order_independent_transparency_settings_store(self : Self) -> @core.ComponentStore[
    OrderIndependentTransparencySettings,
  ]
}

///|
pub fn[W : Has_Hdr] get_hdr_store(world : W) -> @core.ComponentStore[Hdr] {
  world.get_hdr_store()
}

///|
pub fn[W : Has_Fxaa] get_fxaa_store(world : W) -> @core.ComponentStore[Fxaa] {
  world.get_fxaa_store()
}

///|
pub fn[W : Has_Msaa] get_msaa_store(world : W) -> @core.ComponentStore[Msaa] {
  world.get_msaa_store()
}

///|
pub fn[W : Has_Bloom] get_bloom_store(world : W) -> @core.ComponentStore[Bloom] {
  world.get_bloom_store()
}

///|
pub fn[W : Has_Mesh3d] get_mesh3d_store(
  world : W,
) -> @core.ComponentStore[Mesh3d] {
  world.get_mesh3d_store()
}

///|
pub fn[W : Has_Skybox] get_skybox_store(
  world : W,
) -> @core.ComponentStore[Skybox] {
  world.get_skybox_store()
}

///|
pub fn[W : Has_Camera3d] get_camera3d_store(
  world : W,
) -> @core.ComponentStore[Camera3d] {
  world.get_camera3d_store()
}

///|
pub fn[W : Has_Exposure] get_exposure_store(
  world : W,
) -> @core.ComponentStore[Exposure] {
  world.get_exposure_store()
}

///|
pub fn[W : Has_Vignette] get_vignette_store(
  world : W,
) -> @core.ComponentStore[Vignette] {
  world.get_vignette_store()
}

///|
pub fn[W : Has_SpotLight] get_spot_light_store(
  world : W,
) -> @core.ComponentStore[SpotLight] {
  world.get_spot_light_store()
}

///|
pub fn[W : Has_Wireframe] get_wireframe_store(
  world : W,
) -> @core.ComponentStore[Wireframe] {
  world.get_wireframe_store()
}

///|
pub fn[W : Has_FreeCamera] get_free_camera_store(
  world : W,
) -> @core.ComponentStore[FreeCamera] {
  world.get_free_camera_store()
}

///|
pub fn[W : Has_LightProbe] get_light_probe_store(
  world : W,
) -> @core.ComponentStore[LightProbe] {
  world.get_light_probe_store()
}

///|
pub fn[W : Has_MotionBlur] get_motion_blur_store(
  world : W,
) -> @core.ComponentStore[MotionBlur] {
  world.get_motion_blur_store()
}

///|
pub fn[W : Has_PointLight] get_point_light_store(
  world : W,
) -> @core.ComponentStore[PointLight] {
  world.get_point_light_store()
}

///|
pub fn[W : Has_NoWireframe] get_no_wireframe_store(
  world : W,
) -> @core.ComponentStore[NoWireframe] {
  world.get_no_wireframe_store()
}

///|
pub fn[W : Has_Tonemapping] get_tonemapping_store(
  world : W,
) -> @core.ComponentStore[Tonemapping] {
  world.get_tonemapping_store()
}

///|
pub fn[W : Has_ColorGrading] get_color_grading_store(
  world : W,
) -> @core.ComponentStore[ColorGrading] {
  world.get_color_grading_store()
}

///|
pub fn[W : Has_DebandDither] get_deband_dither_store(
  world : W,
) -> @core.ComponentStore[DebandDither] {
  world.get_deband_dither_store()
}

///|
pub fn[W : Has_DepthPrepass] get_depth_prepass_store(
  world : W,
) -> @core.ComponentStore[DepthPrepass] {
  world.get_depth_prepass_store()
}

///|
pub fn[W : Has_ForwardDecal] get_forward_decal_store(
  world : W,
) -> @core.ComponentStore[ForwardDecal] {
  world.get_forward_decal_store()
}

///|
pub fn[W : Has_NormalPrepass] get_normal_prepass_store(
  world : W,
) -> @core.ComponentStore[NormalPrepass] {
  world.get_normal_prepass_store()
}

///|
pub fn[W : Has_ClusteredDecal] get_clustered_decal_store(
  world : W,
) -> @core.ComponentStore[ClusteredDecal] {
  world.get_clustered_decal_store()
}

///|
pub fn[W : Has_ContactShadows] get_contact_shadows_store(
  world : W,
) -> @core.ComponentStore[ContactShadows] {
  world.get_contact_shadows_store()
}

///|
pub fn[W : Has_MeshMaterial3d] get_mesh_material3d_store(
  world : W,
) -> @core.ComponentStore[MeshMaterial3d] {
  world.get_mesh_material3d_store()
}

///|
pub fn[W : Has_TemporalJitter] get_temporal_jitter_store(
  world : W,
) -> @core.ComponentStore[TemporalJitter] {
  world.get_temporal_jitter_store()
}

///|
pub fn[W : Has_WireframeColor] get_wireframe_color_store(
  world : W,
) -> @core.ComponentStore[WireframeColor] {
  world.get_wireframe_color_store()
}

///|
pub fn[W : Has_DeferredPrepass] get_deferred_prepass_store(
  world : W,
) -> @core.ComponentStore[DeferredPrepass] {
  world.get_deferred_prepass_store()
}

///|
pub fn[W : Has_FreeCameraState] get_free_camera_state_store(
  world : W,
) -> @core.ComponentStore[FreeCameraState] {
  world.get_free_camera_state_store()
}

///|
pub fn[W : Has_NotShadowCaster] get_not_shadow_caster_store(
  world : W,
) -> @core.ComponentStore[NotShadowCaster] {
  world.get_not_shadow_caster_store()
}

///|
pub fn[W : Has_SubCameraView3d] get_sub_camera_view3d_store(
  world : W,
) -> @core.ComponentStore[SubCameraView3d] {
  world.get_sub_camera_view3d_store()
}

///|
pub fn[W : Has_DirectionalLight] get_directional_light_store(
  world : W,
) -> @core.ComponentStore[DirectionalLight] {
  world.get_directional_light_store()
}

///|
pub fn[W : Has_IrradianceVolume] get_irradiance_volume_store(
  world : W,
) -> @core.ComponentStore[IrradianceVolume] {
  world.get_irradiance_volume_store()
}

///|
pub fn[W : Has_OcclusionCulling] get_occlusion_culling_store(
  world : W,
) -> @core.ComponentStore[OcclusionCulling] {
  world.get_occlusion_culling_store()
}

///|
pub fn[W : Has_SpotLightTexture] get_spot_light_texture_store(
  world : W,
) -> @core.ComponentStore[SpotLightTexture] {
  world.get_spot_light_texture_store()
}

///|
pub fn[W : Has_NotShadowReceiver] get_not_shadow_receiver_store(
  world : W,
) -> @core.ComponentStore[NotShadowReceiver] {
  world.get_not_shadow_receiver_store()
}

///|
pub fn[W : Has_PointLightTexture] get_point_light_texture_store(
  world : W,
) -> @core.ComponentStore[PointLightTexture] {
  world.get_point_light_texture_store()
}

///|
pub fn[W : Has_CameraProjection3d] get_camera_projection3d_store(
  world : W,
) -> @core.ComponentStore[CameraProjection3d] {
  world.get_camera_projection3d_store()
}

///|
pub fn[W : Has_ParallaxCorrection] get_parallax_correction_store(
  world : W,
) -> @core.ComponentStore[ParallaxCorrection] {
  world.get_parallax_correction_store()
}

///|
pub fn[W : Has_ChromaticAberration] get_chromatic_aberration_store(
  world : W,
) -> @core.ComponentStore[ChromaticAberration] {
  world.get_chromatic_aberration_store()
}

///|
pub fn[W : Has_EnvironmentMapLight] get_environment_map_light_store(
  world : W,
) -> @core.ComponentStore[EnvironmentMapLight] {
  world.get_environment_map_light_store()
}

///|
pub fn[W : Has_MotionVectorPrepass] get_motion_vector_prepass_store(
  world : W,
) -> @core.ComponentStore[MotionVectorPrepass] {
  world.get_motion_vector_prepass_store()
}

///|
pub fn[W : Has_TemporalAntiAliasing] get_temporal_anti_aliasing_store(
  world : W,
) -> @core.ComponentStore[TemporalAntiAliasing] {
  world.get_temporal_anti_aliasing_store()
}

///|
pub fn[W : Has_ShadowFilteringMethod] get_shadow_filtering_method_store(
  world : W,
) -> @core.ComponentStore[ShadowFilteringMethod] {
  world.get_shadow_filtering_method_store()
}

///|
pub fn[W : Has_ScreenSpaceReflections] get_screen_space_reflections_store(
  world : W,
) -> @core.ComponentStore[ScreenSpaceReflections] {
  world.get_screen_space_reflections_store()
}

///|
pub fn[W : Has_DirectionalLightTexture] get_directional_light_texture_store(
  world : W,
) -> @core.ComponentStore[DirectionalLightTexture] {
  world.get_directional_light_texture_store()
}

///|
pub fn[W : Has_ForwardDecalMaterialExt] get_forward_decal_material_ext_store(
  world : W,
) -> @core.ComponentStore[ForwardDecalMaterialExt] {
  world.get_forward_decal_material_ext_store()
}

///|
pub fn[W : Has_ScreenSpaceTransmission] get_screen_space_transmission_store(
  world : W,
) -> @core.ComponentStore[ScreenSpaceTransmission] {
  world.get_screen_space_transmission_store()
}

///|
pub fn[W : Has_TransmittedShadowReceiver] get_transmitted_shadow_receiver_store(
  world : W,
) -> @core.ComponentStore[TransmittedShadowReceiver] {
  world.get_transmitted_shadow_receiver_store()
}

///|
pub fn[W : Has_ScreenSpaceAmbientOcclusion] get_screen_space_ambient_occlusion_store(
  world : W,
) -> @core.ComponentStore[ScreenSpaceAmbientOcclusion] {
  world.get_screen_space_ambient_occlusion_store()
}

///|
pub fn[W : Has_GeneratedEnvironmentMapLight] get_generated_environment_map_light_store(
  world : W,
) -> @core.ComponentStore[GeneratedEnvironmentMapLight] {
  world.get_generated_environment_map_light_store()
}

///|
pub fn[W : Has_OrderIndependentTransparencySettings] get_order_independent_transparency_settings_store(
  world : W,
) -> @core.ComponentStore[OrderIndependentTransparencySettings] {
  world.get_order_independent_transparency_settings_store()
}

///|
pub(open) trait HasRes_WireframeConfig {
  get_wireframe_config_resource(self : Self) -> @core.Resource[WireframeConfig]
}

///|
pub(open) trait HasRes_GlobalAmbientLight {
  get_global_ambient_light_resource(self : Self) -> @core.Resource[
    GlobalAmbientLight,
  ]
}

///|
pub(open) trait HasRes_PointLightShadowMap {
  get_point_light_shadow_map_resource(self : Self) -> @core.Resource[
    PointLightShadowMap,
  ]
}

///|
pub(open) trait HasRes_DirectionalLightShadowMap {
  get_directional_light_shadow_map_resource(self : Self) -> @core.Resource[
    DirectionalLightShadowMap,
  ]
}

///|
pub(open) trait HasRes_DefaultOpaqueRendererMethod {
  get_default_opaque_renderer_method_resource(self : Self) -> @core.Resource[
    DefaultOpaqueRendererMethod,
  ]
}

///|
pub fn[W : HasRes_WireframeConfig] get_wireframe_config_resource(
  world : W,
) -> @core.Resource[WireframeConfig] {
  world.get_wireframe_config_resource()
}

///|
pub fn[W : HasRes_GlobalAmbientLight] get_global_ambient_light_resource(
  world : W,
) -> @core.Resource[GlobalAmbientLight] {
  world.get_global_ambient_light_resource()
}

///|
pub fn[W : HasRes_PointLightShadowMap] get_point_light_shadow_map_resource(
  world : W,
) -> @core.Resource[PointLightShadowMap] {
  world.get_point_light_shadow_map_resource()
}

///|
pub fn[W : HasRes_DirectionalLightShadowMap] get_directional_light_shadow_map_resource(
  world : W,
) -> @core.Resource[DirectionalLightShadowMap] {
  world.get_directional_light_shadow_map_resource()
}

///|
pub fn[W : HasRes_DefaultOpaqueRendererMethod] get_default_opaque_renderer_method_resource(
  world : W,
) -> @core.Resource[DefaultOpaqueRendererMethod] {
  world.get_default_opaque_renderer_method_resource()
}

///|
/// ECS bridge impls for @ecs.World.

///|
let bridge_get_hdr_store_by_world : Map[Int, @core.ComponentStore[Hdr]] = {}

///|
pub impl Has_Hdr for @ecs.World with get_hdr_store(self) {
  bridge_get_hdr_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_fxaa_store_by_world : Map[Int, @core.ComponentStore[Fxaa]] = {}

///|
pub impl Has_Fxaa for @ecs.World with get_fxaa_store(self) {
  bridge_get_fxaa_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_msaa_store_by_world : Map[Int, @core.ComponentStore[Msaa]] = {}

///|
pub impl Has_Msaa for @ecs.World with get_msaa_store(self) {
  bridge_get_msaa_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_bloom_store_by_world : Map[Int, @core.ComponentStore[Bloom]] = {}

///|
pub impl Has_Bloom for @ecs.World with get_bloom_store(self) {
  bridge_get_bloom_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_mesh3d_store_by_world : Map[Int, @core.ComponentStore[Mesh3d]] = {}

///|
pub impl Has_Mesh3d for @ecs.World with get_mesh3d_store(self) {
  bridge_get_mesh3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_skybox_store_by_world : Map[Int, @core.ComponentStore[Skybox]] = {}

///|
pub impl Has_Skybox for @ecs.World with get_skybox_store(self) {
  bridge_get_skybox_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_camera3d_store_by_world : Map[
  Int,
  @core.ComponentStore[Camera3d],
] = {}

///|
pub impl Has_Camera3d for @ecs.World with get_camera3d_store(self) {
  bridge_get_camera3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_exposure_store_by_world : Map[
  Int,
  @core.ComponentStore[Exposure],
] = {}

///|
pub impl Has_Exposure for @ecs.World with get_exposure_store(self) {
  bridge_get_exposure_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_vignette_store_by_world : Map[
  Int,
  @core.ComponentStore[Vignette],
] = {}

///|
pub impl Has_Vignette for @ecs.World with get_vignette_store(self) {
  bridge_get_vignette_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_spot_light_store_by_world : Map[
  Int,
  @core.ComponentStore[SpotLight],
] = {}

///|
pub impl Has_SpotLight for @ecs.World with get_spot_light_store(self) {
  bridge_get_spot_light_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_wireframe_store_by_world : Map[
  Int,
  @core.ComponentStore[Wireframe],
] = {}

///|
pub impl Has_Wireframe for @ecs.World with get_wireframe_store(self) {
  bridge_get_wireframe_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_free_camera_store_by_world : Map[
  Int,
  @core.ComponentStore[FreeCamera],
] = {}

///|
pub impl Has_FreeCamera for @ecs.World with get_free_camera_store(self) {
  bridge_get_free_camera_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_light_probe_store_by_world : Map[
  Int,
  @core.ComponentStore[LightProbe],
] = {}

///|
pub impl Has_LightProbe for @ecs.World with get_light_probe_store(self) {
  bridge_get_light_probe_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_motion_blur_store_by_world : Map[
  Int,
  @core.ComponentStore[MotionBlur],
] = {}

///|
pub impl Has_MotionBlur for @ecs.World with get_motion_blur_store(self) {
  bridge_get_motion_blur_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_point_light_store_by_world : Map[
  Int,
  @core.ComponentStore[PointLight],
] = {}

///|
pub impl Has_PointLight for @ecs.World with get_point_light_store(self) {
  bridge_get_point_light_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_no_wireframe_store_by_world : Map[
  Int,
  @core.ComponentStore[NoWireframe],
] = {}

///|
pub impl Has_NoWireframe for @ecs.World with get_no_wireframe_store(self) {
  bridge_get_no_wireframe_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_tonemapping_store_by_world : Map[
  Int,
  @core.ComponentStore[Tonemapping],
] = {}

///|
pub impl Has_Tonemapping for @ecs.World with get_tonemapping_store(self) {
  bridge_get_tonemapping_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_color_grading_store_by_world : Map[
  Int,
  @core.ComponentStore[ColorGrading],
] = {}

///|
pub impl Has_ColorGrading for @ecs.World with get_color_grading_store(self) {
  bridge_get_color_grading_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_deband_dither_store_by_world : Map[
  Int,
  @core.ComponentStore[DebandDither],
] = {}

///|
pub impl Has_DebandDither for @ecs.World with get_deband_dither_store(self) {
  bridge_get_deband_dither_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_depth_prepass_store_by_world : Map[
  Int,
  @core.ComponentStore[DepthPrepass],
] = {}

///|
pub impl Has_DepthPrepass for @ecs.World with get_depth_prepass_store(self) {
  bridge_get_depth_prepass_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_forward_decal_store_by_world : Map[
  Int,
  @core.ComponentStore[ForwardDecal],
] = {}

///|
pub impl Has_ForwardDecal for @ecs.World with get_forward_decal_store(self) {
  bridge_get_forward_decal_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_normal_prepass_store_by_world : Map[
  Int,
  @core.ComponentStore[NormalPrepass],
] = {}

///|
pub impl Has_NormalPrepass for @ecs.World with get_normal_prepass_store(self) {
  bridge_get_normal_prepass_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_clustered_decal_store_by_world : Map[
  Int,
  @core.ComponentStore[ClusteredDecal],
] = {}

///|
pub impl Has_ClusteredDecal for @ecs.World with get_clustered_decal_store(self) {
  bridge_get_clustered_decal_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_contact_shadows_store_by_world : Map[
  Int,
  @core.ComponentStore[ContactShadows],
] = {}

///|
pub impl Has_ContactShadows for @ecs.World with get_contact_shadows_store(self) {
  bridge_get_contact_shadows_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_mesh_material3d_store_by_world : Map[
  Int,
  @core.ComponentStore[MeshMaterial3d],
] = {}

///|
pub impl Has_MeshMaterial3d for @ecs.World with get_mesh_material3d_store(self) {
  bridge_get_mesh_material3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_temporal_jitter_store_by_world : Map[
  Int,
  @core.ComponentStore[TemporalJitter],
] = {}

///|
pub impl Has_TemporalJitter for @ecs.World with get_temporal_jitter_store(self) {
  bridge_get_temporal_jitter_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_wireframe_color_store_by_world : Map[
  Int,
  @core.ComponentStore[WireframeColor],
] = {}

///|
pub impl Has_WireframeColor for @ecs.World with get_wireframe_color_store(self) {
  bridge_get_wireframe_color_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_deferred_prepass_store_by_world : Map[
  Int,
  @core.ComponentStore[DeferredPrepass],
] = {}

///|
pub impl Has_DeferredPrepass for @ecs.World with get_deferred_prepass_store(
  self,
) {
  bridge_get_deferred_prepass_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_free_camera_state_store_by_world : Map[
  Int,
  @core.ComponentStore[FreeCameraState],
] = {}

///|
pub impl Has_FreeCameraState for @ecs.World with get_free_camera_state_store(
  self,
) {
  bridge_get_free_camera_state_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_not_shadow_caster_store_by_world : Map[
  Int,
  @core.ComponentStore[NotShadowCaster],
] = {}

///|
pub impl Has_NotShadowCaster for @ecs.World with get_not_shadow_caster_store(
  self,
) {
  bridge_get_not_shadow_caster_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_sub_camera_view3d_store_by_world : Map[
  Int,
  @core.ComponentStore[SubCameraView3d],
] = {}

///|
pub impl Has_SubCameraView3d for @ecs.World with get_sub_camera_view3d_store(
  self,
) {
  bridge_get_sub_camera_view3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_directional_light_store_by_world : Map[
  Int,
  @core.ComponentStore[DirectionalLight],
] = {}

///|
pub impl Has_DirectionalLight for @ecs.World with get_directional_light_store(
  self,
) {
  bridge_get_directional_light_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_irradiance_volume_store_by_world : Map[
  Int,
  @core.ComponentStore[IrradianceVolume],
] = {}

///|
pub impl Has_IrradianceVolume for @ecs.World with get_irradiance_volume_store(
  self,
) {
  bridge_get_irradiance_volume_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_occlusion_culling_store_by_world : Map[
  Int,
  @core.ComponentStore[OcclusionCulling],
] = {}

///|
pub impl Has_OcclusionCulling for @ecs.World with get_occlusion_culling_store(
  self,
) {
  bridge_get_occlusion_culling_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_spot_light_texture_store_by_world : Map[
  Int,
  @core.ComponentStore[SpotLightTexture],
] = {}

///|
pub impl Has_SpotLightTexture for @ecs.World with get_spot_light_texture_store(
  self,
) {
  bridge_get_spot_light_texture_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_not_shadow_receiver_store_by_world : Map[
  Int,
  @core.ComponentStore[NotShadowReceiver],
] = {}

///|
pub impl Has_NotShadowReceiver for @ecs.World with get_not_shadow_receiver_store(
  self,
) {
  bridge_get_not_shadow_receiver_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_point_light_texture_store_by_world : Map[
  Int,
  @core.ComponentStore[PointLightTexture],
] = {}

///|
pub impl Has_PointLightTexture for @ecs.World with get_point_light_texture_store(
  self,
) {
  bridge_get_point_light_texture_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_camera_projection3d_store_by_world : Map[
  Int,
  @core.ComponentStore[CameraProjection3d],
] = {}

///|
pub impl Has_CameraProjection3d for @ecs.World with get_camera_projection3d_store(
  self,
) {
  bridge_get_camera_projection3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_parallax_correction_store_by_world : Map[
  Int,
  @core.ComponentStore[ParallaxCorrection],
] = {}

///|
pub impl Has_ParallaxCorrection for @ecs.World with get_parallax_correction_store(
  self,
) {
  bridge_get_parallax_correction_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_chromatic_aberration_store_by_world : Map[
  Int,
  @core.ComponentStore[ChromaticAberration],
] = {}

///|
pub impl Has_ChromaticAberration for @ecs.World with get_chromatic_aberration_store(
  self,
) {
  bridge_get_chromatic_aberration_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_environment_map_light_store_by_world : Map[
  Int,
  @core.ComponentStore[EnvironmentMapLight],
] = {}

///|
pub impl Has_EnvironmentMapLight for @ecs.World with get_environment_map_light_store(
  self,
) {
  bridge_get_environment_map_light_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_motion_vector_prepass_store_by_world : Map[
  Int,
  @core.ComponentStore[MotionVectorPrepass],
] = {}

///|
pub impl Has_MotionVectorPrepass for @ecs.World with get_motion_vector_prepass_store(
  self,
) {
  bridge_get_motion_vector_prepass_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_temporal_anti_aliasing_store_by_world : Map[
  Int,
  @core.ComponentStore[TemporalAntiAliasing],
] = {}

///|
pub impl Has_TemporalAntiAliasing for @ecs.World with get_temporal_anti_aliasing_store(
  self,
) {
  bridge_get_temporal_anti_aliasing_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_shadow_filtering_method_store_by_world : Map[
  Int,
  @core.ComponentStore[ShadowFilteringMethod],
] = {}

///|
pub impl Has_ShadowFilteringMethod for @ecs.World with get_shadow_filtering_method_store(
  self,
) {
  bridge_get_shadow_filtering_method_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_screen_space_reflections_store_by_world : Map[
  Int,
  @core.ComponentStore[ScreenSpaceReflections],
] = {}

///|
pub impl Has_ScreenSpaceReflections for @ecs.World with get_screen_space_reflections_store(
  self,
) {
  bridge_get_screen_space_reflections_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_directional_light_texture_store_by_world : Map[
  Int,
  @core.ComponentStore[DirectionalLightTexture],
] = {}

///|
pub impl Has_DirectionalLightTexture for @ecs.World with get_directional_light_texture_store(
  self,
) {
  bridge_get_directional_light_texture_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_forward_decal_material_ext_store_by_world : Map[
  Int,
  @core.ComponentStore[ForwardDecalMaterialExt],
] = {}

///|
pub impl Has_ForwardDecalMaterialExt for @ecs.World with get_forward_decal_material_ext_store(
  self,
) {
  bridge_get_forward_decal_material_ext_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_screen_space_transmission_store_by_world : Map[
  Int,
  @core.ComponentStore[ScreenSpaceTransmission],
] = {}

///|
pub impl Has_ScreenSpaceTransmission for @ecs.World with get_screen_space_transmission_store(
  self,
) {
  bridge_get_screen_space_transmission_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_transmitted_shadow_receiver_store_by_world : Map[
  Int,
  @core.ComponentStore[TransmittedShadowReceiver],
] = {}

///|
pub impl Has_TransmittedShadowReceiver for @ecs.World with get_transmitted_shadow_receiver_store(
  self,
) {
  bridge_get_transmitted_shadow_receiver_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_screen_space_ambient_occlusion_store_by_world : Map[
  Int,
  @core.ComponentStore[ScreenSpaceAmbientOcclusion],
] = {}

///|
pub impl Has_ScreenSpaceAmbientOcclusion for @ecs.World with get_screen_space_ambient_occlusion_store(
  self,
) {
  bridge_get_screen_space_ambient_occlusion_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_generated_environment_map_light_store_by_world : Map[
  Int,
  @core.ComponentStore[GeneratedEnvironmentMapLight],
] = {}

///|
pub impl Has_GeneratedEnvironmentMapLight for @ecs.World with get_generated_environment_map_light_store(
  self,
) {
  bridge_get_generated_environment_map_light_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_order_independent_transparency_settings_store_by_world : Map[
  Int,
  @core.ComponentStore[OrderIndependentTransparencySettings],
] = {}

///|
pub impl Has_OrderIndependentTransparencySettings for @ecs.World with get_order_independent_transparency_settings_store(
  self,
) {
  bridge_get_order_independent_transparency_settings_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_wireframe_config_resource_by_world : Map[
  Int,
  @core.Resource[WireframeConfig],
] = {}

///|
pub impl HasRes_WireframeConfig for @ecs.World with get_wireframe_config_resource(
  self,
) {
  bridge_get_wireframe_config_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_global_ambient_light_resource_by_world : Map[
  Int,
  @core.Resource[GlobalAmbientLight],
] = {}

///|
pub impl HasRes_GlobalAmbientLight for @ecs.World with get_global_ambient_light_resource(
  self,
) {
  bridge_get_global_ambient_light_resource_by_world.get_or_init(
    self.world_id(),
    fn() { @core.Resource::new() },
  )
}

///|
let bridge_get_point_light_shadow_map_resource_by_world : Map[
  Int,
  @core.Resource[PointLightShadowMap],
] = {}

///|
pub impl HasRes_PointLightShadowMap for @ecs.World with get_point_light_shadow_map_resource(
  self,
) {
  bridge_get_point_light_shadow_map_resource_by_world.get_or_init(
    self.world_id(),
    fn() { @core.Resource::new() },
  )
}

///|
let bridge_get_directional_light_shadow_map_resource_by_world : Map[
  Int,
  @core.Resource[DirectionalLightShadowMap],
] = {}

///|
pub impl HasRes_DirectionalLightShadowMap for @ecs.World with get_directional_light_shadow_map_resource(
  self,
) {
  bridge_get_directional_light_shadow_map_resource_by_world.get_or_init(
    self.world_id(),
    fn() { @core.Resource::new() },
  )
}

///|
let bridge_get_default_opaque_renderer_method_resource_by_world : Map[
  Int,
  @core.Resource[DefaultOpaqueRendererMethod],
] = {}

///|
pub impl HasRes_DefaultOpaqueRendererMethod for @ecs.World with get_default_opaque_renderer_method_resource(
  self,
) {
  bridge_get_default_opaque_renderer_method_resource_by_world.get_or_init(
    self.world_id(),
    fn() { @core.Resource::new() },
  )
}

///|
/// End ECS bridge impls.
