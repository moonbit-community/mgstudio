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
pub let ecs_key_mesh3d : @ecs.ComponentKey[Mesh3d] = @mesh.ecs_key_mesh3d

///|
pub let ecs_key_lightmap : @ecs.ComponentKey[Lightmap] = @lightmap.ecs_key_lightmap

///|
pub let ecs_key_mesh_material3d : @ecs.ComponentKey[MeshMaterial3d] = @material.ecs_key_mesh_material3d

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @core_pipeline.ecs_key_hdr

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @post_process.ecs_key_fxaa

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @core_pipeline.ecs_key_msaa

///|
pub let ecs_key_bloom : @ecs.ComponentKey[Bloom] = @post_process.ecs_key_bloom

///|
pub let ecs_key_custom_post_process3d : @ecs.ComponentKey[CustomPostProcess3d] = @post_process.ecs_key_custom_post_process3d

///|
pub let ecs_key_skybox : @ecs.ComponentKey[Skybox] = @ecs.register_component(
  debug_name="render3d.skybox",
)

///|
pub let ecs_key_camera3d : @ecs.ComponentKey[Camera3d] = @ecs.register_component(
  debug_name="render3d.camera3d",
)

///|
pub let ecs_key_camera_decal_config3d : @ecs.ComponentKey[CameraDecalConfig3d] = @ecs.register_component(
  debug_name="render3d.camera_decal_config3d",
)

///|
pub let ecs_key_camera_deferred_config3d : @ecs.ComponentKey[
  CameraDeferredConfig3d,
] = @ecs.register_component(debug_name="render3d.camera_deferred_config3d")

///|
pub let ecs_key_distance_fog : @ecs.ComponentKey[DistanceFog] = @ecs.register_component(
  debug_name="render3d.distance_fog",
)

///|
pub let ecs_key_auto_exposure : @ecs.ComponentKey[AutoExposure] = @ecs.register_component(
  debug_name="render3d.auto_exposure",
)

///|
pub let ecs_key_depth_of_field : @ecs.ComponentKey[DepthOfField] = @ecs.register_component(
  debug_name="render3d.depth_of_field",
)

///|
pub let ecs_key_volumetric_fog : @ecs.ComponentKey[VolumetricFog] = @light.ecs_key_volumetric_fog

///|
pub let ecs_key_atmosphere : @ecs.ComponentKey[Atmosphere] = @light.ecs_key_atmosphere

///|
pub let ecs_key_atmosphere_settings : @ecs.ComponentKey[AtmosphereSettings] = @light.ecs_key_atmosphere_settings

///|
pub let ecs_key_exposure : @ecs.ComponentKey[Exposure] = @ecs.register_component(
  debug_name="render3d.exposure",
)

///|
pub let ecs_key_vignette : @ecs.ComponentKey[Vignette] = @post_process.ecs_key_vignette

///|
pub let ecs_key_spot_light : @ecs.ComponentKey[SpotLight] = @light.ecs_key_spot_light

///|
pub let ecs_key_wireframe : @ecs.ComponentKey[Wireframe] = @ecs.register_component(
  debug_name="render3d.wireframe",
)

///|
pub let ecs_key_free_camera : @ecs.ComponentKey[FreeCamera] = @ecs.register_component(
  debug_name="render3d.free_camera",
)

///|
pub let ecs_key_light_probe : @ecs.ComponentKey[LightProbe] = @light.ecs_key_light_probe

///|
pub let ecs_key_motion_blur : @ecs.ComponentKey[MotionBlur] = @post_process.ecs_key_motion_blur

///|
pub let ecs_key_point_light : @ecs.ComponentKey[PointLight] = @light.ecs_key_point_light

///|
pub let ecs_key_no_wireframe : @ecs.ComponentKey[NoWireframe] = @ecs.register_component(
  debug_name="render3d.no_wireframe",
)

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @post_process.ecs_key_tonemapping

///|
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @post_process.ecs_key_color_grading

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @post_process.ecs_key_deband_dither

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @pbr_prepass.ecs_key_depth_prepass

///|
pub let ecs_key_forward_decal : @ecs.ComponentKey[ForwardDecal] = @pbr_decal.ecs_key_forward_decal

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @pbr_prepass.ecs_key_normal_prepass

///|
pub let ecs_key_clustered_decal : @ecs.ComponentKey[ClusteredDecal] = @pbr_decal.ecs_key_clustered_decal

///|
pub let ecs_key_contact_shadows : @ecs.ComponentKey[ContactShadows] = @ecs.register_component(
  debug_name="render3d.contact_shadows",
)

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @post_process.ecs_key_temporal_jitter

///|
pub let ecs_key_wireframe_color : @ecs.ComponentKey[WireframeColor] = @ecs.register_component(
  debug_name="render3d.wireframe_color",
)

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @pbr_prepass.ecs_key_deferred_prepass

