// Copyright 2026 International Digital Economy Academy
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

// Core pipeline and camera settings live in `core_pipeline.mbt`.

///|
pub type AlphaMode3d = @material.AlphaMode3d

///|
pub type Face3d = @material.Face3d

///|
pub type ParallaxMappingMethod = @material.ParallaxMappingMethod

///|
pub type OpaqueRendererMethod = @material.OpaqueRendererMethod

///|
pub type DefaultOpaqueRendererMethod = @material.DefaultOpaqueRendererMethod

///|
pub type StandardMaterial = @material.StandardMaterial

///|
pub(open) trait IntoPbrMaterialAsset {
  into_pbr_material_asset(Self) -> StandardMaterial
}

///|
pub fn[S : IntoPbrMaterialAsset] add_material(
  assets : @asset.Assets[StandardMaterial],
  value : S,
) -> @asset.Handle[StandardMaterial] {
  assets.add(value.into_pbr_material_asset())
}

///|
pub impl IntoPbrMaterialAsset for StandardMaterial with into_pbr_material_asset(
  self,
) {
  self
}

///|
pub impl IntoPbrMaterialAsset for @sprite.Color with into_pbr_material_asset(
  self,
) {
  @material.StandardMaterial::from_color(self)
}

///|
pub impl IntoPbrMaterialAsset for @asset.Handle[@asset.Image] with into_pbr_material_asset(
  self,
) {
  @material.StandardMaterial::default().with_base_color_texture(Some(self))
}

///|
pub type ExtendedMaterialMetadata3d = @material.ExtendedMaterialMetadata3d

///|
pub type MeshMaterial3d = @material.MeshMaterial3d

///|
pub type ForwardDecalMaterialExt = @material.ForwardDecalMaterialExt

///|
/// Light-facing ownership lives in `Milky2018/mgstudio/light`.
pub type VolumetricLight = @light.VolumetricLight

///|
pub type VolumetricFog = @light.VolumetricFog

///|
pub type FogVolume = @light.FogVolume

///|
pub type AtmosphereMode = @light.AtmosphereMode

///|
pub type AtmosphereSettings = @light.AtmosphereSettings

///|
pub type ScatteringMedium = @light.ScatteringMedium

///|
pub type Atmosphere = @light.Atmosphere

///|
pub type AtmosphereEnvironmentMapLight = @light.AtmosphereEnvironmentMapLight

///|
pub fn standard_material_add(
  material : StandardMaterial,
) -> @asset.Handle[StandardMaterial] {
  @material.standard_material_add(material)
}

///|
pub fn standard_material_get(
  handle : @asset.Handle[StandardMaterial],
) -> StandardMaterial? {
  @material.standard_material_get(handle)
}

///|
pub fn standard_material_set(
  handle : @asset.Handle[StandardMaterial],
  material : StandardMaterial,
) -> Bool {
  @material.standard_material_set(handle, material)
}

///|
pub fn standard_material_assets_mut_or_abort() -> Ref[
  @asset.Assets[StandardMaterial],
] {
  let assets_ref : Ref[@asset.Assets[StandardMaterial]] = @asset.asset_assets_ref_mut_or_abort()
  assets_ref
}

///|
pub fn mesh_assets_mut_or_abort() -> Ref[@asset.Assets[@mesh.Mesh]] {
  @sprite.mesh_assets_mut_or_abort()
}

///|
struct Render3dInternalAssetsState {
  mut skybox_proxy_mesh : @asset.Handle[@mesh.Mesh]?
  mut tonemapping_luts : Render3dTonemappingLutHandles?
}

///|
fn Render3dInternalAssetsState::new() -> Render3dInternalAssetsState {
  Render3dInternalAssetsState::{
    skybox_proxy_mesh: None,
    tonemapping_luts: None,
  }
}

///|
fn render3d_internal_assets_ref(
  world : @ecs.World,
) -> Ref[Render3dInternalAssetsState]? {
  try! world.get_resource_ref_mut(ecs_key_internal_assets)
}

///|
fn render3d_internal_assets_ref_or_abort(
  world : @ecs.World,
) -> Ref[Render3dInternalAssetsState] {
  match render3d_internal_assets_ref(world) {
    Some(state) => state
    None =>
      abort(
        "render3d internal assets resource is missing; Render3dPlugin must initialize render3d.internal_assets before use",
      )
  }
}

///|
fn render3d_asset_server_from_world_or_abort(
  world : @ecs.World,
) -> @asset.AssetServer {
  match (try! world.get_resource(@asset.asset_server_resource_key())) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "render3d asset server resource is missing; AssetPlugin must initialize AssetServer before render3d internal assets are used",
      )
  }
}

///|
fn render3d_skybox_proxy_mesh_id(world : @ecs.World) -> Int {
  let internal_assets = render3d_internal_assets_ref_or_abort(world)
  let handle = match internal_assets.val.skybox_proxy_mesh {
    Some(handle) => handle
    None => {
      let mesh = Mesh3d::new(
        mesh_assets_mut_or_abort().val.add(
          Mesh::from_3d_geometry(mesh3d_geometry_cuboid(2.0F, 2.0F, 2.0F)),
        ),
      )
      internal_assets.val.skybox_proxy_mesh = Some(mesh.mesh)
      mesh.mesh
    }
  }
  @sprite_render.render2d_upload_mesh_handle(handle)
}

///|
/// Marker component aligned with Bevy's `ForwardDecal`.
///
/// Current runtime note: projected forward-decal shading is not wired in this
/// backend yet. This component preserves scene/API parity for example
/// migration and future renderer integration.
pub struct ForwardDecal {} derive(ToJson, FromJson)

///|
pub fn ForwardDecal::default() -> ForwardDecal {
  ForwardDecal::{  }
}

///|
fn clustered_decal_tag_safe(tag : Int) -> Int {
  if tag < 0 {
    0
  } else {
    tag
  }
}

///|
/// Clustered decal parameters aligned with Bevy's `ClusteredDecal`.
///
/// The decal volume follows Bevy semantics: a transformed unit cube that
/// projects textures along local `-Z`.
///
/// Current runtime note: clustered projection is not yet active in this
/// backend; this component currently carries scene intent metadata.
pub struct ClusteredDecal {
  base_color_texture : @asset.Handle[@asset.Image]?
  normal_map_texture : @asset.Handle[@asset.Image]?
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  emissive_texture : @asset.Handle[@asset.Image]?
  tag : Int
} derive(ToJson, FromJson)

///|
pub fn ClusteredDecal::default() -> ClusteredDecal {
  ClusteredDecal::{
    base_color_texture: None,
    normal_map_texture: None,
    metallic_roughness_texture: None,
    emissive_texture: None,
    tag: 0,
  }
}

///|
pub fn ClusteredDecal::new() -> ClusteredDecal {
  ClusteredDecal::default()
}

///|
pub fn ClusteredDecal::with_base_color_texture(
  self : ClusteredDecal,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, base_color_texture, }
}

///|
pub fn ClusteredDecal::with_normal_map_texture(
  self : ClusteredDecal,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, normal_map_texture, }
}

///|
pub fn ClusteredDecal::with_metallic_roughness_texture(
  self : ClusteredDecal,
  metallic_roughness_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, metallic_roughness_texture, }
}

///|
pub fn ClusteredDecal::with_emissive_texture(
  self : ClusteredDecal,
  emissive_texture : @asset.Handle[@asset.Image]?,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, emissive_texture, }
}

///|
pub fn ClusteredDecal::with_tag(
  self : ClusteredDecal,
  tag : Int,
) -> ClusteredDecal {
  ClusteredDecal::{ ..self, tag: clustered_decal_tag_safe(tag) }
}

///|
/// Light-facing ownership lives in `Milky2018/mgstudio/light`.
pub type PointLight = @light.PointLight

///|
pub type PointLightShadowMap = @light.PointLightShadowMap

///|
pub type DirectionalLightShadowMap = @light.DirectionalLightShadowMap

///|
pub type CascadeShadowConfig = @light.CascadeShadowConfig

///|
pub type CascadeShadowConfigBuilder = @light.CascadeShadowConfigBuilder

///|
pub type DirectionalLight = @light.DirectionalLight

///|
pub type SpotLight = @light.SpotLight

///|
pub type CubemapLayout3d = @light.CubemapLayout3d

///|
pub type DirectionalLightTexture = @light.DirectionalLightTexture

///|
pub type SpotLightTexture = @light.SpotLightTexture

///|
pub type PointLightTexture = @light.PointLightTexture

///|
pub type LightProbe = @light.LightProbe

///|
pub type EnvironmentMapLight = @light.EnvironmentMapLight

///|
pub type GeneratedEnvironmentMapLight = @light.GeneratedEnvironmentMapLight

///|
pub type ParallaxCorrection = @light.ParallaxCorrection

///|
pub type IrradianceVolume = @light.IrradianceVolume

///|
pub type GlobalAmbientLight = @light.GlobalAmbientLight

///|
pub struct Camera3dBundle {
  camera : @sprite.Camera
  projection : Projection
  sub_camera_view : SubCameraView3d?
  screen_space_transmission : ScreenSpaceTransmission?
  screen_space_reflections : ScreenSpaceReflections?
  bloom : Bloom?
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  chromatic_aberration : ChromaticAberration?
  vignette : Vignette?
  motion_blur : MotionBlur?
  exposure : Exposure?
  color_grading : ColorGrading?
  camera3d : Camera3d
  transform : @transform.Transform
  target : @sprite.RenderTarget
  layers : @sprite.RenderLayers
}

///|
pub fn Camera3dBundle::new(
  camera : @sprite.Camera,
  transform : @transform.Transform,
) -> Camera3dBundle {
  Camera3dBundle::{
    camera,
    projection: Projection::default(),
    sub_camera_view: None,
    screen_space_transmission: None,
    screen_space_reflections: None,
    bloom: None,
    tonemapping: Some(Tonemapping::default()),
    deband_dither: Some(Enabled),
    chromatic_aberration: None,
    vignette: None,
    motion_blur: None,
    exposure: Some(Exposure::default()),
    color_grading: None,
    camera3d: Camera3d::default(),
    transform,
    target: @sprite.RenderTarget::Screen,
    layers: @sprite.RenderLayers::default(),
  }
}

///|
pub fn Camera3dBundle::new_with_projection(
  camera : @sprite.Camera,
  projection : Projection,
  transform : @transform.Transform,
) -> Camera3dBundle {
  Camera3dBundle::{
    camera,
    projection,
    sub_camera_view: None,
    screen_space_transmission: None,
    screen_space_reflections: None,
    bloom: None,
    tonemapping: Some(Tonemapping::default()),
    deband_dither: Some(Enabled),
    chromatic_aberration: None,
    vignette: None,
    motion_blur: None,
    exposure: Some(Exposure::default()),
    color_grading: None,
    camera3d: Camera3d::default(),
    transform,
    target: @sprite.RenderTarget::Screen,
    layers: @sprite.RenderLayers::default(),
  }
}

///|
pub fn Camera3dBundle::with_sub_camera_view(
  self : Camera3dBundle,
  sub_camera_view : SubCameraView3d?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, sub_camera_view, }
}

///|
pub fn Camera3dBundle::with_target(
  self : Camera3dBundle,
  target : @sprite.RenderTarget,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, target, }
}

///|
pub fn Camera3dBundle::with_screen_space_transmission(
  self : Camera3dBundle,
  screen_space_transmission : ScreenSpaceTransmission?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, screen_space_transmission, }
}

///|
pub fn Camera3dBundle::with_screen_space_reflections(
  self : Camera3dBundle,
  screen_space_reflections : ScreenSpaceReflections?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, screen_space_reflections, }
}

///|
pub fn Camera3dBundle::with_bloom(
  self : Camera3dBundle,
  bloom : Bloom?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, bloom, }
}

///|
pub fn Camera3dBundle::with_tonemapping(
  self : Camera3dBundle,
  tonemapping : Tonemapping?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, tonemapping, }
}

///|
pub fn Camera3dBundle::with_deband_dither(
  self : Camera3dBundle,
  deband_dither : DebandDither?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, deband_dither, }
}

///|
pub fn Camera3dBundle::with_chromatic_aberration(
  self : Camera3dBundle,
  chromatic_aberration : ChromaticAberration?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, chromatic_aberration, }
}

///|
pub fn Camera3dBundle::with_vignette(
  self : Camera3dBundle,
  vignette : Vignette?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, vignette, }
}

///|
pub fn Camera3dBundle::with_motion_blur(
  self : Camera3dBundle,
  motion_blur : MotionBlur?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, motion_blur, }
}

///|
pub fn Camera3dBundle::with_exposure(
  self : Camera3dBundle,
  exposure : Exposure?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, exposure, }
}

///|
pub fn Camera3dBundle::with_color_grading(
  self : Camera3dBundle,
  color_grading : ColorGrading?,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, color_grading, }
}

///|
pub fn Camera3dBundle::with_camera3d(
  self : Camera3dBundle,
  camera3d : Camera3d,
) -> Camera3dBundle {
  Camera3dBundle::{ ..self, camera3d, }
}

///|
pub fn Camera3dBundle::with_decal_config(
  self : Camera3dBundle,
  decal_config : CameraDecalConfig3d,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_decal_config(decal_config),
  }
}

///|
pub fn Camera3dBundle::with_deferred_config(
  self : Camera3dBundle,
  deferred_config : CameraDeferredConfig3d,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_deferred_config(deferred_config),
  }
}

///|
pub fn Camera3dBundle::with_distance_fog(
  self : Camera3dBundle,
  distance_fog : DistanceFog?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_distance_fog(distance_fog),
  }
}

///|
pub fn Camera3dBundle::with_volumetric_fog(
  self : Camera3dBundle,
  volumetric_fog : VolumetricFog?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_volumetric_fog(volumetric_fog),
  }
}

///|
pub fn Camera3dBundle::with_atmosphere(
  self : Camera3dBundle,
  atmosphere : Atmosphere?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_atmosphere(atmosphere),
  }
}

///|
pub fn Camera3dBundle::with_atmosphere_settings(
  self : Camera3dBundle,
  atmosphere_settings : AtmosphereSettings?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_atmosphere_settings(atmosphere_settings),
  }
}

///|
pub fn Camera3dBundle::with_auto_exposure(
  self : Camera3dBundle,
  auto_exposure : AutoExposure?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_auto_exposure(auto_exposure),
  }
}

///|
pub fn Camera3dBundle::with_depth_of_field(
  self : Camera3dBundle,
  depth_of_field : DepthOfField?,
) -> Camera3dBundle {
  Camera3dBundle::{
    ..self,
    camera3d: self.camera3d.with_depth_of_field(depth_of_field),
  }
}

///|
pub struct MeshMaterial3dBundle {
  mesh : Mesh3d
  material : MeshMaterial3d
  transform : @transform.Transform
  layers : @sprite.RenderLayers
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn MeshMaterial3dBundle::new(
  mesh : Mesh3d,
  material : MeshMaterial3d,
  transform : @transform.Transform,
) -> MeshMaterial3dBundle {
  MeshMaterial3dBundle::{
    mesh,
    material,
    transform,
    layers: @sprite.RenderLayers::default(),
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
fn camera3d_bundle_insert(
  bundle : Camera3dBundle,
  world : @ecs.World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit {
  let ecs_world = world
  get_camera3d_store(ecs_world).insert(entity, bundle.camera3d, loc~)
  get_projection_store(ecs_world).insert(entity, bundle.projection, loc~)
  if bundle.sub_camera_view is Some(sub_camera_view) {
    get_sub_camera_view3d_store(ecs_world).insert(entity, sub_camera_view, loc~)
  }
  if bundle.screen_space_transmission is Some(screen_space_transmission) {
    get_screen_space_transmission_store(ecs_world).insert(
      entity,
      screen_space_transmission,
      loc~,
    )
  }
  if bundle.screen_space_reflections is Some(screen_space_reflections) {
    get_screen_space_reflections_store(ecs_world).insert(
      entity,
      screen_space_reflections,
      loc~,
    )
  }
  if bundle.bloom is Some(bloom) {
    get_bloom_store(ecs_world).insert(entity, bloom, loc~)
  }
  if bundle.tonemapping is Some(tonemapping) {
    get_tonemapping_store(ecs_world).insert(entity, tonemapping, loc~)
  }
  if bundle.deband_dither is Some(deband_dither) {
    get_deband_dither_store(ecs_world).insert(entity, deband_dither, loc~)
  }
  if bundle.chromatic_aberration is Some(chromatic_aberration) {
    get_chromatic_aberration_store(ecs_world).insert(
      entity,
      chromatic_aberration,
      loc~,
    )
  }
  if bundle.vignette is Some(vignette) {
    get_vignette_store(ecs_world).insert(entity, vignette, loc~)
  }
  if bundle.motion_blur is Some(motion_blur) {
    get_motion_blur_store(ecs_world).insert(entity, motion_blur, loc~)
  }
  if bundle.exposure is Some(exposure) {
    get_exposure_store(ecs_world).insert(entity, exposure, loc~)
  }
  if bundle.color_grading is Some(color_grading) {
    get_color_grading_store(ecs_world).insert(entity, color_grading, loc~)
  }
  @sprite.get_camera_store(ecs_world).insert(entity, bundle.camera, loc~)
  @sprite.get_render_target_store(ecs_world).insert(entity, bundle.target, loc~)
  @sprite.get_render_layers_store(ecs_world).insert(entity, bundle.layers, loc~)
  get_frustum_store(ecs_world).insert(
    entity,
    bundle.projection.compute_frustum(bundle.transform),
    loc~,
  )
  @transform.get_transform_store(ecs_world).insert(
    entity,
    bundle.transform,
    loc~,
  )
}

///|
pub impl @app.CommandSpawnComponents for Camera3dBundle with spawn_components(
  self,
  world,
  entity,
  sequence,
  loc~,
) {
  ignore(sequence)
  camera3d_bundle_insert(self, world, entity, loc~)
}

///|
#callsite(autofill(loc))
pub fn Camera3dBundle::spawn(
  self : Camera3dBundle,
  world : @ecs.World,
  loc~ : SourceLoc,
) -> @core.Entity {
  let ecs_world = world
  let entity = ecs_world.spawn_empty()
  camera3d_bundle_insert(self, ecs_world, entity, loc~)
  entity
}

///|
fn mesh_material3d_bundle_insert(
  bundle : MeshMaterial3dBundle,
  world : @ecs.World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit {
  let ecs_world = world
  get_mesh3d_store(ecs_world).insert(entity, bundle.mesh, loc~)
  get_mesh_material3d_store(ecs_world).insert(entity, bundle.material, loc~)
  @sprite.get_render_layers_store(ecs_world).insert(entity, bundle.layers, loc~)
  @visibility.get_visibility_store(ecs_world).insert(
    entity,
    bundle.visibility,
    loc~,
  )
  @visibility.get_inherited_visibility_store(ecs_world).insert(
    entity,
    bundle.inherited_visibility,
    loc~,
  )
  @visibility.get_view_visibility_store(ecs_world).insert(
    entity,
    bundle.view_visibility,
    loc~,
  )
  @transform.get_transform_store(ecs_world).insert(
    entity,
    bundle.transform,
    loc~,
  )
  let mesh_id = @sprite_render.render2d_upload_mesh_handle(bundle.mesh.mesh)
  @sprite.get_gpu_mesh2d_store(ecs_world).insert(
    entity,
    @sprite.GpuMesh2d::new(mesh_id),
    loc~,
  )
}

///|
pub impl @app.CommandSpawnComponents for MeshMaterial3dBundle with spawn_components(
  self,
  world,
  entity,
  sequence,
  loc~,
) {
  ignore(sequence)
  mesh_material3d_bundle_insert(self, world, entity, loc~)
}

///|
#callsite(autofill(loc))
pub fn MeshMaterial3dBundle::spawn(
  self : MeshMaterial3dBundle,
  world : @ecs.World,
  loc~ : SourceLoc,
) -> @core.Entity {
  let ecs_world = world
  let entity = ecs_world.spawn_empty()
  mesh_material3d_bundle_insert(self, ecs_world, entity, loc~)
  entity
}

///|
priv struct ProjectionRuntime3d {
  last_view_width : Float
  last_view_height : Float
}

///|
let ecs_key_projection_runtime3d : @ecs.ComponentKey[ProjectionRuntime3d] = @ecs.register_component(
  debug_name="render3d.projection_runtime3d",
)

///|
priv struct RenderTargetComputed3d {
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
}

///|
priv struct Render3dLightingState {
  ambient_color : @sprite.Color
  ambient_brightness : Float
  directional_dir : @math.Vec3
  directional_color : @sprite.Color
  directional_illuminance : Float
  point_entity : @core.Entity
  point_pos : @math.Vec3
  point_color : @sprite.Color
  point_intensity : Float
  point_range : Float
  point_shadow_maps_enabled : Bool
  point_shadow_depth_bias : Float
  point_shadow_map_near_z : Float
  spot_pos : @math.Vec3
  spot_dir : @math.Vec3
  spot_color : @sprite.Color
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
}

///|
priv struct MotionBlurHistoryEntry {
  entity : @core.Entity
  transform : @transform.Transform
}

///|
priv struct CameraMotionBlurHistoryEntry {
  entity : @core.Entity
  transform : @transform.Transform
  clip_from_world : ProjectionMatrix3d
}

///|
priv struct MotionBlurTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  scene_target_id : Int
  velocity_target_id : Int
}

///|
priv struct TransmissionSourceTargetsEntry {
  entity : @core.Entity
  width : Int
  height : Int
  source_target_id : Int
}

///|
priv struct PointLightShadowTargetsEntry {
  entity : @core.Entity
  size : Int
  target_id : Int
}

///|
priv struct Render3dCameraOrderEntry {
  entity : @core.Entity
  order : Int
}

///|
priv struct GpuPreprocessPrequeuedMeshItem3d {
  entity : PhaseEntityRef3d
  indexed : Bool
  phase : Int
  distance : Float
}

///|
priv struct GpuPreprocessPhaseRange3d {
  phase : Int
  start : Int
  end : Int
}

///|
priv struct GpuPreprocessIndirectParametersCpuMetadata3d {
  base_output_index : Int
  batch_set_index : Int
}

///|
priv struct GpuPreprocessIndirectParametersGpuMetadata3d {
  mesh_index : Int
  early_instance_count : Int
  late_instance_count : Int
}

///|
priv struct GpuPreprocessIndirectBatchSet3d {
  indirect_parameters_count : Int
  indirect_parameters_base : Int
}

///|
priv struct GpuPreprocessIndirectMeshClassMetadata3d {
  indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ]
  indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ]
  indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d]
}

///|
priv struct GpuPreprocessIndirectMetadata3d {
  indexed : GpuPreprocessIndirectMeshClassMetadata3d
  non_indexed : GpuPreprocessIndirectMeshClassMetadata3d
}

///|
priv struct GpuPreprocessShaderWorkItem3d {
  input_index : Int
  output_or_indirect_parameters_index : Int
}

///|
priv struct GpuOcclusionCullingWorkItemBuffers3d {
  late_indexed : Array[GpuPreprocessShaderWorkItem3d]
  late_non_indexed : Array[GpuPreprocessShaderWorkItem3d]
  late_indirect_parameters_indexed_offset : Int
  late_indirect_parameters_non_indexed_offset : Int
}

///|
priv enum GpuPreprocessWorkItemBuffers3d {
  Direct(Array[GpuPreprocessShaderWorkItem3d])
  Indirect(
    Array[GpuPreprocessShaderWorkItem3d],
    Array[GpuPreprocessShaderWorkItem3d],
    GpuOcclusionCullingWorkItemBuffers3d?
  )
}

///|
const RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE : Int = 64

///|
priv struct GpuPreprocessDispatchMetadata3d {
  direct_workgroup_count : Int
  indexed_workgroup_count : Int
  non_indexed_workgroup_count : Int
  late_indexed_workgroup_count : Int
  late_non_indexed_workgroup_count : Int
}

///|
priv struct GpuPreprocessCameraQueueEntry3d {
  camera_entity : @core.Entity
  items : Array[GpuPreprocessPrequeuedMeshItem3d]
  phase_ranges : Array[GpuPreprocessPhaseRange3d]
  indirect_metadata : GpuPreprocessIndirectMetadata3d
  dispatch_metadata : GpuPreprocessDispatchMetadata3d
  work_item_buffers : GpuPreprocessWorkItemBuffers3d
}

///|
priv struct GpuPreprocessResolvedCameraQueueEntry3d {
  draw_items : Array[MeshPhaseItem3d]
  phase_ranges : Array[GpuPreprocessPhaseRange3d]
  indirect_metadata : GpuPreprocessIndirectMetadata3d
  dispatch_metadata : GpuPreprocessDispatchMetadata3d
  work_item_buffers : GpuPreprocessWorkItemBuffers3d
}

///|
let motion_blur_history : Ref[Array[MotionBlurHistoryEntry]] = Ref::new([])

///|
let camera_motion_blur_history : Ref[Array[CameraMotionBlurHistoryEntry]] = Ref::new([],
)

///|
let motion_blur_targets : Ref[Array[MotionBlurTargetsEntry]] = Ref::new([])

///|
let transmission_source_targets : Ref[Array[TransmissionSourceTargetsEntry]] = Ref::new([],
)

///|
let point_light_shadow_targets : Ref[Array[PointLightShadowTargetsEntry]] = Ref::new([],
)

///|
let render3d_runtime_initialized_ref : Ref[Bool] = Ref::new(false)

///|
let render3d_prepared_camera_order_ref : Ref[Array[@core.Entity]] = Ref::new([])

///|
let render3d_queued_visible_mesh_count_ref : Ref[Int] = Ref::new(0)

///|
let render3d_diagnostic_queued_visible_mesh_count_ref : Ref[Int] = Ref::new(0)

///|
let render3d_diagnostic_prepared_camera_count_ref : Ref[Int] = Ref::new(0)

///|
let render3d_gpu_preprocess_camera_queues_ref : Ref[
  Array[GpuPreprocessCameraQueueEntry3d],
] = Ref::new([])

///|
priv struct WireframeMeshCacheEntry {
  source_mesh_handle_id : Int
  wireframe_mesh_id : Int
}

///|
let wireframe_mesh_cache : Ref[Array[WireframeMeshCacheEntry]] = Ref::new([])

///|
fn cmp_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn cmp_float(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn render3d_target_info(
  world : @ecs.World,
  target : @sprite.RenderTarget,
) -> RenderTargetComputed3d? {
  match target {
    @sprite.RenderTarget::Screen => {
      let width = @window.window_physical_width_for(
        world,
        @window.WindowRef::Primary,
      )
      let height = @window.window_physical_height_for(
        world,
        @window.WindowRef::Primary,
      )
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(
        world,
        @window.WindowRef::Primary,
      )
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: -1,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @sprite.RenderTarget::Window(window_ref) => {
      guard @window.window_host_window_for_ref(world, window_ref)
        is Some(host_window) else {
        return None
      }
      let surface_target_id = @render.host_gpu_surface_target_id_for_window(
        host_window,
      )
      if surface_target_id >= 0 {
        return None
      }
      let width = @window.window_physical_width_for(world, window_ref)
      let height = @window.window_physical_height_for(world, window_ref)
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(world, window_ref)
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: surface_target_id,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @sprite.RenderTarget::Image(handle) => {
      let width = @asset.asset_texture_width(handle)
      let height = @asset.asset_texture_height(handle)
      if width <= 0 || height <= 0 {
        return None
      }
      Some(RenderTargetComputed3d::{
        target_id: handle.id(),
        target_size: @math.IVec2::new(width, height),
        scale_factor: 1.0F,
      })
    }
  }
}

///|
fn render3d_clamp_viewport(
  viewport : @sprite.Viewport,
  target_size : @math.IVec2,
) -> @sprite.Viewport {
  let mut position_x = viewport.physical_position.x
  let mut position_y = viewport.physical_position.y
  let mut size_x = viewport.physical_size.x
  let mut size_y = viewport.physical_size.y
  if position_x < 0 {
    position_x = 0
  }
  if position_y < 0 {
    position_y = 0
  }
  if size_x < 0 {
    size_x = 0
  }
  if size_y < 0 {
    size_y = 0
  }
  let max_width = if target_size.x - position_x < 0 {
    0
  } else {
    target_size.x - position_x
  }
  let max_height = if target_size.y - position_y < 0 {
    0
  } else {
    target_size.y - position_y
  }
  if size_x > max_width {
    size_x = max_width
  }
  if size_y > max_height {
    size_y = max_height
  }
  @sprite.Viewport::new(
    @math.IVec2::new(position_x, position_y),
    @math.IVec2::new(size_x, size_y),
  ).with_depth(viewport.depth_min, viewport.depth_max)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn render3d_transform_forward(transform : @transform.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn render3d_default_lighting_state() -> Render3dLightingState {
  Render3dLightingState::{
    ambient_color: @sprite.Color::white(),
    ambient_brightness: 80.0F,
    directional_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    directional_color: @sprite.Color::white(),
    directional_illuminance: 0.0F,
    point_entity: @core.Entity::placeholder(),
    point_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    point_color: @sprite.Color::white(),
    point_intensity: 0.0F,
    point_range: 1.0F,
    point_shadow_maps_enabled: false,
    point_shadow_depth_bias: 0.08F,
    point_shadow_map_near_z: 0.1F,
    spot_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    spot_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    spot_color: @sprite.Color::white(),
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
  }
}

///|
fn motion_blur_history_get(entity : @core.Entity) -> @transform.Transform? {
  for item in motion_blur_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item.transform)
    }
  }
  None
}

///|
fn motion_blur_history_sync(meshes : Array[ExtractedMesh3d]) -> Unit {
  let next : Array[MotionBlurHistoryEntry] = []
  for mesh in meshes {
    next.push({
      entity: mesh.entity.main_entity,
      transform: mesh.payload.transform,
    })
  }
  motion_blur_history.val = next
}

///|
fn camera_motion_blur_history_get(
  entity : @core.Entity,
) -> CameraMotionBlurHistoryEntry? {
  for item in camera_motion_blur_history.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item)
    }
  }
  None
}

///|
fn camera_motion_blur_history_sync(
  history : Array[CameraMotionBlurHistoryEntry],
) -> Unit {
  camera_motion_blur_history.val = history
}

///|
fn render3d_float_clamp(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn render3d_fxaa_enabled(fxaa : Fxaa?) -> Bool {
  match fxaa {
    Some(value) => value.enabled
    None => false
  }
}

///|
fn render3d_tonemapping_stage_enabled(
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  hdr_enabled : Bool,
  color_grading : ColorGrading?,
) -> Bool {
  deband_dither |> ignore
  let color_grading_enabled = color_grading is Some(_)
  if color_grading_enabled {
    return true
  }
  if !hdr_enabled {
    return false
  }
  match tonemapping {
    Some(None) => false
    Some(_) => true
    None => Tonemapping::default() != None
  }
}

///|
fn render3d_effect_stack_enabled(
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
) -> Bool {
  render3d_chromatic_aberration_enabled(chromatic_aberration) ||
  render3d_vignette_enabled(vignette)
}

///|
fn render3d_chromatic_aberration_enabled(
  chromatic_aberration : ChromaticAberration?,
) -> Bool {
  match chromatic_aberration {
    Some(value) => value.intensity > 0.0F && value.max_samples > 0
    None => false
  }
}

///|
fn render3d_vignette_enabled(vignette : Vignette?) -> Bool {
  match vignette {
    Some(value) => value.intensity > 0.0F
    None => false
  }
}

///|
const RENDER3D_PASS_KIND_BASE_SCENE : Int = 0

///|
const RENDER3D_PASS_KIND_BASE_MOTION_VECTOR : Int = 1

///|
const RENDER3D_PASS_KIND_BASE_POINT_SHADOW : Int = 2

///|
const RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
const RENDER3D_PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
const RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
const RENDER3D_MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
const STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT : UInt = 1U << 0

///|
const STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT : UInt = 1U << 1

///|
const STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT : UInt = 1U << 2

///|
const STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT : UInt = 1U << 3

///|
const STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT : UInt = 1U << 4

///|
const STANDARD_MATERIAL_FLAGS_UNLIT_BIT : UInt = 1U << 5

///|
const STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y : UInt = 1U << 7

///|
const STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT : UInt = 1U << 9

///|
const STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT : UInt = 1U << 17

///|
const STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT : UInt = 1U << 19

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE : UInt = 0U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK : UInt = 1U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND : UInt = 2U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED : UInt = 3U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD : UInt = 4U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY : UInt = 5U << 29

///|
const STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE : UInt = 6U << 29

///|
fn render3d_pass_kind_encode(
  base_kind : Int,
  postprocess_enabled : Bool,
  fog_enabled : Bool,
  decal_enabled : Bool,
) -> Int {
  let mut value = base_kind
  if !postprocess_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_POSTPROCESS_FLAG
  }
  if !fog_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_FOG_FLAG
  }
  if !decal_enabled {
    value = value | RENDER3D_PASS_KIND_DISABLE_DECAL_FLAG
  }
  value
}

///|
fn render3d_mesh_draw_flags(mesh : ExtractedMesh3d) -> Int {
  let mut flags = 0
  if mesh.payload.is_forward_decal || mesh.payload.clustered_decal is Some(_) {
    flags = flags | RENDER3D_MESH3D_DRAW_FLAG_DECAL
  }
  flags
}

///|
fn render3d_standard_material_alpha_mode_flags(
  alpha_mode : AlphaMode3d,
) -> UInt {
  match alpha_mode {
    Opaque => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE
    Mask(_) => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK
    Blend => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_BLEND
    Premultiplied => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_PREMULTIPLIED
    Add => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ADD
    Multiply => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MULTIPLY
    AlphaToCoverage => STANDARD_MATERIAL_FLAGS_ALPHA_MODE_ALPHA_TO_COVERAGE
  }
}

///|
fn render3d_standard_material_alpha_cutoff(alpha_mode : AlphaMode3d) -> Float {
  match alpha_mode {
    Mask(cutoff) => cutoff
    _ => 0.5F
  }
}

///|
fn render3d_standard_material_flags(
  material : StandardMaterial,
  base_color_texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
) -> UInt {
  let mut flags = render3d_standard_material_alpha_mode_flags(
    material.alpha_mode,
  )
  if base_color_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT
  }
  if emissive_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT
  }
  if metallic_roughness_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT
  }
  if occlusion_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT
  }
  if material.cull_mode is None {
    flags = flags | STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT
  }
  if material.unlit {
    flags = flags | STANDARD_MATERIAL_FLAGS_UNLIT_BIT
  }
  if normal_texture_id >= 0 && material.flip_normal_map_y {
    flags = flags | STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y
  }
  if depth_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT
  }
  if anisotropy_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT
  }
  if specular_tint_texture_id >= 0 {
    flags = flags | STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT
  }
  flags
}

///|
fn render3d_distance_fog_enabled(fog : DistanceFog) -> Bool {
  if fog.color.a <= 0.0F {
    return false
  }
  match fog.falloff {
    FogFalloff3d::Linear(start, end_) => end_ > start
    FogFalloff3d::Exponential(density) => density > 0.0F
    FogFalloff3d::ExponentialSquared(density) => density > 0.0F
    FogFalloff3d::Atmospheric(extinction, inscattering) =>
      extinction.x +
      extinction.y +
      extinction.z +
      inscattering.x +
      inscattering.y +
      inscattering.z >
      0.0001F
  }
}

///|
fn render3d_decal_mode_allows_forward(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => true
    ClusteredOnly => false
    ForwardAndClustered => true
  }
}

///|
fn render3d_decal_mode_allows_clustered(mode : DecalRenderMode3d) -> Bool {
  match mode {
    Disabled => false
    ForwardOnly => false
    ClusteredOnly => true
    ForwardAndClustered => true
  }
}

///|
fn render3d_camera_deferred_mode(
  config : CameraDeferredConfig3d,
  default_method : OpaqueRendererMethod,
  deferred_lighting_enabled : Bool,
) -> OpaqueRendererMethod {
  if !deferred_lighting_enabled {
    return OpaqueRendererMethod::Forward
  }
  match config.mode {
    CameraDeferredMode3d::Forward => OpaqueRendererMethod::Forward
    CameraDeferredMode3d::Deferred => OpaqueRendererMethod::Deferred
    CameraDeferredMode3d::Auto =>
      match default_method {
        OpaqueRendererMethod::Forward => OpaqueRendererMethod::Forward
        OpaqueRendererMethod::Deferred => OpaqueRendererMethod::Deferred
        OpaqueRendererMethod::Auto => OpaqueRendererMethod::Forward
      }
  }
}

///|
fn render3d_apply_extended_material_metadata(
  material : StandardMaterial,
  extension : ExtendedMaterialMetadata3d?,
) -> StandardMaterial {
  guard extension is Some(extension_value) else { return material }
  let mut out = material
  if extension_value.alpha_mode_override is Some(alpha_mode_override) {
    out = out.with_alpha_mode(alpha_mode_override)
  }
  if extension_value.opaque_render_method_override
    is Some(opaque_render_method_override) {
    out = out.with_opaque_render_method(opaque_render_method_override)
  }
  out
}

///|
fn render3d_default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in render3d systems")
  }
}

///|
fn render3d_runtime_config_or_default(
  world : @ecs.World,
) -> PbrPluginRuntimeConfig {
  match (try! world.get_resource(ecs_key_pbr_plugin_runtime_config)) {
    Some(config) => config
    None => pbr_plugin_runtime_config()
  }
}

///|
fn render3d_indirect_first_instance_supported() -> Bool {
  @render.host_gpu_mesh3d_indirect_first_instance_supported()
}

///|
fn render3d_camera_indirect_enabled(
  use_gpu_instance_buffer_builder : Bool,
  indirect_first_instance_supported : Bool,
  no_indirect_drawing : Bool,
) -> Bool {
  use_gpu_instance_buffer_builder &&
  indirect_first_instance_supported &&
  !no_indirect_drawing
}

///|
fn render3d_color_lerp(
  from_ : @sprite.Color,
  to_ : @sprite.Color,
  t : Float,
) -> @sprite.Color {
  @sprite.Color::new(
    from_.r + (to_.r - from_.r) * t,
    from_.g + (to_.g - from_.g) * t,
    from_.b + (to_.b - from_.b) * t,
    from_.a + (to_.a - from_.a) * t,
  )
}

///|
fn render3d_camera_distance_fog(
  base_fog : DistanceFog,
  volumetric_fog : VolumetricFog?,
  atmosphere : Atmosphere?,
  atmosphere_settings : AtmosphereSettings?,
) -> DistanceFog {
  let mut fog = base_fog
  if volumetric_fog is Some(volumetric_fog_value) {
    let ambient_mix = render3d_float_clamp(
      volumetric_fog_value.ambient_intensity,
      0.0F,
      1.0F,
    )
    fog = DistanceFog::{
      ..fog,
      color: render3d_color_lerp(
        fog.color,
        volumetric_fog_value.ambient_color,
        ambient_mix,
      ),
      directional_light_color: render3d_color_lerp(
        fog.directional_light_color,
        volumetric_fog_value.ambient_color,
        ambient_mix * 0.6F,
      ),
      directional_light_exponent: fog.directional_light_exponent +
      Float::from_double(volumetric_fog_value.step_count.to_double()) /
      64.0F *
      0.5F,
    }
  }
  if atmosphere is Some(atmosphere_value) {
    let albedo_color = @sprite.Color::new(
      render3d_float_clamp(atmosphere_value.ground_albedo.x, 0.0F, 1.0F),
      render3d_float_clamp(atmosphere_value.ground_albedo.y, 0.0F, 1.0F),
      render3d_float_clamp(atmosphere_value.ground_albedo.z, 0.0F, 1.0F),
      1.0F,
    )
    fog = DistanceFog::{
      ..fog,
      color: render3d_color_lerp(fog.color, albedo_color, 0.15F),
    }
  }
  if atmosphere_settings is Some(atmosphere_settings_value) {
    let unit_scale = if atmosphere_settings_value.scene_units_to_m <= 0.0F {
      0.0001F
    } else {
      atmosphere_settings_value.scene_units_to_m
    }
    let falloff = match fog.falloff {
      FogFalloff3d::Linear(start, end_) =>
        FogFalloff3d::linear(start * unit_scale, end_ * unit_scale)
      FogFalloff3d::Exponential(density) =>
        FogFalloff3d::exponential(density / unit_scale)
      FogFalloff3d::ExponentialSquared(density) =>
        FogFalloff3d::exponential_squared(density / @math.sqrt(unit_scale))
      FogFalloff3d::Atmospheric(extinction, inscattering) =>
        FogFalloff3d::atmospheric(
          extinction.mul_scalar(1.0F / unit_scale),
          inscattering.mul_scalar(1.0F / unit_scale),
        )
    }
    fog = DistanceFog::{ ..fog, falloff, }
    if atmosphere_settings_value.rendering_method is AtmosphereMode::Raymarched {
      fog = DistanceFog::{
        ..fog,
        directional_light_exponent: fog.directional_light_exponent + 1.0F,
      }
    }
  }
  fog
}

///|
fn render3d_motion_blur_targets_get_or_create(
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> (Int, Int) {
  for item in motion_blur_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return (item.scene_target_id, item.velocity_target_id)
    }
  }
  let scene_target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
  )
  let velocity_target_id = @render.host_gpu_create_render_target_rg16f(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[MotionBlurTargetsEntry] = []
  let mut replaced = false
  for item in motion_blur_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, scene_target_id, velocity_target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, scene_target_id, velocity_target_id })
  }
  motion_blur_targets.val = next
  (scene_target_id, velocity_target_id)
}

///|
fn render3d_transmission_source_target_get_or_create(
  entity : @core.Entity,
  width : Int,
  height : Int,
) -> Int {
  for item in transmission_source_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.width == width &&
      item.height == height {
      return item.source_target_id
    }
  }
  let source_target_id = @render.host_gpu_create_render_target_rgba16f(
    width~,
    height~,
    nearest=false,
  )
  let next : Array[TransmissionSourceTargetsEntry] = []
  let mut replaced = false
  for item in transmission_source_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, width, height, source_target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, width, height, source_target_id })
  }
  transmission_source_targets.val = next
  source_target_id
}

///|
fn render3d_point_light_shadow_target_get_or_create(
  entity : @core.Entity,
  size : Int,
) -> Int {
  let safe_size = if size <= 0 { 1 } else { size }
  for item in point_light_shadow_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation &&
      item.size == safe_size {
      return item.target_id
    }
  }
  let target_id = @render.host_gpu_create_point_light_shadow_target(
    size=safe_size,
  )
  let next : Array[PointLightShadowTargetsEntry] = []
  let mut replaced = false
  for item in point_light_shadow_targets.val {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      if !replaced {
        next.push({ entity, size: safe_size, target_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ entity, size: safe_size, target_id })
  }
  point_light_shadow_targets.val = next
  target_id
}