///|
pub let ecs_key_free_camera_state : @ecs.ComponentKey[FreeCameraState] = @ecs.register_component(
  debug_name="render3d.free_camera_state",
)

///|
pub let ecs_key_not_shadow_caster : @ecs.ComponentKey[NotShadowCaster] = @ecs.register_component(
  debug_name="render3d.not_shadow_caster",
)

///|
pub let ecs_key_sub_camera_view3d : @ecs.ComponentKey[SubCameraView3d] = @pbr_render.ecs_key_sub_camera_view3d

///|
pub let ecs_key_directional_light : @ecs.ComponentKey[DirectionalLight] = @light.ecs_key_directional_light

///|
pub let ecs_key_sun_disk : @ecs.ComponentKey[SunDisk] = @light.ecs_key_sun_disk

///|
pub let ecs_key_volumetric_light : @ecs.ComponentKey[VolumetricLight] = @light.ecs_key_volumetric_light

///|
pub let ecs_key_fog_volume : @ecs.ComponentKey[FogVolume] = @light.ecs_key_fog_volume

///|
pub let ecs_key_irradiance_volume : @ecs.ComponentKey[IrradianceVolume] = @light.ecs_key_irradiance_volume

///|
pub let ecs_key_occlusion_culling : @ecs.ComponentKey[OcclusionCulling] = @ecs.register_component(
  debug_name="render3d.occlusion_culling",
)

///|
pub let ecs_key_no_indirect_drawing : @ecs.ComponentKey[NoIndirectDrawing] = @ecs.register_component(
  debug_name="render3d.no_indirect_drawing",
)

///|
pub let ecs_key_spot_light_texture : @ecs.ComponentKey[SpotLightTexture] = @light.ecs_key_spot_light_texture

///|
pub let ecs_key_not_shadow_receiver : @ecs.ComponentKey[NotShadowReceiver] = @ecs.register_component(
  debug_name="render3d.not_shadow_receiver",
)

///|
pub let ecs_key_point_light_texture : @ecs.ComponentKey[PointLightTexture] = @light.ecs_key_point_light_texture

///|
pub let ecs_key_projection : @ecs.ComponentKey[Projection] = @ecs.register_component(
  debug_name="render3d.projection",
)

///|
pub let ecs_key_frustum : @ecs.ComponentKey[Frustum] = @pbr_render.ecs_key_frustum

///|
pub let ecs_key_parallax_correction : @ecs.ComponentKey[ParallaxCorrection] = @light.ecs_key_parallax_correction

///|
pub let ecs_key_chromatic_aberration : @ecs.ComponentKey[ChromaticAberration] = @post_process.ecs_key_chromatic_aberration

///|
pub let ecs_key_environment_map_light : @ecs.ComponentKey[EnvironmentMapLight] = @light.ecs_key_environment_map_light

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @pbr_prepass.ecs_key_motion_vector_prepass

///|
pub let ecs_key_previous_view_data : @ecs.ComponentKey[
  @pbr_prepass.PreviousViewData,
] = @pbr_prepass.ecs_key_previous_view_data

///|
pub let ecs_key_previous_global_transform : @ecs.ComponentKey[
  @pbr_prepass.PreviousGlobalTransform,
] = @pbr_prepass.ecs_key_previous_global_transform

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @post_process.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_shadow_filtering_method : @ecs.ComponentKey[
  ShadowFilteringMethod,
] = @ecs.register_component(debug_name="render3d.shadow_filtering_method")

///|
pub let ecs_key_screen_space_reflections : @ecs.ComponentKey[
  ScreenSpaceReflections,
] = @post_process.ecs_key_screen_space_reflections

///|
pub let ecs_key_directional_light_texture : @ecs.ComponentKey[
  DirectionalLightTexture,
] = @light.ecs_key_directional_light_texture

///|
pub let ecs_key_forward_decal_material_ext : @ecs.ComponentKey[
  ForwardDecalMaterialExt,
] = @material.ecs_key_forward_decal_material_ext

///|
pub let ecs_key_screen_space_transmission : @ecs.ComponentKey[
  ScreenSpaceTransmission,
] = @transmission.ecs_key_screen_space_transmission

///|
pub let ecs_key_transmitted_shadow_receiver : @ecs.ComponentKey[
  TransmittedShadowReceiver,
] = @ecs.register_component(debug_name="render3d.transmitted_shadow_receiver")

///|
pub let ecs_key_screen_space_ambient_occlusion : @ecs.ComponentKey[
  ScreenSpaceAmbientOcclusion,
] = @post_process.ecs_key_screen_space_ambient_occlusion

///|
pub let ecs_key_generated_environment_map_light : @ecs.ComponentKey[
  GeneratedEnvironmentMapLight,
] = @light.ecs_key_generated_environment_map_light