///|
fn render3d_point_shadow_face_transform(
  light_position : @math.Vec3,
  face_index : Int,
) -> @transform.Transform {
  let (forward, up) = match face_index {
    // Match Bevy's `CUBE_MAP_FACES` exactly:
    // [+X, -X, +Y, -Y, +Z, -Z] face order with left-handed cubemap conventions.
    0 => (@math.Vec3::new(1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    1 => (@math.Vec3::new(-1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    2 => (@math.Vec3::new(0.0F, 1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, 1.0F))
    3 =>
      (@math.Vec3::new(0.0F, -1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, -1.0F))
    4 => (@math.Vec3::new(0.0F, 0.0F, -1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    _ => (@math.Vec3::new(0.0F, 0.0F, 1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  @transform.Transform::from_xyz(
    light_position.x,
    light_position.y,
    light_position.z,
  ).looking_at(light_position.add(forward), up)
}

///|
fn render3d_blit_texture_to_target(
  source_texture_id : Int,
  target_id : Int,
  width_logical : Int,
  height_logical : Int,
) -> Unit {
  if source_texture_id < 0 ||
    target_id < 0 ||
    width_logical <= 0 ||
    height_logical <= 0 {
    return
  }
  let sx = Float::from_double(width_logical.to_double()) / 128.0F
  let sy = Float::from_double(height_logical.to_double()) / 128.0F
  @render.host_gpu_begin_pass(
    target_id~,
    width=width_logical,
    height=height_logical,
    clear_r=0.0F,
    clear_g=0.0F,
    clear_b=0.0F,
    clear_a=0.0F,
    camera_x=0.0F,
    camera_y=0.0F,
    camera_rotation=0.0F,
    camera_scale=1.0F,
    viewport_x=0,
    viewport_y=0,
    viewport_width=width_logical,
    viewport_height=height_logical,
    viewport_depth_min=0.0F,
    viewport_depth_max=1.0F,
    clear_enabled=1,
  )
  @render.host_gpu_draw_sprite_uv(
    texture_id=source_texture_id,
    x=0.0F,
    y=0.0F,
    rotation=0.0F,
    scale_x=sx,
    scale_y=sy,
    color_r=1.0F,
    color_g=1.0F,
    color_b=1.0F,
    color_a=1.0F,
    uv_min_x=0.0F,
    uv_min_y=0.0F,
    uv_max_x=1.0F,
    uv_max_y=1.0F,
  )
  @render.host_gpu_end_pass()
}

///|
fn render3d_wireframe_mesh_cache_get(source_mesh_handle_id : Int) -> Int? {
  for item in wireframe_mesh_cache.val {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      return Some(item.wireframe_mesh_id)
    }
  }
  None
}

///|
fn render3d_wireframe_mesh_cache_set(
  source_mesh_handle_id : Int,
  wireframe_mesh_id : Int,
) -> Unit {
  let next : Array[WireframeMeshCacheEntry] = []
  let mut replaced = false
  for item in wireframe_mesh_cache.val {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      if !replaced {
        next.push({ source_mesh_handle_id, wireframe_mesh_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ source_mesh_handle_id, wireframe_mesh_id })
  }
  wireframe_mesh_cache.val = next
}

///|
fn render3d_wireframe_mesh_id(mesh_handle : @asset.Handle[@mesh.Mesh]) -> Int? {
  let source_mesh_handle_id = mesh_handle.id()
  if render3d_wireframe_mesh_cache_get(source_mesh_handle_id) is Some(mesh_id) {
    return Some(mesh_id)
  }
  let source_mesh = match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) => mesh_asset
    None => return None
  }
  match source_mesh.geometry {
    @mesh.MeshGeometry::Geometry3d(geometry3d) =>
      match geometry3d.primitive_topology() {
        @mesh.Mesh3dPrimitiveTopology::TriangleList =>
          match geometry3d.to_wireframe_line_list() {
            Some(wireframe_geometry) => {
              let wireframe_handle = @sprite.render_mesh_asset_add(
                @mesh.Mesh::from_3d_geometry(wireframe_geometry),
              )
              let wireframe_mesh_id = @sprite_render.render2d_upload_mesh_handle(
                wireframe_handle,
              )
              render3d_wireframe_mesh_cache_set(
                source_mesh_handle_id, wireframe_mesh_id,
              )
              Some(wireframe_mesh_id)
            }
            None => return None
          }
        @mesh.Mesh3dPrimitiveTopology::LineList => {
          let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(source_mesh_handle_id, mesh_id)
          Some(mesh_id)
        }
        @mesh.Mesh3dPrimitiveTopology::LineStrip => {
          let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh_handle)
          render3d_wireframe_mesh_cache_set(source_mesh_handle_id, mesh_id)
          Some(mesh_id)
        }
      }
    _ => return None
  }
}

///|
fn render3d_mesh_should_draw_wireframe(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> Bool {
  guard wireframe_config is Some(config) else { return false }
  if mesh.payload.has_no_wireframe {
    false
  } else if mesh.payload.has_wireframe {
    true
  } else {
    config.global
  }
}

///|
fn render3d_mesh_wireframe_color(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> @sprite.Color {
  if mesh.payload.wireframe_color is Some(color_component) {
    color_component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    @sprite.Color::white()
  }
}

///|
fn render3d_collect_lighting(world : @ecs.World) -> Render3dLightingState {
  let mut lighting = render3d_default_lighting_state()
  let point_luminous_power_to_intensity = 4.0F * @math.pi()
  if (try! world.get_resource(ecs_key_global_ambient_light)) is Some(ambient) {
    lighting = Render3dLightingState::{
      ..lighting,
      ambient_color: ambient.color,
      ambient_brightness: ambient.brightness,
    }
  }
  let transform_store = world.component(@transform.ecs_key_transform)
  let directional_light_store = world.component(ecs_key_directional_light)
  let mut directional_found = false
  directional_light_store.for_each(fn(entity, light) {
    if directional_found {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    directional_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      directional_dir: render3d_transform_forward(transform),
      directional_color: light.color,
      directional_illuminance: light.illuminance,
    }
  })
  let point_light_store = world.component(ecs_key_point_light)
  let mut point_found = false
  point_light_store.for_each(fn(entity, light) {
    if point_found {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    point_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      point_entity: entity,
      point_pos: transform.translation,
      point_color: light.color,
      point_intensity: if point_luminous_power_to_intensity <= 0.0F {
        light.intensity
      } else {
        light.intensity / point_luminous_power_to_intensity
      },
      point_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      point_shadow_maps_enabled: light.shadow_maps_enabled,
      point_shadow_depth_bias: light.shadow_depth_bias,
      point_shadow_map_near_z: if light.shadow_map_near_z > 0.0001F {
        light.shadow_map_near_z
      } else {
        0.0001F
      },
    }
  })
  let spot_light_store = world.component(ecs_key_spot_light)
  let mut spot_found = false
  spot_light_store.for_each(fn(entity, light) {
    if spot_found {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    let inner = light.inner_angle
    let mut outer = light.outer_angle
    if outer < inner {
      outer = inner
    }
    spot_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      spot_pos: transform.translation,
      spot_dir: render3d_transform_forward(transform),
      spot_color: light.color,
      spot_intensity: if point_luminous_power_to_intensity <= 0.0F {
        light.intensity
      } else {
        light.intensity / point_luminous_power_to_intensity
      },
      spot_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      spot_inner_angle: inner,
      spot_outer_angle: outer,
    }
  })
  lighting
}

///|
fn render3d_draw_camera_skybox(
  world : @ecs.World,
  camera : ExtractedCamera3d,
  camera_far : Float,
) -> Unit {
  guard camera.payload.skybox is Some(skybox) else { return }
  guard skybox.image is Some(image) else { return }
  let mesh_id = render3d_skybox_proxy_mesh_id(world)
  if mesh_id <= 0 {
    return
  }
  let brightness = maxf(0.0F, skybox.brightness)
  let skybox_extent = maxf(5.0F, minf(camera_far * 0.45F, 20_000.0F))
  // Negative d marks stacked-vertical cubemap sampling in mesh3d.wgsl.
  @render.host_gpu_draw_mesh3d(
    mesh_id~,
    x=camera.payload.transform.translation.x,
    y=camera.payload.transform.translation.y,
    z=camera.payload.transform.translation.z,
    rotation_x=skybox.rotation.x,
    rotation_y=skybox.rotation.y,
    rotation_z=skybox.rotation.z,
    rotation_w=skybox.rotation.w,
    scale_x=skybox_extent,
    scale_y=skybox_extent,
    scale_z=skybox_extent,
    previous_x=camera.payload.previous_transform.translation.x,
    previous_y=camera.payload.previous_transform.translation.y,
    previous_z=camera.payload.previous_transform.translation.z,
    previous_rotation_x=camera.payload.previous_transform.rotation.x,
    previous_rotation_y=camera.payload.previous_transform.rotation.y,
    previous_rotation_z=camera.payload.previous_transform.rotation.z,
    previous_rotation_w=camera.payload.previous_transform.rotation.w,
    previous_scale_x=camera.payload.previous_transform.scale.x,
    previous_scale_y=camera.payload.previous_transform.scale.y,
    previous_scale_z=camera.payload.previous_transform.scale.z,
    color_r=brightness,
    color_g=brightness,
    color_b=brightness,
    color_a=1.0F,
    texture_id=image.id(),
    uv_transform_a=1.0F,
    uv_transform_b=0.0F,
    uv_transform_c=0.0F,
    uv_transform_d=-1.0F,
    uv_transform_tx=0.0F,
    uv_transform_ty=0.0F,
    uv_transform_mode=-1.0F,
    normal_texture_id=-1,
    emissive_texture_id=-1,
    metallic_roughness_texture_id=-1,
    occlusion_texture_id=-1,
    depth_texture_id=-1,
    emissive_r=0.0F,
    emissive_g=0.0F,
    emissive_b=0.0F,
    metallic=0.0F,
    roughness=1.0F,
    reflectance=0.0F,
    parallax_depth_scale=0.0F,
    max_parallax_layer_count=0.0F,
    max_relief_mapping_search_steps=0.0F,
    anisotropy_texture_id=-1,
    anisotropy_strength=0.0F,
    anisotropy_rotation=0.0F,
    specular_tint_texture_id=-1,
    specular_tint_r=1.0F,
    specular_tint_g=1.0F,
    specular_tint_b=1.0F,
    diffuse_transmission=0.0F,
    specular_transmission=0.0F,
    thickness=0.0F,
    ior=1.5F,
    alpha_cutoff=0.5F,
    material_flags=STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT |
      STANDARD_MATERIAL_FLAGS_UNLIT_BIT |
      STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE,
    transmission_source_texture_id=-1,
    transmission_blur_taps=0.0F,
    transmission_steps=0.0F,
    point_shadow_texture_id=-1,
    point_shadow_enabled=0.0F,
    point_shadow_depth_bias=0.0F,
    cull_mode=1,
  )
}

///|
fn render3d_queue_camera_phase_items(
  cameras : Array[ExtractedCamera3d],
) -> Array[CameraPhaseItem3d] {
  let items : Array[CameraPhaseItem3d] = []
  for i in 0..<cameras.length() {
    let camera = cameras[i]
    items.push(CameraPhaseItem3d::{
      entity: camera.entity,
      extracted_index: i,
      order: camera.payload.camera.order,
    })
  }
  items.sort_by(fn(a, b) {
    let order_cmp = cmp_int(a.order, b.order)
    if order_cmp != 0 {
      return order_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
fn render3d_mesh_phase_kind(alpha_mode : AlphaMode3d, alpha : Float) -> Int? {
  match alpha_mode {
    Opaque => Some(RENDER3D_PHASE_OPAQUE)
    AlphaToCoverage => Some(RENDER3D_PHASE_OPAQUE)
    Mask(cutoff) =>
      if alpha >= cutoff {
        Some(RENDER3D_PHASE_ALPHA_MASK)
      } else {
        None
      }
    Blend => Some(RENDER3D_PHASE_TRANSPARENT)
    Premultiplied => Some(RENDER3D_PHASE_TRANSPARENT)
    Add => Some(RENDER3D_PHASE_TRANSPARENT)
    Multiply => Some(RENDER3D_PHASE_TRANSPARENT)
  }
}

///|
fn render3d_split_phase_ranges(
  length : Int,
  max_num_splits : Int,
) -> Array[(Int, Int)] {
  if length <= 0 || max_num_splits <= 0 {
    return []
  }
  let num_splits = if length < max_num_splits { length } else { max_num_splits }
  let step = length / num_splits
  let ranges : Array[(Int, Int)] = []
  let mut remainder = length % num_splits
  let mut start = 0
  for _ in 0..<num_splits {
    let extra = if remainder > 0 {
      remainder = remainder - 1
      1
    } else {
      0
    }
    let next_end = start + step + extra
    let end_ = if next_end < length { next_end } else { length }
    ranges.push((start, end_))
    start = end_
  }
  ranges
}

///|
fn render3d_mesh_draw_alpha(alpha_mode : AlphaMode3d, alpha : Float) -> Float? {
  match alpha_mode {
    Opaque => Some(1.0F)
    Blend => Some(alpha)
    Premultiplied => Some(alpha)
    Add => Some(alpha)
    Multiply => Some(alpha)
    AlphaToCoverage => Some(alpha)
    Mask(cutoff) => if alpha >= cutoff { Some(1.0F) } else { None }
  }
}

///|
fn render3d_projection_aspect_ratio(width : Float, height : Float) -> Float {
  if width <= 0.0F || height <= 0.0F {
    1.0F
  } else {
    width / height
  }
}

///|
fn render3d_signum(value : Float) -> Float {
  if value < 0.0F {
    -1.0F
  } else if value > 0.0F {
    1.0F
  } else {
    0.0F
  }
}

///|
fn render3d_vec4_dot(lhs : @math.Vec4, rhs : @math.Vec4) -> Float {
  lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w
}

///|
fn render3d_default_near_clip_plane(near : Float) -> @math.Vec4 {
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  @math.Vec4::new(0.0F, 0.0F, -1.0F, -safe_near)
}

///|
fn render3d_adjust_perspective_matrix_for_clip_plane(
  projection : PerspectiveProjection3d,
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d {
  let clip_plane = projection.near_clip_plane
  if clip_plane == render3d_default_near_clip_plane(projection.near) {
    return matrix
  }
  match render3d_projection_matrix_inverse(matrix) {
    None => matrix
    Some(inverse) => {
      let q_prime = @math.Vec4::new(
        render3d_signum(clip_plane.x),
        render3d_signum(clip_plane.y),
        0.0F,
        1.0F,
      )
      let q = inverse.mul_vec4(q_prime)
      let denominator = render3d_vec4_dot(clip_plane, q)
      let safe_denominator = if denominator >= -1.0e-12F &&
        denominator <= 1.0e-12F {
        1.0F
      } else {
        denominator
      }
      let a = -q.z / safe_denominator
      let m3_prime = @math.Vec4::new(
        -clip_plane.x * a,
        -clip_plane.y * a,
        -1.0F - clip_plane.z * a,
        -clip_plane.w * a,
      )
      ProjectionMatrix3d::{
        x_axis: @math.Vec4::new(
          matrix.x_axis.x,
          matrix.x_axis.y,
          m3_prime.x,
          matrix.x_axis.w,
        ),
        y_axis: @math.Vec4::new(
          matrix.y_axis.x,
          matrix.y_axis.y,
          m3_prime.y,
          matrix.y_axis.w,
        ),
        z_axis: @math.Vec4::new(
          matrix.z_axis.x,
          matrix.z_axis.y,
          m3_prime.z,
          matrix.z_axis.w,
        ),
        w_axis: @math.Vec4::new(
          matrix.w_axis.x,
          matrix.w_axis.y,
          m3_prime.w,
          matrix.w_axis.w,
        ),
      }
    }
  }
}

///|
fn render3d_perspective_projection_matrix_raw(
  near : Float,
  fov : Float,
  aspect_ratio : Float,
) -> ProjectionMatrix3d {
  let safe_aspect = if aspect_ratio <= 0.0F { 1.0F } else { aspect_ratio }
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let half_fov = fov * 0.5F
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov == 0.0F {
    1.0F
  } else {
    @math.sin(half_fov) / cos_half_fov
  }
  let y = if tan_half_fov == 0.0F { 1.0F } else { 1.0F / tan_half_fov }
  let x = y / safe_aspect
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, y, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, -1.0F),
    @math.Vec4::new(0.0F, 0.0F, safe_near, 0.0F),
  )
}

///|
fn render3d_perspective_projection_matrix(
  projection : PerspectiveProjection3d,
) -> ProjectionMatrix3d {
  render3d_adjust_perspective_matrix_for_clip_plane(
    projection,
    render3d_perspective_projection_matrix_raw(
      projection.near,
      projection.fov,
      projection.aspect_ratio,
    ),
  )
}

///|
fn render3d_perspective_projection_matrix_for_sub(
  projection : PerspectiveProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  let full_width = Float::from_double(sub_view.full_size.x.to_double())
  let full_height = Float::from_double(sub_view.full_size.y.to_double())
  let sub_width = Float::from_double(sub_view.size.x.to_double())
  let sub_height = Float::from_double(sub_view.size.y.to_double())
  if full_width <= 0.0F ||
    full_height <= 0.0F ||
    sub_width <= 0.0F ||
    sub_height <= 0.0F {
    return projection.get_clip_from_view()
  }
  let near = if projection.near <= 0.0F { 0.0001F } else { projection.near }
  let offset_x = sub_view.offset.x
  let offset_y = full_height - (sub_view.offset.y + sub_height)
  let full_aspect = full_width / full_height
  let half_fov = projection.fov * 0.5F
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov == 0.0F {
    1.0F
  } else {
    @math.sin(half_fov) / cos_half_fov
  }
  let top = near * tan_half_fov
  let bottom = -top
  let right = top * full_aspect
  let left = -right
  let width = right - left
  let height = top - bottom
  let left_prime = left + width * offset_x / full_width
  let right_prime = left + width * (offset_x + sub_width) / full_width
  let bottom_prime = bottom + height * offset_y / full_height
  let top_prime = bottom + height * (offset_y + sub_height) / full_height
  let x = 2.0F * near / (right_prime - left_prime)
  let y = 2.0F * near / (top_prime - bottom_prime)
  let a = (right_prime + left_prime) / (right_prime - left_prime)
  let b = (top_prime + bottom_prime) / (top_prime - bottom_prime)
  render3d_adjust_perspective_matrix_for_clip_plane(
    projection,
    ProjectionMatrix3d::from_cols(
      @math.Vec4::new(x, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, y, 0.0F, 0.0F),
      @math.Vec4::new(a, b, 0.0F, -1.0F),
      @math.Vec4::new(0.0F, 0.0F, near, 0.0F),
    ),
  )
}

///|
fn render3d_perspective_frustum_corners(
  aspect_ratio : Float,
  fov : Float,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  let half_fov = fov * 0.5F
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov == 0.0F {
    1.0F
  } else {
    @math.sin(half_fov) / cos_half_fov
  }
  let near_half_height = tan_half_fov *
    (if z_near < 0.0F { -z_near } else { z_near })
  let far_half_height = tan_half_fov *
    (if z_far < 0.0F { -z_far } else { z_far })
  let near_half_width = near_half_height * aspect_ratio
  let far_half_width = far_half_height * aspect_ratio
  [
    @math.Vec3::new(near_half_width, -near_half_height, z_near),
    @math.Vec3::new(near_half_width, near_half_height, z_near),
    @math.Vec3::new(-near_half_width, near_half_height, z_near),
    @math.Vec3::new(-near_half_width, -near_half_height, z_near),
    @math.Vec3::new(far_half_width, -far_half_height, z_far),
    @math.Vec3::new(far_half_width, far_half_height, z_far),
    @math.Vec3::new(-far_half_width, far_half_height, z_far),
    @math.Vec3::new(-far_half_width, -far_half_height, z_far),
  ]
}

///|
priv struct Render3dPassProjection {
  clip_from_view : ProjectionMatrix3d
  unjittered_clip_from_view : ProjectionMatrix3d
  camera_near : Float
  camera_far : Float
}

///|
fn render3d_projection_matrix_apply_temporal_jitter(
  clip_from_view : ProjectionMatrix3d,
  temporal_jitter : TemporalJitter,
  view_width : Int,
  view_height : Int,
) -> ProjectionMatrix3d {
  let width = Float::from_double(view_width.to_double())
  let height = Float::from_double(view_height.to_double())
  if width <= 0.0F || height <= 0.0F {
    return clip_from_view
  }
  let mut jitter_x = temporal_jitter.offset.x * 2.0F / width
  let mut jitter_y = temporal_jitter.offset.y * -2.0F / height
  if clip_from_view.w_axis.w == 1.0F {
    jitter_x = jitter_x * clip_from_view.x_axis.x * 0.5F
    jitter_y = jitter_y * clip_from_view.y_axis.y * 0.5F
  }
  let z_axis = clip_from_view.z_axis
  ProjectionMatrix3d::{
    ..clip_from_view,
    z_axis: @math.Vec4::new(
      z_axis.x + jitter_x,
      z_axis.y + jitter_y,
      z_axis.z,
      z_axis.w,
    ),
  }
}

///|
fn render3d_projection_near_from_clip_matrix(
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  if clip_from_view.w_axis.w == 0.0F {
    maxf(0.0001F, clip_from_view.w_axis.z)
  } else {
    let safe_z = if clip_from_view.z_axis.z == 0.0F {
      1.0F
    } else {
      clip_from_view.z_axis.z
    }
    clip_from_view.w_axis.z / safe_z
  }
}

///|
fn render3d_projection_near(
  projection : Projection,
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  match projection {
    Perspective(perspective) => maxf(0.0001F, perspective.near)
    Orthographic(orthographic) => orthographic.near
    Custom(_) => render3d_projection_near_from_clip_matrix(clip_from_view)
  }
}

///|
fn render3d_camera_pass_projection(
  projection : Projection,
  sub_camera_view : SubCameraView3d?,
  temporal_jitter : TemporalJitter?,
  view_width : Int,
  view_height : Int,
) -> Render3dPassProjection {
  let unjittered_clip_from_view = match sub_camera_view {
    Some(sub_view) => projection.get_clip_from_view_for_sub(sub_view)
    None => projection.get_clip_from_view()
  }
  let clip_from_view = match temporal_jitter {
    Some(temporal_jitter) =>
      render3d_projection_matrix_apply_temporal_jitter(
        unjittered_clip_from_view, temporal_jitter, view_width, view_height,
      )
    None => unjittered_clip_from_view
  }
  Render3dPassProjection::{
    clip_from_view,
    unjittered_clip_from_view,
    camera_near: render3d_projection_near(projection, unjittered_clip_from_view),
    camera_far: projection.far(),
  }
}

///|
fn render3d_point_shadow_pass_projection(
  near : Float,
  far : Float,
) -> Render3dPassProjection {
  let shadow_near = if near > 0.0001F { near } else { 0.0001F }
  let shadow_far = if far > shadow_near { far } else { shadow_near + 1.0F }
  let clip_from_view = render3d_perspective_projection_matrix_raw(
    shadow_near,
    @math.pi_half(),
    1.0F,
  )
  Render3dPassProjection::{
    clip_from_view,
    unjittered_clip_from_view: clip_from_view,
    camera_near: shadow_near,
    camera_far: shadow_far,
  }
}

///|
fn render3d_view_from_world_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let inverse_rotation = render3d_quat_conjugate(transform.rotation.normalize())
  let x_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let y_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let z_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
  )
  let translation = transform.translation
  // `x_axis/y_axis/z_axis` are columns of the inverse rotation matrix.
  // Translation in view space is `-(R_inv * world_translation)`.
  let offset_x = -(x_axis.x * translation.x +
    y_axis.x * translation.y +
    z_axis.x * translation.z)
  let offset_y = -(x_axis.y * translation.x +
    y_axis.y * translation.y +
    z_axis.y * translation.z)
  let offset_z = -(x_axis.z * translation.x +
    y_axis.z * translation.y +
    z_axis.z * translation.z)
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(offset_x, offset_y, offset_z, 1.0F),
  )
}

///|
fn render3d_pass_projection_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  pass_projection.clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
}

///|
fn render3d_pass_projection_unjittered_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  pass_projection.unjittered_clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
}

///|
fn render3d_mesh_view_depth(
  mesh_transform : @transform.Transform,
  camera_transform : @transform.Transform,
) -> Float {
  let to_mesh = @math.Vec3::new(
    mesh_transform.translation.x - camera_transform.translation.x,
    mesh_transform.translation.y - camera_transform.translation.y,
    mesh_transform.translation.z - camera_transform.translation.z,
  )
  let camera_forward = render3d_transform_forward(camera_transform)
  to_mesh.x * camera_forward.x +
  to_mesh.y * camera_forward.y +
  to_mesh.z * camera_forward.z
}

///|
fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
const RENDER3D_TONEMAPPING_LUT_AGX_PATH : String = "textures/tonemapping/AgX-default_contrast.ktx2"

///|
const RENDER3D_TONEMAPPING_LUT_TONY_PATH : String = "textures/tonemapping/tony_mc_mapface.ktx2"

///|
const RENDER3D_TONEMAPPING_LUT_BLENDER_PATH : String = "textures/tonemapping/Blender_-11_12.ktx2"

///|
priv struct Render3dTonemappingLutHandles {
  agx : @asset.Handle[@asset.Image]
  tony : @asset.Handle[@asset.Image]
  blender : @asset.Handle[@asset.Image]
}

///|
fn render3d_tonemapping_lut_handles(
  world : @ecs.World,
) -> Render3dTonemappingLutHandles {
  let internal_assets = render3d_internal_assets_ref_or_abort(world)
  if internal_assets.val.tonemapping_luts is Some(handles) {
    return handles
  }
  let asset_server = render3d_asset_server_from_world_or_abort(world)
  let handles = Render3dTonemappingLutHandles::{
    agx: asset_server.load(RENDER3D_TONEMAPPING_LUT_AGX_PATH),
    tony: asset_server.load(RENDER3D_TONEMAPPING_LUT_TONY_PATH),
    blender: asset_server.load(RENDER3D_TONEMAPPING_LUT_BLENDER_PATH),
  }
  internal_assets.val.tonemapping_luts = Some(handles)
  handles
}

///|
priv struct Render3dAutoExposureCurveGpuData {
  lut : Bytes
  min_log_lum : Float
  max_log_lum : Float
  min_compensation : Float
  max_compensation : Float
}

///|
fn render3d_default_auto_exposure_curve_gpu_data() -> Render3dAutoExposureCurveGpuData {
  Render3dAutoExposureCurveGpuData::{
    lut: Bytes::makei(256, _ => 0),
    min_log_lum: 0.0F,
    max_log_lum: 0.0F,
    min_compensation: 0.0F,
    max_compensation: 0.0F,
  }
}

///|
fn render3d_auto_exposure_curve_gpu_data(
  world : @ecs.World,
  curve_handle : @asset.Handle[AutoExposureCompensationCurve]?,
) -> Render3dAutoExposureCurveGpuData {
  let key : @ecs.ResourceKey[@asset.Assets[AutoExposureCompensationCurve]] = @asset.assets_resource_key()
  guard (try! world.get_resource(key)) is Some(curves) else {
    return render3d_default_auto_exposure_curve_gpu_data()
  }
  let resolved_handle = match curve_handle {
    Some(handle) => handle
    None => @asset.Handle::new(0)
  }
  match curves.get(resolved_handle) {
    Some(curve) =>
      Render3dAutoExposureCurveGpuData::{
        lut: curve.lut,
        min_log_lum: curve.min_log_lum,
        max_log_lum: curve.max_log_lum,
        min_compensation: curve.min_compensation,
        max_compensation: curve.max_compensation,
      }
    None => render3d_default_auto_exposure_curve_gpu_data()
  }
}

///|
fn render3d_apply_camera_auto_exposure(
  world : @ecs.World,
  camera_entity : @core.Entity,
  auto_exposure : AutoExposure,
  color_grading : @post_process.ColorGrading?,
  scene_texture_id : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  delta_time : Float,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let curve = render3d_auto_exposure_curve_gpu_data(
    world,
    auto_exposure.compensation_curve,
  )
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_apply_auto_exposure(
    view_key_hi=camera_entity.id,
    view_key_lo=camera_entity.generation,
    scene_texture_id~,
    min_ev100=auto_exposure.min_ev100,
    max_ev100=auto_exposure.max_ev100,
    low_percent=auto_exposure.low_percent,
    high_percent=auto_exposure.high_percent,
    speed_brighten=auto_exposure.speed_brighten,
    speed_darken=auto_exposure.speed_darken,
    exponential_transition_distance=auto_exposure.exponential_transition_distance,
    delta_time~,
    color_grading=color_grading_uniform,
    metering_mask_texture_id=match auto_exposure.metering_mask {
      Some(mask) => mask.id()
      None => -1
    },
    compensation_curve_lut=curve.lut,
    compensation_curve_min_log_lum=curve.min_log_lum,
    compensation_curve_max_log_lum=curve.max_log_lum,
    compensation_curve_min_compensation=curve.min_compensation,
    compensation_curve_max_compensation=curve.max_compensation,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_bloom_clamp_unit(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_clamp_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_max_mip_dimension(value : Int) -> Int {
  if value < 4 {
    4
  } else {
    value
  }
}

///|
fn render3d_bloom_safe_scale_axis(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn render3d_bloom_sanitize(bloom : Bloom) -> Bloom {
  let prefilter = BloomPrefilter::new(
    render3d_bloom_clamp_non_negative(bloom.prefilter.threshold),
    render3d_bloom_clamp_unit(bloom.prefilter.threshold_softness),
  )
  Bloom::new(render3d_bloom_clamp_non_negative(bloom.intensity))
  .with_low_frequency_boost(
    render3d_bloom_clamp_unit(bloom.low_frequency_boost),
  )
  .with_low_frequency_boost_curvature(
    render3d_bloom_clamp_unit(bloom.low_frequency_boost_curvature),
  )
  .with_high_pass_frequency(
    render3d_bloom_clamp_unit(bloom.high_pass_frequency),
  )
  .with_prefilter_settings(prefilter)
  .with_composite_mode(bloom.composite_mode)
  .with_max_mip_dimension(
    render3d_bloom_safe_max_mip_dimension(bloom.max_mip_dimension),
  )
  .with_scale(
    @math.Vec2::new(
      render3d_bloom_safe_scale_axis(bloom.scale.x),
      render3d_bloom_safe_scale_axis(bloom.scale.y),
    ),
  )
}

///|
fn render3d_tonemapping_mode_to_int(mode : Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
  }
}

///|
fn render3d_fxaa_sensitivity_mode_int(sensitivity : FxaaSensitivity) -> Int {
  match sensitivity {
    Low => 0
    Medium => 1
    High => 2
    Ultra => 3
    Extreme => 4
  }
}

///|
fn render3d_fxaa_postprocess_values(fxaa : Fxaa?) -> (Int, Int, Int) {
  match fxaa {
    Some(value) =>
      (
        if value.enabled {
          1
        } else {
          0
        },
        render3d_fxaa_sensitivity_mode_int(value.edge_threshold),
        render3d_fxaa_sensitivity_mode_int(value.edge_threshold_min),
      )
    None =>
      (
        0,
        render3d_fxaa_sensitivity_mode_int(FxaaSensitivity::default()),
        render3d_fxaa_sensitivity_mode_int(FxaaSensitivity::default()),
      )
  }
}

///|
fn render3d_chromatic_aberration_postprocess_values(
  chromatic_aberration : ChromaticAberration?,
) -> (Float, Int) {
  match chromatic_aberration {
    Some(value) =>
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.max_samples <= 0 {
          1
        } else {
          value.max_samples
        },
      )
    None => {
      let defaults = ChromaticAberration::default()
      (0.0F, defaults.max_samples)
    }
  }
}

///|
fn render3d_vignette_postprocess_values(
  vignette : Vignette?,
) -> (
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
) {
  match vignette {
    Some(value) => {
      let safe_edge_compensation = if value.edge_compensation < 0.0F {
        0.0F
      } else if value.edge_compensation > 1.0F {
        1.0F
      } else {
        value.edge_compensation
      }
      (
        if value.intensity < 0.0F {
          0.0F
        } else {
          value.intensity
        },
        if value.radius < 0.0F {
          0.0F
        } else {
          value.radius
        },
        if value.smoothness <= 0.01F {
          0.01F
        } else {
          value.smoothness
        },
        if value.roundness <= 0.01F {
          0.01F
        } else {
          value.roundness
        },
        value.center.x,
        value.center.y,
        safe_edge_compensation,
        value.color.r,
        value.color.g,
        value.color.b,
        value.color.a,
      )
    }
    None => {
      let defaults = Vignette::default()
      (
        0.0F,
        defaults.radius,
        defaults.smoothness,
        defaults.roundness,
        defaults.center.x,
        defaults.center.y,
        defaults.edge_compensation,
        defaults.color.r,
        defaults.color.g,
        defaults.color.b,
        defaults.color.a,
      )
    }
  }
}

///|
fn render3d_postprocess_stage_target(
  source_texture_id : Int,
  scene_texture_id : Int,
  ping_texture_id : Int,
  camera_target_id : Int,
  stage_index : Int,
  stage_count : Int,
) -> Int {
  if stage_index >= stage_count - 1 {
    camera_target_id
  } else if source_texture_id == ping_texture_id {
    scene_texture_id
  } else {
    ping_texture_id
  }
}

///|
fn render3d_draw_camera_effect_stack_stage(
  scene_texture_id : Int,
  chromatic_aberration : ChromaticAberration?,
  vignette : Vignette?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if !render3d_effect_stack_enabled(chromatic_aberration, vignette) {
    return
  }
  let (chromatic_aberration_intensity, chromatic_aberration_max_samples) = render3d_chromatic_aberration_postprocess_values(
    chromatic_aberration,
  )
  let (
    vignette_intensity,
    vignette_radius,
    vignette_smoothness,
    vignette_roundness,
    vignette_center_x,
    vignette_center_y,
    vignette_edge_compensation,
    vignette_color_r,
    vignette_color_g,
    vignette_color_b,
    vignette_color_a,
  ) = render3d_vignette_postprocess_values(vignette)
  @render.host_gpu_draw_effect_stack(
    scene_texture_id~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_tonemapping_stage(
  world : @ecs.World,
  scene_texture_id : Int,
  exposure : Exposure?,
  tonemapping : Tonemapping?,
  deband_dither : DebandDither?,
  color_grading : ColorGrading?,
  hdr_enabled : Bool,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  exposure |> ignore
  if !render3d_tonemapping_stage_enabled(
      tonemapping, deband_dither, hdr_enabled, color_grading,
    ) {
    return
  }
  let luts = render3d_tonemapping_lut_handles(world)
  let color_grading_uniform = @render.host_color_grading_from_post_process(
    color_grading,
  )
  @render.host_gpu_draw_tonemapping3d(
    scene_texture_id~,
    exposure=1.0F,
    tonemapping_mode=match tonemapping {
      Some(mode) => render3d_tonemapping_mode_to_int(mode)
      None => 0
    },
    deband_dither_enabled=match deband_dither {
      Some(Enabled) => 1
      _ => 0
    },
    view_width=view_width_logical,
    view_height=view_height_logical,
    agx_lut_texture_id=luts.agx.id(),
    tony_lut_texture_id=luts.tony.id(),
    blender_lut_texture_id=luts.blender.id(),
    color_grading=color_grading_uniform,
  )
}

///|
fn render3d_draw_camera_fxaa_stage(
  scene_texture_id : Int,
  fxaa : Fxaa?,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  let (fxaa_enabled, fxaa_edge_threshold_mode, fxaa_edge_threshold_min_mode) = render3d_fxaa_postprocess_values(
    fxaa,
  )
  if fxaa_enabled == 0 {
    return
  }
  @render.host_gpu_draw_fxaa(
    scene_texture_id~,
    fxaa_enabled~,
    fxaa_edge_threshold_mode~,
    fxaa_edge_threshold_min_mode~,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_draw_camera_bloom_stage(
  scene_texture_id : Int,
  bloom : Bloom,
  view_width_logical : Int,
  view_height_logical : Int,
) -> Unit {
  if scene_texture_id < 0 || view_width_logical <= 0 || view_height_logical <= 0 {
    return
  }
  let settings = render3d_bloom_sanitize(bloom)
  @render.host_gpu_apply_bloom(
    scene_texture_id~,
    intensity=settings.intensity,
    low_frequency_boost=settings.low_frequency_boost,
    low_frequency_boost_curvature=settings.low_frequency_boost_curvature,
    high_pass_frequency=settings.high_pass_frequency,
    threshold=settings.prefilter.threshold,
    threshold_softness=settings.prefilter.threshold_softness,
    composite_mode=match settings.composite_mode {
      EnergyConserving => 0
      Additive => 1
    },
    max_mip_dimension=settings.max_mip_dimension,
    scale_x=settings.scale.x,
    scale_y=settings.scale.y,
    view_width=view_width_logical,
    view_height=view_height_logical,
  )
}

///|
fn render3d_rotate_by_quat(v : @math.Vec3, q : @math.Quat) -> @math.Vec3 {
  let q_vec = @math.Vec3::new(q.x, q.y, q.z)
  let t = q_vec.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(q_vec.cross(t))
}

///|
fn render3d_transform_point(
  transform : @transform.Transform,
  local_point : @math.Vec3,
) -> @math.Vec3 {
  let scaled = local_point.mul(transform.scale)
  transform.translation.add(render3d_rotate_by_quat(scaled, transform.rotation))
}

///|
fn render3d_inverse_transform_point(
  transform : @transform.Transform,
  world_point : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let translated = world_point.sub(transform.translation)
  let rotated = render3d_rotate_by_quat(
    translated,
    render3d_quat_conjugate(transform.rotation),
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
fn render3d_inverse_transform_direction(
  transform : @transform.Transform,
  world_direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let rotated = render3d_rotate_by_quat(
    world_direction,
    render3d_quat_conjugate(transform.rotation),
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
fn render3d_transform_local_normal(
  transform : @transform.Transform,
  local_normal : @math.Vec3,
) -> @math.Vec3 {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return render3d_rotate_by_quat(local_normal, transform.rotation).normalize_or_zero()
  }
  let scaled = @math.Vec3::new(
    local_normal.x / transform.scale.x,
    local_normal.y / transform.scale.y,
    local_normal.z / transform.scale.z,
  )
  render3d_rotate_by_quat(scaled, transform.rotation).normalize_or_zero()
}

///|
fn render3d_ray_local_aabb_hit(
  origin : @math.Vec3,
  direction : @math.Vec3,
  min_corner : @math.Vec3,
  max_corner : @math.Vec3,
  ray_epsilon : Float,
  max_distance : Float,
) -> (Float, @math.Vec3)? {
  let mut t_min = -max_distance
  let mut t_max = max_distance
  let mut enter_normal = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let mut exit_normal = @math.Vec3::new(-1.0F, 0.0F, 0.0F)

  let axes : Array[(@math.Vec3, Float, Float, Float, Float)] = [
    (
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      origin.x,
      direction.x,
      min_corner.x,
      max_corner.x,
    ),
    (
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      origin.y,
      direction.y,
      min_corner.y,
      max_corner.y,
    ),
    (
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
      origin.z,
      direction.z,
      min_corner.z,
      max_corner.z,
    ),
  ]

  for axis_data in axes {
    let axis = axis_data.0
    let o = axis_data.1
    let d = axis_data.2
    let slab_min = axis_data.3
    let slab_max = axis_data.4
    if absf(d) <= 1.0e-9F {
      if o < slab_min || o > slab_max {
        return None
      }
      continue
    }

    let inv_d = 1.0F / d
    let mut t1 = (slab_min - o) * inv_d
    let mut t2 = (slab_max - o) * inv_d
    let mut near_normal = axis.neg()
    let mut far_normal = axis
    if t1 > t2 {
      let t_swap = t1
      t1 = t2
      t2 = t_swap
      let normal_swap = near_normal
      near_normal = far_normal
      far_normal = normal_swap
    }
    if t1 > t_min {
      t_min = t1
      enter_normal = near_normal
    }
    if t2 < t_max {
      t_max = t2
      exit_normal = far_normal
    }
    if t_min > t_max {
      return None
    }
  }

  if t_max < ray_epsilon {
    return None
  }
  let (distance, normal) = if t_min >= ray_epsilon {
    (t_min, enter_normal)
  } else {
    (t_max, exit_normal)
  }
  if distance < ray_epsilon || distance > max_distance {
    return None
  }
  Some((distance, normal))
}

///|
fn render3d_mesh_local_aabb(mesh3d : Mesh3d) -> (@math.Vec3, @math.Vec3)? {
  guard @sprite.render_mesh_asset_get(mesh3d.mesh) is Some(mesh_asset) else {
    return None
  }
  guard mesh_asset.geometry is @mesh.MeshGeometry::Geometry3d(geometry3d) else {
    return None
  }
  guard geometry3d.positions.length() > 0 else { return None }
  let mut min_x = geometry3d.positions[0].x
  let mut min_y = geometry3d.positions[0].y
  let mut min_z = geometry3d.positions[0].z
  let mut max_x = geometry3d.positions[0].x
  let mut max_y = geometry3d.positions[0].y
  let mut max_z = geometry3d.positions[0].z
  for i in 1..<geometry3d.positions.length() {
    let p = geometry3d.positions[i]
    min_x = minf(min_x, p.x)
    min_y = minf(min_y, p.y)
    min_z = minf(min_z, p.z)
    max_x = maxf(max_x, p.x)
    max_y = maxf(max_y, p.y)
    max_z = maxf(max_z, p.z)
  }
  Some(
    (@math.Vec3::new(min_x, min_y, min_z), @math.Vec3::new(max_x, max_y, max_z)),
  )
}

///|
fn render3d_mesh_local_aabb_center(mesh3d : Mesh3d) -> @math.Vec3? {
  if render3d_mesh_local_aabb(mesh3d) is Some((min_corner, max_corner)) {
    Some(
      @math.Vec3::new(
        (min_corner.x + max_corner.x) * 0.5F,
        (min_corner.y + max_corner.y) * 0.5F,
        (min_corner.z + max_corner.z) * 0.5F,
      ),
    )
  } else {
    None
  }
}

///|
fn render3d_pow_e(value : Float) -> Float {
  @math.pow(FOG_FALLOFF_E, value)
}

///|
fn render3d_fog_channel_factor(density : Float, distance : Float) -> Float {
  let safe_density = if density < 0.0F { 0.0F } else { density }
  1.0F - render3d_pow_e(-(safe_density * distance))
}

///|
fn render3d_fog_falloff_factor(
  falloff : FogFalloff3d,
  distance : Float,
) -> Float {
  let safe_distance = if distance < 0.0F { 0.0F } else { distance }
  match falloff {
    Linear(start, end_) => {
      let safe_start = if start < 0.0F { 0.0F } else { start }
      let safe_end = if end_ < safe_start { safe_start } else { end_ }
      if safe_end <= safe_start {
        if safe_distance >= safe_end {
          1.0F
        } else {
          0.0F
        }
      } else if safe_distance <= safe_start {
        0.0F
      } else if safe_distance >= safe_end {
        1.0F
      } else {
        (safe_distance - safe_start) / (safe_end - safe_start)
      }
    }
    Exponential(density) => {
      let safe_density = if density < 0.0F { 0.0F } else { density }
      1.0F - render3d_pow_e(-safe_density * safe_distance)
    }
    ExponentialSquared(density) => {
      let safe_density = if density < 0.0F { 0.0F } else { density }
      let d = safe_density * safe_distance
      1.0F - render3d_pow_e(-(d * d))
    }
    Atmospheric(extinction, inscattering) => {
      let extinction_max = maxf(maxf(extinction.x, extinction.y), extinction.z)
      let inscattering_max = maxf(
        maxf(inscattering.x, inscattering.y),
        inscattering.z,
      )
      let extinction_factor = render3d_fog_channel_factor(
        extinction_max, safe_distance,
      )
      let inscattering_factor = render3d_fog_channel_factor(
        inscattering_max, safe_distance,
      )
      clamp01((extinction_factor + inscattering_factor) * 0.5F)
    }
  }
}

///|
fn render3d_distance_fog_mix_factor(
  fog : DistanceFog,
  distance : Float,
) -> Float {
  let falloff_factor = render3d_fog_falloff_factor(fog.falloff, distance)
  clamp01(falloff_factor * clamp01(fog.color.a))
}

///|
fn render3d_distance_fog_directional_mix(
  fog : DistanceFog,
  fog_presence : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> Float {
  let directional_alpha = clamp01(fog.directional_light_color.a)
  if directional_alpha <= 0.0F {
    return 0.0F
  }
  if fog.directional_light_exponent <= 0.0F {
    return 0.0F
  }
  if lighting.directional_illuminance <= 0.0F {
    return 0.0F
  }
  let view_direction = mesh_position.sub(camera_position).normalize_or_zero()
  let light_direction = lighting.directional_dir.neg().normalize_or_zero()
  let alignment = clamp01(light_direction.dot(view_direction) * 0.5F + 0.5F)
  let phase = @math.pow(alignment, fog.directional_light_exponent)
  let illuminance_mix = clamp01(lighting.directional_illuminance / 50_000.0F)
  clamp01(phase * directional_alpha * illuminance_mix * fog_presence)
}

///|
fn render3d_apply_distance_fog(
  fog : DistanceFog,
  distance : Float,
  base_r : Float,
  base_g : Float,
  base_b : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> (Float, Float, Float) {
  let fog_alpha = clamp01(fog.color.a)
  let mut fogged_r = base_r
  let mut fogged_g = base_g
  let mut fogged_b = base_b
  let mut fog_presence = 0.0F

  match fog.falloff {
    Atmospheric(extinction, inscattering) => {
      let extinction_r = clamp01(
        render3d_fog_channel_factor(extinction.x, distance) * fog_alpha,
      )
      let extinction_g = clamp01(
        render3d_fog_channel_factor(extinction.y, distance) * fog_alpha,
      )
      let extinction_b = clamp01(
        render3d_fog_channel_factor(extinction.z, distance) * fog_alpha,
      )
      let inscattering_r = clamp01(
        render3d_fog_channel_factor(inscattering.x, distance) * fog_alpha,
      )
      let inscattering_g = clamp01(
        render3d_fog_channel_factor(inscattering.y, distance) * fog_alpha,
      )
      let inscattering_b = clamp01(
        render3d_fog_channel_factor(inscattering.z, distance) * fog_alpha,
      )

      fogged_r = base_r * (1.0F - extinction_r) + fog.color.r * inscattering_r
      fogged_g = base_g * (1.0F - extinction_g) + fog.color.g * inscattering_g
      fogged_b = base_b * (1.0F - extinction_b) + fog.color.b * inscattering_b

      let extinction_peak = maxf(maxf(extinction_r, extinction_g), extinction_b)
      let inscattering_peak = maxf(
        maxf(inscattering_r, inscattering_g),
        inscattering_b,
      )
      fog_presence = clamp01((extinction_peak + inscattering_peak) * 0.5F)
    }
    _ => {
      let fog_mix = render3d_distance_fog_mix_factor(fog, distance)
      fogged_r = base_r * (1.0F - fog_mix) + fog.color.r * fog_mix
      fogged_g = base_g * (1.0F - fog_mix) + fog.color.g * fog_mix
      fogged_b = base_b * (1.0F - fog_mix) + fog.color.b * fog_mix
      fog_presence = fog_mix
    }
  }

  let directional_mix = render3d_distance_fog_directional_mix(
    fog, fog_presence, camera_position, mesh_position, lighting,
  )
  if directional_mix > 0.0F {
    let directional_tint_r = clamp01(
      fog.directional_light_color.r * lighting.directional_color.r,
    )
    let directional_tint_g = clamp01(
      fog.directional_light_color.g * lighting.directional_color.g,
    )
    let directional_tint_b = clamp01(
      fog.directional_light_color.b * lighting.directional_color.b,
    )
    fogged_r = fogged_r * (1.0F - directional_mix) +
      directional_tint_r * directional_mix
    fogged_g = fogged_g * (1.0F - directional_mix) +
      directional_tint_g * directional_mix
    fogged_b = fogged_b * (1.0F - directional_mix) +
      directional_tint_b * directional_mix
  }

  (clamp01(fogged_r), clamp01(fogged_g), clamp01(fogged_b))
}

///|
fn render3d_visibility_range_visible(
  visibility_range : @visibility.VisibilityRange,
  camera_transform : @transform.Transform,
  mesh_transform : @transform.Transform,
  mesh_aabb_center_world : @math.Vec3?,
) -> Bool {
  let mesh_position = if visibility_range.use_aabb {
    match mesh_aabb_center_world {
      Some(center) => center
      None => mesh_transform.translation
    }
  } else {
    mesh_transform.translation
  }
  let to_mesh = mesh_position.sub(camera_transform.translation)
  let distance = to_mesh.length()
  let near_bound = visibility_range.start_margin_min
  let far_bound = visibility_range.end_margin_max
  if far_bound < near_bound {
    return false
  }
  distance >= near_bound && distance < far_bound
}

///|
fn render3d_queue_mesh_phase_items_cpu_builder(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
) -> Array[MeshPhaseItem3d] {
  let items : Array[MeshPhaseItem3d] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    let payload = mesh.payload
    if payload.mesh_id <= 0 {
      continue
    }
    if !payload.layers.matches(layers) {
      continue
    }
    if payload.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        payload.transform,
        payload.aabb_center_world,
      ) {
      continue
    }
    let alpha = payload.material.base_color.a
    if render3d_mesh_phase_kind(payload.material.alpha_mode, alpha) is None {
      continue
    }
    let phase = render3d_mesh_phase_kind(payload.material.alpha_mode, alpha).unwrap()
    items.push(MeshPhaseItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      phase,
      distance: render3d_mesh_view_depth(payload.transform, camera_transform),
    })
  }
  items.sort_by(fn(a, b) {
    let phase_cmp = cmp_int(a.phase, b.phase)
    if phase_cmp != 0 {
      return phase_cmp
    }
    if a.phase == RENDER3D_PHASE_TRANSPARENT {
      let depth_cmp = cmp_float(b.distance, a.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    } else {
      let depth_cmp = cmp_float(a.distance, b.distance)
      if depth_cmp != 0 {
        return depth_cmp
      }
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  items
}

///|
priv struct GpuPreprocessWorkItem3d {
  entity : PhaseEntityRef3d
  extracted_index : Int
  phase : Int
  distance : Float
}

///|
fn render3d_collect_meshes_for_gpu_building(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
) -> Array[GpuPreprocessWorkItem3d] {
  let work_items : Array[GpuPreprocessWorkItem3d] = []
  for i in 0..<meshes.length() {
    let mesh = meshes[i]
    let payload = mesh.payload
    if payload.mesh_id <= 0 {
      continue
    }
    if !payload.layers.matches(layers) {
      continue
    }
    if payload.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        payload.transform,
        payload.aabb_center_world,
      ) {
      continue
    }
    let alpha = payload.material.base_color.a
    guard render3d_mesh_phase_kind(payload.material.alpha_mode, alpha)
      is Some(phase) else {
      continue
    }
    work_items.push(GpuPreprocessWorkItem3d::{
      entity: mesh.entity,
      extracted_index: i,
      phase,
      distance: render3d_mesh_view_depth(payload.transform, camera_transform),
    })
  }
  work_items
}

///|
fn render3d_sort_gpu_preprocess_work_items(
  work_items : Array[GpuPreprocessWorkItem3d],
) -> Array[GpuPreprocessWorkItem3d] {
  let opaque_items : Array[GpuPreprocessWorkItem3d] = []
  let alpha_mask_items : Array[GpuPreprocessWorkItem3d] = []
  let transparent_items : Array[GpuPreprocessWorkItem3d] = []
  for work_item in work_items {
    if work_item.phase == RENDER3D_PHASE_OPAQUE {
      opaque_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_ALPHA_MASK {
      alpha_mask_items.push(work_item)
    } else if work_item.phase == RENDER3D_PHASE_TRANSPARENT {
      transparent_items.push(work_item)
    }
  }
  opaque_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(a.distance, b.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  alpha_mask_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(a.distance, b.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  transparent_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(b.distance, a.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  let sorted : Array[GpuPreprocessWorkItem3d] = []
  for item in opaque_items {
    sorted.push(item)
  }
  for item in alpha_mask_items {
    sorted.push(item)
  }
  for item in transparent_items {
    sorted.push(item)
  }
  sorted
}

///|
fn render3d_write_batched_instance_buffers(
  work_items : Array[GpuPreprocessWorkItem3d],
) -> Array[MeshPhaseItem3d] {
  let phase_items : Array[MeshPhaseItem3d] = []
  for work_item in render3d_sort_gpu_preprocess_work_items(work_items) {
    phase_items.push(MeshPhaseItem3d::{
      entity: work_item.entity,
      extracted_index: work_item.extracted_index,
      phase: work_item.phase,
      distance: work_item.distance,
    })
  }
  phase_items
}

///|
priv struct GpuPreprocessMeshCandidate3d {
  entity : PhaseEntityRef3d
  mesh_id : Int
  indexed : Bool
  layers : @sprite.RenderLayers
  visibility_range : @visibility.VisibilityRange?
  aabb_center_world : @math.Vec3?
  transform : @transform.Transform
  alpha_mode : AlphaMode3d
  alpha : Float
}

///|
fn phase_entity_ref3d_main_eq(
  lhs : PhaseEntityRef3d,
  rhs : PhaseEntityRef3d,
) -> Bool {
  lhs.main_entity.id == rhs.main_entity.id &&
  lhs.main_entity.generation == rhs.main_entity.generation
}

///|
fn render3d_mesh_handle_is_indexed(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Bool {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) =>
          geometry3d.indices is Some(_)
        _ => false
      }
    None => false
  }
}

///|
fn render3d_sort_gpu_preprocess_prequeued_items(
  items : Array[GpuPreprocessPrequeuedMeshItem3d],
) -> Array[GpuPreprocessPrequeuedMeshItem3d] {
  let opaque_items : Array[GpuPreprocessPrequeuedMeshItem3d] = []
  let alpha_mask_items : Array[GpuPreprocessPrequeuedMeshItem3d] = []
  let transparent_items : Array[GpuPreprocessPrequeuedMeshItem3d] = []
  for item in items {
    if item.phase == RENDER3D_PHASE_OPAQUE {
      opaque_items.push(item)
    } else if item.phase == RENDER3D_PHASE_ALPHA_MASK {
      alpha_mask_items.push(item)
    } else if item.phase == RENDER3D_PHASE_TRANSPARENT {
      transparent_items.push(item)
    }
  }
  opaque_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(a.distance, b.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  alpha_mask_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(a.distance, b.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  transparent_items.sort_by(fn(a, b) {
    let depth_cmp = cmp_float(b.distance, a.distance)
    if depth_cmp != 0 {
      return depth_cmp
    }
    phase_entity_ref3d_cmp(a.entity, b.entity)
  })
  let sorted : Array[GpuPreprocessPrequeuedMeshItem3d] = []
  for item in opaque_items {
    sorted.push(item)
  }
  for item in alpha_mask_items {
    sorted.push(item)
  }
  for item in transparent_items {
    sorted.push(item)
  }
  sorted
}

///|
fn render3d_collect_gpu_preprocess_mesh_candidates(
  world : @ecs.World,
) -> Array[GpuPreprocessMeshCandidate3d] {
  let mesh_store = world.component(ecs_key_mesh3d)
  let material_store = world.component(ecs_key_mesh_material3d)
  let gpu_mesh_store = world.component(@sprite.ecs_key_gpu_mesh2d)
  let visibility_range_store = world.component(
    @visibility.ecs_key_visibility_range,
  )
  let view_visibility_store = world.component(
    @visibility.ecs_key_view_visibility,
  )
  let layers_store = world.component(@sprite.ecs_key_render_layers)
  let transform_store = world.component(@transform.ecs_key_transform)
  let candidates : Array[GpuPreprocessMeshCandidate3d] = []
  mesh_store.for_each(fn(entity, mesh3d) {
    if view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard gpu_mesh_store.get(entity) is Some(gpu_mesh) else { return }
    guard material_store.get(entity) is Some(material_handle) else { return }
    guard standard_material_get(material_handle.material) is Some(base_material) else {
      return
    }
    let material = render3d_apply_extended_material_metadata(
      base_material,
      material_handle.extended_material,
    )
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    let visibility_range = visibility_range_store.get(entity)
    let aabb_center_world = if visibility_range is Some(range) && range.use_aabb {
      match render3d_mesh_local_aabb_center(mesh3d) {
        Some(local_center) =>
          Some(render3d_transform_point(transform, local_center))
        None => None
      }
    } else {
      None
    }
    let layers = match layers_store.get(entity) {
      Some(value) => value
      None => @sprite.RenderLayers::default()
    }
    candidates.push(GpuPreprocessMeshCandidate3d::{
      entity: phase_entity_ref3d_for_main(entity),
      mesh_id: gpu_mesh.mesh_id,
      indexed: render3d_mesh_handle_is_indexed(mesh3d.mesh),
      layers,
      visibility_range,
      aabb_center_world,
      transform,
      alpha_mode: material.alpha_mode,
      alpha: material.base_color.a,
    })
  })
  candidates
}

///|
fn render3d_collect_gpu_preprocess_camera_queue_items(
  mesh_candidates : Array[GpuPreprocessMeshCandidate3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
) -> Array[GpuPreprocessPrequeuedMeshItem3d] {
  let items : Array[GpuPreprocessPrequeuedMeshItem3d] = []
  for candidate in mesh_candidates {
    if candidate.mesh_id <= 0 {
      continue
    }
    if !candidate.layers.matches(layers) {
      continue
    }
    if candidate.visibility_range is Some(visibility_range) &&
      !render3d_visibility_range_visible(
        visibility_range,
        camera_transform,
        candidate.transform,
        candidate.aabb_center_world,
      ) {
      continue
    }
    guard render3d_mesh_phase_kind(candidate.alpha_mode, candidate.alpha)
      is Some(phase) else {
      continue
    }
    items.push(GpuPreprocessPrequeuedMeshItem3d::{
      entity: candidate.entity,
      indexed: candidate.indexed,
      phase,
      distance: render3d_mesh_view_depth(candidate.transform, camera_transform),
    })
  }
  render3d_sort_gpu_preprocess_prequeued_items(items)
}

///|
fn render3d_build_gpu_preprocess_phase_ranges_from_prequeued_items(
  items : Array[GpuPreprocessPrequeuedMeshItem3d],
) -> Array[GpuPreprocessPhaseRange3d] {
  let phase_ranges : Array[GpuPreprocessPhaseRange3d] = []
  if items.length() == 0 {
    return phase_ranges
  }
  let mut current_phase = items[0].phase
  let mut range_start = 0
  for i in 1..<items.length() {
    if items[i].phase == current_phase {
      continue
    }
    phase_ranges.push(GpuPreprocessPhaseRange3d::{
      phase: current_phase,
      start: range_start,
      end: i,
    })
    current_phase = items[i].phase
    range_start = i
  }
  phase_ranges.push(GpuPreprocessPhaseRange3d::{
    phase: current_phase,
    start: range_start,
    end: items.length(),
  })
  phase_ranges
}

///|
fn render3d_build_gpu_preprocess_phase_ranges_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
) -> Array[GpuPreprocessPhaseRange3d] {
  let phase_ranges : Array[GpuPreprocessPhaseRange3d] = []
  if draw_items.length() == 0 {
    return phase_ranges
  }
  let mut current_phase = draw_items[0].phase
  let mut range_start = 0
  for i in 1..<draw_items.length() {
    if draw_items[i].phase == current_phase {
      continue
    }
    phase_ranges.push(GpuPreprocessPhaseRange3d::{
      phase: current_phase,
      start: range_start,
      end: i,
    })
    current_phase = draw_items[i].phase
    range_start = i
  }
  phase_ranges.push(GpuPreprocessPhaseRange3d::{
    phase: current_phase,
    start: range_start,
    end: draw_items.length(),
  })
  phase_ranges
}

///|
fn render3d_empty_gpu_preprocess_indirect_mesh_class_metadata() -> GpuPreprocessIndirectMeshClassMetadata3d {
  let indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ] = []
  let indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ] = []
  let indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d] = []
  GpuPreprocessIndirectMeshClassMetadata3d::{
    indirect_parameters_cpu_metadata,
    indirect_parameters_gpu_metadata,
    indirect_batch_sets,
  }
}

///|
fn render3d_build_gpu_preprocess_indirect_mesh_class_metadata(
  items : Array[GpuPreprocessShaderWorkItem3d],
) -> GpuPreprocessIndirectMeshClassMetadata3d {
  let indirect_parameters_cpu_metadata : Array[
    GpuPreprocessIndirectParametersCpuMetadata3d,
  ] = []
  let indirect_parameters_gpu_metadata : Array[
    GpuPreprocessIndirectParametersGpuMetadata3d,
  ] = []
  let indirect_batch_sets : Array[GpuPreprocessIndirectBatchSet3d] = []
  for item in items {
    let indirect_parameters_index = item.output_or_indirect_parameters_index
    indirect_parameters_cpu_metadata.push(GpuPreprocessIndirectParametersCpuMetadata3d::{
      base_output_index: item.input_index,
      // We currently issue one indirect draw per slot, not multi-draw-count batches.
      batch_set_index: -1,
    })
    indirect_parameters_gpu_metadata.push(GpuPreprocessIndirectParametersGpuMetadata3d::{
      mesh_index: item.input_index,
      early_instance_count: 0,
      late_instance_count: 0,
    })
    indirect_batch_sets.push(GpuPreprocessIndirectBatchSet3d::{
      indirect_parameters_count: 0,
      indirect_parameters_base: indirect_parameters_index,
    })
  }
  GpuPreprocessIndirectMeshClassMetadata3d::{
    indirect_parameters_cpu_metadata,
    indirect_parameters_gpu_metadata,
    indirect_batch_sets,
  }
}

///|
fn render3d_build_gpu_preprocess_indirect_metadata(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> GpuPreprocessIndirectMetadata3d {
  match work_item_buffers {
    Direct(_) =>
      GpuPreprocessIndirectMetadata3d::{
        indexed: render3d_empty_gpu_preprocess_indirect_mesh_class_metadata(),
        non_indexed: render3d_empty_gpu_preprocess_indirect_mesh_class_metadata(),
      }
    Indirect(indexed_items, non_indexed_items, _) =>
      GpuPreprocessIndirectMetadata3d::{
        indexed: render3d_build_gpu_preprocess_indirect_mesh_class_metadata(
          indexed_items,
        ),
        non_indexed: render3d_build_gpu_preprocess_indirect_mesh_class_metadata(
          non_indexed_items,
        ),
      }
  }
}

///|
fn render3d_gpu_preprocess_workgroup_count(item_count : Int) -> Int {
  if item_count <= 0 {
    return 0
  }
  let quotient = item_count / RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE
  if item_count % RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE == 0 {
    quotient
  } else {
    quotient + 1
  }
}

///|
fn render3d_build_gpu_preprocess_dispatch_metadata(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> GpuPreprocessDispatchMetadata3d {
  match work_item_buffers {
    Direct(items) =>
      GpuPreprocessDispatchMetadata3d::{
        direct_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          items.length(),
        ),
        indexed_workgroup_count: 0,
        non_indexed_workgroup_count: 0,
        late_indexed_workgroup_count: 0,
        late_non_indexed_workgroup_count: 0,
      }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      let late_indexed_item_count = match gpu_occlusion_culling {
        Some(culling_buffers) => culling_buffers.late_indexed.length()
        None => 0
      }
      let late_non_indexed_item_count = match gpu_occlusion_culling {
        Some(culling_buffers) => culling_buffers.late_non_indexed.length()
        None => 0
      }
      GpuPreprocessDispatchMetadata3d::{
        direct_workgroup_count: 0,
        indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          indexed_items.length(),
        ),
        non_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          non_indexed_items.length(),
        ),
        late_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          late_indexed_item_count,
        ),
        late_non_indexed_workgroup_count: render3d_gpu_preprocess_workgroup_count(
          late_non_indexed_item_count,
        ),
      }
    }
  }
}

///|
fn render3d_build_gpu_occlusion_culling_work_item_buffers(
  indexed_work_items : Array[GpuPreprocessShaderWorkItem3d],
  non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d],
  enabled : Bool,
) -> GpuOcclusionCullingWorkItemBuffers3d? {
  if !enabled {
    return None
  }
  let late_indexed : Array[GpuPreprocessShaderWorkItem3d] = []
  for item in indexed_work_items {
    late_indexed.push(item)
  }
  let late_non_indexed : Array[GpuPreprocessShaderWorkItem3d] = []
  for item in non_indexed_work_items {
    late_non_indexed.push(item)
  }
  Some(GpuOcclusionCullingWorkItemBuffers3d::{
    late_indexed,
    late_non_indexed,
    late_indirect_parameters_indexed_offset: 0,
    late_indirect_parameters_non_indexed_offset: 0,
  })
}

///|
fn render3d_build_gpu_preprocess_work_item_buffers_from_prequeued_items(
  items : Array[GpuPreprocessPrequeuedMeshItem3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessWorkItemBuffers3d {
  if !indirect_enabled {
    let direct_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
    for i in 0..<items.length() {
      direct_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: i,
      })
    }
    return GpuPreprocessWorkItemBuffers3d::Direct(direct_work_items)
  }
  let indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  let non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  for i in 0..<items.length() {
    if items[i].indexed {
      indexed_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: indexed_work_items.length(),
      })
    } else {
      non_indexed_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: non_indexed_work_items.length(),
      })
    }
  }
  GpuPreprocessWorkItemBuffers3d::Indirect(
    indexed_work_items,
    non_indexed_work_items,
    render3d_build_gpu_occlusion_culling_work_item_buffers(
      indexed_work_items, non_indexed_work_items, gpu_occlusion_culling_enabled,
    ),
  )
}

///|
fn render3d_build_gpu_preprocess_work_item_buffers_from_draw_items(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessWorkItemBuffers3d {
  if !indirect_enabled {
    let direct_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
    for i in 0..<draw_items.length() {
      direct_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: i,
      })
    }
    return GpuPreprocessWorkItemBuffers3d::Direct(direct_work_items)
  }
  let indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  let non_indexed_work_items : Array[GpuPreprocessShaderWorkItem3d] = []
  for i in 0..<draw_items.length() {
    let draw_item = draw_items[i]
    let indexed = if draw_item.extracted_index >= 0 &&
      draw_item.extracted_index < meshes.length() {
      render3d_mesh_handle_is_indexed(
        meshes[draw_item.extracted_index].payload.mesh_handle,
      )
    } else {
      false
    }
    if indexed {
      indexed_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: indexed_work_items.length(),
      })
    } else {
      non_indexed_work_items.push(GpuPreprocessShaderWorkItem3d::{
        input_index: i,
        output_or_indirect_parameters_index: non_indexed_work_items.length(),
      })
    }
  }
  GpuPreprocessWorkItemBuffers3d::Indirect(
    indexed_work_items,
    non_indexed_work_items,
    render3d_build_gpu_occlusion_culling_work_item_buffers(
      indexed_work_items, non_indexed_work_items, gpu_occlusion_culling_enabled,
    ),
  )
}

///|
fn render3d_resolve_prequeued_to_draw_item_indices(
  prequeued_items : Array[GpuPreprocessPrequeuedMeshItem3d],
  draw_items : Array[MeshPhaseItem3d],
) -> Array[Int] {
  let prequeued_to_draw_item_indices : Array[Int] = []
  for prequeued_item in prequeued_items {
    let mut draw_item_index = -1
    for i in 0..<draw_items.length() {
      if phase_entity_ref3d_main_eq(prequeued_item.entity, draw_items[i].entity) {
        draw_item_index = i
        break
      }
    }
    prequeued_to_draw_item_indices.push(draw_item_index)
  }
  prequeued_to_draw_item_indices
}

///|
fn render3d_remap_gpu_preprocess_work_item_buffers_to_resolved_draw_items(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
  prequeued_items : Array[GpuPreprocessPrequeuedMeshItem3d],
  draw_items : Array[MeshPhaseItem3d],
) -> GpuPreprocessWorkItemBuffers3d {
  let prequeued_to_draw_item_indices = render3d_resolve_prequeued_to_draw_item_indices(
    prequeued_items, draw_items,
  )
  let remap_index = fn(index : Int) -> Int {
    if index < 0 || index >= prequeued_to_draw_item_indices.length() {
      return -1
    }
    prequeued_to_draw_item_indices[index]
  }
  match work_item_buffers {
    Direct(items) => {
      let remapped_direct_items : Array[GpuPreprocessShaderWorkItem3d] = []
      for item in items {
        let input_index = remap_index(item.input_index)
        let output_or_indirect_parameters_index = remap_index(
          item.output_or_indirect_parameters_index,
        )
        if input_index < 0 || output_or_indirect_parameters_index < 0 {
          continue
        }
        remapped_direct_items.push(GpuPreprocessShaderWorkItem3d::{
          input_index,
          output_or_indirect_parameters_index,
        })
      }
      GpuPreprocessWorkItemBuffers3d::Direct(remapped_direct_items)
    }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      let remapped_indexed_items : Array[GpuPreprocessShaderWorkItem3d] = []
      for item in indexed_items {
        let input_index = remap_index(item.input_index)
        if input_index < 0 {
          continue
        }
        remapped_indexed_items.push(GpuPreprocessShaderWorkItem3d::{
          input_index,
          output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
        })
      }
      let remapped_non_indexed_items : Array[GpuPreprocessShaderWorkItem3d] = []
      for item in non_indexed_items {
        let input_index = remap_index(item.input_index)
        if input_index < 0 {
          continue
        }
        remapped_non_indexed_items.push(GpuPreprocessShaderWorkItem3d::{
          input_index,
          output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
        })
      }
      let remapped_gpu_occlusion_culling = match gpu_occlusion_culling {
        None => None
        Some(buffers) => {
          let remapped_late_indexed : Array[GpuPreprocessShaderWorkItem3d] = []
          for item in buffers.late_indexed {
            let input_index = remap_index(item.input_index)
            if input_index < 0 {
              continue
            }
            remapped_late_indexed.push(GpuPreprocessShaderWorkItem3d::{
              input_index,
              output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
            })
          }
          let remapped_late_non_indexed : Array[GpuPreprocessShaderWorkItem3d] = []
          for item in buffers.late_non_indexed {
            let input_index = remap_index(item.input_index)
            if input_index < 0 {
              continue
            }
            remapped_late_non_indexed.push(GpuPreprocessShaderWorkItem3d::{
              input_index,
              output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
            })
          }
          Some(GpuOcclusionCullingWorkItemBuffers3d::{
            late_indexed: remapped_late_indexed,
            late_non_indexed: remapped_late_non_indexed,
            late_indirect_parameters_indexed_offset: buffers.late_indirect_parameters_indexed_offset,
            late_indirect_parameters_non_indexed_offset: buffers.late_indirect_parameters_non_indexed_offset,
          })
        }
      }
      GpuPreprocessWorkItemBuffers3d::Indirect(
        remapped_indexed_items, remapped_non_indexed_items, remapped_gpu_occlusion_culling,
      )
    }
  }
}

///|
fn render3d_build_gpu_preprocess_camera_queue_entry(
  camera_entity : @core.Entity,
  mesh_candidates : Array[GpuPreprocessMeshCandidate3d],
  camera_layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessCameraQueueEntry3d {
  let items = render3d_collect_gpu_preprocess_camera_queue_items(
    mesh_candidates, camera_layers, camera_transform,
  )
  let phase_ranges = render3d_build_gpu_preprocess_phase_ranges_from_prequeued_items(
    items,
  )
  let work_item_buffers = render3d_build_gpu_preprocess_work_item_buffers_from_prequeued_items(
    items, indirect_enabled, gpu_occlusion_culling_enabled,
  )
  let indirect_metadata = render3d_build_gpu_preprocess_indirect_metadata(
    work_item_buffers,
  )
  let dispatch_metadata = render3d_build_gpu_preprocess_dispatch_metadata(
    work_item_buffers,
  )
  GpuPreprocessCameraQueueEntry3d::{
    camera_entity,
    items,
    phase_ranges,
    indirect_metadata,
    dispatch_metadata,
    work_item_buffers,
  }
}

///|
fn render3d_resolve_prequeued_mesh_phase_items(
  prequeued_items : Array[GpuPreprocessPrequeuedMeshItem3d],
  meshes : Array[ExtractedMesh3d],
) -> Array[MeshPhaseItem3d] {
  let resolved : Array[MeshPhaseItem3d] = []
  for prequeued_item in prequeued_items {
    let mut extracted_index = -1
    for i in 0..<meshes.length() {
      if phase_entity_ref3d_main_eq(meshes[i].entity, prequeued_item.entity) {
        extracted_index = i
        break
      }
    }
    if extracted_index < 0 {
      continue
    }
    resolved.push(MeshPhaseItem3d::{
      entity: prequeued_item.entity,
      extracted_index,
      phase: prequeued_item.phase,
      distance: prequeued_item.distance,
    })
  }
  resolved
}

///|
fn render3d_make_fallback_gpu_preprocess_queue_entry(
  draw_items : Array[MeshPhaseItem3d],
  meshes : Array[ExtractedMesh3d],
  indirect_enabled : Bool,
  gpu_occlusion_culling_enabled : Bool,
) -> GpuPreprocessResolvedCameraQueueEntry3d {
  let phase_ranges = render3d_build_gpu_preprocess_phase_ranges_from_draw_items(
    draw_items,
  )
  let work_item_buffers = render3d_build_gpu_preprocess_work_item_buffers_from_draw_items(
    draw_items, meshes, indirect_enabled, gpu_occlusion_culling_enabled,
  )
  let indirect_metadata = render3d_build_gpu_preprocess_indirect_metadata(
    work_item_buffers,
  )
  let dispatch_metadata = render3d_build_gpu_preprocess_dispatch_metadata(
    work_item_buffers,
  )
  GpuPreprocessResolvedCameraQueueEntry3d::{
    draw_items,
    phase_ranges,
    indirect_metadata,
    dispatch_metadata,
    work_item_buffers,
  }
}

///|
fn render3d_take_gpu_preprocess_camera_queue_items(
  camera_entity : @core.Entity,
  meshes : Array[ExtractedMesh3d],
) -> GpuPreprocessResolvedCameraQueueEntry3d? {
  for i in 0..<render3d_gpu_preprocess_camera_queues_ref.val.length() {
    let queue_entry = render3d_gpu_preprocess_camera_queues_ref.val[i]
    if queue_entry.camera_entity.id == camera_entity.id &&
      queue_entry.camera_entity.generation == camera_entity.generation {
      render3d_gpu_preprocess_camera_queues_ref.val.remove(i) |> ignore
      let draw_items = render3d_resolve_prequeued_mesh_phase_items(
        queue_entry.items,
        meshes,
      )
      let work_item_buffers = render3d_remap_gpu_preprocess_work_item_buffers_to_resolved_draw_items(
        queue_entry.work_item_buffers,
        queue_entry.items,
        draw_items,
      )
      return Some(GpuPreprocessResolvedCameraQueueEntry3d::{
        draw_items,
        phase_ranges: queue_entry.phase_ranges,
        indirect_metadata: queue_entry.indirect_metadata,
        dispatch_metadata: queue_entry.dispatch_metadata,
        work_item_buffers,
      })
    }
  }
  None
}

///|
fn render3d_gpu_preprocess_opaque_alpha_end_index(
  phase_ranges : Array[GpuPreprocessPhaseRange3d],
) -> Int {
  let mut opaque_alpha_end = 0
  for phase_range in phase_ranges {
    if phase_range.start < 0 {
      continue
    }
    if phase_range.phase != RENDER3D_PHASE_OPAQUE &&
      phase_range.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    if phase_range.end > opaque_alpha_end {
      opaque_alpha_end = phase_range.end
    }
  }
  opaque_alpha_end
}

///|
fn render3d_gpu_preprocess_indirect_mesh_class_metadata_checksum(
  metadata : GpuPreprocessIndirectMeshClassMetadata3d,
) -> Int {
  let mut checksum = 0
  for cpu_metadata in metadata.indirect_parameters_cpu_metadata {
    checksum = checksum +
      cpu_metadata.base_output_index +
      cpu_metadata.batch_set_index
  }
  for gpu_metadata in metadata.indirect_parameters_gpu_metadata {
    checksum = checksum +
      gpu_metadata.mesh_index +
      gpu_metadata.early_instance_count +
      gpu_metadata.late_instance_count
  }
  for batch_set in metadata.indirect_batch_sets {
    checksum = checksum +
      batch_set.indirect_parameters_count +
      batch_set.indirect_parameters_base
  }
  checksum
}

///|
fn render3d_gpu_preprocess_indirect_metadata_checksum(
  metadata : GpuPreprocessIndirectMetadata3d,
) -> Int {
  render3d_gpu_preprocess_indirect_mesh_class_metadata_checksum(
    metadata.indexed,
  ) +
  render3d_gpu_preprocess_indirect_mesh_class_metadata_checksum(
    metadata.non_indexed,
  )
}

///|
fn render3d_gpu_preprocess_work_item_buffers_checksum(
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> Int {
  match work_item_buffers {
    Direct(items) => {
      let mut checksum = 0
      for item in items {
        checksum = checksum +
          item.input_index +
          item.output_or_indirect_parameters_index
      }
      checksum
    }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      let mut checksum = 0
      for item in indexed_items {
        checksum = checksum +
          item.input_index +
          item.output_or_indirect_parameters_index
      }
      for item in non_indexed_items {
        checksum = checksum +
          item.input_index +
          item.output_or_indirect_parameters_index
      }
      if gpu_occlusion_culling is Some(culling_buffers) {
        checksum = checksum +
          culling_buffers.late_indirect_parameters_indexed_offset +
          culling_buffers.late_indirect_parameters_non_indexed_offset
        for item in culling_buffers.late_indexed {
          checksum = checksum +
            item.input_index +
            item.output_or_indirect_parameters_index
        }
        for item in culling_buffers.late_non_indexed {
          checksum = checksum +
            item.input_index +
            item.output_or_indirect_parameters_index
        }
      }
      checksum
    }
  }
}

///|
fn render3d_gpu_preprocess_dispatch_metadata_checksum(
  metadata : GpuPreprocessDispatchMetadata3d,
) -> Int {
  metadata.direct_workgroup_count +
  metadata.indexed_workgroup_count +
  metadata.non_indexed_workgroup_count +
  metadata.late_indexed_workgroup_count +
  metadata.late_non_indexed_workgroup_count
}

///|
fn render3d_host_preprocess_shader_work_item(
  item : GpuPreprocessShaderWorkItem3d,
) -> @render.HostMesh3dPreprocessShaderWorkItem {
  @render.HostMesh3dPreprocessShaderWorkItem::{
    input_index: item.input_index,
    output_or_indirect_parameters_index: item.output_or_indirect_parameters_index,
  }
}

///|
fn render3d_host_preprocess_cpu_metadata(
  metadata : GpuPreprocessIndirectParametersCpuMetadata3d,
) -> @render.HostMesh3dPreprocessIndirectParametersCpuMetadata {
  @render.HostMesh3dPreprocessIndirectParametersCpuMetadata::{
    base_output_index: metadata.base_output_index,
    batch_set_index: metadata.batch_set_index,
  }
}

///|
fn render3d_host_preprocess_gpu_metadata(
  metadata : GpuPreprocessIndirectParametersGpuMetadata3d,
) -> @render.HostMesh3dPreprocessIndirectParametersGpuMetadata {
  @render.HostMesh3dPreprocessIndirectParametersGpuMetadata::{
    mesh_index: metadata.mesh_index,
    early_instance_count: metadata.early_instance_count,
    late_instance_count: metadata.late_instance_count,
  }
}

///|
fn render3d_host_preprocess_batch_set(
  batch_set : GpuPreprocessIndirectBatchSet3d,
) -> @render.HostMesh3dPreprocessIndirectBatchSet {
  @render.HostMesh3dPreprocessIndirectBatchSet::{
    indirect_parameters_count: batch_set.indirect_parameters_count,
    indirect_parameters_base: batch_set.indirect_parameters_base,
  }
}

///|
fn render3d_host_preprocess_view_frustum_planes(
  projection : Projection,
  camera_transform : @transform.Transform,
) -> Array[@render.HostMesh3dPreprocessFrustumPlane] {
  let planes : Array[@render.HostMesh3dPreprocessFrustumPlane] = []
  for half_space in projection.compute_frustum(camera_transform).half_spaces {
    let normal_d = half_space.normal_d
    planes.push(@render.HostMesh3dPreprocessFrustumPlane::{
      normal_x: normal_d.x,
      normal_y: normal_d.y,
      normal_z: normal_d.z,
      distance: normal_d.w,
    })
  }
  planes
}

///|
fn render3d_host_preprocess_view(
  projection : Projection,
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> @render.HostMesh3dPreprocessView {
  let clip_from_world = render3d_pass_projection_clip_from_world(
    pass_projection, camera_transform,
  )
  let unjittered_clip_from_world = render3d_pass_projection_unjittered_clip_from_world(
    pass_projection, camera_transform,
  )
  let view_from_world = render3d_view_from_world_matrix(camera_transform)
  let world_from_view = render3d_world_from_view_matrix(camera_transform)
  let world_from_clip = match
    render3d_projection_matrix_inverse(clip_from_world) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  let view_from_clip = match
    render3d_projection_matrix_inverse(pass_projection.clip_from_view) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  @render.HostMesh3dPreprocessView::{
    clip_from_world: render3d_host_gpu_clip_matrix(clip_from_world),
    unjittered_clip_from_world: render3d_host_gpu_clip_matrix(
      unjittered_clip_from_world,
    ),
    world_from_clip: render3d_host_gpu_clip_matrix(world_from_clip),
    world_from_view: render3d_host_gpu_clip_matrix(world_from_view),
    view_from_world: render3d_host_gpu_clip_matrix(view_from_world),
    clip_from_view: render3d_host_gpu_clip_matrix(
      pass_projection.clip_from_view,
    ),
    view_from_clip: render3d_host_gpu_clip_matrix(view_from_clip),
    world_position_x: camera_transform.translation.x,
    world_position_y: camera_transform.translation.y,
    world_position_z: camera_transform.translation.z,
    exposure: camera_exposure_value,
    viewport_x: Float::from_double(viewport_x.to_double()),
    viewport_y: Float::from_double(viewport_y.to_double()),
    viewport_width: Float::from_double(viewport_width.to_double()),
    viewport_height: Float::from_double(viewport_height.to_double()),
    main_pass_viewport_x: Float::from_double(viewport_x.to_double()),
    main_pass_viewport_y: Float::from_double(viewport_y.to_double()),
    main_pass_viewport_width: Float::from_double(viewport_width.to_double()),
    main_pass_viewport_height: Float::from_double(viewport_height.to_double()),
    frustum_planes: render3d_host_preprocess_view_frustum_planes(
      projection, camera_transform,
    ),
    mip_bias: 0.0F,
  }
}

///|
fn render3d_projection_matrix_identity() -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn render3d_host_preprocess_previous_view(
  pass_projection : Render3dPassProjection,
  previous_transform : @transform.Transform,
  previous_clip_from_world : ProjectionMatrix3d?,
) -> @render.HostMesh3dPreprocessPreviousView {
  let resolved_previous_view_from_world = render3d_view_from_world_matrix(
    previous_transform,
  )
  let resolved_previous_clip_from_world = match previous_clip_from_world {
    Some(value) => value
    None =>
      render3d_pass_projection_clip_from_world(
        pass_projection, previous_transform,
      )
  }
  let resolved_previous_world_from_clip = match
    render3d_projection_matrix_inverse(resolved_previous_clip_from_world) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  let resolved_previous_world_from_view = render3d_world_from_view_matrix(
    previous_transform,
  )
  let resolved_previous_clip_from_view = resolved_previous_clip_from_world.mul(
    resolved_previous_world_from_view,
  )
  let resolved_previous_view_from_clip = match
    render3d_projection_matrix_inverse(resolved_previous_clip_from_view) {
    Some(value) => value
    None => render3d_projection_matrix_identity()
  }
  @render.HostMesh3dPreprocessPreviousView::{
    view_from_world: render3d_host_gpu_clip_matrix(
      resolved_previous_view_from_world,
    ),
    clip_from_world: render3d_host_gpu_clip_matrix(
      resolved_previous_clip_from_world,
    ),
    clip_from_view: render3d_host_gpu_clip_matrix(
      resolved_previous_clip_from_view,
    ),
    world_from_clip: render3d_host_gpu_clip_matrix(
      resolved_previous_world_from_clip,
    ),
    view_from_clip: render3d_host_gpu_clip_matrix(
      resolved_previous_view_from_clip,
    ),
  }
}

///|
fn render3d_host_preprocess_mesh_culling_data(
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
) -> @render.HostMesh3dPreprocessMeshCullingData {
  if draw_item.extracted_index < 0 ||
    draw_item.extracted_index >= meshes.length() {
    return @render.HostMesh3dPreprocessMeshCullingData::{
      aabb_center_x: 0.0F,
      aabb_center_y: 0.0F,
      aabb_center_z: 0.0F,
      aabb_half_extents_x: 0.0F,
      aabb_half_extents_y: 0.0F,
      aabb_half_extents_z: 0.0F,
    }
  }
  let mesh = meshes[draw_item.extracted_index].payload
  match render3d_mesh_handle_local_aabb(mesh.mesh_handle) {
    Some((min_corner, max_corner)) => {
      let center = @math.Vec3::new(
        (min_corner.x + max_corner.x) * 0.5F,
        (min_corner.y + max_corner.y) * 0.5F,
        (min_corner.z + max_corner.z) * 0.5F,
      )
      let half_extents = @math.Vec3::new(
        (max_corner.x - min_corner.x) * 0.5F,
        (max_corner.y - min_corner.y) * 0.5F,
        (max_corner.z - min_corner.z) * 0.5F,
      )
      @render.HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: center.x,
        aabb_center_y: center.y,
        aabb_center_z: center.z,
        aabb_half_extents_x: half_extents.x,
        aabb_half_extents_y: half_extents.y,
        aabb_half_extents_z: half_extents.z,
      }
    }
    None =>
      @render.HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: 0.0F,
        aabb_center_y: 0.0F,
        aabb_center_z: 0.0F,
        aabb_half_extents_x: 0.0F,
        aabb_half_extents_y: 0.0F,
        aabb_half_extents_z: 0.0F,
      }
  }
}

///|
fn render3d_mesh_handle_preprocess_counts(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> (Int, Int, Int) {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          let first_vertex_index = 0
          let first_index_index = 0
          let index_count = match geometry3d.indices {
            Some(indices) => indices.length()
            None => geometry3d.positions.length()
          }
          (first_vertex_index, first_index_index, index_count)
        }
        _ => (0, 0, 0)
      }
    None => (0, 0, 0)
  }
}

///|
fn render3d_mesh_handle_local_aabb(
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> (@math.Vec3, @math.Vec3)? {
  match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) =>
      match mesh_asset.geometry {
        @mesh.MeshGeometry::Geometry3d(geometry3d) => {
          guard geometry3d.positions.length() > 0 else { return None }
          let mut min_x = geometry3d.positions[0].x
          let mut min_y = geometry3d.positions[0].y
          let mut min_z = geometry3d.positions[0].z
          let mut max_x = geometry3d.positions[0].x
          let mut max_y = geometry3d.positions[0].y
          let mut max_z = geometry3d.positions[0].z
          for i in 1..<geometry3d.positions.length() {
            let p = geometry3d.positions[i]
            min_x = minf(min_x, p.x)
            min_y = minf(min_y, p.y)
            min_z = minf(min_z, p.z)
            max_x = maxf(max_x, p.x)
            max_y = maxf(max_y, p.y)
            max_z = maxf(max_z, p.z)
          }
          Some(
            (
              @math.Vec3::new(min_x, min_y, min_z),
              @math.Vec3::new(max_x, max_y, max_z),
            ),
          )
        }
        _ => None
      }
    None => None
  }
}

///|
fn render3d_host_gpu_clip_matrix(
  matrix : ProjectionMatrix3d,
) -> @render.HostGpuClipMatrix {
  @render.host_gpu_clip_matrix(
    matrix.x_axis.x,
    matrix.x_axis.y,
    matrix.x_axis.z,
    matrix.x_axis.w,
    matrix.y_axis.x,
    matrix.y_axis.y,
    matrix.y_axis.z,
    matrix.y_axis.w,
    matrix.z_axis.x,
    matrix.z_axis.y,
    matrix.z_axis.z,
    matrix.z_axis.w,
    matrix.w_axis.x,
    matrix.w_axis.y,
    matrix.w_axis.z,
    matrix.w_axis.w,
  )
}

///|
fn render3d_world_from_view_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let x_axis = quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(transform.scale.x, 0.0F, 0.0F),
  )
  let y_axis = quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(0.0F, transform.scale.y, 0.0F),
  )
  let z_axis = quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(0.0F, 0.0F, transform.scale.z),
  )
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(
      transform.translation.x,
      transform.translation.y,
      transform.translation.z,
      1.0F,
    ),
  )
}

///|
fn render3d_host_preprocess_mesh_input(
  draw_item : MeshPhaseItem3d,
  meshes : Array[ExtractedMesh3d],
) -> @render.HostMesh3dPreprocessMeshInput {
  if draw_item.extracted_index < 0 ||
    draw_item.extracted_index >= meshes.length() {
    return @render.HostMesh3dPreprocessMeshInput::{
      translation_x: 0.0F,
      translation_y: 0.0F,
      translation_z: 0.0F,
      rotation_x: 0.0F,
      rotation_y: 0.0F,
      rotation_z: 0.0F,
      rotation_w: 1.0F,
      scale_x: 1.0F,
      scale_y: 1.0F,
      scale_z: 1.0F,
      previous_translation_x: 0.0F,
      previous_translation_y: 0.0F,
      previous_translation_z: 0.0F,
      previous_rotation_x: 0.0F,
      previous_rotation_y: 0.0F,
      previous_rotation_z: 0.0F,
      previous_rotation_w: 1.0F,
      previous_scale_x: 1.0F,
      previous_scale_y: 1.0F,
      previous_scale_z: 1.0F,
      flags: 0U,
      first_vertex_index: 0,
      first_index_index: 0,
      index_count: 0,
      tag: 0,
    }
  }
  let mesh = meshes[draw_item.extracted_index].payload
  let (first_vertex_index, first_index_index, index_count) = render3d_mesh_handle_preprocess_counts(
    mesh.mesh_handle,
  )
  let flags = if render3d_mesh_handle_local_aabb(mesh.mesh_handle) is Some(_) {
    0U
  } else {
    @render.MESH3D_PREPROCESS_INPUT_FLAG_NO_FRUSTUM_CULLING
  }
  @render.HostMesh3dPreprocessMeshInput::{
    translation_x: mesh.transform.translation.x,
    translation_y: mesh.transform.translation.y,
    translation_z: mesh.transform.translation.z,
    rotation_x: mesh.transform.rotation.x,
    rotation_y: mesh.transform.rotation.y,
    rotation_z: mesh.transform.rotation.z,
    rotation_w: mesh.transform.rotation.w,
    scale_x: mesh.transform.scale.x,
    scale_y: mesh.transform.scale.y,
    scale_z: mesh.transform.scale.z,
    previous_translation_x: mesh.previous_transform.translation.x,
    previous_translation_y: mesh.previous_transform.translation.y,
    previous_translation_z: mesh.previous_transform.translation.z,
    previous_rotation_x: mesh.previous_transform.rotation.x,
    previous_rotation_y: mesh.previous_transform.rotation.y,
    previous_rotation_z: mesh.previous_transform.rotation.z,
    previous_rotation_w: mesh.previous_transform.rotation.w,
    previous_scale_x: mesh.previous_transform.scale.x,
    previous_scale_y: mesh.previous_transform.scale.y,
    previous_scale_z: mesh.previous_transform.scale.z,
    flags,
    first_vertex_index,
    first_index_index,
    index_count,
    tag: draw_item.extracted_index,
  }
}