///|
pub let ecs_key_atmosphere_environment_map_light : @ecs.ComponentKey[
  AtmosphereEnvironmentMapLight,
] = @light.ecs_key_atmosphere_environment_map_light

///|
pub let ecs_key_order_independent_transparency_settings : @ecs.ComponentKey[
  OrderIndependentTransparencySettings,
] = @ecs.register_component(
  debug_name="render3d.order_independent_transparency_settings",
)

///|
pub impl @ecs.Component for Skybox with component() {
  ecs_key_skybox
}

///|
pub impl @ecs.Component for Camera3d with component() {
  ecs_key_camera3d
}

///|
pub impl @ecs.Component for CameraDecalConfig3d with component() {
  ecs_key_camera_decal_config3d
}

///|
pub impl @ecs.Component for CameraDeferredConfig3d with component() {
  ecs_key_camera_deferred_config3d
}

///|
pub impl @ecs.Component for DistanceFog with component() {
  ecs_key_distance_fog
}

///|
pub impl @ecs.Component for AutoExposure with component() {
  ecs_key_auto_exposure
}

///|
pub impl @ecs.Component for DepthOfField with component() {
  ecs_key_depth_of_field
}

///|
pub impl @ecs.Component for Exposure with component() {
  ecs_key_exposure
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
pub impl @ecs.Component for NoWireframe with component() {
  ecs_key_no_wireframe
}

///|
pub impl @ecs.Component for ContactShadows with component() {
  ecs_key_contact_shadows
}

///|
pub impl @ecs.Component for WireframeColor with component() {
  ecs_key_wireframe_color
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
pub impl @ecs.Component for OcclusionCulling with component() {
  ecs_key_occlusion_culling
}

///|
pub impl @ecs.Component for NoIndirectDrawing with component() {
  ecs_key_no_indirect_drawing
}

///|
pub impl @ecs.Component for NotShadowReceiver with component() {
  ecs_key_not_shadow_receiver
}

///|
pub impl @ecs.Component for Projection with component() {
  ecs_key_projection
}

///|
pub impl @ecs.Component for ShadowFilteringMethod with component() {
  ecs_key_shadow_filtering_method
}

///|
pub impl @ecs.Component for TransmittedShadowReceiver with component() {
  ecs_key_transmitted_shadow_receiver
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
pub let ecs_key_global_ambient_light : @ecs.ResourceKey[GlobalAmbientLight] = @light.ecs_key_global_ambient_light

///|
pub let ecs_key_point_light_shadow_map : @ecs.ResourceKey[PointLightShadowMap] = @light.ecs_key_point_light_shadow_map

///|
pub let ecs_key_directional_light_shadow_map : @ecs.ResourceKey[
  DirectionalLightShadowMap,
] = @light.ecs_key_directional_light_shadow_map

///|
pub let ecs_key_default_opaque_renderer_method : @ecs.ResourceKey[
  DefaultOpaqueRendererMethod,
] = @material.ecs_key_default_opaque_renderer_method

///|
pub let ecs_key_internal_assets : @ecs.ResourceKey[Render3dInternalAssetsState] = @ecs.register_resource(
  debug_name="render3d.internal_assets",
)

///|
pub let ecs_components : Array[String] = [
  "Hdr", "Fxaa", "Msaa", "Bloom", "CustomPostProcess3d", "Mesh3d", "Skybox", "Camera3d",
  "CameraDecalConfig3d", "CameraDeferredConfig3d", "DistanceFog", "AutoExposure",
  "DepthOfField", "VolumetricFog", "Atmosphere", "AtmosphereSettings", "Exposure",
  "Vignette", "SpotLight", "Wireframe", "FreeCamera", "LightProbe", "MotionBlur",
  "PointLight", "NoWireframe", "Tonemapping", "ColorGrading", "DebandDither", "DepthPrepass",
  "ForwardDecal", "NormalPrepass", "ClusteredDecal", "ContactShadows", "MeshMaterial3d",
  "Lightmap", "TemporalJitter", "WireframeColor", "DeferredPrepass", "FreeCameraState",
  "NotShadowCaster", "SubCameraView3d", "DirectionalLight", "IrradianceVolume", "OcclusionCulling",
  "NoIndirectDrawing", "SunDisk", "SpotLightTexture", "NotShadowReceiver", "PointLightTexture",
  "Projection", "Frustum", "ParallaxCorrection", "ChromaticAberration", "EnvironmentMapLight",
  "MotionVectorPrepass", "TemporalAntiAliasing", "ShadowFilteringMethod", "ScreenSpaceReflections",
  "DirectionalLightTexture", "ForwardDecalMaterialExt", "ScreenSpaceTransmission",
  "TransmittedShadowReceiver", "ScreenSpaceAmbientOcclusion", "GeneratedEnvironmentMapLight",
  "OrderIndependentTransparencySettings",
]

///|
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