///|
fn render3d_host_preprocess_camera_payload(
  queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  camera : Camera3dViewPayload,
  pass_projection : Render3dPassProjection,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_exposure_value : Float,
) -> @render.HostMesh3dPreprocessCameraPayload {
  let view = render3d_host_preprocess_view(
    camera.projection,
    pass_projection,
    camera.transform,
    viewport_x,
    viewport_y,
    viewport_width,
    viewport_height,
    camera_exposure_value,
  )
  let previous_view = render3d_host_preprocess_previous_view(
    pass_projection,
    camera.previous_transform,
    camera.previous_clip_from_world,
  )
  let mesh_culling_data : Array[@render.HostMesh3dPreprocessMeshCullingData] = []
  let mesh_inputs : Array[@render.HostMesh3dPreprocessMeshInput] = []
  for draw_item in queue_entry.draw_items {
    mesh_culling_data.push(
      render3d_host_preprocess_mesh_culling_data(draw_item, meshes),
    )
    mesh_inputs.push(render3d_host_preprocess_mesh_input(draw_item, meshes))
  }
  let direct_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let indexed_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let non_indexed_work_items : Array[@render.HostMesh3dPreprocessShaderWorkItem] = []
  let late_indexed_work_items : Array[
    @render.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  let late_non_indexed_work_items : Array[
    @render.HostMesh3dPreprocessShaderWorkItem,
  ] = []
  match queue_entry.work_item_buffers {
    Direct(items) =>
      for item in items {
        direct_work_items.push(render3d_host_preprocess_shader_work_item(item))
      }
    Indirect(indexed_items, non_indexed_items, gpu_occlusion_culling) => {
      for item in indexed_items {
        indexed_work_items.push(render3d_host_preprocess_shader_work_item(item))
      }
      for item in non_indexed_items {
        non_indexed_work_items.push(
          render3d_host_preprocess_shader_work_item(item),
        )
      }
      if gpu_occlusion_culling is Some(culling) {
        for item in culling.late_indexed {
          late_indexed_work_items.push(
            render3d_host_preprocess_shader_work_item(item),
          )
        }
        for item in culling.late_non_indexed {
          late_non_indexed_work_items.push(
            render3d_host_preprocess_shader_work_item(item),
          )
        }
      }
    }
  }
  let indexed_cpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.indexed.indirect_parameters_cpu_metadata {
    indexed_cpu_metadata.push(render3d_host_preprocess_cpu_metadata(metadata))
  }
  let indexed_gpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.indexed.indirect_parameters_gpu_metadata {
    indexed_gpu_metadata.push(render3d_host_preprocess_gpu_metadata(metadata))
  }
  let indexed_batch_sets : Array[@render.HostMesh3dPreprocessIndirectBatchSet] = []
  for batch_set in queue_entry.indirect_metadata.indexed.indirect_batch_sets {
    indexed_batch_sets.push(render3d_host_preprocess_batch_set(batch_set))
  }
  let non_indexed_cpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.non_indexed.indirect_parameters_cpu_metadata {
    non_indexed_cpu_metadata.push(
      render3d_host_preprocess_cpu_metadata(metadata),
    )
  }
  let non_indexed_gpu_metadata : Array[
    @render.HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ] = []
  for
    metadata in queue_entry.indirect_metadata.non_indexed.indirect_parameters_gpu_metadata {
    non_indexed_gpu_metadata.push(
      render3d_host_preprocess_gpu_metadata(metadata),
    )
  }
  let non_indexed_batch_sets : Array[
    @render.HostMesh3dPreprocessIndirectBatchSet,
  ] = []
  for batch_set in queue_entry.indirect_metadata.non_indexed.indirect_batch_sets {
    non_indexed_batch_sets.push(render3d_host_preprocess_batch_set(batch_set))
  }
  let dispatch_metadata = @render.HostMesh3dPreprocessDispatchMetadata::{
    direct_workgroup_count: queue_entry.dispatch_metadata.direct_workgroup_count,
    indexed_workgroup_count: queue_entry.dispatch_metadata.indexed_workgroup_count,
    non_indexed_workgroup_count: queue_entry.dispatch_metadata.non_indexed_workgroup_count,
    late_indexed_workgroup_count: queue_entry.dispatch_metadata.late_indexed_workgroup_count,
    late_non_indexed_workgroup_count: queue_entry.dispatch_metadata.late_non_indexed_workgroup_count,
  }
  @render.HostMesh3dPreprocessCameraPayload::{
    view,
    previous_view,
    mesh_culling_data,
    mesh_inputs,
    direct_work_items,
    indexed_work_items,
    non_indexed_work_items,
    late_indexed_work_items,
    late_non_indexed_work_items,
    indexed_cpu_metadata,
    indexed_gpu_metadata,
    indexed_batch_sets,
    non_indexed_cpu_metadata,
    non_indexed_gpu_metadata,
    non_indexed_batch_sets,
    dispatch_metadata,
  }
}

///|
fn render3d_gpu_preprocess_opaque_alpha_draw_item_indices(
  draw_items : Array[MeshPhaseItem3d],
  phase_ranges : Array[GpuPreprocessPhaseRange3d],
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> Array[Int] {
  let opaque_alpha_end_index_raw = render3d_gpu_preprocess_opaque_alpha_end_index(
    phase_ranges,
  )
  let opaque_alpha_end_index = if opaque_alpha_end_index_raw >
    draw_items.length() {
    draw_items.length()
  } else {
    opaque_alpha_end_index_raw
  }
  let indices : Array[Int] = []
  let push_if_valid = fn(index : Int) {
    if index < 0 || index >= opaque_alpha_end_index {
      return
    }
    if draw_items[index].phase == RENDER3D_PHASE_OPAQUE ||
      draw_items[index].phase == RENDER3D_PHASE_ALPHA_MASK {
      indices.push(index)
    }
  }
  match work_item_buffers {
    Direct(items) =>
      for item in items {
        push_if_valid(item.output_or_indirect_parameters_index)
      }
    Indirect(indexed_items, non_indexed_items, _) => {
      for item in indexed_items {
        push_if_valid(item.input_index)
      }
      for item in non_indexed_items {
        push_if_valid(item.input_index)
      }
    }
  }
  if indices.length() > 0 {
    return indices
  }
  for i in 0..<opaque_alpha_end_index {
    if draw_items[i].phase == RENDER3D_PHASE_OPAQUE ||
      draw_items[i].phase == RENDER3D_PHASE_ALPHA_MASK {
      indices.push(i)
    }
  }
  indices
}

///|
fn render3d_gpu_preprocess_indirect_parameter_index_maps(
  draw_items : Array[MeshPhaseItem3d],
  work_item_buffers : GpuPreprocessWorkItemBuffers3d,
) -> (Array[Int], Array[Int]) {
  let indexed : Array[Int] = []
  let non_indexed : Array[Int] = []
  for _ in draw_items {
    indexed.push(-1)
    non_indexed.push(-1)
  }
  match work_item_buffers {
    Direct(_) => ()
    Indirect(indexed_items, non_indexed_items, _) => {
      for item in indexed_items {
        if item.input_index >= 0 && item.input_index < indexed.length() {
          indexed[item.input_index] = item.output_or_indirect_parameters_index
        }
      }
      for item in non_indexed_items {
        if item.input_index >= 0 && item.input_index < non_indexed.length() {
          non_indexed[item.input_index] = item.output_or_indirect_parameters_index
        }
      }
    }
  }
  (indexed, non_indexed)
}

///|
fn render3d_queue_mesh_phase_items_gpu_builder(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
) -> Array[MeshPhaseItem3d] {
  // Keep the same high-level architecture as Bevy's GPU preprocessing path:
  // collect mesh work items, then write batched instance work payloads.
  let work_items = render3d_collect_meshes_for_gpu_building(
    meshes, layers, camera_transform,
  )
  render3d_write_batched_instance_buffers(work_items)
}

///|
fn render3d_queue_mesh_phase_items(
  meshes : Array[ExtractedMesh3d],
  layers : @sprite.RenderLayers,
  camera_transform : @transform.Transform,
  use_gpu_instance_buffer_builder : Bool,
) -> Array[MeshPhaseItem3d] {
  if use_gpu_instance_buffer_builder {
    return render3d_queue_mesh_phase_items_gpu_builder(
      meshes, layers, camera_transform,
    )
  }
  render3d_queue_mesh_phase_items_cpu_builder(meshes, layers, camera_transform)
}

///|
fn free_camera_angles_from_transform(
  transform : @transform.Transform,
) -> (Float, Float) {
  let forward = render3d_transform_forward(transform)
  let horizontal = @math.sqrt(forward.x * forward.x + forward.z * forward.z)
  let pitch = @math.atan2(forward.y, horizontal)
  let yaw = @math.atan2(-forward.x, -forward.z)
  (yaw, pitch)
}

///|
fn free_camera_clamp_pitch(pitch : Float) -> Float {
  let half_pi = @math.pi_half()
  if pitch < -half_pi {
    -half_pi
  } else if pitch > half_pi {
    half_pi
  } else {
    pitch
  }
}

///|
fn free_camera_exp_decay(rate : Float, delta_seconds : Float) -> Float {
  if rate <= 0.0F || delta_seconds <= 0.0F {
    return 1.0F
  }
  @math.pow(2.718281828459045F, -rate * delta_seconds)
}

///|
pub fn run_freecamera_controller(world : @ecs.World) -> Unit {
  let delta_seconds = render3d_default_time_or_default(world).delta_seconds()
  let camera_store = world.component(@sprite.ecs_key_camera)
  let transform_store = world.component(@transform.ecs_key_transform)
  let free_camera_store = world.component(ecs_key_free_camera)
  let free_camera_state_store = get_free_camera_state_store(world)
  let mut system_state = free_camera_system_state.val

  let controlled_entities : Array[@core.Entity] = []
  free_camera_store.for_each(fn(entity, _config) {
    if camera_store.get(entity) is None || transform_store.get(entity) is None {
      return
    }
    controlled_entities.push(entity)
  })
  if controlled_entities.length() != 1 {
    return
  }
  let controlled_entity = controlled_entities[0]

  guard free_camera_store.get(controlled_entity) is Some(config) else { return }
  guard transform_store.get(controlled_entity) is Some(initial_transform) else {
    return
  }
  let mut transform = initial_transform
  let mut state = match free_camera_state_store.get(controlled_entity) {
    Some(existing) => existing
    None => {
      let default_state = FreeCameraState::default()
      free_camera_state_store.insert(controlled_entity, default_state)
      default_state
    }
  }

  if !state.initialized {
    let (yaw, pitch) = free_camera_angles_from_transform(transform)
    state = FreeCameraState::{ ..state, initialized: true, pitch, yaw }
  }

  if !state.enabled {
    if system_state.toggle_cursor_grab || system_state.mouse_cursor_grab {
      system_state = FreeCameraSystemState::{
        toggle_cursor_grab: false,
        mouse_cursor_grab: false,
        last_mouse_position: None,
      }
      @window.window_set_cursor_grab_mode(mode=@window.CursorGrabMode::GrabNone)
      @window.window_set_cursor_visible(visible=true)
    }
    free_camera_system_state.val = system_state
    free_camera_state_store.set(controlled_entity, state) |> ignore
    return
  }

  let wheel = @input.mouse_wheel_delta()
  let mut speed_multiplier = state.speed_multiplier +
    wheel.y * config.scroll_factor
  if speed_multiplier < 0.0F {
    speed_multiplier = 0.0F
  }
  state = FreeCameraState::{ ..state, speed_multiplier, }

  let mut axis_input = @math.Vec3::zero()
  if @input.key_pressed(config.key_forward) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  }
  if @input.key_pressed(config.key_back) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }
  if @input.key_pressed(config.key_right) {
    axis_input = axis_input.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  }
  if @input.key_pressed(config.key_left) {
    axis_input = axis_input.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }
  if @input.key_pressed(config.key_up) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if @input.key_pressed(config.key_down) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }

  let mut cursor_grab_change = false
  if @input.key_just_pressed(config.keyboard_key_toggle_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      toggle_cursor_grab: !system_state.toggle_cursor_grab,
    }
    cursor_grab_change = true
  }
  if @input.mouse_button_just_pressed(config.mouse_key_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      mouse_cursor_grab: true,
    }
    cursor_grab_change = true
  }
  if @input.mouse_button_just_released(config.mouse_key_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      mouse_cursor_grab: false,
    }
    cursor_grab_change = true
  }
  let cursor_grab = system_state.toggle_cursor_grab ||
    system_state.mouse_cursor_grab

  let mut velocity = state.velocity
  if axis_input.length_squared() > 0.0F {
    let base_speed = if @input.key_pressed(config.key_run) {
      config.run_speed
    } else {
      config.walk_speed
    }
    velocity = axis_input
      .normalize_or_zero()
      .mul_scalar(base_speed * state.speed_multiplier)
  } else {
    let friction = if config.friction < 0.0F { 0.0F } else { config.friction }
    let decay = free_camera_exp_decay(friction, delta_seconds)
    velocity = velocity.mul_scalar(decay)
    if velocity.length_squared() < 1.0e-6F {
      velocity = @math.Vec3::zero()
    }
  }
  state = FreeCameraState::{ ..state, velocity, }

  if velocity.length_squared() > 0.0F {
    let forward = render3d_transform_forward(transform)
    let right = quat_rotate_vec3(
      transform.rotation,
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
    ).normalize_or_zero()
    let movement = right
      .mul_scalar(velocity.x * delta_seconds)
      .add(
        @math.Vec3::new(0.0F, 1.0F, 0.0F).mul_scalar(velocity.y * delta_seconds),
      )
      .add(forward.mul_scalar(velocity.z * delta_seconds))
    transform = transform.with_translation(transform.translation.add(movement))
  }

  if cursor_grab_change {
    if cursor_grab {
      @window.window_set_cursor_grab_mode(
        mode=@window.CursorGrabMode::GrabLocked,
      )
      @window.window_set_cursor_visible(visible=false)
    } else {
      @window.window_set_cursor_grab_mode(mode=@window.CursorGrabMode::GrabNone)
      @window.window_set_cursor_visible(visible=true)
    }
  }

  if cursor_grab {
    match @input.mouse_position() {
      Some(mouse_position) => {
        let mouse_delta = match system_state.last_mouse_position {
          Some(last_position) => mouse_position.sub(last_position)
          None => @math.Vec2::new(0.0F, 0.0F)
        }
        system_state = FreeCameraSystemState::{
          ..system_state,
          last_mouse_position: Some(mouse_position),
        }
        if mouse_delta.x != 0.0F || mouse_delta.y != 0.0F {
          let pitch = free_camera_clamp_pitch(
            state.pitch -
            mouse_delta.y * FREE_CAMERA_RADIANS_PER_DOT * config.sensitivity,
          )
          let yaw = state.yaw -
            mouse_delta.x * FREE_CAMERA_RADIANS_PER_DOT * config.sensitivity
          let rotation = @math.Quat::from_rotation_y(yaw)
            .mul(@math.Quat::from_rotation_x(pitch))
            .normalize()
          transform = transform.with_rotation(rotation)
          state = FreeCameraState::{ ..state, pitch, yaw }
        }
      }
      None =>
        system_state = FreeCameraSystemState::{
          ..system_state,
          last_mouse_position: None,
        }
    }
  } else {
    system_state = FreeCameraSystemState::{
      ..system_state,
      last_mouse_position: None,
    }
  }

  free_camera_system_state.val = system_state
  transform_store.set(controlled_entity, transform) |> ignore
  free_camera_state_store.set(controlled_entity, state) |> ignore
}

///|
pub fn free_camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_pre_update_system(run_freecamera_controller)
}

///|
fn render3d_sorted_camera_entities(world : @ecs.World) -> Array[@core.Entity] {
  let camera3d_store = world.component(ecs_key_camera3d)
  let camera_store = world.component(@sprite.ecs_key_camera)
  let entries : Array[Render3dCameraOrderEntry] = []
  camera3d_store.for_each(fn(entity, _camera3d) {
    let order = match camera_store.get(entity) {
      Some(camera) => camera.order
      None => @sprite.Camera::default().order
    }
    entries.push(Render3dCameraOrderEntry::{ entity, order })
  })
  entries.sort_by(fn(a, b) {
    let order_cmp = cmp_int(a.order, b.order)
    if order_cmp != 0 {
      return order_cmp
    }
    let id_cmp = cmp_int(a.entity.id, b.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(a.entity.generation, b.entity.generation)
  })
  let sorted : Array[@core.Entity] = []
  for entry in entries {
    sorted.push(entry.entity)
  }
  sorted
}

///|
fn render3d_prepared_camera_phase_items(
  cameras : Array[ExtractedCamera3d],
) -> Array[CameraPhaseItem3d]? {
  let prepared = render3d_prepared_camera_order_ref.val
  if prepared.length() != cameras.length() {
    return None
  }
  let items : Array[CameraPhaseItem3d] = []
  for entity in prepared {
    let mut found_index = -1
    for i in 0..<cameras.length() {
      let camera = cameras[i]
      if camera.entity.main_entity.id == entity.id &&
        camera.entity.main_entity.generation == entity.generation {
        found_index = i
        break
      }
    }
    if found_index < 0 {
      return None
    }
    let camera = cameras[found_index]
    items.push(CameraPhaseItem3d::{
      entity: camera.entity,
      extracted_index: found_index,
      order: camera.payload.camera.order,
    })
  }
  Some(items)
}

///|
pub fn render3d_extract_system(world : @ecs.World) -> Unit {
  render3d_prepared_camera_order_ref.val = render3d_sorted_camera_entities(
    world,
  )
  render3d_gpu_preprocess_camera_queues_ref.val.clear()
  render3d_diagnostic_prepared_camera_count_ref.val = render3d_prepared_camera_order_ref.val.length()
  render3d_queued_visible_mesh_count_ref.val = 0
  render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
}

///|
pub fn render3d_prepare_system(world : @ecs.World) -> Unit {
  let mesh_store = world.component(ecs_key_mesh3d)
  let gpu_mesh_store = world.component(@sprite.ecs_key_gpu_mesh2d)
  mesh_store.for_each(fn(entity, mesh) {
    if gpu_mesh_store.get(entity) is Some(_) {
      return
    }
    let mesh_id = @sprite_render.render2d_upload_mesh_handle(mesh.mesh)
    gpu_mesh_store.insert(entity, @sprite.GpuMesh2d::new(mesh_id))
  })
  if render3d_prepared_camera_order_ref.val.length() == 0 {
    render3d_prepared_camera_order_ref.val = render3d_sorted_camera_entities(
      world,
    )
  }
}

///|
pub fn render3d_queue_system(world : @ecs.World) -> Unit {
  render3d_gpu_preprocess_camera_queues_ref.val.clear()
  if render3d_prepared_camera_order_ref.val.length() == 0 {
    render3d_queued_visible_mesh_count_ref.val = 0
    render3d_diagnostic_queued_visible_mesh_count_ref.val = 0
    return
  }
  let mesh_store = world.component(ecs_key_mesh3d)
  let view_visibility_store = world.component(
    @visibility.ecs_key_view_visibility,
  )
  let layers_store = world.component(@sprite.ecs_key_render_layers)
  let no_indirect_drawing_store = world.component(ecs_key_no_indirect_drawing)
  let occlusion_culling_store = world.component(ecs_key_occlusion_culling)
  let transform_store = world.component(@transform.ecs_key_transform)
  let mut visible_mesh_count = 0
  mesh_store.for_each(fn(entity, _mesh3d) {
    if view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    visible_mesh_count = visible_mesh_count + 1
  })
  render3d_queued_visible_mesh_count_ref.val = visible_mesh_count
  render3d_diagnostic_queued_visible_mesh_count_ref.val = visible_mesh_count
  let runtime_config = render3d_runtime_config_or_default(world)
  let indirect_first_instance_supported = render3d_indirect_first_instance_supported()
  if !runtime_config.use_gpu_instance_buffer_builder {
    return
  }
  let mesh_candidates = render3d_collect_gpu_preprocess_mesh_candidates(world)
  for prepared_camera in render3d_prepared_camera_order_ref.val {
    let camera_entity = prepared_camera
    let camera_layers = match layers_store.get(camera_entity) {
      Some(value) => value
      None => @sprite.RenderLayers::default()
    }
    let camera_transform = match transform_store.get(camera_entity) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    let no_indirect_drawing = no_indirect_drawing_store.get(camera_entity)
      is Some(_)
    let camera_indirect_enabled = render3d_camera_indirect_enabled(
      runtime_config.use_gpu_instance_buffer_builder,
      indirect_first_instance_supported,
      no_indirect_drawing,
    )
    let gpu_occlusion_culling_enabled = camera_indirect_enabled &&
      occlusion_culling_store.get(camera_entity) is Some(_)
    render3d_gpu_preprocess_camera_queues_ref.val.push(
      render3d_build_gpu_preprocess_camera_queue_entry(
        camera_entity, mesh_candidates, camera_layers, camera_transform, camera_indirect_enabled,
        gpu_occlusion_culling_enabled,
      ),
    )
  }
}

///|
pub fn render3d_diagnostic_queued_visible_mesh_count() -> Int {
  render3d_diagnostic_queued_visible_mesh_count_ref.val
}

///|
pub fn render3d_diagnostic_prepared_camera_count() -> Int {
  render3d_diagnostic_prepared_camera_count_ref.val
}

///|
pub fn render3d_prepared_camera_count() -> Int? {
  if !render3d_runtime_initialized_ref.val {
    return Some(0)
  }
  Some(render3d_prepared_camera_order_ref.val.length())
}

///|
pub fn render3d_queued_visible_mesh_count() -> Int? {
  if !render3d_runtime_initialized_ref.val {
    return Some(0)
  }
  Some(render3d_queued_visible_mesh_count_ref.val)
}

///|
fn render3d_begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
  secondary_target_id? : Int = -1,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_transform : @transform.Transform,
  pass_projection : Render3dPassProjection,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  lighting : Render3dLightingState,
  camera_exposure? : Float = 1.0F,
  previous_clip_from_world~ : ProjectionMatrix3d?,
  point_shadow_near~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  let clip_from_world = render3d_pass_projection_clip_from_world(
    pass_projection, camera_transform,
  )
  let unjittered_clip_from_world = render3d_pass_projection_unjittered_clip_from_world(
    pass_projection, camera_transform,
  )
  let resolved_previous_clip_from_world = match previous_clip_from_world {
    Some(value) => value
    None => clip_from_world
  }
  @render.host_gpu_begin_pass_3d(
    target_id~,
    target_layer~,
    secondary_target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x=camera_transform.translation.x,
    camera_y=camera_transform.translation.y,
    camera_z=camera_transform.translation.z,
    camera_exposure~,
    camera_rot_x=camera_transform.rotation.x,
    camera_rot_y=camera_transform.rotation.y,
    camera_rot_z=camera_transform.rotation.z,
    camera_rot_w=camera_transform.rotation.w,
    clip_from_world_x_axis_x=clip_from_world.x_axis.x,
    clip_from_world_x_axis_y=clip_from_world.x_axis.y,
    clip_from_world_x_axis_z=clip_from_world.x_axis.z,
    clip_from_world_x_axis_w=clip_from_world.x_axis.w,
    clip_from_world_y_axis_x=clip_from_world.y_axis.x,
    clip_from_world_y_axis_y=clip_from_world.y_axis.y,
    clip_from_world_y_axis_z=clip_from_world.y_axis.z,
    clip_from_world_y_axis_w=clip_from_world.y_axis.w,
    clip_from_world_z_axis_x=clip_from_world.z_axis.x,
    clip_from_world_z_axis_y=clip_from_world.z_axis.y,
    clip_from_world_z_axis_z=clip_from_world.z_axis.z,
    clip_from_world_z_axis_w=clip_from_world.z_axis.w,
    clip_from_world_w_axis_x=clip_from_world.w_axis.x,
    clip_from_world_w_axis_y=clip_from_world.w_axis.y,
    clip_from_world_w_axis_z=clip_from_world.w_axis.z,
    clip_from_world_w_axis_w=clip_from_world.w_axis.w,
    unjittered_clip_from_world_x_axis_x=unjittered_clip_from_world.x_axis.x,
    unjittered_clip_from_world_x_axis_y=unjittered_clip_from_world.x_axis.y,
    unjittered_clip_from_world_x_axis_z=unjittered_clip_from_world.x_axis.z,
    unjittered_clip_from_world_x_axis_w=unjittered_clip_from_world.x_axis.w,
    unjittered_clip_from_world_y_axis_x=unjittered_clip_from_world.y_axis.x,
    unjittered_clip_from_world_y_axis_y=unjittered_clip_from_world.y_axis.y,
    unjittered_clip_from_world_y_axis_z=unjittered_clip_from_world.y_axis.z,
    unjittered_clip_from_world_y_axis_w=unjittered_clip_from_world.y_axis.w,
    unjittered_clip_from_world_z_axis_x=unjittered_clip_from_world.z_axis.x,
    unjittered_clip_from_world_z_axis_y=unjittered_clip_from_world.z_axis.y,
    unjittered_clip_from_world_z_axis_z=unjittered_clip_from_world.z_axis.z,
    unjittered_clip_from_world_z_axis_w=unjittered_clip_from_world.z_axis.w,
    unjittered_clip_from_world_w_axis_x=unjittered_clip_from_world.w_axis.x,
    unjittered_clip_from_world_w_axis_y=unjittered_clip_from_world.w_axis.y,
    unjittered_clip_from_world_w_axis_z=unjittered_clip_from_world.w_axis.z,
    unjittered_clip_from_world_w_axis_w=unjittered_clip_from_world.w_axis.w,
    previous_clip_from_world_x_axis_x=resolved_previous_clip_from_world.x_axis.x,
    previous_clip_from_world_x_axis_y=resolved_previous_clip_from_world.x_axis.y,
    previous_clip_from_world_x_axis_z=resolved_previous_clip_from_world.x_axis.z,
    previous_clip_from_world_x_axis_w=resolved_previous_clip_from_world.x_axis.w,
    previous_clip_from_world_y_axis_x=resolved_previous_clip_from_world.y_axis.x,
    previous_clip_from_world_y_axis_y=resolved_previous_clip_from_world.y_axis.y,
    previous_clip_from_world_y_axis_z=resolved_previous_clip_from_world.y_axis.z,
    previous_clip_from_world_y_axis_w=resolved_previous_clip_from_world.y_axis.w,
    previous_clip_from_world_z_axis_x=resolved_previous_clip_from_world.z_axis.x,
    previous_clip_from_world_z_axis_y=resolved_previous_clip_from_world.z_axis.y,
    previous_clip_from_world_z_axis_z=resolved_previous_clip_from_world.z_axis.z,
    previous_clip_from_world_z_axis_w=resolved_previous_clip_from_world.z_axis.w,
    previous_clip_from_world_w_axis_x=resolved_previous_clip_from_world.w_axis.x,
    previous_clip_from_world_w_axis_y=resolved_previous_clip_from_world.w_axis.y,
    previous_clip_from_world_w_axis_z=resolved_previous_clip_from_world.w_axis.z,
    previous_clip_from_world_w_axis_w=resolved_previous_clip_from_world.w_axis.w,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    ambient_r=lighting.ambient_color.r,
    ambient_g=lighting.ambient_color.g,
    ambient_b=lighting.ambient_color.b,
    ambient_brightness=lighting.ambient_brightness,
    directional_dir_x=lighting.directional_dir.x,
    directional_dir_y=lighting.directional_dir.y,
    directional_dir_z=lighting.directional_dir.z,
    directional_color_r=lighting.directional_color.r,
    directional_color_g=lighting.directional_color.g,
    directional_color_b=lighting.directional_color.b,
    directional_illuminance=lighting.directional_illuminance,
    point_pos_x=lighting.point_pos.x,
    point_pos_y=lighting.point_pos.y,
    point_pos_z=lighting.point_pos.z,
    point_color_r=lighting.point_color.r,
    point_color_g=lighting.point_color.g,
    point_color_b=lighting.point_color.b,
    point_intensity=lighting.point_intensity,
    point_range=lighting.point_range,
    spot_pos_x=lighting.spot_pos.x,
    spot_pos_y=lighting.spot_pos.y,
    spot_pos_z=lighting.spot_pos.z,
    spot_dir_x=lighting.spot_dir.x,
    spot_dir_y=lighting.spot_dir.y,
    spot_dir_z=lighting.spot_dir.z,
    spot_color_r=lighting.spot_color.r,
    spot_color_g=lighting.spot_color.g,
    spot_color_b=lighting.spot_color.b,
    spot_intensity=lighting.spot_intensity,
    spot_range=lighting.spot_range,
    spot_inner_angle=lighting.spot_inner_angle,
    spot_outer_angle=lighting.spot_outer_angle,
    point_shadow_near~,
    pass_kind~,
    clear_enabled~,
  )
}

///|
fn render3d_cull_mode_value(
  material : StandardMaterial,
  draw_flags : Int,
) -> Int {
  let draw_cull_mode_base = match material.cull_mode {
    None => 0
    Some(face) =>
      match face {
        Face3d::Front => 1
        Face3d::Back => 2
      }
  }
  draw_cull_mode_base | draw_flags
}

///|
fn render3d_build_mesh_gpu_draw_payload(
  mesh_id : Int,
  preprocess_camera_key_hi : Int,
  preprocess_camera_key_lo : Int,
  draw_storage_index : Int,
  indirect_kind : Int,
  indirect_parameters_index : Int,
  material : StandardMaterial,
  transform : @transform.Transform,
  previous_transform : @transform.Transform,
  draw_color_r : Float,
  draw_color_g : Float,
  draw_color_b : Float,
  draw_alpha : Float,
  texture_id : Int,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  anisotropy_texture_id : Int,
  specular_tint_texture_id : Int,
  draw_surface_roughness : Float,
  draw_reflectance : Float,
  draw_diffuse_transmission : Float,
  draw_specular_transmission : Float,
  draw_thickness : Float,
  draw_ior : Float,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Float,
  transmission_steps : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  specular_tint : @sprite.Color,
  anisotropy_strength : Float,
  max_relief_mapping_search_steps : Float,
  draw_flags : Int,
) -> MeshGpuDrawPayload3d {
  let material_flags = render3d_standard_material_flags(
    material, texture_id, normal_texture_id, emissive_texture_id, metallic_roughness_texture_id,
    occlusion_texture_id, depth_texture_id, anisotropy_texture_id, specular_tint_texture_id,
  )
  MeshGpuDrawPayload3d::{
    mesh_id,
    preprocess_camera_key_hi,
    preprocess_camera_key_lo,
    draw_storage_index,
    indirect_kind,
    indirect_parameters_index,
    transform,
    previous_transform,
    color_r: draw_color_r,
    color_g: draw_color_g,
    color_b: draw_color_b,
    color_a: draw_alpha,
    texture_id,
    uv_transform: material.uv_transform,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    emissive: material.emissive,
    metallic: material.metallic,
    anisotropy_texture_id,
    anisotropy_rotation: material.anisotropy_rotation,
    specular_tint_texture_id,
    parallax_depth_scale: material.parallax_depth_scale,
    max_parallax_layer_count: material.max_parallax_layer_count,
    surface_roughness: draw_surface_roughness,
    reflectance: draw_reflectance,
    diffuse_transmission: draw_diffuse_transmission,
    specular_transmission: draw_specular_transmission,
    thickness: draw_thickness,
    ior: draw_ior,
    alpha_cutoff: render3d_standard_material_alpha_cutoff(material.alpha_mode),
    material_flags,
    transmission_source_texture_id,
    transmission_blur_taps,
    transmission_steps,
    point_shadow_texture_id,
    point_shadow_enabled,
    point_shadow_depth_bias,
    specular_tint,
    anisotropy_strength,
    max_relief_mapping_search_steps,
    cull_mode: render3d_cull_mode_value(material, draw_flags),
  }
}

///|
fn render3d_draw_mesh_gpu_payload(payload : MeshGpuDrawPayload3d) -> Unit {
  @render.host_gpu_draw_mesh3d(
    mesh_id=payload.mesh_id,
    preprocess_camera_key_hi=payload.preprocess_camera_key_hi,
    preprocess_camera_key_lo=payload.preprocess_camera_key_lo,
    draw_storage_index=payload.draw_storage_index,
    indirect_kind=payload.indirect_kind,
    indirect_parameters_index=payload.indirect_parameters_index,
    x=payload.transform.translation.x,
    y=payload.transform.translation.y,
    z=payload.transform.translation.z,
    rotation_x=payload.transform.rotation.x,
    rotation_y=payload.transform.rotation.y,
    rotation_z=payload.transform.rotation.z,
    rotation_w=payload.transform.rotation.w,
    scale_x=payload.transform.scale.x,
    scale_y=payload.transform.scale.y,
    scale_z=payload.transform.scale.z,
    previous_x=payload.previous_transform.translation.x,
    previous_y=payload.previous_transform.translation.y,
    previous_z=payload.previous_transform.translation.z,
    previous_rotation_x=payload.previous_transform.rotation.x,
    previous_rotation_y=payload.previous_transform.rotation.y,
    previous_rotation_z=payload.previous_transform.rotation.z,
    previous_rotation_w=payload.previous_transform.rotation.w,
    previous_scale_x=payload.previous_transform.scale.x,
    previous_scale_y=payload.previous_transform.scale.y,
    previous_scale_z=payload.previous_transform.scale.z,
    color_r=payload.color_r,
    color_g=payload.color_g,
    color_b=payload.color_b,
    color_a=payload.color_a,
    texture_id=payload.texture_id,
    uv_transform_a=payload.uv_transform.a,
    uv_transform_b=payload.uv_transform.b,
    uv_transform_c=payload.uv_transform.c,
    uv_transform_d=payload.uv_transform.d,
    uv_transform_tx=payload.uv_transform.tx,
    uv_transform_ty=payload.uv_transform.ty,
    uv_transform_mode=1.0F,
    normal_texture_id=payload.normal_texture_id,
    emissive_texture_id=payload.emissive_texture_id,
    metallic_roughness_texture_id=payload.metallic_roughness_texture_id,
    occlusion_texture_id=payload.occlusion_texture_id,
    depth_texture_id=payload.depth_texture_id,
    emissive_r=payload.emissive.r,
    emissive_g=payload.emissive.g,
    emissive_b=payload.emissive.b,
    metallic=payload.metallic,
    roughness=payload.surface_roughness,
    reflectance=payload.reflectance,
    parallax_depth_scale=payload.parallax_depth_scale,
    max_parallax_layer_count=payload.max_parallax_layer_count,
    max_relief_mapping_search_steps=payload.max_relief_mapping_search_steps,
    anisotropy_texture_id=payload.anisotropy_texture_id,
    anisotropy_strength=payload.anisotropy_strength,
    anisotropy_rotation=payload.anisotropy_rotation,
    specular_tint_texture_id=payload.specular_tint_texture_id,
    specular_tint_r=payload.specular_tint.r,
    specular_tint_g=payload.specular_tint.g,
    specular_tint_b=payload.specular_tint.b,
    diffuse_transmission=payload.diffuse_transmission,
    specular_transmission=payload.specular_transmission,
    thickness=payload.thickness,
    ior=payload.ior,
    alpha_cutoff=payload.alpha_cutoff,
    material_flags=payload.material_flags,
    transmission_source_texture_id=payload.transmission_source_texture_id,
    transmission_blur_taps=payload.transmission_blur_taps,
    transmission_steps=payload.transmission_steps,
    point_shadow_texture_id=payload.point_shadow_texture_id,
    point_shadow_enabled=payload.point_shadow_enabled,
    point_shadow_depth_bias=payload.point_shadow_depth_bias,
    cull_mode=payload.cull_mode,
  )
}

///|
pub fn render3d_execute_system(world : @ecs.World) -> Unit {
  let cameras : Array[ExtractedCamera3d] = []
  let meshes : Array[ExtractedMesh3d] = []
  let projection_updates : Array[
    (@core.Entity, Projection, ProjectionRuntime3d),
  ] = []
  let projection_runtime_removals : Array[@core.Entity] = []
  let camera3d_store = world.component(ecs_key_camera3d)
  let camera_store = world.component(@sprite.ecs_key_camera)
  let projection_store = world.component(ecs_key_projection)
  let projection_runtime_store = world.component(ecs_key_projection_runtime3d)
  let sub_camera_view_store = world.component(ecs_key_sub_camera_view3d)
  let screen_space_transmission_store = world.component(
    ecs_key_screen_space_transmission,
  )
  let bloom_store = world.component(ecs_key_bloom)
  let tonemapping_store = world.component(ecs_key_tonemapping)
  let deband_dither_store = world.component(ecs_key_deband_dither)
  let chromatic_aberration_store = world.component(ecs_key_chromatic_aberration)
  let vignette_store = world.component(ecs_key_vignette)
  let motion_blur_store = world.component(ecs_key_motion_blur)
  let exposure_store = world.component(ecs_key_exposure)
  let color_grading_store = world.component(ecs_key_color_grading)
  let skybox_store = world.component(ecs_key_skybox)
  let hdr_store = world.component(ecs_key_hdr)
  let fxaa_store = world.component(ecs_key_fxaa)
  let temporal_jitter_store = world.component(ecs_key_temporal_jitter)
  let motion_vector_prepass_store = world.component(
    ecs_key_motion_vector_prepass,
  )
  let temporal_anti_aliasing_store = world.component(
    ecs_key_temporal_anti_aliasing,
  )
  let target_store = world.component(@sprite.ecs_key_render_target)
  let layers_store = world.component(@sprite.ecs_key_render_layers)
  let depth_prepass_store = world.component(ecs_key_depth_prepass)
  let deferred_prepass_store = world.component(ecs_key_deferred_prepass)
  let no_indirect_drawing_store = world.component(ecs_key_no_indirect_drawing)
  let occlusion_culling_store = world.component(ecs_key_occlusion_culling)
  let msaa_store = world.component(ecs_key_msaa)
  let transform_store = world.component(@transform.ecs_key_transform)
  let view_visibility_store = world.component(
    @visibility.ecs_key_view_visibility,
  )
  let runtime_config = render3d_runtime_config_or_default(world)
  let prepass_enabled = standard_material_prepass_enabled(world)
  let deferred_lighting_enabled = runtime_config.add_default_deferred_lighting_plugin &&
    deferred_pbr_lighting_enabled(world)
  let indirect_first_instance_supported = render3d_indirect_first_instance_supported()
  let gpu_instance_buffer_builder_enabled = runtime_config.use_gpu_instance_buffer_builder
  @render.host_gpu_set_mesh3d_gpu_instance_builder_enabled(
    gpu_instance_buffer_builder_enabled,
  )
  let delta_seconds = render3d_default_time_or_default(world).delta_seconds()
  let mut default_opaque_renderer_method = if (try! world.get_resource(
      ecs_key_default_opaque_renderer_method,
    ))
    is Some(default_method) {
    default_method.renderer_method()
  } else {
    OpaqueRendererMethod::Forward
  }
  if !deferred_lighting_enabled &&
    default_opaque_renderer_method is OpaqueRendererMethod::Deferred {
    default_opaque_renderer_method = OpaqueRendererMethod::Forward
  }
  let point_light_shadow_map_size = if (try! world.get_resource(
      ecs_key_point_light_shadow_map,
    ))
    is Some(shadow_map) {
    if shadow_map.size <= 0 {
      1
    } else {
      shadow_map.size
    }
  } else {
    PointLightShadowMap::default().size
  }
  camera3d_store.for_each(fn(entity, camera3d) {
    let camera = match camera_store.get(entity) {
      Some(v) => v
      None => @sprite.Camera::default()
    }
    let projection_component = projection_store.get(entity)
    let projection = match projection_component {
      Some(v) => v
      None => Projection::default()
    }
    let projection_changed = true
    let sub_camera_view = sub_camera_view_store.get(entity)
    let screen_space_transmission = screen_space_transmission_store.get(entity)
    let bloom = bloom_store.get(entity)
    let tonemapping = tonemapping_store.get(entity)
    let deband_dither = deband_dither_store.get(entity)
    let chromatic_aberration = chromatic_aberration_store.get(entity)
    let vignette = vignette_store.get(entity)
    let motion_blur = motion_blur_store.get(entity)
    let exposure = exposure_store.get(entity)
    let color_grading = color_grading_store.get(entity)
    let skybox = skybox_store.get(entity)
    let hdr_enabled = hdr_store.get(entity) is Some(_)
    let fxaa = fxaa_store.get(entity)
    let temporal_jitter = temporal_jitter_store.get(entity)
    let depth_prepass_enabled = prepass_enabled &&
      depth_prepass_store.get(entity) is Some(_)
    let deferred_prepass_enabled = prepass_enabled &&
      deferred_prepass_store.get(entity) is Some(_)
    let no_indirect_drawing = no_indirect_drawing_store.get(entity) is Some(_)
    let camera_indirect_enabled = render3d_camera_indirect_enabled(
      runtime_config.use_gpu_instance_buffer_builder,
      indirect_first_instance_supported,
      no_indirect_drawing,
    )
    let gpu_occlusion_culling_enabled = depth_prepass_enabled &&
      camera_indirect_enabled &&
      occlusion_culling_store.get(entity) is Some(_)
    let motion_vector_prepass_enabled = prepass_enabled &&
      (
        motion_vector_prepass_store.get(entity) is Some(_) ||
        gpu_occlusion_culling_enabled
      )
    let temporal_anti_aliasing = temporal_anti_aliasing_store.get(entity)
    let msaa = msaa_store.get(entity)
    let target = match target_store.get(entity) {
      Some(v) => v
      None => @sprite.RenderTarget::Screen
    }
    let layers = match layers_store.get(entity) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
    let transform = match transform_store.get(entity) {
      Some(v) => v
      None => @transform.Transform::identity()
    }
    let previous_camera_history = camera_motion_blur_history_get(entity)
    let previous_transform = match previous_camera_history {
      Some(v) => v.transform
      None => transform
    }
    match render3d_target_info(world, target) {
      Some(target_info) => {
        let mut camera_clamped = camera
        if camera.viewport is Some(viewport) {
          let clamped = render3d_clamp_viewport(
            viewport,
            target_info.target_size,
          )
          camera_clamped = camera.with_viewport(clamped)
        }
        let projection = match projection_component {
          Some(component_projection) => {
            let (runtime_projection, runtime_update) = render3d_projection_runtime_update(
              component_projection,
              projection_runtime_store.get(entity),
              projection_changed,
              camera_clamped,
              target_info.target_size,
              target_info.scale_factor,
            )
            if runtime_update is Some(runtime_state) {
              projection_updates.push(
                (entity, runtime_projection, runtime_state),
              )
            }
            runtime_projection
          }
          None =>
            render3d_projection_runtime_projection(
              projection,
              camera_clamped,
              target_info.target_size,
              target_info.scale_factor,
            )
        }
        cameras.push(ExtractedCamera3d::{
          entity: phase_entity_ref3d_for_main(entity),
          payload: Camera3dViewPayload::{
            camera3d,
            camera: camera_clamped,
            projection,
            sub_camera_view,
            screen_space_transmission,
            bloom,
            tonemapping,
            deband_dither,
            chromatic_aberration,
            vignette,
            motion_blur,
            exposure,
            color_grading,
            skybox,
            depth_prepass_enabled,
            deferred_prepass_enabled,
            no_indirect_drawing,
            gpu_occlusion_culling_enabled,
            hdr_enabled,
            fxaa,
            temporal_jitter,
            temporal_anti_aliasing,
            motion_vector_prepass_enabled,
            msaa,
            transform,
            previous_transform,
            previous_clip_from_world: match previous_camera_history {
              Some(v) => Some(v.clip_from_world)
              None => None
            },
            target_id: target_info.target_id,
            target_size: target_info.target_size,
            scale_factor: target_info.scale_factor,
            layers,
          },
        })
      }
      None => ()
    }
    if projection_component is None &&
      projection_runtime_store.get(entity) is Some(_) {
      projection_runtime_removals.push(entity)
    }
  })
  for update in projection_updates {
    projection_store.insert(update.0, update.1)
    projection_runtime_store.insert(update.0, update.2)
  }
  for entity in projection_runtime_removals {
    projection_runtime_store.remove(entity) |> ignore
  }
  if cameras.length() == 0 {
    render3d_prepared_camera_order_ref.val.clear()
    render3d_queued_visible_mesh_count_ref.val = 0
    return
  }
  let mesh_store = world.component(ecs_key_mesh3d)
  let material_store = world.component(ecs_key_mesh_material3d)
  let gpu_mesh_store = world.component(@sprite.ecs_key_gpu_mesh2d)
  let visibility_range_store = world.component(
    @visibility.ecs_key_visibility_range,
  )
  let wireframe_store = world.component(ecs_key_wireframe)
  let no_wireframe_store = world.component(ecs_key_no_wireframe)
  let wireframe_color_store = world.component(ecs_key_wireframe_color)
  let forward_decal_store = world.component(ecs_key_forward_decal)
  let forward_decal_material_ext_store = world.component(
    ecs_key_forward_decal_material_ext,
  )
  let clustered_decal_store = world.component(ecs_key_clustered_decal)
  let wireframe_config = if (try! world.get_resource(ecs_key_wireframe_config))
    is Some(config) {
    Some(config)
  } else {
    None
  }
  mesh_store.for_each(fn(entity, mesh3d) {
    if view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard gpu_mesh_store.get(entity) is Some(gpu_mesh) else { return }
    guard material_store.get(entity) is Some(material_handle) else { return }
    guard standard_material_get(material_handle.material) is Some(base_material) else {
      return
    }
    let material = render3d_apply_extended_material_metadata(
      base_material,
      material_handle.extended_material,
    )
    let layers = match layers_store.get(entity) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
    let transform = match transform_store.get(entity) {
      Some(v) => v
      None => @transform.Transform::identity()
    }
    let previous_transform = match motion_blur_history_get(entity) {
      Some(v) => v
      None => transform
    }
    let visibility_range = visibility_range_store.get(entity)
    let aabb_center_world = if visibility_range is Some(range) && range.use_aabb {
      match render3d_mesh_local_aabb_center(mesh3d) {
        Some(local_center) =>
          Some(render3d_transform_point(transform, local_center))
        None => None
      }
    } else {
      None
    }
    meshes.push(ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(entity),
      payload: Mesh3dExtractedPayload::{
        mesh_handle: mesh3d.mesh,
        mesh_id: gpu_mesh.mesh_id,
        transform,
        previous_transform,
        visibility_range,
        aabb_center_world,
        material,
        material_extension: material_handle.extended_material,
        is_forward_decal: forward_decal_store.get(entity) is Some(_),
        forward_decal_material_ext: forward_decal_material_ext_store.get(entity),
        clustered_decal: clustered_decal_store.get(entity),
        layers,
        has_wireframe: wireframe_store.get(entity) is Some(_),
        has_no_wireframe: no_wireframe_store.get(entity) is Some(_),
        wireframe_color: wireframe_color_store.get(entity),
      },
    })
  })
  motion_blur_history_sync(meshes)
  let lighting = render3d_collect_lighting(world)
  let camera_phase_items = match render3d_prepared_camera_phase_items(cameras) {
    Some(items) => items
    None => render3d_queue_camera_phase_items(cameras)
  }
  let next_camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry] = []
  for camera_phase_item in camera_phase_items {
    let extracted_camera = cameras[camera_phase_item.extracted_index]
    let camera_entity = extracted_camera.entity.main_entity
    let camera = extracted_camera.payload
    @render.host_gpu_set_active_surface_target(camera.target_id)
    let target_width = camera.target_size.x
    let target_height = camera.target_size.y
    if target_width <= 0 || target_height <= 0 {
      continue
    }
    let mut viewport_x = 0
    let mut viewport_y = 0
    let mut viewport_width = target_width
    let mut viewport_height = target_height
    let mut viewport_depth_min = 0.0F
    let mut viewport_depth_max = 1.0F
    let mut view_width = target_width
    let mut view_height = target_height
    if camera.camera.viewport is Some(viewport) {
      viewport_x = viewport.physical_position.x
      viewport_y = viewport.physical_position.y
      viewport_width = viewport.physical_size.x
      viewport_height = viewport.physical_size.y
      if viewport_width <= 0 || viewport_height <= 0 {
        continue
      }
      viewport_depth_min = viewport.depth_min
      viewport_depth_max = viewport.depth_max
      view_width = viewport_width
      view_height = viewport_height
    }
    // Render target textures and viewport dimensions are in physical pixels.
    // Do not divide by window scale factor here; doing so halves render size on
    // high-DPI displays and breaks camera framing/post-process alignment.
    camera.scale_factor |> ignore
    let view_width_logical = view_width
    let view_height_logical = view_height
    if view_width_logical <= 0 || view_height_logical <= 0 {
      continue
    }
    let temporal_aa_enabled = camera.temporal_anti_aliasing is Some(_)
    let camera_pass_projection = render3d_camera_pass_projection(
      camera.projection,
      camera.sub_camera_view,
      camera.temporal_jitter,
      view_width,
      view_height,
    )
    let camera_near = camera_pass_projection.camera_near
    let camera_far = camera_pass_projection.camera_far
    let current_clip_from_world = render3d_pass_projection_clip_from_world(
      camera_pass_projection,
      camera.transform,
    )
    next_camera_motion_blur_history.push({
      entity: camera_entity,
      transform: camera.transform,
      clip_from_world: current_clip_from_world,
    })
    let pass_lighting = lighting
    let camera_deferred_mode = render3d_camera_deferred_mode(
      camera.camera3d.deferred_config,
      default_opaque_renderer_method,
      deferred_lighting_enabled,
    )
    let camera_deferred_enabled = deferred_lighting_enabled &&
      prepass_enabled &&
      (
        camera.deferred_prepass_enabled ||
        camera.camera3d.deferred_config.requires_deferred_prepass ||
        camera_deferred_mode is OpaqueRendererMethod::Deferred
      )
    let camera_msaa_allows_forward_decals = match camera.msaa {
      Some(msaa) => msaa is Msaa::Off
      None => true
    }
    let camera_forward_decal_enabled = render3d_decal_mode_allows_forward(
        camera.camera3d.decal_config.mode,
      ) &&
      camera_msaa_allows_forward_decals &&
      (
        !camera.camera3d.decal_config.requires_depth_prepass ||
        camera.depth_prepass_enabled
      )
    let camera_clustered_decal_enabled = render3d_decal_mode_allows_clustered(
        camera.camera3d.decal_config.mode,
      ) &&
      (
        !camera.camera3d.decal_config.clustered_requires_deferred_prepass ||
        camera_deferred_enabled
      )
    let effective_exposure = camera.exposure
    let camera_exposure_value = match effective_exposure {
      Some(value) => value.exposure()
      None => Exposure::default().exposure()
    }
    let camera_base_fog = match camera.camera3d.distance_fog {
      Some(value) => value
      None => render3d_distance_fog()
    }
    let distance_fog = render3d_camera_distance_fog(
      camera_base_fog,
      camera.camera3d.volumetric_fog,
      camera.camera3d.atmosphere,
      camera.camera3d.atmosphere_settings,
    )
    let (clear_enabled, resolved_clear_color) = camera.camera.clear_color.resolve()
    let mut clear_color = resolved_clear_color
    // Bevy renders atmosphere / volumetric fog sky contribution as a full-view
    // background. Until that stage is fully ported, use fog color as the clear
    // background when the camera clear color is black to avoid losing the scene
    // behind sparse geometry.
    if clear_enabled &&
      (
        camera.camera3d.atmosphere is Some(_) ||
        camera.camera3d.volumetric_fog is Some(_) ||
        render3d_distance_fog_enabled(distance_fog)
      ) {
      let fog_color = distance_fog.color
      clear_color = @sprite.Color::new(
        maxf(clear_color.r, maxf(0.02F, fog_color.r)),
        maxf(clear_color.g, maxf(0.02F, fog_color.g)),
        maxf(clear_color.b, maxf(0.02F, fog_color.b)),
        clear_color.a,
      )
    }
    let motion_blur_active = if camera.motion_blur is Some(motion_blur) {
      motion_blur.samples > 0 && motion_blur.shutter_angle > 0.0F
    } else {
      false
    }
    let transmission_blur_taps = if camera.screen_space_transmission
      is Some(transmission) &&
      transmission.steps > 0 {
      screen_space_transmission_blur_taps(transmission.quality)
    } else {
      0
    }
    let transmission_steps = if camera.screen_space_transmission
      is Some(transmission) {
      transmission.steps
    } else {
      0
    }
    let transmission_enabled = transmission_blur_taps > 0
    let bloom_enabled = camera.bloom is Some(_)
    let tonemapping_stage_enabled = render3d_tonemapping_stage_enabled(
      camera.tonemapping,
      camera.deband_dither,
      camera.hdr_enabled,
      camera.color_grading,
    )
    let effect_stack_postprocess_enabled = render3d_effect_stack_enabled(
      camera.chromatic_aberration,
      camera.vignette,
    )
    let fxaa_postprocess_enabled = render3d_fxaa_enabled(camera.fxaa)
    let tonemap_postprocess_enabled = tonemapping_stage_enabled ||
      effect_stack_postprocess_enabled ||
      fxaa_postprocess_enabled
    let motion_vector_prepass_enabled = prepass_enabled &&
      (
        motion_blur_active ||
        camera.motion_vector_prepass_enabled ||
        temporal_aa_enabled ||
        camera.gpu_occlusion_culling_enabled
      )
    let fog_enabled = render3d_distance_fog_enabled(distance_fog)
    let decal_enabled = camera_forward_decal_enabled ||
      camera_clustered_decal_enabled
    let postprocess_enabled = motion_blur_active ||
      bloom_enabled ||
      tonemap_postprocess_enabled
    let scene_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_SCENE,
      postprocess_enabled,
      fog_enabled,
      decal_enabled,
    )
    let motion_vector_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_MOTION_VECTOR,
      false,
      false,
      false,
    )
    let point_shadow_pass_kind = render3d_pass_kind_encode(
      RENDER3D_PASS_KIND_BASE_POINT_SHADOW,
      false,
      false,
      false,
    )
    let mut scene_target_id = camera.target_id
    let mut velocity_target_id = -1
    let mut point_shadow_texture_id = -1
    let mut point_shadow_enabled = 0.0F
    let mut point_shadow_depth_bias = 0.0F
    let point_shadow_near = if pass_lighting.point_shadow_map_near_z > 0.0001F {
      pass_lighting.point_shadow_map_near_z
    } else {
      0.0001F
    }
    let draw_queue_entry = if gpu_instance_buffer_builder_enabled {
      match
        render3d_take_gpu_preprocess_camera_queue_items(camera_entity, meshes) {
        Some(prequeued_entry) => prequeued_entry
        None =>
          render3d_make_fallback_gpu_preprocess_queue_entry(
            render3d_queue_mesh_phase_items(
              meshes,
              camera.layers,
              camera.transform,
              true,
            ),
            meshes,
            render3d_camera_indirect_enabled(
              gpu_instance_buffer_builder_enabled,
              indirect_first_instance_supported,
              camera.no_indirect_drawing,
            ),
            camera.gpu_occlusion_culling_enabled,
          )
      }
    } else {
      render3d_make_fallback_gpu_preprocess_queue_entry(
        render3d_queue_mesh_phase_items(
          meshes,
          camera.layers,
          camera.transform,
          false,
        ),
        meshes,
        false,
        false,
      )
    }
    let draw_items = draw_queue_entry.draw_items
    let opaque_alpha_draw_item_indices = render3d_gpu_preprocess_opaque_alpha_draw_item_indices(
      draw_items,
      draw_queue_entry.phase_ranges,
      draw_queue_entry.work_item_buffers,
    )
    let (
      indexed_indirect_parameter_indices,
      non_indexed_indirect_parameter_indices,
    ) = render3d_gpu_preprocess_indirect_parameter_index_maps(
      draw_items,
      draw_queue_entry.work_item_buffers,
    )
    render3d_gpu_preprocess_indirect_metadata_checksum(
      draw_queue_entry.indirect_metadata,
    )
    |> ignore
    render3d_gpu_preprocess_work_item_buffers_checksum(
      draw_queue_entry.work_item_buffers,
    )
    |> ignore
    render3d_gpu_preprocess_dispatch_metadata_checksum(
      draw_queue_entry.dispatch_metadata,
    )
    |> ignore
    @render.host_gpu_upload_mesh3d_preprocess_camera_payload(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
      payload=render3d_host_preprocess_camera_payload(
        draw_queue_entry, meshes, camera, camera_pass_projection, viewport_x, viewport_y,
        viewport_width, viewport_height, camera_exposure_value,
      ),
    )
    if camera.gpu_occlusion_culling_enabled {
      @render.host_gpu_preprocess_mesh3d(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
        phase_kind=@render.MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION,
      )
      @render.host_gpu_build_mesh3d_indirect_parameters(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
        phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_EARLY,
      )
    } else {
      @render.host_gpu_preprocess_mesh3d(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
      )
      @render.host_gpu_build_mesh3d_indirect_parameters(
        camera_key_hi=camera_entity.id,
        camera_key_lo=camera_entity.generation,
      )
    }
    if motion_vector_prepass_enabled {
      let (shared_scene_id, shared_velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera_entity, view_width, view_height,
      )
      if motion_blur_active {
        scene_target_id = shared_scene_id
      }
      velocity_target_id = shared_velocity_id
      render3d_begin_pass_3d(
        target_id=shared_scene_id,
        secondary_target_id=velocity_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=0.0F,
        clear_g=0.0F,
        clear_b=0.0F,
        clear_a=0.0F,
        camera.transform,
        camera_pass_projection,
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        pass_lighting,
        camera_exposure=camera_exposure_value,
        previous_clip_from_world=camera.previous_clip_from_world,
        point_shadow_near~,
        pass_kind=motion_vector_pass_kind,
        clear_enabled=1,
      )
      for draw_item_index in opaque_alpha_draw_item_indices {
        let draw_item = draw_items[draw_item_index]
        if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
          draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
          continue
        }
        let extracted_mesh = meshes[draw_item.extracted_index]
        let mesh = extracted_mesh.payload
        guard render3d_mesh_draw_alpha(
            mesh.material.alpha_mode,
            mesh.material.base_color.a,
          )
          is Some(draw_alpha) else {
          continue
        }
        if draw_alpha < 0.999F {
          continue
        }
        let motion_vector_indexed = render3d_mesh_handle_is_indexed(
          mesh.mesh_handle,
        )
        let motion_vector_indirect_parameters_index = if motion_vector_indexed {
          indexed_indirect_parameter_indices[draw_item_index]
        } else {
          non_indexed_indirect_parameter_indices[draw_item_index]
        }
        render3d_draw_mesh_gpu_payload(
          render3d_build_mesh_gpu_draw_payload(
            mesh.mesh_id,
            camera_entity.id,
            camera_entity.generation,
            draw_item_index,
            if motion_vector_indirect_parameters_index >= 0 {
              if motion_vector_indexed {
                MESH3D_DRAW_INDIRECT_KIND_INDEXED
              } else {
                MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
              }
            } else {
              MESH3D_DRAW_INDIRECT_KIND_NONE
            },
            motion_vector_indirect_parameters_index,
            mesh.material,
            mesh.transform,
            mesh.previous_transform,
            1.0F,
            1.0F,
            1.0F,
            1.0F,
            -1,
            -1,
            -1,
            -1,
            -1,
            -1,
            -1,
            -1,
            0.5F,
            0.5F,
            0.0F,
            0.0F,
            0.0F,
            1.5F,
            -1,
            0.0F,
            0.0F,
            -1,
            0.0F,
            0.0F,
            @sprite.Color::white(),
            0.0F,
            0.0F,
            render3d_mesh_draw_flags(extracted_mesh),
          ),
        )
      }
      @render.host_gpu_end_pass()
      if camera.gpu_occlusion_culling_enabled {
        @render.host_gpu_downsample_mesh3d_depth_pyramid(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
        )
        @render.host_gpu_preprocess_mesh3d(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
          phase_kind=@render.MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION,
        )
        @render.host_gpu_build_mesh3d_indirect_parameters(
          camera_key_hi=camera_entity.id,
          camera_key_lo=camera_entity.generation,
          phase_kind=@render.MESH3D_BUILD_INDIRECT_PHASE_MAIN,
        )
      }
    }
    if pass_lighting.point_shadow_maps_enabled &&
      !pass_lighting.point_entity.is_placeholder() &&
      pass_lighting.point_range > 0.0F &&
      point_light_shadow_map_size > 0 {
      let shadow_target_id = render3d_point_light_shadow_target_get_or_create(
        pass_lighting.point_entity,
        point_light_shadow_map_size,
      )
      point_shadow_texture_id = shadow_target_id
      point_shadow_enabled = 1.0F
      point_shadow_depth_bias = maxf(
        0.0F,
        pass_lighting.point_shadow_depth_bias,
      )
      let shadow_camera_near = if pass_lighting.point_shadow_map_near_z >
        0.0001F {
        pass_lighting.point_shadow_map_near_z
      } else {
        0.0001F
      }
      let shadow_view_size = point_light_shadow_map_size
      let point_shadow_pass_projection = render3d_point_shadow_pass_projection(
        shadow_camera_near,
        pass_lighting.point_range,
      )
      for face_index in 0..<6 {
        let shadow_camera_transform = render3d_point_shadow_face_transform(
          pass_lighting.point_pos,
          face_index,
        )
        render3d_begin_pass_3d(
          target_id=shadow_target_id,
          target_layer=face_index,
          width=shadow_view_size,
          height=shadow_view_size,
          clear_r=1.0F,
          clear_g=1.0F,
          clear_b=1.0F,
          clear_a=1.0F,
          shadow_camera_transform,
          point_shadow_pass_projection,
          viewport_x=0,
          viewport_y=0,
          viewport_width=shadow_view_size,
          viewport_height=shadow_view_size,
          pass_lighting,
          previous_clip_from_world=None,
          point_shadow_near=shadow_camera_near,
          pass_kind=point_shadow_pass_kind,
          clear_enabled=1,
        )
        for draw_item_index in opaque_alpha_draw_item_indices {
          let shadow_draw_item = draw_items[draw_item_index]
          if shadow_draw_item.phase != RENDER3D_PHASE_OPAQUE &&
            shadow_draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
            continue
          }
          let extracted_shadow_mesh = meshes[shadow_draw_item.extracted_index]
          let shadow_mesh = extracted_shadow_mesh.payload
          if shadow_mesh.is_forward_decal ||
            shadow_mesh.clustered_decal is Some(_) {
            continue
          }
          guard render3d_mesh_draw_alpha(
              shadow_mesh.material.alpha_mode,
              shadow_mesh.material.base_color.a,
            )
            is Some(shadow_alpha) else {
            continue
          }
          if shadow_alpha < 0.999F {
            continue
          }
          let shadow_indexed = render3d_mesh_handle_is_indexed(
            shadow_mesh.mesh_handle,
          )
          let shadow_indirect_parameters_index = if shadow_indexed {
            indexed_indirect_parameter_indices[draw_item_index]
          } else {
            non_indexed_indirect_parameter_indices[draw_item_index]
          }
          render3d_draw_mesh_gpu_payload(
            render3d_build_mesh_gpu_draw_payload(
              shadow_mesh.mesh_id,
              camera_entity.id,
              camera_entity.generation,
              draw_item_index,
              if shadow_indirect_parameters_index >= 0 {
                if shadow_indexed {
                  MESH3D_DRAW_INDIRECT_KIND_INDEXED
                } else {
                  MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
                }
              } else {
                MESH3D_DRAW_INDIRECT_KIND_NONE
              },
              shadow_indirect_parameters_index,
              shadow_mesh.material,
              shadow_mesh.transform,
              shadow_mesh.transform,
              1.0F,
              1.0F,
              1.0F,
              1.0F,
              -1,
              -1,
              -1,
              -1,
              -1,
              -1,
              -1,
              -1,
              0.5F,
              0.5F,
              0.0F,
              0.0F,
              0.0F,
              1.5F,
              -1,
              0.0F,
              0.0F,
              -1,
              0.0F,
              0.0F,
              @sprite.Color::white(),
              0.0F,
              0.0F,
              0,
            ),
          )
        }
        @render.host_gpu_end_pass()
      }
    }
    if !motion_blur_active &&
      (transmission_enabled || bloom_enabled || tonemap_postprocess_enabled) &&
      (camera.target_id < 0 || bloom_enabled || tonemap_postprocess_enabled) {
      let (scene_id, _velocity_id) = render3d_motion_blur_targets_get_or_create(
        camera_entity, view_width, view_height,
      )
      scene_target_id = scene_id
    }
    let mut transmission_source_target_id = -1
    render3d_begin_pass_3d(
      target_id=scene_target_id,
      width=view_width_logical,
      height=view_height_logical,
      clear_r=clear_color.r,
      clear_g=clear_color.g,
      clear_b=clear_color.b,
      clear_a=clear_color.a,
      camera.transform,
      camera_pass_projection,
      viewport_x~,
      viewport_y~,
      viewport_width~,
      viewport_height~,
      pass_lighting,
      camera_exposure=camera_exposure_value,
      previous_clip_from_world=camera.previous_clip_from_world,
      point_shadow_near~,
      pass_kind=scene_pass_kind,
      clear_enabled=if clear_enabled { 1 } else { 0 },
    )
    let main_pass_draws : Array[MeshGpuDrawPayload3d] = []
    let transmissive_phase_items : Array[TransmissivePhaseItem3d] = []
    let transparent_draws : Array[MeshGpuDrawPayload3d] = []
    for draw_item_index in 0..<draw_items.length() {
      let draw_item = draw_items[draw_item_index]
      let extracted_mesh = meshes[draw_item.extracted_index]
      let mesh = extracted_mesh.payload
      if mesh.is_forward_decal && !camera_forward_decal_enabled {
        continue
      }
      if mesh.clustered_decal is Some(_) && !camera_clustered_decal_enabled {
        continue
      }
      if mesh.material_extension is Some(extension) {
        if extension.requires_depth_prepass && !camera.depth_prepass_enabled {
          continue
        }
        if extension.requires_deferred_prepass && !camera_deferred_enabled {
          continue
        }
      }
      let mesh_opaque_mode = if mesh.material.opaque_render_method
        is OpaqueRendererMethod::Auto {
        camera_deferred_mode
      } else {
        mesh.material.opaque_render_method
      }
      if mesh_opaque_mode is OpaqueRendererMethod::Deferred &&
        !camera_deferred_enabled {
        continue
      }
      guard render3d_mesh_draw_alpha(
          mesh.material.alpha_mode,
          mesh.material.base_color.a,
        )
        is Some(base_draw_alpha) else {
        continue
      }
      let mut draw_alpha = base_draw_alpha
      let mut texture_id = match mesh.material.base_color_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let mut normal_texture_id = match
        (
          mesh.material.normal_map_texture,
          mesh.material.clearcoat_normal_texture,
        ) {
        (Some(texture), _) => texture.id()
        (None, Some(texture)) => texture.id()
        (None, None) => -1
      }
      let mut emissive_texture_id = match mesh.material.emissive_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let mut metallic_roughness_texture_id = match
        mesh.material.metallic_roughness_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let occlusion_texture_id = match mesh.material.occlusion_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let depth_texture_id = match mesh.material.depth_map {
        Some(texture) => texture.id()
        None => -1
      }
      let anisotropy_texture_id = match mesh.material.anisotropy_texture {
        Some(texture) => texture.id()
        None => -1
      }
      let specular_tint_texture_id = match mesh.material.specular_tint_texture {
        Some(texture) => texture.id()
        None => -1
      }
      if mesh.clustered_decal is Some(clustered_decal) {
        if clustered_decal.base_color_texture is Some(texture) {
          texture_id = texture.id()
        }
        if clustered_decal.normal_map_texture is Some(texture) {
          normal_texture_id = texture.id()
        }
        if clustered_decal.metallic_roughness_texture is Some(texture) {
          metallic_roughness_texture_id = texture.id()
        }
        if clustered_decal.emissive_texture is Some(texture) {
          emissive_texture_id = texture.id()
        }
      }
      let anisotropy_strength = maxf(
        0.0F,
        minf(1.0F, mesh.material.anisotropy_strength),
      )
      let max_relief_mapping_search_steps = Float::from_double(
        mesh.material.parallax_mapping_method.max_steps().to_double(),
      )
      let mut clearcoat_reflectance = maxf(
        0.0F,
        mesh.material.reflectance + mesh.material.clearcoat * 0.5F,
      )
      let clearcoat_roughness = minf(
        mesh.material.perceptual_roughness,
        mesh.material.clearcoat_perceptual_roughness,
      )
      let mut draw_roughness = if mesh.material.clearcoat > 0.0F {
        clearcoat_roughness
      } else {
        mesh.material.perceptual_roughness
      }
      let mesh_distance = mesh.transform.translation
        .sub(camera.transform.translation)
        .length()
      if mesh.is_forward_decal {
        let depth_fade_factor = if mesh.forward_decal_material_ext
          is Some(extension) {
          extension.depth_fade_factor
        } else {
          8.0F
        }
        let safe_depth_fade_factor = if depth_fade_factor < 0.001F {
          0.001F
        } else {
          depth_fade_factor
        }
        let decal_alpha = safe_depth_fade_factor /
          (safe_depth_fade_factor + maxf(0.0F, mesh_distance - camera_near))
        draw_alpha = draw_alpha * render3d_float_clamp(decal_alpha, 0.0F, 1.0F)
        clearcoat_reflectance = 0.0F
        draw_roughness = maxf(draw_roughness, 0.85F)
      }
      let (fogged_r, fogged_g, fogged_b) = render3d_apply_distance_fog(
        distance_fog,
        mesh_distance,
        mesh.material.base_color.r,
        mesh.material.base_color.g,
        mesh.material.base_color.b,
        camera.transform.translation,
        mesh.transform.translation,
        pass_lighting,
      )
      let draw_color_r = fogged_r
      let draw_color_g = fogged_g
      let draw_color_b = fogged_b
      let draw_surface_roughness = draw_roughness
      let draw_reflectance = clearcoat_reflectance
      let draw_diffuse_transmission = clamp01(
        mesh.material.diffuse_transmission,
      )
      let draw_specular_transmission = clamp01(
        mesh.material.specular_transmission,
      )
      let draw_thickness = maxf(0.0F, mesh.material.thickness)
      let draw_ior = maxf(1.0F, mesh.material.ior)
      let draw_flags = render3d_mesh_draw_flags(extracted_mesh)
      let draw_indexed = render3d_mesh_handle_is_indexed(mesh.mesh_handle)
      let draw_indirect_parameters_index = if draw_indexed {
        indexed_indirect_parameter_indices[draw_item_index]
      } else {
        non_indexed_indirect_parameter_indices[draw_item_index]
      }
      let draw_payload = render3d_build_mesh_gpu_draw_payload(
        mesh.mesh_id,
        camera_entity.id,
        camera_entity.generation,
        draw_item_index,
        if draw_indirect_parameters_index >= 0 {
          if draw_indexed {
            MESH3D_DRAW_INDIRECT_KIND_INDEXED
          } else {
            MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
          }
        } else {
          MESH3D_DRAW_INDIRECT_KIND_NONE
        },
        draw_indirect_parameters_index,
        mesh.material,
        mesh.transform,
        mesh.previous_transform,
        draw_color_r,
        draw_color_g,
        draw_color_b,
        draw_alpha,
        texture_id,
        normal_texture_id,
        emissive_texture_id,
        metallic_roughness_texture_id,
        occlusion_texture_id,
        depth_texture_id,
        anisotropy_texture_id,
        specular_tint_texture_id,
        draw_surface_roughness,
        draw_reflectance,
        draw_diffuse_transmission,
        draw_specular_transmission,
        draw_thickness,
        draw_ior,
        -1,
        0.0F,
        0.0F,
        point_shadow_texture_id,
        point_shadow_enabled,
        point_shadow_depth_bias,
        mesh.material.specular_tint,
        anisotropy_strength,
        max_relief_mapping_search_steps,
        draw_flags,
      )
      if draw_item.phase == RENDER3D_PHASE_TRANSPARENT {
        transparent_draws.push(draw_payload)
        continue
      }
      if transmission_enabled && draw_specular_transmission > 0.0F {
        transmissive_phase_items.push(TransmissivePhaseItem3d::{
          entity: extracted_mesh.entity,
          distance: draw_item.distance,
          payload: draw_payload,
        })
        continue
      }
      main_pass_draws.push(draw_payload)
    }
    for draw_payload in main_pass_draws {
      render3d_draw_mesh_gpu_payload(draw_payload)
    }
    render3d_draw_camera_skybox(world, extracted_camera, camera_far)
    @render.host_gpu_end_pass()
    let transmissive_draws = render3d_sort_transmissive_phase_items(
      transmissive_phase_items,
    )
    if transmissive_draws.length() > 0 {
      transmission_source_target_id = render3d_transmission_source_target_get_or_create(
        camera_entity, view_width, view_height,
      )
      let transmission_ranges = if transmission_steps > 0 {
        render3d_split_phase_ranges(
          transmissive_draws.length(),
          transmission_steps,
        )
      } else {
        [(0, transmissive_draws.length())]
      }
      for transmission_range in transmission_ranges {
        if transmission_steps > 0 {
          render3d_blit_texture_to_target(
            scene_target_id, transmission_source_target_id, view_width_logical, view_height_logical,
          )
        }
        render3d_begin_pass_3d(
          target_id=scene_target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera.transform,
          camera_pass_projection,
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          pass_lighting,
          camera_exposure=camera_exposure_value,
          previous_clip_from_world=camera.previous_clip_from_world,
          point_shadow_near~,
          pass_kind=scene_pass_kind,
          clear_enabled=0,
        )
        for i in transmission_range.0..<transmission_range.1 {
          let transmissive_draw = transmissive_draws[i]
          transmissive_draw.entity |> ignore
          render3d_draw_mesh_gpu_payload(MeshGpuDrawPayload3d::{
            ..transmissive_draw.payload,
            transmission_source_texture_id: if transmission_steps > 0 {
              transmission_source_target_id
            } else {
              -1
            },
            transmission_blur_taps: Float::from_double(
              transmission_blur_taps.to_double(),
            ),
            transmission_steps: Float::from_double(
              transmission_steps.to_double(),
            ),
            point_shadow_texture_id,
            point_shadow_enabled,
            point_shadow_depth_bias,
          })
        }
        @render.host_gpu_end_pass()
      }
    }
    let wireframe_draws : Array[MeshGpuDrawPayload3d] = []
    for draw_item_index in 0..<draw_items.length() {
      let draw_item = draw_items[draw_item_index]
      let extracted_mesh = meshes[draw_item.extracted_index]
      let mesh = extracted_mesh.payload
      if !render3d_mesh_should_draw_wireframe(extracted_mesh, wireframe_config) {
        continue
      }
      guard render3d_wireframe_mesh_id(mesh.mesh_handle)
        is Some(wireframe_mesh_id) else {
        continue
      }
      let wireframe_color = render3d_mesh_wireframe_color(
        extracted_mesh, wireframe_config,
      )
      let wireframe_material = StandardMaterial::from_color(wireframe_color)
        .with_unlit(true)
        .with_cull_mode(mesh.material.cull_mode)
      guard render3d_mesh_draw_alpha(
          wireframe_material.alpha_mode,
          wireframe_material.base_color.a,
        )
        is Some(wireframe_draw_alpha) else {
        continue
      }
      wireframe_draws.push(
        render3d_build_mesh_gpu_draw_payload(
          wireframe_mesh_id,
          camera_entity.id,
          camera_entity.generation,
          draw_item_index,
          MESH3D_DRAW_INDIRECT_KIND_NONE,
          -1,
          wireframe_material,
          mesh.transform,
          mesh.previous_transform,
          wireframe_material.base_color.r,
          wireframe_material.base_color.g,
          wireframe_material.base_color.b,
          wireframe_draw_alpha,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          -1,
          0.5F,
          0.5F,
          0.0F,
          0.0F,
          0.0F,
          1.5F,
          -1,
          0.0F,
          0.0F,
          -1,
          0.0F,
          0.0F,
          @sprite.Color::white(),
          0.0F,
          0.0F,
          render3d_mesh_draw_flags(extracted_mesh),
        ),
      )
    }
    if transparent_draws.length() > 0 || wireframe_draws.length() > 0 {
      render3d_begin_pass_3d(
        target_id=scene_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera.transform,
        camera_pass_projection,
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        pass_lighting,
        camera_exposure=camera_exposure_value,
        previous_clip_from_world=camera.previous_clip_from_world,
        point_shadow_near~,
        pass_kind=scene_pass_kind,
        clear_enabled=0,
      )
      for draw_payload in transparent_draws {
        render3d_draw_mesh_gpu_payload(draw_payload)
      }
      for wireframe_draw in wireframe_draws {
        render3d_draw_mesh_gpu_payload(wireframe_draw)
      }
      @render.host_gpu_end_pass()
    }
    let mut final_source_texture_id = -1
    if motion_blur_active &&
      camera.motion_blur is Some(motion_blur) &&
      velocity_target_id >= 0 {
      if bloom_enabled || tonemap_postprocess_enabled {
        let post_motion_blur_target_id = render3d_transmission_source_target_get_or_create(
          camera_entity, view_width, view_height,
        )
        @render.host_gpu_begin_pass(
          target_id=post_motion_blur_target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        @render.host_gpu_draw_motion_blur(
          scene_texture_id=scene_target_id,
          velocity_texture_id=velocity_target_id,
          shutter_angle=motion_blur.shutter_angle,
          samples=motion_blur.samples,
        )
        @render.host_gpu_end_pass()
        final_source_texture_id = post_motion_blur_target_id
      } else {
        @render.host_gpu_begin_pass(
          target_id=camera.target_id,
          width=view_width_logical,
          height=view_height_logical,
          clear_r=clear_color.r,
          clear_g=clear_color.g,
          clear_b=clear_color.b,
          clear_a=clear_color.a,
          camera_x=0.0F,
          camera_y=0.0F,
          camera_rotation=0.0F,
          camera_scale=1.0F,
          viewport_x~,
          viewport_y~,
          viewport_width~,
          viewport_height~,
          viewport_depth_min~,
          viewport_depth_max~,
          clear_enabled=if clear_enabled { 1 } else { 0 },
        )
        @render.host_gpu_draw_motion_blur(
          scene_texture_id=scene_target_id,
          velocity_texture_id=velocity_target_id,
          shutter_angle=motion_blur.shutter_angle,
          samples=motion_blur.samples,
        )
        @render.host_gpu_end_pass()
      }
    } else if scene_target_id != camera.target_id {
      final_source_texture_id = scene_target_id
    }
    if bloom_enabled || tonemap_postprocess_enabled {
      let postprocess_source_texture_id = if final_source_texture_id >= 0 {
        final_source_texture_id
      } else {
        scene_target_id
      }
      if postprocess_source_texture_id >= 0 {
        if camera.camera3d.auto_exposure is Some(auto_exposure_settings) {
          @render.host_gpu_begin_pass(
            target_id=camera.target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x~,
            viewport_y~,
            viewport_width~,
            viewport_height~,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=if clear_enabled { 1 } else { 0 },
          )
          render3d_apply_camera_auto_exposure(
            world,
            camera_entity,
            auto_exposure_settings,
            camera.color_grading,
            postprocess_source_texture_id,
            view_width_logical,
            view_height_logical,
            delta_seconds,
          )
          @render.host_gpu_end_pass()
        }
        if bloom_enabled && camera.bloom is Some(bloom) {
          @render.host_gpu_begin_pass(
            target_id=camera.target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x~,
            viewport_y~,
            viewport_width~,
            viewport_height~,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=if clear_enabled { 1 } else { 0 },
          )
          render3d_draw_camera_bloom_stage(
            postprocess_source_texture_id, bloom, view_width_logical, view_height_logical,
          )
          @render.host_gpu_end_pass()
        }
        let postprocess_stage_count = (if effect_stack_postprocess_enabled {
            1
          } else {
            0
          }) +
          (if tonemapping_stage_enabled { 1 } else { 0 }) +
          (if fxaa_postprocess_enabled { 1 } else { 0 })
        if postprocess_stage_count > 0 {
          let stage_ping_target_id = render3d_transmission_source_target_get_or_create(
            camera_entity, view_width, view_height,
          )
          let mut current_source_texture_id = postprocess_source_texture_id
          let mut stage_index = 0
          if effect_stack_postprocess_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x~,
              viewport_y~,
              viewport_width~,
              viewport_height~,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=if clear_enabled { 1 } else { 0 },
            )
            render3d_draw_camera_effect_stack_stage(
              current_source_texture_id,
              camera.chromatic_aberration,
              camera.vignette,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
            current_source_texture_id = stage_target_id
            stage_index = stage_index + 1
          }
          if tonemapping_stage_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x~,
              viewport_y~,
              viewport_width~,
              viewport_height~,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=if clear_enabled { 1 } else { 0 },
            )
            render3d_draw_camera_tonemapping_stage(
              world,
              current_source_texture_id,
              effective_exposure,
              camera.tonemapping,
              camera.deband_dither,
              camera.color_grading,
              camera.hdr_enabled,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
            current_source_texture_id = stage_target_id
            stage_index = stage_index + 1
          }
          if fxaa_postprocess_enabled {
            let stage_target_id = render3d_postprocess_stage_target(
              current_source_texture_id,
              scene_target_id,
              stage_ping_target_id,
              camera.target_id,
              stage_index,
              postprocess_stage_count,
            )
            @render.host_gpu_begin_pass(
              target_id=stage_target_id,
              width=view_width_logical,
              height=view_height_logical,
              clear_r=clear_color.r,
              clear_g=clear_color.g,
              clear_b=clear_color.b,
              clear_a=clear_color.a,
              camera_x=0.0F,
              camera_y=0.0F,
              camera_rotation=0.0F,
              camera_scale=1.0F,
              viewport_x~,
              viewport_y~,
              viewport_width~,
              viewport_height~,
              viewport_depth_min~,
              viewport_depth_max~,
              clear_enabled=if clear_enabled { 1 } else { 0 },
            )
            render3d_draw_camera_fxaa_stage(
              current_source_texture_id,
              camera.fxaa,
              view_width_logical,
              view_height_logical,
            )
            @render.host_gpu_end_pass()
          }
        } else if postprocess_source_texture_id != camera.target_id {
          @render.host_gpu_begin_pass(
            target_id=camera.target_id,
            width=view_width_logical,
            height=view_height_logical,
            clear_r=clear_color.r,
            clear_g=clear_color.g,
            clear_b=clear_color.b,
            clear_a=clear_color.a,
            camera_x=0.0F,
            camera_y=0.0F,
            camera_rotation=0.0F,
            camera_scale=1.0F,
            viewport_x~,
            viewport_y~,
            viewport_width~,
            viewport_height~,
            viewport_depth_min~,
            viewport_depth_max~,
            clear_enabled=if clear_enabled { 1 } else { 0 },
          )
          if bloom_enabled {
            // Bloom can render through an fp16 intermediate even when camera
            // HDR is disabled. Resolve through the postprocess fullscreen
            // shader to avoid dark fp16->surface blits on this path.
            render3d_draw_camera_tonemapping_stage(
              world,
              postprocess_source_texture_id,
              Some(Exposure::new(0.0F)),
              None,
              None,
              None,
              true,
              view_width_logical,
              view_height_logical,
            )
          } else {
            @render.host_gpu_draw_sprite_uv(
              texture_id=postprocess_source_texture_id,
              x=0.0F,
              y=0.0F,
              rotation=0.0F,
              scale_x=Float::from_double(view_width_logical.to_double()) /
                128.0F,
              scale_y=Float::from_double(view_height_logical.to_double()) /
                128.0F,
              color_r=1.0F,
              color_g=1.0F,
              color_b=1.0F,
              color_a=1.0F,
              uv_min_x=0.0F,
              uv_min_y=0.0F,
              uv_max_x=1.0F,
              uv_max_y=1.0F,
            )
          }
          @render.host_gpu_end_pass()
        }
      }
    } else if final_source_texture_id >= 0 {
      @render.host_gpu_begin_pass(
        target_id=camera.target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera_x=0.0F,
        camera_y=0.0F,
        camera_rotation=0.0F,
        camera_scale=1.0F,
        viewport_x~,
        viewport_y~,
        viewport_width~,
        viewport_height~,
        viewport_depth_min~,
        viewport_depth_max~,
        clear_enabled=if clear_enabled { 1 } else { 0 },
      )
      @render.host_gpu_draw_sprite_uv(
        texture_id=final_source_texture_id,
        x=0.0F,
        y=0.0F,
        rotation=0.0F,
        scale_x=Float::from_double(view_width_logical.to_double()) / 128.0F,
        scale_y=Float::from_double(view_height_logical.to_double()) / 128.0F,
        color_r=1.0F,
        color_g=1.0F,
        color_b=1.0F,
        color_a=1.0F,
        uv_min_x=0.0F,
        uv_min_y=0.0F,
        uv_max_x=1.0F,
        uv_max_y=1.0F,
      )
      @render.host_gpu_end_pass()
    }
  }
  camera_motion_blur_history_sync(next_camera_motion_blur_history)
  render3d_prepared_camera_order_ref.val.clear()
  render3d_queued_visible_mesh_count_ref.val = 0
}

///|
fn render3d_camera_viewport_rect_logical(
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Float, Float, Float, Float)? {
  let target_width = target_size.x
  let target_height = target_size.y
  if target_width <= 0 || target_height <= 0 {
    return None
  }
  let mut viewport_x = 0
  let mut viewport_y = 0
  let mut viewport_width = target_width
  let mut viewport_height = target_height
  if camera.viewport is Some(viewport) {
    viewport_x = if viewport.physical_position.x < 0 {
      0
    } else {
      viewport.physical_position.x
    }
    viewport_y = if viewport.physical_position.y < 0 {
      0
    } else {
      viewport.physical_position.y
    }
    viewport_width = if viewport.physical_size.x < 0 {
      0
    } else {
      viewport.physical_size.x
    }
    viewport_height = if viewport.physical_size.y < 0 {
      0
    } else {
      viewport.physical_size.y
    }
    let max_width = if target_width - viewport_x < 0 {
      0
    } else {
      target_width - viewport_x
    }
    let max_height = if target_height - viewport_y < 0 {
      0
    } else {
      target_height - viewport_y
    }
    if viewport_width > max_width {
      viewport_width = max_width
    }
    if viewport_height > max_height {
      viewport_height = max_height
    }
  }
  if viewport_width <= 0 || viewport_height <= 0 {
    return None
  }
  let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical_x = Float::from_double(viewport_x.to_double()) / sf
  let logical_y = Float::from_double(viewport_y.to_double()) / sf
  let logical_width = Float::from_double(viewport_width.to_double()) / sf
  let logical_height = Float::from_double(viewport_height.to_double()) / sf
  if logical_width <= 0.0F || logical_height <= 0.0F {
    return None
  }
  Some((logical_x, logical_y, logical_width, logical_height))
}

///|
fn render3d_orthographic_area(
  orthographic : OrthographicProjection3d,
  view_width : Float,
  view_height : Float,
) -> @math.Rect {
  let safe_view_width = if view_width <= 0.0F { 1.0F } else { view_width }
  let safe_view_height = if view_height <= 0.0F { 1.0F } else { view_height }
  let (projection_width, projection_height) = match orthographic.scaling_mode {
    WindowSize => (safe_view_width, safe_view_height)
    AutoMin(min_width, min_height) =>
      if safe_view_width * min_height > min_width * safe_view_height {
        (safe_view_width * min_height / safe_view_height, min_height)
      } else {
        (min_width, safe_view_height * min_width / safe_view_width)
      }
    AutoMax(max_width, max_height) =>
      if safe_view_width * max_height < max_width * safe_view_height {
        (safe_view_width * max_height / safe_view_height, max_height)
      } else {
        (max_width, safe_view_height * max_width / safe_view_width)
      }
    FixedVertical(viewport_height) =>
      (safe_view_width * viewport_height / safe_view_height, viewport_height)
    FixedHorizontal(viewport_width) =>
      (viewport_width, safe_view_height * viewport_width / safe_view_width)
    Fixed(width, height) => (width, height)
  }
  let origin_x = projection_width * orthographic.viewport_origin.x
  let origin_y = projection_height * orthographic.viewport_origin.y
  @math.Rect::new(
    @math.Vec2::new(
      orthographic.scale * -origin_x,
      orthographic.scale * -origin_y,
    ),
    @math.Vec2::new(
      orthographic.scale * (projection_width - origin_x),
      orthographic.scale * (projection_height - origin_y),
    ),
  )
}

///|
fn render3d_orthographic_projection_matrix(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> ProjectionMatrix3d {
  let width = right - left
  let height = top - bottom
  let depth = near - far
  let safe_width = if width == 0.0F { 1.0F } else { width }
  let safe_height = if height == 0.0F { 1.0F } else { height }
  let safe_depth = if depth == 0.0F { 1.0F } else { depth }
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(2.0F / safe_width, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 2.0F / safe_height, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F / safe_depth, 0.0F),
    @math.Vec4::new(
      -(right + left) / safe_width,
      -(top + bottom) / safe_height,
      near / safe_depth,
      1.0F,
    ),
  )
}

///|
fn render3d_orthographic_projection_matrix_for_sub(
  orthographic : OrthographicProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  let full_width = Float::from_double(sub_view.full_size.x.to_double())
  let full_height = Float::from_double(sub_view.full_size.y.to_double())
  let sub_width = Float::from_double(sub_view.size.x.to_double())
  let sub_height = Float::from_double(sub_view.size.y.to_double())
  if full_width <= 0.0F ||
    full_height <= 0.0F ||
    sub_width <= 0.0F ||
    sub_height <= 0.0F {
    return orthographic.get_clip_from_view()
  }
  let top = orthographic.area.max.y
  let bottom = orthographic.area.min.y
  let orthographic_height = top - bottom
  let orthographic_width = orthographic_height *
    render3d_projection_aspect_ratio(full_width, full_height)
  let center_x = (orthographic.area.max.x + orthographic.area.min.x) * 0.5F
  let left = center_x - orthographic_width * 0.5F
  let right = center_x + orthographic_width * 0.5F
  let scale_w = (right - left) / full_width
  let scale_h = (top - bottom) / full_height
  let left_prime = left + scale_w * sub_view.offset.x
  let right_prime = left_prime + scale_w * sub_width
  let top_prime = top - scale_h * sub_view.offset.y
  let bottom_prime = top_prime - scale_h * sub_height
  render3d_orthographic_projection_matrix(
    left_prime,
    right_prime,
    bottom_prime,
    top_prime,
    orthographic.far,
    orthographic.near,
  )
}

///|
fn render3d_projection_matrix_inverse(
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d? {
  let augmented : Array[Float] = [
    matrix.x_axis.x,
    matrix.y_axis.x,
    matrix.z_axis.x,
    matrix.w_axis.x,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    matrix.x_axis.y,
    matrix.y_axis.y,
    matrix.z_axis.y,
    matrix.w_axis.y,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    matrix.x_axis.z,
    matrix.y_axis.z,
    matrix.z_axis.z,
    matrix.w_axis.z,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    matrix.x_axis.w,
    matrix.y_axis.w,
    matrix.z_axis.w,
    matrix.w_axis.w,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
  ]
  for pivot in 0..<4 {
    let mut pivot_row = pivot
    let pivot_index = pivot * 8 + pivot
    let mut pivot_abs = if augmented[pivot_index] < 0.0F {
      -augmented[pivot_index]
    } else {
      augmented[pivot_index]
    }
    for row in (pivot + 1)..<4 {
      let value = augmented[row * 8 + pivot]
      let value_abs = if value < 0.0F { -value } else { value }
      if value_abs > pivot_abs {
        pivot_row = row
        pivot_abs = value_abs
      }
    }
    if pivot_abs <= 1.0e-12F {
      return None
    }
    if pivot_row != pivot {
      for col in 0..<8 {
        let lhs_index = pivot * 8 + col
        let rhs_index = pivot_row * 8 + col
        let tmp = augmented[lhs_index]
        augmented[lhs_index] = augmented[rhs_index]
        augmented[rhs_index] = tmp
      }
    }
    let pivot_value = augmented[pivot * 8 + pivot]
    for col in 0..<8 {
      let index = pivot * 8 + col
      augmented[index] = augmented[index] / pivot_value
    }
    for row in 0..<4 {
      if row == pivot {
        continue
      }
      let factor = augmented[row * 8 + pivot]
      if factor == 0.0F {
        continue
      }
      for col in 0..<8 {
        let row_index = row * 8 + col
        let pivot_row_index = pivot * 8 + col
        augmented[row_index] = augmented[row_index] -
          factor * augmented[pivot_row_index]
      }
    }
  }
  Some(
    ProjectionMatrix3d::from_cols(
      @math.Vec4::new(augmented[4], augmented[12], augmented[20], augmented[28]),
      @math.Vec4::new(augmented[5], augmented[13], augmented[21], augmented[29]),
      @math.Vec4::new(augmented[6], augmented[14], augmented[22], augmented[30]),
      @math.Vec4::new(augmented[7], augmented[15], augmented[23], augmented[31]),
    ),
  )
}

///|
fn render3d_projection_runtime_projection(
  projection : Projection,
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> Projection {
  match
    render3d_camera_viewport_rect_logical(camera, target_size, scale_factor) {
    Some((_, _, viewport_width, viewport_height)) =>
      projection.update(viewport_width, viewport_height)
    None => projection
  }
}

///|
fn render3d_projection_runtime_update(
  projection : Projection,
  runtime : ProjectionRuntime3d?,
  force_update : Bool,
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Projection, ProjectionRuntime3d?) {
  match
    render3d_camera_viewport_rect_logical(camera, target_size, scale_factor) {
    Some((_, _, viewport_width, viewport_height)) => {
      let next_runtime = ProjectionRuntime3d::{
        last_view_width: viewport_width,
        last_view_height: viewport_height,
      }
      if runtime is Some(previous_runtime) &&
        previous_runtime.last_view_width == viewport_width &&
        previous_runtime.last_view_height == viewport_height &&
        !force_update {
        (projection, None)
      } else {
        (projection.update(viewport_width, viewport_height), Some(next_runtime))
      }
    }
    None => (projection, None)
  }
}

///|
fn render3d_quat_conjugate(value : @math.Quat) -> @math.Quat {
  @math.Quat::new(-value.x, -value.y, -value.z, value.w)
}

///|
const MESH_RAY_CAST_DEFAULT_MAX_DISTANCE : Float = 1_000_000.0F

///|
const MESH_RAY_CAST_DEFAULT_RAY_EPSILON : Float = 0.000001F

///|
const MESH_RAY_CAST_DEFAULT_MAX_HITS : Int = 64

///|
pub struct MeshRayCastSettings {
  max_distance : Float
  ray_epsilon : Float
  max_hits : Int
  include_invisible : Bool
  only_entities : Array[@core.Entity]?
}

///|
pub fn MeshRayCastSettings::default() -> MeshRayCastSettings {
  {
    max_distance: MESH_RAY_CAST_DEFAULT_MAX_DISTANCE,
    ray_epsilon: MESH_RAY_CAST_DEFAULT_RAY_EPSILON,
    max_hits: MESH_RAY_CAST_DEFAULT_MAX_HITS,
    include_invisible: false,
    only_entities: None,
  }
}

///|
pub fn MeshRayCastSettings::with_max_distance(
  self : MeshRayCastSettings,
  max_distance : Float,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, max_distance, }
}

///|
pub fn MeshRayCastSettings::with_ray_epsilon(
  self : MeshRayCastSettings,
  ray_epsilon : Float,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, ray_epsilon, }
}

///|
pub fn MeshRayCastSettings::with_max_hits(
  self : MeshRayCastSettings,
  max_hits : Int,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, max_hits, }
}

///|
pub fn MeshRayCastSettings::with_include_invisible(
  self : MeshRayCastSettings,
  include_invisible : Bool,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, include_invisible, }
}

///|
pub fn MeshRayCastSettings::with_only_entities(
  self : MeshRayCastSettings,
  only_entities : Array[@core.Entity]?,
) -> MeshRayCastSettings {
  MeshRayCastSettings::{ ..self, only_entities, }
}

///|
pub struct MeshRayCastHit {
  point : @math.Vec3
  normal : @math.Vec3
  distance : Float
}

///|
fn render3d_entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn render3d_entity_in_list(
  entity : @core.Entity,
  entities : Array[@core.Entity],
) -> Bool {
  for candidate in entities {
    if render3d_entity_eq(entity, candidate) {
      return true
    }
  }
  false
}

///|
pub fn mesh_ray_cast(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  let ray_direction = direction.normalize_or_zero()
  if ray_direction.length_squared() <= 1.0e-12F {
    return []
  }
  let max_distance = if settings.max_distance <= 0.0F {
    MESH_RAY_CAST_DEFAULT_MAX_DISTANCE
  } else {
    settings.max_distance
  }
  let ray_epsilon = if settings.ray_epsilon <= 0.0F {
    MESH_RAY_CAST_DEFAULT_RAY_EPSILON
  } else {
    settings.ray_epsilon
  }
  let max_hits = if settings.max_hits <= 0 { 1 } else { settings.max_hits }
  let hits : Array[(@core.Entity, MeshRayCastHit)] = []
  let mesh_store = world.component(ecs_key_mesh3d)
  let transform_store = world.component(@transform.ecs_key_transform)
  let view_visibility_store = world.component(
    @visibility.ecs_key_view_visibility,
  )

  mesh_store.for_each(fn(entity, mesh3d) {
    if settings.only_entities is Some(only_entities) &&
      !render3d_entity_in_list(entity, only_entities) {
      return
    }
    if !settings.include_invisible &&
      view_visibility_store.get(entity) is Some(view_visibility) &&
      !view_visibility.is_visible() {
      return
    }
    guard render3d_mesh_local_aabb(mesh3d) is Some((min_corner, max_corner)) else {
      return
    }
    let transform = match transform_store.get(entity) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    guard render3d_inverse_transform_point(transform, origin)
      is Some(local_origin) else {
      return
    }
    guard render3d_inverse_transform_direction(transform, ray_direction)
      is Some(local_direction) else {
      return
    }
    guard render3d_ray_local_aabb_hit(
        local_origin, local_direction, min_corner, max_corner, ray_epsilon, max_distance,
      )
      is Some((distance, local_normal)) else {
      return
    }
    let normal = render3d_transform_local_normal(transform, local_normal)
    if normal.length_squared() <= 1.0e-12F {
      return
    }
    hits.push(
      (
        entity,
        {
          point: origin.add(ray_direction.mul_scalar(distance)),
          normal,
          distance,
        },
      ),
    )
  })

  hits.sort_by(fn(a, b) {
    let distance_cmp = cmp_float(a.1.distance, b.1.distance)
    if distance_cmp != 0 {
      return distance_cmp
    }
    let id_cmp = cmp_int(a.0.id, b.0.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(a.0.generation, b.0.generation)
  })

  let capped_hits : Array[(@core.Entity, MeshRayCastHit)] = []
  for i in 0..<hits.length() {
    if i >= max_hits {
      break
    }
    capped_hits.push(hits[i])
  }
  capped_hits
}

///|
pub fn mesh_ray_cast_first(
  world : @ecs.World,
  origin : @math.Vec3,
  direction : @math.Vec3,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  let hits = mesh_ray_cast(world, origin, direction, settings.with_max_hits(1))
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
}

///|
pub fn mesh_ray_cast_from_camera(
  world : @ecs.World,
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> Array[(@core.Entity, MeshRayCastHit)] {
  if render3d_camera_viewport_to_world_ray(
      screen, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((origin, direction)) {
    mesh_ray_cast(world, origin, direction, settings)
  } else {
    []
  }
}

///|
pub fn mesh_ray_cast_from_camera_first(
  world : @ecs.World,
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
  settings : MeshRayCastSettings,
) -> (@core.Entity, MeshRayCastHit)? {
  let hits = mesh_ray_cast_from_camera(
    world,
    screen,
    camera,
    projection,
    camera_transform,
    target_size,
    scale_factor,
    settings.with_max_hits(1),
  )
  if hits.length() > 0 {
    Some(hits[0])
  } else {
    None
  }
}

///|
pub fn render3d_camera_viewport_to_world_ray(
  screen : @math.Vec2,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (@math.Vec3, @math.Vec3)? {
  guard render3d_camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  if screen.x < viewport_x ||
    screen.y < viewport_y ||
    screen.x > viewport_x + viewport_width ||
    screen.y > viewport_y + viewport_height {
    return None
  }
  let viewport_local_x = (screen.x - viewport_x) / viewport_width
  let viewport_local_y = (screen.y - viewport_y) / viewport_height
  let ndc_x = viewport_local_x * 2.0F - 1.0F
  let ndc_y = 1.0F - viewport_local_y * 2.0F
  let runtime_projection = render3d_projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
  let clip_from_view = runtime_projection.get_clip_from_view()
  guard render3d_projection_matrix_inverse(clip_from_view)
    is Some(view_from_clip) else {
    return None
  }
  let near_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 1.0F, 1.0F),
  )
  let far_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 0.0F, 1.0F),
  )
  if near_view_h.w == 0.0F || far_view_h.w == 0.0F {
    return None
  }
  let near_view = @math.Vec3::new(
    near_view_h.x / near_view_h.w,
    near_view_h.y / near_view_h.w,
    near_view_h.z / near_view_h.w,
  )
  let far_view = @math.Vec3::new(
    far_view_h.x / far_view_h.w,
    far_view_h.y / far_view_h.w,
    far_view_h.z / far_view_h.w,
  )
  let ray_camera = far_view.sub(near_view).normalize_or_zero()
  if ray_camera.length_squared() <= 1.0e-12F {
    return None
  }
  let ray_world = quat_rotate_vec3(camera_transform.rotation, ray_camera).normalize_or_zero()
  if ray_world.length_squared() <= 1.0e-12F {
    return None
  }
  Some(
    (
      camera_transform.translation.add(
        quat_rotate_vec3(camera_transform.rotation, near_view),
      ),
      ray_world,
    ),
  )
}

///|
pub fn render3d_camera_world_to_viewport(
  world : @math.Vec3,
  camera : @sprite.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  guard render3d_camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  let to_world = world.sub(camera_transform.translation)
  let inv_rotation = render3d_quat_conjugate(camera_transform.rotation).normalize()
  let view_pos = quat_rotate_vec3(inv_rotation, to_world)
  let runtime_projection = render3d_projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
  guard runtime_projection.get_clip_from_view().project_point3(view_pos)
    is Some(ndc_point) else {
    return None
  }
  if ndc_point.z < 0.0F || ndc_point.z > 1.0F {
    return None
  }
  let ndc_x = ndc_point.x
  let ndc_y = ndc_point.y
  let local_x = (ndc_x + 1.0F) * 0.5F * viewport_width
  let local_y = (1.0F - ndc_y) * 0.5F * viewport_height
  if local_x < 0.0F ||
    local_y < 0.0F ||
    local_x > viewport_width ||
    local_y > viewport_height {
    return None
  }
  Some(@math.Vec2::new(local_x + viewport_x, local_y + viewport_y))
}
