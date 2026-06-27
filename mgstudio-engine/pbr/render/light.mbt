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

///|
pub(all) struct Render3dLightingState {
  ambient_color : @color.Color
  ambient_brightness : Float
  directional_dir : @math.Vec3
  directional_color : @color.Color
  directional_illuminance : Float
  directional_entity : @core.Entity?
  directional_transform : @transform.Transform
  directional_shadow_maps_enabled : Bool
  directional_shadow_depth_bias : Float
  directional_shadow_normal_bias : Float
  directional_shadow_soft_size : Float
  directional_cascade_bounds : Array[Float]
  directional_cascade_overlap_proportion : Float
  directional_cascade_minimum_distance : Float
  directional_cascades : @light.Cascades
  directional_occlusion_culling : Bool
  point_entity : @core.Entity?
  point_pos : @math.Vec3
  point_color : @color.Color
  point_intensity : Float
  point_range : Float
  point_light_index : Int
  point_shadow_maps_enabled : Bool
  point_shadow_depth_bias : Float
  point_shadow_map_near_z : Float
  spot_pos : @math.Vec3
  spot_dir : @math.Vec3
  spot_color : @color.Color
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
  spot_entity : @core.Entity?
  spot_transform : @transform.Transform
  spot_light_index : Int
  spot_shadow_maps_enabled : Bool
  spot_shadow_depth_bias : Float
  spot_shadow_normal_bias : Float
  spot_shadow_map_near_z : Float
  gpu_lights : GpuLights3d?
  gpu_clustered_lights_bytes : Bytes?
  gpu_clusterable_object_index_lists_bytes : Bytes?
  gpu_cluster_offsets_and_counts_bytes : Bytes?
}

///|
pub const MAX_DIRECTIONAL_LIGHTS : Int = 10

///|
pub const MAX_CASCADES_PER_LIGHT : Int = 4

///|
pub const MAX_RECT_LIGHTS : Int = 8

///|
const POINT_LIGHT_FLAG_SHADOW_MAPS_ENABLED : UInt = 1U << 0

///|
const POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE : UInt = 1U << 1

///|
const POINT_LIGHT_FLAG_VOLUMETRIC : UInt = 1U << 2

///|
const POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE : UInt = 1U << 3

///|
const POINT_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED : UInt = 1U << 4

///|
const POINT_LIGHT_FLAG_SPOT_LIGHT : UInt = 1U << 5

///|
const POINT_LIGHT_FLAG_NONE : UInt = 0U

///|
const DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED : UInt = 1U << 0

///|
const DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC : UInt = 1U << 1

///|
const DIRECTIONAL_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE : UInt = 1U << 2

///|
const DIRECTIONAL_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED : UInt = 1U << 3

///|
const DIRECTIONAL_LIGHT_FLAG_NONE : UInt = 0U

///|
const DIRECTIONAL_LIGHT_FLAG_UNINITIALIZED : UInt = 0xFFFFU

///|
const LIGHT_MESH_PIPELINE_KEY_DEPTH_PREPASS : UInt64 = 1UL << 2

///|
const LIGHT_MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO : UInt64 = 1UL << 9

///|
const LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS : Int = 37

///|
const LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_PERSPECTIVE : UInt64 = 1UL <<
  LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS

///|
const LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_ORTHOGRAPHIC : UInt64 = 2UL <<
  LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_SHIFT_BITS

///|
fn light_mesh_pipeline_key_for_shadow_view(
  is_directional_light : Bool,
) -> @material.ErasedMeshPipelineKey {
  let projection_bits = if is_directional_light {
    LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_ORTHOGRAPHIC |
    LIGHT_MESH_PIPELINE_KEY_UNCLIPPED_DEPTH_ORTHO
  } else {
    LIGHT_MESH_PIPELINE_KEY_VIEW_PROJECTION_PERSPECTIVE
  }
  @material.ErasedMeshPipelineKey::new(
    LIGHT_MESH_PIPELINE_KEY_DEPTH_PREPASS | projection_bits,
    "MeshPipelineKey",
  )
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/light.rs` (`LightKeyCache`).
pub struct LightKeyCache {
  keys : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    @material.ErasedMeshPipelineKey,
  ]
}

///|
pub fn LightKeyCache::LightKeyCache() -> LightKeyCache {
  LightKeyCache::{ keys: @hashmap.HashMap([]) }
}

///|
pub fn LightKeyCache::len(self : LightKeyCache) -> Int {
  self.keys.length()
}

///|
pub fn LightKeyCache::get(
  self : LightKeyCache,
  view : @render_view.RetainedViewEntity,
) -> @material.ErasedMeshPipelineKey? {
  self.keys.get(view)
}

///|
pub fn LightKeyCache::insert(
  self : LightKeyCache,
  view : @render_view.RetainedViewEntity,
  key : @material.ErasedMeshPipelineKey,
) -> Unit {
  self.keys.set(view, key)
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/light.rs::check_views_lights_need_specialization`.
pub fn check_view_light_needs_specialization(
  light_key_cache : LightKeyCache,
  dirty_specializations : @render_view_visibility.DirtySpecializations,
  retained_view_entity : @render_view.RetainedViewEntity,
  shadow_render_phase_exists : Bool,
  is_directional_light : Bool,
) -> Unit {
  if !shadow_render_phase_exists {
    return
  }
  let light_key = light_mesh_pipeline_key_for_shadow_view(is_directional_light)
  match light_key_cache.get(retained_view_entity) {
    Some(current_key) =>
      if current_key.bits() != light_key.bits() {
        light_key_cache.insert(retained_view_entity, light_key)
        dirty_specializations.insert_view(retained_view_entity)
      }
    None => {
      light_key_cache.insert(retained_view_entity, light_key)
      dirty_specializations.insert_view(retained_view_entity)
    }
  }
}

///|
let ecs_key_light_key_cache : @ecs.ResourceKey[LightKeyCache] = @ecs.register_resource(
  debug_name="mgstudio_pbr::LightKeyCache",
)

///|
pub impl @app.Resource for LightKeyCache with fn resource() {
  ecs_key_light_key_cache
}

///|
pub struct SpecializedShadowMaterialViewPipelineCache {
  map : @hashmap.HashMap[
    @render_gpu.MainEntity,
    (@material.CachedRenderPipelineId, @material.DrawFunctionId),
  ]
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::SpecializedShadowMaterialViewPipelineCache() -> SpecializedShadowMaterialViewPipelineCache {
  SpecializedShadowMaterialViewPipelineCache::{ map: @hashmap.HashMap([]) }
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::len(
  self : SpecializedShadowMaterialViewPipelineCache,
) -> Int {
  self.map.length()
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::clear(
  self : SpecializedShadowMaterialViewPipelineCache,
) -> Unit {
  self.map.clear()
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::get(
  self : SpecializedShadowMaterialViewPipelineCache,
  entity : @render_gpu.MainEntity,
) -> (@material.CachedRenderPipelineId, @material.DrawFunctionId)? {
  self.map.get(entity)
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::contains(
  self : SpecializedShadowMaterialViewPipelineCache,
  entity : @render_gpu.MainEntity,
) -> Bool {
  self.map.contains(entity)
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::insert(
  self : SpecializedShadowMaterialViewPipelineCache,
  entity : @render_gpu.MainEntity,
  pipeline_id : @material.CachedRenderPipelineId,
  draw_function_id : @material.DrawFunctionId,
) -> Unit {
  self.map.set(entity, (pipeline_id, draw_function_id))
}

///|
pub fn SpecializedShadowMaterialViewPipelineCache::remove(
  self : SpecializedShadowMaterialViewPipelineCache,
  entity : @render_gpu.MainEntity,
) -> Bool {
  if self.map.contains(entity) {
    self.map.remove(entity)
    true
  } else {
    false
  }
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/light.rs`
//   (`SpecializedShadowMaterialPipelineCache`).
pub struct SpecializedShadowMaterialPipelineCache {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    SpecializedShadowMaterialViewPipelineCache,
  ]
}

///|
pub fn SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache() -> SpecializedShadowMaterialPipelineCache {
  SpecializedShadowMaterialPipelineCache::{ views: @hashmap.HashMap([]) }
}

///|
pub fn SpecializedShadowMaterialPipelineCache::len(
  self : SpecializedShadowMaterialPipelineCache,
) -> Int {
  self.views.length()
}

///|
pub fn SpecializedShadowMaterialPipelineCache::get(
  self : SpecializedShadowMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> SpecializedShadowMaterialViewPipelineCache? {
  self.views.get(view)
}

///|
pub fn SpecializedShadowMaterialPipelineCache::view_or_insert(
  self : SpecializedShadowMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> SpecializedShadowMaterialViewPipelineCache {
  match self.views.get(view) {
    Some(cache) => cache
    None => {
      let cache = SpecializedShadowMaterialViewPipelineCache::SpecializedShadowMaterialViewPipelineCache()
      self.views.set(view, cache)
      cache
    }
  }
}

///|
pub fn SpecializedShadowMaterialPipelineCache::insert(
  self : SpecializedShadowMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
  entity : @render_gpu.MainEntity,
  pipeline_id : @material.CachedRenderPipelineId,
  draw_function_id : @material.DrawFunctionId,
) -> Unit {
  self.view_or_insert(view).insert(entity, pipeline_id, draw_function_id)
}

///|
pub fn SpecializedShadowMaterialPipelineCache::pipeline_id(
  self : SpecializedShadowMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
  entity : @render_gpu.MainEntity,
) -> @material.CachedRenderPipelineId? {
  match self.get(view) {
    Some(view_cache) =>
      view_cache
      .get(entity)
      .map(fn(entry) {
        let (pipeline_id, _) = entry
        pipeline_id
      })
    None => None
  }
}

///|
pub fn SpecializedShadowMaterialPipelineCache::expire_stale_views(
  self : SpecializedShadowMaterialPipelineCache,
  live_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let stale : Array[@render_view.RetainedViewEntity] = []
  for view, _cache in self.views {
    if !live_views.contains(view) {
      stale.push(view)
    }
  }
  for view in stale {
    self.views.remove(view)
  }
}

///|
let ecs_key_specialized_shadow_material_pipeline_cache : @ecs.ResourceKey[
  SpecializedShadowMaterialPipelineCache,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedShadowMaterialPipelineCache",
)

///|
pub impl @app.Resource for SpecializedShadowMaterialPipelineCache with fn resource() {
  ecs_key_specialized_shadow_material_pipeline_cache
}

///|
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/light.rs` (`PendingShadowQueues`).
pub struct PendingShadowQueues {
  queues : @render_gpu.PendingQueues
}

///|
pub fn PendingShadowQueues::PendingShadowQueues() -> PendingShadowQueues {
  PendingShadowQueues::{ queues: @render_gpu.PendingQueues::PendingQueues() }
}

///|
pub fn PendingShadowQueues::queues(
  self : PendingShadowQueues,
) -> @render_gpu.PendingQueues {
  self.queues
}

///|
let ecs_key_pending_shadow_queues : @ecs.ResourceKey[PendingShadowQueues] = @ecs.register_resource(
  debug_name="mgstudio_pbr::PendingShadowQueues",
)

///|
pub impl @app.Resource for PendingShadowQueues with fn resource() {
  ecs_key_pending_shadow_queues
}

///|
pub(all) struct ShadowSamplers {
  point_light_comparison_sampler : @wgpu.Sampler
  directional_light_comparison_sampler : @wgpu.Sampler
}

///|
pub let ecs_key_shadow_samplers : @ecs.ResourceKey[ShadowSamplers] = @ecs.register_resource(
  debug_name="mgstudio_pbr::ShadowSamplers",
)

///|
pub impl @app.Resource for ShadowSamplers with fn resource() {
  ecs_key_shadow_samplers
}

///|
priv struct AmbientLightResourceExtractState {
  last_source_changed_tick : @core.Tick?
}

///|
let ecs_key_ambient_light_resource_extract_state : @ecs.ResourceKey[
  AmbientLightResourceExtractState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::AmbientLightResourceExtractState",
)

///|
pub fn ShadowSamplers::point_light_comparison_sampler(
  self : ShadowSamplers,
) -> @wgpu.Sampler {
  self.point_light_comparison_sampler
}

///|
pub fn ShadowSamplers::directional_light_comparison_sampler(
  self : ShadowSamplers,
) -> @wgpu.Sampler {
  self.directional_light_comparison_sampler
}

///|
fn pbr_create_shadow_comparison_sampler(
  device : @wgpu.Device,
  label : String,
) -> @wgpu.Sampler {
  let sampler = device.create_sampler_u32(
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.FILTER_MODE_LINEAR,
    @wgpu.FILTER_MODE_LINEAR,
    @wgpu.MIPMAP_FILTER_MODE_NEAREST,
    compare_u32=@wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
  )
  sampler.set_label(label)
  sampler
}

///|
pub fn init_shadow_samplers(world : @ecs.World) -> Unit {
  guard world.get_resource(@render_gpu.render_device_resource_key)
    is Some(render_device) else {
    return
  }
  let device = render_device.wgpu_device()
  world.insert_resource(ecs_key_shadow_samplers, ShadowSamplers::{
    point_light_comparison_sampler: pbr_create_shadow_comparison_sampler(
      device, "point light shadow map sampler",
    ),
    directional_light_comparison_sampler: pbr_create_shadow_comparison_sampler(
      device, "directional light shadow map sampler",
    ),
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::extract_ambient_light_resource`.
fn ambient_light_resource_source_tick_matches(
  lhs : @core.Tick?,
  rhs : @core.Tick?,
) -> Bool {
  match (lhs, rhs) {
    (Some(left), Some(right)) => left == right
    (None, None) => true
    _ => false
  }
}

///|
fn extract_ambient_light_resource_from_worlds(
  source_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  let resource_key = @light.ecs_key_global_ambient_light
  guard source_world.get_resource(resource_key) is Some(main_resource) else {
    return
  }
  let source_changed_tick = source_world.resource_changed_tick(resource_key)
  let previous_changed_tick = match
    render_world.get_resource(ecs_key_ambient_light_resource_extract_state) {
    Some(state) => state.last_source_changed_tick
    None => None
  }
  let target_missing = render_world.get_resource(resource_key) is None
  if target_missing ||
    !ambient_light_resource_source_tick_matches(
      previous_changed_tick, source_changed_tick,
    ) {
    let state = AmbientLightResourceExtractState::{
      last_source_changed_tick: source_changed_tick,
    }
    render_world.insert_resource(resource_key, main_resource)
    render_world.insert_resource(
      ecs_key_ambient_light_resource_extract_state, state,
    )
  }
}

///|
pub fn extract_ambient_light_resource(render_world : @ecs.World) -> Unit {
  extract_ambient_light_resource_from_worlds(
    @render_gpu.render_source_world(render_world),
    render_world,
  )
}

///|
fn extract_point_light_shadow_map_resource_from_worlds(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  let resource_key = @light.ecs_key_point_light_shadow_map
  guard source_world.get_resource(resource_key) is Some(main_resource) else {
    return
  }
  let target_missing = render_world.get_resource(resource_key) is None
  if target_missing ||
    source_world.is_resource_changed(resource_key, system_ticks) {
    render_world.insert_resource(resource_key, main_resource)
  }
}

///|
fn extract_directional_light_shadow_map_resource_from_worlds(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  let resource_key = @light.ecs_key_directional_light_shadow_map
  guard source_world.get_resource(resource_key) is Some(main_resource) else {
    return
  }
  let target_missing = render_world.get_resource(resource_key) is None
  if target_missing ||
    source_world.is_resource_changed(resource_key, system_ticks) {
    render_world.insert_resource(resource_key, main_resource)
  }
}

///|
fn extract_shadow_map_resources_from_worlds(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  extract_point_light_shadow_map_resource_from_worlds(
    source_world, render_world, system_ticks,
  )
  extract_directional_light_shadow_map_resource_from_worlds(
    source_world, render_world, system_ticks,
  )
}

///|
fn render3d_sqrt2() -> Float {
  @math.sqrt(2.0F)
}

///|
fn render3d_tan(value : Float) -> Float {
  let sinv = @math.sin(value)
  let cosv = @math.cos(value)
  if cosv >= 0.0F && cosv < 1.0e-6F {
    sinv / 1.0e-6F
  } else if cosv < 0.0F && cosv > -1.0e-6F {
    sinv / -1.0e-6F
  } else {
    sinv / cosv
  }
}

///|
pub fn render3d_spot_light_clip_from_view(
  angle : Float,
  near_z : Float,
) -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_mat4(@light.spot_light_clip_from_view(angle, near_z))
}

///|
pub fn render3d_projection_matrix_from_affine3(
  affine : @math.Affine3,
) -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(
      affine.matrix3.x_axis.x,
      affine.matrix3.x_axis.y,
      affine.matrix3.x_axis.z,
      0.0F,
    ),
    @math.Vec4::new(
      affine.matrix3.y_axis.x,
      affine.matrix3.y_axis.y,
      affine.matrix3.y_axis.z,
      0.0F,
    ),
    @math.Vec4::new(
      affine.matrix3.z_axis.x,
      affine.matrix3.z_axis.y,
      affine.matrix3.z_axis.z,
      0.0F,
    ),
    @math.Vec4::new(
      affine.translation.x,
      affine.translation.y,
      affine.translation.z,
      1.0F,
    ),
  )
}

///|
pub fn render3d_spot_light_clip_from_world(
  transform : @transform.Transform,
  angle : Float,
  near_z : Float,
) -> ProjectionMatrix3d {
  let world_from_view = @light.spot_light_world_from_view(
    @transform.GlobalTransform::from_transform(transform),
  )
  render3d_spot_light_clip_from_view(angle, near_z).mul(
    render3d_projection_matrix_from_affine3(world_from_view.inverse()),
  )
}

///|
fn render3d_scale_color(color : @color.Color, scale : Float) -> @color.Color {
  @color.Color::new(
    color.r * scale,
    color.g * scale,
    color.b * scale,
    color.a * scale,
  )
}

///|
fn render3d_bool_sort_key(value : Bool) -> Int {
  if value {
    1
  } else {
    0
  }
}

///|
fn render3d_point_light_shadow_texel_size(world : @ecs.World) -> Float {
  let shadow_map_size = match
    world.get_resource(@light.ecs_key_point_light_shadow_map) {
    Some(v) => if v.size <= 0 { 1 } else { v.size }
    None => @light.PointLightShadowMap::PointLightShadowMap().size
  }
  2.0F / Float::from_double(shadow_map_size.to_double())
}

///|
fn render3d_directional_light_shadow_map_size(world : @ecs.World) -> Int {
  match world.get_resource(@light.ecs_key_directional_light_shadow_map) {
    Some(v) => if v.size <= 0 { 1 } else { v.size }
    None => @light.DirectionalLightShadowMap::DirectionalLightShadowMap().size
  }
}

///|
fn render3d_light_is_view_visible(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  match (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(v) => v.is_visible()
    None => true
  }
}

///|
fn render3d_directional_light_decal_index(
  world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  match world.get_resource(@pbr_decal.ecs_key_render_clustered_decals) {
    Some(decals) =>
      match decals.get_decal_index(entity) {
        Some(index) => index
        None => -1
      }
    None => -1
  }
}

///|
pub struct ExtractedPointLight3d {
  entity : @core.Entity
  color : @color.Color
  intensity : Float
  range : Float
  radius : Float
  transform : @transform.Transform
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  shadow_map_near_z : Float
  spot_light_angles : (Float, Float)?
  volumetric : Bool
  soft_shadows_enabled : Bool
  affects_lightmapped_mesh_diffuse : Bool
}

///|
pub let ecs_key_extracted_point_light3d : @ecs.ComponentKey[
  ExtractedPointLight3d,
] = @ecs.register_component(debug_name="mgstudio_pbr::ExtractedPointLight3d")

///|
pub impl @ecs.Component for ExtractedPointLight3d with fn component() {
  ecs_key_extracted_point_light3d
}

///|
pub struct ExtractedClusterablePointLight3d {
  clusterable_type_order : Int
  light : ExtractedPointLight3d
}

///|
pub fn ExtractedClusterablePointLight3d::is_point_light(
  self : ExtractedClusterablePointLight3d,
) -> Bool {
  self.clusterable_type_order == 0
}

///|
pub fn ExtractedClusterablePointLight3d::is_spot_light(
  self : ExtractedClusterablePointLight3d,
) -> Bool {
  self.clusterable_type_order == 1
}

///|
pub fn ExtractedClusterablePointLight3d::light(
  self : ExtractedClusterablePointLight3d,
) -> ExtractedPointLight3d {
  self.light
}

///|
pub struct ExtractedDirectionalLight3d {
  entity : @core.Entity
  color : @color.Color
  illuminance : Float
  transform : @transform.Transform
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  volumetric : Bool
  affects_lightmapped_mesh_diffuse : Bool
  soft_shadow_size : Float?
  cascade_count : Int
  cascade_bounds : Array[Float]
  cascade_overlap_proportion : Float
  cascade_minimum_distance : Float
  cascades : @light.Cascades
  render_layers : @camera_render_layers.RenderLayers
  occlusion_culling : Bool
  sun_disk_angular_size : Float
  sun_disk_intensity : Float
}

///|
pub let ecs_key_extracted_directional_light3d : @ecs.ComponentKey[
  ExtractedDirectionalLight3d,
] = @ecs.register_component(
  debug_name="mgstudio_pbr::ExtractedDirectionalLight3d",
)

///|
pub impl @ecs.Component for ExtractedDirectionalLight3d with fn component() {
  ecs_key_extracted_directional_light3d
}

///|
pub struct ExtractedRectLight3d {
  entity : @core.Entity
  color : @color.Color
  intensity : Float
  range : Float
  width : Float
  height : Float
  transform : @transform.Transform
}

///|
pub let ecs_key_extracted_rect_light3d : @ecs.ComponentKey[ExtractedRectLight3d] = @ecs.register_component(
  debug_name="mgstudio_pbr::ExtractedRectLight3d",
)

///|
pub impl @ecs.Component for ExtractedRectLight3d with fn component() {
  ecs_key_extracted_rect_light3d
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::DirectionalLightViewEntities`.
pub struct DirectionalLightViewEntities {
  view_entities_by_view : @hashmap.HashMap[@core.Entity, Array[@core.Entity]]
}

///|
pub fn DirectionalLightViewEntities::DirectionalLightViewEntities() -> DirectionalLightViewEntities {
  DirectionalLightViewEntities::{ view_entities_by_view: @hashmap.HashMap([]) }
}

///|
pub fn DirectionalLightViewEntities::insert(
  self : DirectionalLightViewEntities,
  view : @core.Entity,
  entities : Array[@core.Entity],
) -> Unit {
  self.view_entities_by_view.set(view, entities)
}

///|
pub fn DirectionalLightViewEntities::len(
  self : DirectionalLightViewEntities,
) -> Int {
  self.view_entities_by_view.length()
}

///|
pub fn DirectionalLightViewEntities::despawn_view_entities(
  self : DirectionalLightViewEntities,
  world : @ecs.World,
) -> Unit {
  for entities in self.view_entities_by_view.values() {
    for entity in entities {
      world.despawn(entity) catch {
        _ => ()
      }
    }
  }
}

///|
pub let ecs_key_directional_light_view_entities : @ecs.ComponentKey[
  DirectionalLightViewEntities,
] = @ecs.register_component(
  debug_name="mgstudio_pbr::DirectionalLightViewEntities",
)

///|
pub impl @ecs.Component for DirectionalLightViewEntities with fn component() {
  ecs_key_directional_light_view_entities
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::PointAndSpotLightViewEntities`.
pub struct PointAndSpotLightViewEntities {
  entities : Array[@core.Entity]
}

///|
pub fn PointAndSpotLightViewEntities::PointAndSpotLightViewEntities() -> PointAndSpotLightViewEntities {
  PointAndSpotLightViewEntities::{ entities: [] }
}

///|
pub fn PointAndSpotLightViewEntities::new(
  entities : Array[@core.Entity],
) -> PointAndSpotLightViewEntities {
  PointAndSpotLightViewEntities::{ entities, }
}

///|
pub fn PointAndSpotLightViewEntities::len(
  self : PointAndSpotLightViewEntities,
) -> Int {
  self.entities.length()
}

///|
pub fn PointAndSpotLightViewEntities::despawn_view_entities(
  self : PointAndSpotLightViewEntities,
  world : @ecs.World,
) -> Unit {
  for entity in self.entities {
    world.despawn(entity) catch {
      _ => ()
    }
  }
}

///|
pub let ecs_key_point_and_spot_light_view_entities : @ecs.ComponentKey[
  PointAndSpotLightViewEntities,
] = @ecs.register_component(
  debug_name="mgstudio_pbr::PointAndSpotLightViewEntities",
)

///|
pub impl @ecs.Component for PointAndSpotLightViewEntities with fn component() {
  ecs_key_point_and_spot_light_view_entities
}

///|
// Bevy source: `bevy_pbr/src/render/light.rs::add_light_view_entities`.
pub fn add_light_view_entities(
  add : @ecs.ComponentOn[@ecs.Add, ExtractedDirectionalLight3d],
) -> Unit {
  let world = add.world()
  world.set_by_key(
    add.entity(),
    ecs_key_directional_light_view_entities,
    DirectionalLightViewEntities::DirectionalLightViewEntities(),
  ) catch {
    _ => ()
  }
}

///|
// Bevy source: `bevy_pbr/src/render/light.rs::remove_light_view_entities`.
pub fn remove_light_view_entities(
  remove : @ecs.ComponentOn[@ecs.Remove, DirectionalLightViewEntities],
) -> Unit {
  let world = remove.world()
  match
    (world.get_by_key(remove.entity(), ecs_key_directional_light_view_entities) catch {
      _ => None
    }) {
    Some(entities) => entities.despawn_view_entities(world)
    None => ()
  }
}

///|
// Bevy source: `bevy_pbr/src/render/light.rs::remove_point_and_spot_light_view_entities`.
pub fn remove_point_and_spot_light_view_entities(
  remove : @ecs.ComponentOn[@ecs.Remove, PointAndSpotLightViewEntities],
) -> Unit {
  let world = remove.world()
  match
    (world.get_by_key(
      remove.entity(),
      ecs_key_point_and_spot_light_view_entities,
    ) catch {
      _ => None
    }) {
    Some(entities) => entities.despawn_view_entities(world)
    None => ()
  }
}

///|
fn light_sync_target_remove_common_shadow_components(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> Unit {
  ignore(
    render_world.remove_by_key(
      render_entity, @render_view_visibility.ecs_key_render_extracted_shadow_map_visible_entities,
    ) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(
      render_entity, @render_view_visibility.ecs_key_render_shadow_map_visible_entities,
    ) catch {
      _ => false
    },
  )
}

///|
// Bevy source: `impl SyncComponent<PbrPlugin> for DirectionalLight`.
pub fn remove_directional_light_sync_target(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @ecs.World {
  ignore(
    render_world.remove_by_key(render_entity, @light.ecs_key_directional_light) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(
      render_entity, ecs_key_extracted_directional_light3d,
    ) catch {
      _ => false
    },
  )
  light_sync_target_remove_common_shadow_components(render_world, render_entity)
  ignore(
    render_world.remove_by_key(
      render_entity, ecs_key_directional_light_view_entities,
    ) catch {
      _ => false
    },
  )
  render_world
}

///|
// Bevy source: `impl SyncComponent<PbrPlugin> for PointLight`.
pub fn remove_point_light_sync_target(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @ecs.World {
  ignore(
    render_world.remove_by_key(render_entity, @light.ecs_key_point_light) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_extracted_point_light3d) catch {
      _ => false
    },
  )
  light_sync_target_remove_common_shadow_components(render_world, render_entity)
  ignore(
    render_world.remove_by_key(
      render_entity, ecs_key_point_and_spot_light_view_entities,
    ) catch {
      _ => false
    },
  )
  render_world
}

///|
// Bevy source: `impl SyncComponent<PbrPlugin> for SpotLight`.
pub fn remove_spot_light_sync_target(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @ecs.World {
  ignore(
    render_world.remove_by_key(render_entity, @light.ecs_key_spot_light) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_extracted_point_light3d) catch {
      _ => false
    },
  )
  light_sync_target_remove_common_shadow_components(render_world, render_entity)
  ignore(
    render_world.remove_by_key(
      render_entity, ecs_key_point_and_spot_light_view_entities,
    ) catch {
      _ => false
    },
  )
  render_world
}

///|
// Bevy source: `impl SyncComponent<PbrPlugin> for RectLight`.
pub fn remove_rect_light_sync_target(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @ecs.World {
  ignore(
    render_world.remove_by_key(render_entity, @light.ecs_key_rect_light) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_extracted_rect_light3d) catch {
      _ => false
    },
  )
  render_world
}

///|
priv struct LightExtractionState {
  mut last_source_change_tick : @core.Tick
}

///|
let ecs_key_light_extraction_state : @ecs.ResourceKey[LightExtractionState] = @ecs.register_resource(
  debug_name="mgstudio_pbr::LightExtractionState",
)

///|
fn light_extraction_system_ticks(
  render_world : @ecs.World,
  source_world : @ecs.World,
) -> @core.SystemTicks {
  let this_run = source_world.read_change_tick()
  let last_run = match
    render_world.get_resource(ecs_key_light_extraction_state) {
    Some(state) => state.last_source_change_tick
    None => 0
  }
  @core.SystemTicks::new(last_run, this_run)
}

///|
fn light_extraction_set_last_source_change_tick(
  render_world : @ecs.World,
  tick : @core.Tick,
) -> Unit {
  match render_world.get_resource_mut(ecs_key_light_extraction_state) {
    Some(state) =>
      state.modify(fn(value) { value.last_source_change_tick = tick })
    None =>
      render_world.insert_resource(ecs_key_light_extraction_state, LightExtractionState::{
        last_source_change_tick: tick,
      })
  }
}

///|
pub struct GpuDirectionalCascade3d {
  far_bound : Float
  texel_size : Float
  clip_from_world : ProjectionMatrix3d
}

///|
pub struct GpuDirectionalLight3d {
  cascades : Array[GpuDirectionalCascade3d]
  color : @color.Color
  dir_to_light : @math.Vec3
  flags : UInt
  soft_shadow_size : Float
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  num_cascades : Int
  cascades_overlap_proportion : Float
  depth_texture_base_index : Int
  decal_index : Int
  sun_disk_angular_size : Float
  sun_disk_intensity : Float
}

///|
pub struct GpuRectLight3d {
  color : @color.Color
  position : @math.Vec3
  width : Float
  right : @math.Vec3
  height : Float
  up : @math.Vec3
  range : Float
}

///|
pub struct GpuLights3d {
  directional_lights : Array[GpuDirectionalLight3d]
  ambient_color : @color.Color
  cluster_dimensions : (Int, Int, Int, Int)
  cluster_factors : @math.Vec4
  n_directional_lights : Int
  spot_light_shadowmap_offset : Int
  ambient_light_affects_lightmapped_meshes : Int
  n_rect_lights : Int
  rect_lights : Array[GpuRectLight3d]
}

///|
pub fn GpuLights3d::GpuLights3d() -> GpuLights3d {
  GpuLights3d::{
    directional_lights: [],
    ambient_color: @color.Color::black(),
    cluster_dimensions: (0, 0, 0, 0),
    cluster_factors: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    n_directional_lights: 0,
    spot_light_shadowmap_offset: 0,
    ambient_light_affects_lightmapped_meshes: 0,
    n_rect_lights: 0,
    rect_lights: [],
  }
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::LightMeta`.

///|
pub struct ViewLightsUniformOffset {
  offset : UInt
}

///|
pub fn ViewLightsUniformOffset::new(offset : UInt) -> ViewLightsUniformOffset {
  ViewLightsUniformOffset::{ offset, }
}

///|
pub fn ViewLightsUniformOffset::offset(self : ViewLightsUniformOffset) -> UInt {
  self.offset
}

///|
pub let ecs_key_view_lights_uniform_offset : @ecs.ComponentKey[
  ViewLightsUniformOffset,
] = @ecs.register_component(debug_name="mgstudio_pbr::ViewLightsUniformOffset")

///|
pub impl @ecs.Component for ViewLightsUniformOffset with fn component() {
  ecs_key_view_lights_uniform_offset
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::ViewLightEntities`.
pub struct ViewLightEntities {
  lights : Array[@core.Entity]
}

///|
pub fn ViewLightEntities::new(
  lights : Array[@core.Entity],
) -> ViewLightEntities {
  ViewLightEntities::{ lights, }
}

///|
pub fn ViewLightEntities::ViewLightEntities() -> ViewLightEntities {
  ViewLightEntities::{ lights: [] }
}

///|
pub fn ViewLightEntities::lights(
  self : ViewLightEntities,
) -> Array[@core.Entity] {
  self.lights
}

///|
pub fn ViewLightEntities::len(self : ViewLightEntities) -> Int {
  self.lights.length()
}

///|
pub let ecs_key_view_light_entities : @ecs.ComponentKey[ViewLightEntities] = @ecs.register_component(
  debug_name="mgstudio_pbr::ViewLightEntities",
)

///|
pub impl @ecs.Component for ViewLightEntities with fn component() {
  ecs_key_view_light_entities
}

///|
pub struct LightMeta {
  view_gpu_lights : @render_resource.DynamicUniformBuffer[GpuLights3d]
  mut view_gpu_lights_buffer : @wgpu.Buffer?
  mut view_gpu_lights_capacity : UInt64
}

///|
pub fn LightMeta::LightMeta() -> LightMeta {
  LightMeta::{
    view_gpu_lights: @render_resource.DynamicUniformBuffer::new(),
    view_gpu_lights_buffer: None,
    view_gpu_lights_capacity: 0UL,
  }
}

///|
pub fn LightMeta::view_gpu_lights_len(self : LightMeta) -> Int {
  self.view_gpu_lights.len()
}

///|
pub fn LightMeta::view_gpu_lights_at(
  self : LightMeta,
  index : Int,
) -> GpuLights3d? {
  self.view_gpu_lights.values().get(index)
}

///|
pub fn LightMeta::push_view_gpu_lights(
  self : LightMeta,
  lights : GpuLights3d,
) -> UInt {
  let offset = self.view_gpu_lights.len() *
    render3d_gpu_lights_uniform_bytes(lights).length()
  self.view_gpu_lights.push(lights)
  offset.reinterpret_as_uint()
}

///|
pub fn LightMeta::clear_view_gpu_lights(self : LightMeta) -> Unit {
  self.view_gpu_lights.clear()
}

///|
fn light_meta_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
fn LightMeta::view_gpu_lights_bytes(self : LightMeta) -> Bytes {
  let out : Array[Byte] = []
  for lights in self.view_gpu_lights.values() {
    let bytes = render3d_gpu_lights_uniform_bytes(lights)
    for byte in bytes {
      out.push(byte)
    }
  }
  Bytes::from_array(out)
}

///|
pub fn LightMeta::write_view_gpu_lights_buffer(
  self : LightMeta,
  device : @wgpu.Device,
  queue : @wgpu.Queue,
) -> Unit {
  let bytes = self.view_gpu_lights_bytes()
  if bytes.length() == 0 {
    return
  }
  let required_size = light_meta_non_zero_u64(bytes.length().to_uint64())
  let buffer = match self.view_gpu_lights_buffer {
    Some(existing) if self.view_gpu_lights_capacity >= required_size => existing
    Some(existing) => {
      existing.release()
      let next = device.create_buffer(
        size=required_size,
        usage=@wgpu.BufferUsage::from_u64(
          @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
        ),
      )
      next.set_label("view gpu lights buffer")
      self.view_gpu_lights_capacity = required_size
      next
    }
    None => {
      let next = device.create_buffer(
        size=required_size,
        usage=@wgpu.BufferUsage::from_u64(
          @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
        ),
      )
      next.set_label("view gpu lights buffer")
      self.view_gpu_lights_capacity = required_size
      next
    }
  }
  queue.write_buffer(buffer, 0UL, bytes)
  self.view_gpu_lights_buffer = Some(buffer)
}

///|
pub fn LightMeta::view_gpu_lights_binding(self : LightMeta) -> @wgpu.Buffer? {
  self.view_gpu_lights_buffer
}

///|
pub fn LightMeta::view_gpu_lights_capacity(self : LightMeta) -> UInt64 {
  self.view_gpu_lights_capacity
}

///|
pub let ecs_key_light_meta : @ecs.ResourceKey[LightMeta] = @ecs.register_resource(
  debug_name="mgstudio_pbr::LightMeta",
)

///|
pub impl @app.Resource for LightMeta with fn resource() {
  ecs_key_light_meta
}

///|
const MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS : Int = 204

///|
const MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES : Int = 16384

///|
const MAX_STORAGE_BUFFER_CLUSTERS : Int = 4096

///|
priv struct Render3dClusteredLightFlagLimits {
  point_light_count : Int
  point_light_shadow_maps_count : Int
  point_light_volumetric_enabled_count : Int
  spot_light_shadow_maps_count : Int
  spot_light_volumetric_enabled_count : Int
}

///|
fn render3d_min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn render3d_max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn render3d_lights_max_texture_array_layers(world : @ecs.World) -> Int {
  match world.get_resource(@render_gpu.render_device_resource_key) {
    Some(render_device) =>
      render_device.limits_max_texture_array_layers_u32().reinterpret_as_int()
    None =>
      // Unit tests call this CPU mirror without a render device. Bevy's runtime
      // path always receives `RenderDevice`; use the WebGPU native floor here
      // only for offline byte-layout tests.
      256
  }
}

///|
fn render3d_clustered_light_flag_limits(
  world : @ecs.World,
  clusterable_lights : Array[ExtractedClusterablePointLight3d],
) -> Render3dClusteredLightFlagLimits {
  let max_texture_array_layers = render3d_lights_max_texture_array_layers(world)
  let max_texture_cubes = max_texture_array_layers / 6
  let mut point_light_count = 0
  let mut point_light_shadow_maps_enabled_count = 0
  let mut point_light_volumetric_enabled_count = 0
  let mut spot_light_shadow_maps_enabled_count = 0
  let mut spot_light_volumetric_enabled_count = 0
  for clustered in clusterable_lights {
    let light = clustered.light()
    if clustered.is_spot_light() {
      if light.shadow_maps_enabled {
        spot_light_shadow_maps_enabled_count += 1
      }
      if light.volumetric {
        spot_light_volumetric_enabled_count += 1
      }
    } else {
      point_light_count += 1
      if light.shadow_maps_enabled {
        point_light_shadow_maps_enabled_count += 1
      }
      if light.volumetric {
        point_light_volumetric_enabled_count += 1
      }
    }
  }
  let directional_lights = render3d_collect_extracted_directional_lights(world)
  let mut directional_shadow_enabled_count = 0
  let directional_count = render3d_min_int(
    directional_lights.length(),
    MAX_DIRECTIONAL_LIGHTS,
  )
  for i in 0..<directional_count {
    if directional_lights[i].shadow_maps_enabled {
      directional_shadow_enabled_count += 1
    }
  }
  directional_shadow_enabled_count = render3d_min_int(
    directional_shadow_enabled_count,
    max_texture_array_layers / MAX_CASCADES_PER_LIGHT,
  )
  let remaining_spot_texture_layers = render3d_max_int(
    0,
    max_texture_array_layers -
    directional_shadow_enabled_count * MAX_CASCADES_PER_LIGHT,
  )
  Render3dClusteredLightFlagLimits::{
    point_light_count,
    point_light_shadow_maps_count: render3d_min_int(
      point_light_shadow_maps_enabled_count, max_texture_cubes,
    ),
    point_light_volumetric_enabled_count: render3d_min_int(
      point_light_volumetric_enabled_count, max_texture_cubes,
    ),
    spot_light_shadow_maps_count: render3d_min_int(
      spot_light_shadow_maps_enabled_count, remaining_spot_texture_layers,
    ),
    spot_light_volumetric_enabled_count: render3d_min_int(
      spot_light_volumetric_enabled_count, remaining_spot_texture_layers,
    ),
  }
}

///|
fn render3d_clustered_point_light_flags(
  clustered : ExtractedClusterablePointLight3d,
  index : Int,
  limits : Render3dClusteredLightFlagLimits,
) -> UInt {
  let extracted = clustered.light()
  let mut flags = POINT_LIGHT_FLAG_NONE
  if extracted.shadow_maps_enabled {
    if clustered.is_spot_light() {
      let spot_index = index - limits.point_light_count
      if spot_index >= 0 && spot_index < limits.spot_light_shadow_maps_count {
        flags = flags | POINT_LIGHT_FLAG_SHADOW_MAPS_ENABLED
      }
    } else if index < limits.point_light_shadow_maps_count {
      flags = flags | POINT_LIGHT_FLAG_SHADOW_MAPS_ENABLED
    }
  }
  if extracted.contact_shadows_enabled {
    flags = flags | POINT_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED
  }
  if clustered.is_spot_light() {
    flags = flags | POINT_LIGHT_FLAG_SPOT_LIGHT
    let light_direction = render3d_transform_forward(extracted.transform)
    if light_direction.y < 0.0F {
      flags = flags | POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE
    }
  }
  if extracted.volumetric && extracted.shadow_maps_enabled {
    if clustered.is_spot_light() {
      let spot_index = index - limits.point_light_count
      if spot_index >= 0 &&
        spot_index < limits.spot_light_volumetric_enabled_count {
        flags = flags | POINT_LIGHT_FLAG_VOLUMETRIC
      }
    } else if index < limits.point_light_volumetric_enabled_count {
      flags = flags | POINT_LIGHT_FLAG_VOLUMETRIC
    }
  }
  if extracted.affects_lightmapped_mesh_diffuse {
    flags = flags | POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  }
  flags
}

///|
fn render3d_lights_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn render3d_lights_push_u32(words : Array[UInt], value : UInt) -> Unit {
  words.push(value)
}

///|
fn render3d_lights_push_i32(words : Array[UInt], value : Int) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn render3d_lights_push_matrix(
  words : Array[UInt],
  matrix : ProjectionMatrix3d,
) -> Unit {
  render3d_lights_push_f32(words, matrix.x_axis.x)
  render3d_lights_push_f32(words, matrix.x_axis.y)
  render3d_lights_push_f32(words, matrix.x_axis.z)
  render3d_lights_push_f32(words, matrix.x_axis.w)
  render3d_lights_push_f32(words, matrix.y_axis.x)
  render3d_lights_push_f32(words, matrix.y_axis.y)
  render3d_lights_push_f32(words, matrix.y_axis.z)
  render3d_lights_push_f32(words, matrix.y_axis.w)
  render3d_lights_push_f32(words, matrix.z_axis.x)
  render3d_lights_push_f32(words, matrix.z_axis.y)
  render3d_lights_push_f32(words, matrix.z_axis.z)
  render3d_lights_push_f32(words, matrix.z_axis.w)
  render3d_lights_push_f32(words, matrix.w_axis.x)
  render3d_lights_push_f32(words, matrix.w_axis.y)
  render3d_lights_push_f32(words, matrix.w_axis.z)
  render3d_lights_push_f32(words, matrix.w_axis.w)
}

///|
fn render3d_lights_push_directional_cascade(
  words : Array[UInt],
  cascade : GpuDirectionalCascade3d,
) -> Unit {
  render3d_lights_push_matrix(words, cascade.clip_from_world)
  render3d_lights_push_f32(words, cascade.texel_size)
  render3d_lights_push_f32(words, cascade.far_bound)
  render3d_lights_push_f32(words, 0.0F)
  render3d_lights_push_f32(words, 0.0F)
}

///|
fn render3d_lights_push_directional_light(
  words : Array[UInt],
  light : GpuDirectionalLight3d,
) -> Unit {
  for cascade_index in 0..<MAX_CASCADES_PER_LIGHT {
    let cascade = if cascade_index < light.cascades.length() {
      light.cascades[cascade_index]
    } else {
      render3d_gpu_directional_cascade_default()
    }
    render3d_lights_push_directional_cascade(words, cascade)
  }
  render3d_lights_push_f32(words, light.color.r)
  render3d_lights_push_f32(words, light.color.g)
  render3d_lights_push_f32(words, light.color.b)
  render3d_lights_push_f32(words, light.color.a)
  render3d_lights_push_f32(words, light.dir_to_light.x)
  render3d_lights_push_f32(words, light.dir_to_light.y)
  render3d_lights_push_f32(words, light.dir_to_light.z)
  render3d_lights_push_u32(words, light.flags)
  render3d_lights_push_f32(words, light.soft_shadow_size)
  render3d_lights_push_f32(words, light.shadow_depth_bias)
  render3d_lights_push_f32(words, light.shadow_normal_bias)
  render3d_lights_push_u32(words, light.num_cascades.reinterpret_as_uint())
  render3d_lights_push_f32(words, light.cascades_overlap_proportion)
  render3d_lights_push_u32(
    words,
    light.depth_texture_base_index.reinterpret_as_uint(),
  )
  render3d_lights_push_i32(words, light.decal_index)
  render3d_lights_push_f32(words, light.sun_disk_angular_size)
  render3d_lights_push_f32(words, light.sun_disk_intensity)
  render3d_lights_push_f32(words, 0.0F)
  render3d_lights_push_f32(words, 0.0F)
  render3d_lights_push_f32(words, 0.0F)
}

///|
fn render3d_gpu_rect_light_default() -> GpuRectLight3d {
  GpuRectLight3d::{
    color: @color.Color::black(),
    position: @math.Vec3::zero(),
    width: 0.0F,
    right: @math.Vec3::zero(),
    height: 0.0F,
    up: @math.Vec3::zero(),
    range: 0.0F,
  }
}

///|
fn render3d_lights_push_rect_light(
  words : Array[UInt],
  light : GpuRectLight3d,
) -> Unit {
  render3d_lights_push_f32(words, light.color.r)
  render3d_lights_push_f32(words, light.color.g)
  render3d_lights_push_f32(words, light.color.b)
  render3d_lights_push_f32(words, light.color.a)
  render3d_lights_push_f32(words, light.position.x)
  render3d_lights_push_f32(words, light.position.y)
  render3d_lights_push_f32(words, light.position.z)
  render3d_lights_push_f32(words, light.width)
  render3d_lights_push_f32(words, light.right.x)
  render3d_lights_push_f32(words, light.right.y)
  render3d_lights_push_f32(words, light.right.z)
  render3d_lights_push_f32(words, light.height)
  render3d_lights_push_f32(words, light.up.x)
  render3d_lights_push_f32(words, light.up.y)
  render3d_lights_push_f32(words, light.up.z)
  render3d_lights_push_f32(words, light.range)
}

///|
fn render3d_lights_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
pub fn render3d_gpu_lights_uniform_bytes(lights : GpuLights3d) -> Bytes {
  let words : Array[UInt] = []
  for light_index in 0..<MAX_DIRECTIONAL_LIGHTS {
    let light = if light_index < lights.directional_lights.length() {
      lights.directional_lights[light_index]
    } else {
      render3d_gpu_directional_light_default()
    }
    render3d_lights_push_directional_light(words, light)
  }
  render3d_lights_push_f32(words, lights.ambient_color.r)
  render3d_lights_push_f32(words, lights.ambient_color.g)
  render3d_lights_push_f32(words, lights.ambient_color.b)
  render3d_lights_push_f32(words, lights.ambient_color.a)
  render3d_lights_push_u32(
    words,
    lights.cluster_dimensions.0.reinterpret_as_uint(),
  )
  render3d_lights_push_u32(
    words,
    lights.cluster_dimensions.1.reinterpret_as_uint(),
  )
  render3d_lights_push_u32(
    words,
    lights.cluster_dimensions.2.reinterpret_as_uint(),
  )
  render3d_lights_push_u32(
    words,
    lights.cluster_dimensions.3.reinterpret_as_uint(),
  )
  render3d_lights_push_f32(words, lights.cluster_factors.x)
  render3d_lights_push_f32(words, lights.cluster_factors.y)
  render3d_lights_push_f32(words, lights.cluster_factors.z)
  render3d_lights_push_f32(words, lights.cluster_factors.w)
  render3d_lights_push_u32(
    words,
    lights.n_directional_lights.reinterpret_as_uint(),
  )
  render3d_lights_push_i32(words, lights.spot_light_shadowmap_offset)
  render3d_lights_push_u32(
    words,
    lights.ambient_light_affects_lightmapped_meshes.reinterpret_as_uint(),
  )
  render3d_lights_push_u32(words, lights.n_rect_lights.reinterpret_as_uint())
  for rect_light_index in 0..<MAX_RECT_LIGHTS {
    let rect_light = if rect_light_index < lights.rect_lights.length() {
      lights.rect_lights[rect_light_index]
    } else {
      render3d_gpu_rect_light_default()
    }
    render3d_lights_push_rect_light(words, rect_light)
  }
  render3d_lights_u32le_pack(words)
}

///|
fn render3d_gpu_directional_cascade_from_flat_data(
  data : Array[Float],
  cascade_index : Int,
) -> GpuDirectionalCascade3d {
  let base = cascade_index * 20
  if cascade_index < 0 || base + 17 >= data.length() {
    return render3d_gpu_directional_cascade_default()
  }
  GpuDirectionalCascade3d::{
    clip_from_world: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(
        data[base],
        data[base + 1],
        data[base + 2],
        data[base + 3],
      ),
      @math.Vec4::new(
        data[base + 4],
        data[base + 5],
        data[base + 6],
        data[base + 7],
      ),
      @math.Vec4::new(
        data[base + 8],
        data[base + 9],
        data[base + 10],
        data[base + 11],
      ),
      @math.Vec4::new(
        data[base + 12],
        data[base + 13],
        data[base + 14],
        data[base + 15],
      ),
    ),
    texel_size: data[base + 16],
    far_bound: data[base + 17],
  }
}

///|
fn render3d_clamp_directional_cascade_count(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > MAX_CASCADES_PER_LIGHT {
    MAX_CASCADES_PER_LIGHT
  } else {
    value
  }
}

///|
pub fn render3d_gpu_lights_with_directional_shadow_cascades(
  lights : GpuLights3d,
  directional_shadow_texture_id : Int,
  directional_shadow_enabled : Float,
  directional_shadow_cascade_count : Int,
  directional_shadow_cascade_overlap : Float,
  directional_shadow_cascade_data : Array[Float],
) -> GpuLights3d {
  let cascades_enabled = directional_shadow_texture_id >= 0 &&
    directional_shadow_enabled > 0.5F
  let resolved_cascade_count = if cascades_enabled {
    render3d_clamp_directional_cascade_count(directional_shadow_cascade_count)
  } else {
    0
  }
  if resolved_cascade_count == 0 {
    return lights
  }
  let resolved_cascades : Array[GpuDirectionalCascade3d] = []
  for cascade_index in 0..<MAX_CASCADES_PER_LIGHT {
    if cascade_index < resolved_cascade_count {
      resolved_cascades.push(
        render3d_gpu_directional_cascade_from_flat_data(
          directional_shadow_cascade_data, cascade_index,
        ),
      )
    } else {
      resolved_cascades.push(render3d_gpu_directional_cascade_default())
    }
  }
  let directional_lights : Array[GpuDirectionalLight3d] = []
  for light_index in 0..<lights.directional_lights.length() {
    let light = lights.directional_lights[light_index]
    if light_index == 0 {
      directional_lights.push(GpuDirectionalLight3d::{
        ..light,
        cascades: resolved_cascades,
        flags: light.flags | DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED,
        num_cascades: resolved_cascade_count,
        cascades_overlap_proportion: directional_shadow_cascade_overlap,
      })
    } else {
      directional_lights.push(light)
    }
  }
  GpuLights3d::{ ..lights, directional_lights, }
}

///|
fn render3d_clustered_light_index(
  lights : Array[ExtractedClusterablePointLight3d],
  entity : @core.Entity,
) -> Int {
  for i in 0..<lights.length() {
    if lights[i].light.entity == entity {
      return i
    }
  }
  -1
}

///|
fn render3d_clustered_decal_index(
  world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  match world.get_resource(@pbr_decal.ecs_key_render_clustered_decals) {
    Some(decals) =>
      match decals.get_decal_index(entity) {
        Some(index) => index
        None => -1
      }
    None => -1
  }
}

///|
fn render3d_lights_push_clustered_light(
  world : @ecs.World,
  words : Array[UInt],
  item : ExtractedClusterablePointLight3d?,
  index : Int,
  flag_limits : Render3dClusteredLightFlagLimits,
) -> Unit {
  match item {
    None =>
      for _ in 0..<20 {
        render3d_lights_push_u32(words, 0U)
      }
    Some(clustered) => {
      let extracted = clustered.light()
      match extracted.spot_light_angles {
        Some((inner, outer)) if clustered.is_spot_light() => {
          let direction = render3d_transform_forward(extracted.transform)
          let cos_outer = @math.cos(outer)
          let raw_denom = @math.cos(inner) - cos_outer
          let denom = if raw_denom < 0.0001F { 0.0001F } else { raw_denom }
          let spot_scale = 1.0F / denom
          let spot_offset = 0.0F - cos_outer * spot_scale
          render3d_lights_push_f32(words, direction.x)
          render3d_lights_push_f32(words, direction.z)
          render3d_lights_push_f32(words, spot_scale)
          render3d_lights_push_f32(words, spot_offset)
          render3d_lights_push_f32(
            words,
            extracted.color.r * extracted.intensity,
          )
          render3d_lights_push_f32(
            words,
            extracted.color.g * extracted.intensity,
          )
          render3d_lights_push_f32(
            words,
            extracted.color.b * extracted.intensity,
          )
          render3d_lights_push_f32(
            words,
            1.0F / (extracted.range * extracted.range),
          )
          render3d_lights_push_f32(words, extracted.transform.translation.x)
          render3d_lights_push_f32(words, extracted.transform.translation.y)
          render3d_lights_push_f32(words, extracted.transform.translation.z)
          render3d_lights_push_f32(words, extracted.radius)
          render3d_lights_push_u32(
            words,
            render3d_clustered_point_light_flags(clustered, index, flag_limits),
          )
          render3d_lights_push_f32(words, extracted.shadow_depth_bias)
          render3d_lights_push_f32(words, extracted.shadow_normal_bias)
          render3d_lights_push_f32(words, render3d_tan(outer))
          render3d_lights_push_f32(
            words,
            if extracted.soft_shadows_enabled {
              extracted.radius
            } else {
              0.0F
            },
          )
          render3d_lights_push_f32(words, extracted.shadow_map_near_z)
          let decal_index = render3d_clustered_decal_index(
            world,
            extracted.entity,
          )
          render3d_lights_push_u32(
            words,
            if decal_index >= 0 {
              decal_index.reinterpret_as_uint()
            } else {
              0xFFFF_FFFFU
            },
          )
          render3d_lights_push_f32(words, 0.0F)
        }
        _ => {
          let cube_face_projection = render3d_point_shadow_pass_projection(
              extracted.shadow_map_near_z,
              extracted.range,
            ).clip_from_view
          render3d_lights_push_f32(words, cube_face_projection.z_axis.z)
          render3d_lights_push_f32(words, cube_face_projection.z_axis.w)
          render3d_lights_push_f32(words, cube_face_projection.w_axis.z)
          render3d_lights_push_f32(words, cube_face_projection.w_axis.w)
          render3d_lights_push_f32(
            words,
            extracted.color.r * extracted.intensity,
          )
          render3d_lights_push_f32(
            words,
            extracted.color.g * extracted.intensity,
          )
          render3d_lights_push_f32(
            words,
            extracted.color.b * extracted.intensity,
          )
          render3d_lights_push_f32(
            words,
            1.0F / (extracted.range * extracted.range),
          )
          render3d_lights_push_f32(words, extracted.transform.translation.x)
          render3d_lights_push_f32(words, extracted.transform.translation.y)
          render3d_lights_push_f32(words, extracted.transform.translation.z)
          render3d_lights_push_f32(words, extracted.radius)
          render3d_lights_push_u32(
            words,
            render3d_clustered_point_light_flags(clustered, index, flag_limits),
          )
          render3d_lights_push_f32(words, extracted.shadow_depth_bias)
          render3d_lights_push_f32(words, extracted.shadow_normal_bias)
          render3d_lights_push_f32(words, 0.0F)
          render3d_lights_push_f32(
            words,
            if extracted.soft_shadows_enabled {
              extracted.radius
            } else {
              0.0F
            },
          )
          render3d_lights_push_f32(words, extracted.shadow_map_near_z)
          let decal_index = render3d_clustered_decal_index(
            world,
            extracted.entity,
          )
          render3d_lights_push_u32(
            words,
            if decal_index >= 0 {
              decal_index.reinterpret_as_uint()
            } else {
              0xFFFF_FFFFU
            },
          )
          render3d_lights_push_f32(words, 0.0F)
        }
      }
    }
  }
}

///|
fn render3d_gpu_cluster_buffers(
  world : @ecs.World,
  camera_entity : @core.Entity?,
  clusterable_lights : Array[ExtractedClusterablePointLight3d],
  reflection_probe_entities : Array[@core.Entity],
  irradiance_volume_entities : Array[@core.Entity],
) -> (Bytes, Bytes, Bytes) {
  let clustered_words : Array[UInt] = []
  let flag_limits = render3d_clustered_light_flag_limits(
    world, clusterable_lights,
  )
  for i in 0..<MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS {
    let item = if i < clusterable_lights.length() {
      Some(clusterable_lights[i])
    } else {
      None
    }
    render3d_lights_push_clustered_light(
      world, clustered_words, item, i, flag_limits,
    )
  }
  let index_words : Array[UInt] = []
  let offset_words : Array[UInt] = []
  let clusters = match render3d_cluster_camera_entity(world) {
    Some(entity) =>
      match camera_entity {
        Some(preferred) =>
          try! world.get_by_key(preferred, @light_cluster.Clusters::component())
        None =>
          try! world.get_by_key(entity, @light_cluster.Clusters::component())
      }
    None =>
      match camera_entity {
        Some(preferred) =>
          try! world.get_by_key(preferred, @light_cluster.Clusters::component())
        None => None
      }
  }
  let cluster_objects = match clusters {
    Some(value) => value.clusterable_objects()
    None => []
  }
  let mut next_index_offset = 0
  for cluster_index in 0..<MAX_STORAGE_BUFFER_CLUSTERS {
    let point_indices : Array[UInt] = []
    let spot_indices : Array[UInt] = []
    let reflection_probe_indices : Array[UInt] = []
    let irradiance_volume_indices : Array[UInt] = []
    let decal_indices : Array[UInt] = []
    if cluster_index < cluster_objects.length() {
      for entity in cluster_objects[cluster_index].iter() {
        let light_index = render3d_clustered_light_index(
          clusterable_lights, entity,
        )
        if light_index >= 0 {
          if (try! world.contains_by_key(entity, @light.ecs_key_spot_light)) {
            spot_indices.push(light_index.reinterpret_as_uint())
          } else {
            point_indices.push(light_index.reinterpret_as_uint())
          }
        } else if (try! world.contains_by_key(
            entity, @light.ecs_key_environment_map_light,
          )) {
          let reflection_probe_index = render3d_clustered_light_probe_index(
            reflection_probe_entities, entity,
          )
          if reflection_probe_index >= 0 {
            reflection_probe_indices.push(
              reflection_probe_index.reinterpret_as_uint(),
            )
          } else {
            reflection_probe_indices.push(0xFFFF_FFFFU)
          }
        } else if (try! world.contains_by_key(
            entity, @light.ecs_key_irradiance_volume,
          )) {
          let irradiance_volume_index = render3d_clustered_light_probe_index(
            irradiance_volume_entities, entity,
          )
          if irradiance_volume_index >= 0 {
            irradiance_volume_indices.push(
              irradiance_volume_index.reinterpret_as_uint(),
            )
          } else {
            irradiance_volume_indices.push(0xFFFF_FFFFU)
          }
        } else if (try! world.contains_by_key(
            entity, @light.ecs_key_clustered_decal,
          )) {
          let decal_index = render3d_clustered_decal_index(world, entity)
          if decal_index >= 0 {
            decal_indices.push(decal_index.reinterpret_as_uint())
          } else {
            decal_indices.push(0xFFFF_FFFFU)
          }
        }
      }
    }
    offset_words.push(next_index_offset.reinterpret_as_uint())
    offset_words.push(point_indices.length().reinterpret_as_uint())
    offset_words.push(spot_indices.length().reinterpret_as_uint())
    offset_words.push(reflection_probe_indices.length().reinterpret_as_uint())
    offset_words.push(irradiance_volume_indices.length().reinterpret_as_uint())
    offset_words.push(decal_indices.length().reinterpret_as_uint())
    offset_words.push(0U)
    offset_words.push(0U)
    for index in point_indices {
      if index_words.length() < MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES {
        index_words.push(index)
        next_index_offset += 1
      }
    }
    for index in spot_indices {
      if index_words.length() < MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES {
        index_words.push(index)
        next_index_offset += 1
      }
    }
    for index in reflection_probe_indices {
      if index_words.length() < MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES {
        index_words.push(index)
        next_index_offset += 1
      }
    }
    for index in irradiance_volume_indices {
      if index_words.length() < MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES {
        index_words.push(index)
        next_index_offset += 1
      }
    }
    for index in decal_indices {
      if index_words.length() < MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES {
        index_words.push(index)
        next_index_offset += 1
      }
    }
  }
  while index_words.length() < MAX_STORAGE_BUFFER_CLUSTERABLE_OBJECT_INDICES {
    index_words.push(0U)
  }
  (
    render3d_lights_u32le_pack(clustered_words),
    render3d_lights_u32le_pack(index_words),
    render3d_lights_u32le_pack(offset_words),
  )
}

///|
pub fn render3d_gpu_cluster_buffers_for_reflection_probe_entities(
  world : @ecs.World,
  camera_entity : @core.Entity,
  reflection_probe_entities : Array[@core.Entity],
  irradiance_volume_entities : Array[@core.Entity],
) -> (Bytes, Bytes, Bytes) {
  render3d_gpu_cluster_buffers(
    world,
    Some(camera_entity),
    render3d_collect_extracted_clusterable_point_lights(world),
    reflection_probe_entities,
    irradiance_volume_entities,
  )
}

///|
priv struct Render3dClusteredReflectionProbeIndexEntry {
  entity : @core.Entity
  distance_squared : Float
}

///|
fn render3d_clustered_reflection_probe_indices(
  world : @ecs.World,
) -> Array[@core.Entity] {
  let camera_transform = match render3d_cluster_camera_entity(world) {
    Some(entity) => render3d_extract_light_transform(world, entity)
    None => @transform.Transform::identity()
  }
  let entries : Array[Render3dClusteredReflectionProbeIndexEntry] = []
  world.for_each_component(@light.ecs_key_environment_map_light, fn(
    entity,
    _environment_map_light,
  ) {
    if !(try! world.contains_by_key(entity, @light.ecs_key_light_probe)) {
      return
    }
    let transform = render3d_extract_light_transform(world, entity)
    entries.push(Render3dClusteredReflectionProbeIndexEntry::{
      entity,
      distance_squared: transform.translation
      .sub(camera_transform.translation)
      .length_squared(),
    })
  })
  entries.sort_by(fn(left, right) {
    let distance_cmp = cmp_float(left.distance_squared, right.distance_squared)
    if distance_cmp != 0 {
      return distance_cmp
    }
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  entries.map(fn(entry) { entry.entity })
}

///|
fn render3d_clustered_irradiance_volume_indices(
  world : @ecs.World,
) -> Array[@core.Entity] {
  let camera_transform = match render3d_cluster_camera_entity(world) {
    Some(entity) => render3d_extract_light_transform(world, entity)
    None => @transform.Transform::identity()
  }
  let entries : Array[Render3dClusteredReflectionProbeIndexEntry] = []
  world.for_each_component(@light.ecs_key_irradiance_volume, fn(
    entity,
    _irradiance_volume,
  ) {
    if !(try! world.contains_by_key(entity, @light.ecs_key_light_probe)) {
      return
    }
    let transform = render3d_extract_light_transform(world, entity)
    entries.push(Render3dClusteredReflectionProbeIndexEntry::{
      entity,
      distance_squared: transform.translation
      .sub(camera_transform.translation)
      .length_squared(),
    })
  })
  entries.sort_by(fn(left, right) {
    let distance_cmp = cmp_float(left.distance_squared, right.distance_squared)
    if distance_cmp != 0 {
      return distance_cmp
    }
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  entries.map(fn(entry) { entry.entity })
}

///|
fn render3d_clustered_light_probe_index(
  light_probe_entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Int {
  for index in 0..<light_probe_entities.length() {
    let candidate = light_probe_entities[index]
    if candidate.id == entity.id && candidate.generation == entity.generation {
      return index
    }
  }
  -1
}

///|
pub fn render3d_point_light_flags(extracted : ExtractedPointLight3d) -> UInt {
  let mut flags = POINT_LIGHT_FLAG_NONE
  if extracted.shadow_maps_enabled {
    flags = flags | POINT_LIGHT_FLAG_SHADOW_MAPS_ENABLED
  }
  if extracted.spot_light_angles is Some(_) {
    flags = flags | POINT_LIGHT_FLAG_SPOT_LIGHT
    let light_direction = render3d_transform_forward(extracted.transform)
    if light_direction.y < 0.0F {
      flags = flags | POINT_LIGHT_FLAG_SPOT_LIGHT_Y_NEGATIVE
    }
  }
  if extracted.volumetric && extracted.shadow_maps_enabled {
    flags = flags | POINT_LIGHT_FLAG_VOLUMETRIC
  }
  if extracted.affects_lightmapped_mesh_diffuse {
    flags = flags | POINT_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  }
  if extracted.contact_shadows_enabled {
    flags = flags | POINT_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED
  }
  flags
}

///|
pub fn render3d_directional_light_flags(
  extracted : ExtractedDirectionalLight3d,
) -> UInt {
  render3d_directional_light_flags_for_gpu(
    extracted,
    extracted.shadow_maps_enabled,
    extracted.volumetric && extracted.shadow_maps_enabled,
  )
}

///|
fn render3d_directional_light_flags_for_gpu(
  extracted : ExtractedDirectionalLight3d,
  shadow_maps_enabled : Bool,
  volumetric_enabled : Bool,
) -> UInt {
  let mut flags = DIRECTIONAL_LIGHT_FLAG_NONE
  if shadow_maps_enabled {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_SHADOW_MAPS_ENABLED
  }
  if volumetric_enabled {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_VOLUMETRIC
  }
  if extracted.affects_lightmapped_mesh_diffuse {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE
  }
  if extracted.contact_shadows_enabled {
    flags = flags | DIRECTIONAL_LIGHT_FLAG_CONTACT_SHADOWS_ENABLED
  }
  flags
}

///|
fn render3d_extract_light_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) => return global_transform.to_transform_approx()
    None => ()
  }
  match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
    Some(v) => v
    None => @transform.Transform::identity()
  }
}

///|
fn render3d_extract_point_light(
  world : @ecs.World,
  entity : @core.Entity,
  light : @light.PointLight,
  volumetric : Bool,
  point_light_texel_size : Float,
) -> ExtractedPointLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  ExtractedPointLight3d::{
    entity,
    color: light.color,
    // Bevy parity: point-light authoring uses lumens, extracted runtime stores
    // luminous intensity (lumens/steradian).
    intensity: light.intensity / (4.0F * @math.pi()),
    range: light.range,
    radius: light.radius,
    transform,
    shadow_maps_enabled: light.shadow_maps_enabled,
    contact_shadows_enabled: light.contact_shadows_enabled,
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias *
    point_light_texel_size *
    render3d_sqrt2(),
    shadow_map_near_z: light.shadow_map_near_z,
    spot_light_angles: None,
    volumetric,
    soft_shadows_enabled: light.soft_shadows_enabled,
    affects_lightmapped_mesh_diffuse: light.affects_lightmapped_mesh_diffuse,
  }
}

///|
fn render3d_extract_spot_light(
  world : @ecs.World,
  entity : @core.Entity,
  light : @light.SpotLight,
  volumetric : Bool,
  directional_light_shadow_map_size : Int,
) -> ExtractedPointLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  let inner = light.inner_angle
  let outer = light.outer_angle
  let safe_shadow_map_size = if directional_light_shadow_map_size <= 0 {
    1
  } else {
    directional_light_shadow_map_size
  }
  let texel_size = 2.0F *
    render3d_tan(outer) /
    Float::from_double(safe_shadow_map_size.to_double())
  ExtractedPointLight3d::{
    entity,
    color: light.color,
    // Bevy parity: spot-light authoring uses lumens, extracted runtime stores
    // luminous intensity (lumens/steradian).
    intensity: light.intensity / (4.0F * @math.pi()),
    range: light.range,
    radius: light.radius,
    transform,
    shadow_maps_enabled: light.shadow_maps_enabled,
    contact_shadows_enabled: light.contact_shadows_enabled,
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias * texel_size * render3d_sqrt2(),
    shadow_map_near_z: light.shadow_map_near_z,
    spot_light_angles: Some((inner, outer)),
    volumetric,
    soft_shadows_enabled: light.soft_shadows_enabled,
    affects_lightmapped_mesh_diffuse: light.affects_lightmapped_mesh_diffuse,
  }
}

///|
fn render3d_extract_directional_light(
  world : @ecs.World,
  entity : @core.Entity,
  light : @light.DirectionalLight,
  volumetric : Bool,
) -> ExtractedDirectionalLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  let render_layers = match
    (try! world.get_by_key(entity, @camera_render_layers.ecs_key_render_layers)) {
    Some(layers) => layers
    None => @camera_render_layers.RenderLayers::RenderLayers()
  }
  let occlusion_culling = (try! world.get_by_key(
      entity, @render_occlusion_culling.ecs_key_occlusion_culling,
    ))
    is Some(_)
  let sun_disk = match
    (try! world.get_by_key(entity, @light.ecs_key_sun_disk)) {
    Some(v) => v
    None => @light.SunDisk::SunDisk()
  }
  let cascade_config = match
    (try! world.get_by_key(entity, @light.ecs_key_cascade_shadow_config)) {
    Some(config) => config
    None => @light.CascadeShadowConfig::CascadeShadowConfig()
  }
  let cascades = match
    (try! world.get_by_key(entity, @light.ecs_key_cascades)) {
    Some(value) => render3d_clone_cascades(value)
    None => @light.Cascades::Cascades()
  }
  let cascade_count = cascade_config.bounds.length()
  let cascade_overlap_proportion = cascade_config.overlap_proportion
  ExtractedDirectionalLight3d::{
    entity,
    color: light.color,
    illuminance: light.illuminance,
    transform,
    shadow_maps_enabled: light.shadow_maps_enabled,
    contact_shadows_enabled: light.contact_shadows_enabled,
    shadow_depth_bias: light.shadow_depth_bias,
    shadow_normal_bias: light.shadow_normal_bias * render3d_sqrt2(),
    volumetric,
    affects_lightmapped_mesh_diffuse: light.affects_lightmapped_mesh_diffuse,
    soft_shadow_size: light.soft_shadow_size,
    cascade_count: if cascade_count > MAX_CASCADES_PER_LIGHT {
      MAX_CASCADES_PER_LIGHT
    } else if cascade_count < 0 {
      0
    } else {
      cascade_count
    },
    cascade_bounds: cascade_config.bounds,
    cascade_overlap_proportion,
    cascade_minimum_distance: cascade_config.minimum_distance,
    cascades,
    render_layers,
    occlusion_culling,
    sun_disk_angular_size: sun_disk.angular_size,
    sun_disk_intensity: sun_disk.intensity,
  }
}

///|
fn render3d_clone_cascades(cascades : @light.Cascades) -> @light.Cascades {
  let cloned = @light.Cascades::Cascades()
  for entry in cascades.entries() {
    let (view, source_view_cascades) = entry
    let view_cascades : Array[@light.Cascade] = []
    for cascade in source_view_cascades {
      view_cascades.push(cascade)
    }
    cloned.set(view, view_cascades)
  }
  cloned
}

///|
fn extract_point_light_changed(
  world : @ecs.World,
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  world.is_changed_by_key(entity, @light.ecs_key_point_light, system_ticks) ||
  world.is_changed_by_key(entity, @transform.ecs_key_transform, system_ticks) ||
  world.is_changed_by_key(
    entity, @transform.ecs_key_global_transform, system_ticks,
  ) ||
  world.is_changed_by_key(
    entity, @visibility.ecs_key_view_visibility, system_ticks,
  ) ||
  world.is_changed_by_key(entity, @light.ecs_key_volumetric_light, system_ticks)
}

///|
fn extract_spot_light_changed(
  world : @ecs.World,
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  world.is_changed_by_key(entity, @light.ecs_key_spot_light, system_ticks) ||
  world.is_changed_by_key(entity, @transform.ecs_key_transform, system_ticks) ||
  world.is_changed_by_key(
    entity, @transform.ecs_key_global_transform, system_ticks,
  ) ||
  world.is_changed_by_key(
    entity, @visibility.ecs_key_view_visibility, system_ticks,
  ) ||
  world.is_changed_by_key(entity, ecs_key_frustum, system_ticks) ||
  world.is_changed_by_key(entity, @light.ecs_key_volumetric_light, system_ticks)
}

///|
fn extract_directional_light_changed(
  world : @ecs.World,
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  world.is_changed_by_key(
    entity, @light.ecs_key_directional_light, system_ticks,
  ) ||
  world.is_changed_by_key(entity, @transform.ecs_key_transform, system_ticks) ||
  world.is_changed_by_key(
    entity, @transform.ecs_key_global_transform, system_ticks,
  ) ||
  world.is_changed_by_key(
    entity, @visibility.ecs_key_view_visibility, system_ticks,
  ) ||
  world.is_changed_by_key(
    entity, @camera_render_layers.ecs_key_render_layers, system_ticks,
  ) ||
  world.is_changed_by_key(entity, @light.ecs_key_volumetric_light, system_ticks) ||
  world.is_changed_by_key(
    entity, @render_occlusion_culling.ecs_key_occlusion_culling, system_ticks,
  ) ||
  world.is_changed_by_key(entity, @light.ecs_key_cascades, system_ticks) ||
  world.is_changed_by_key(entity, @light.ecs_key_sun_disk, system_ticks)
}

///|
fn extract_rect_light_changed(
  world : @ecs.World,
  entity : @core.Entity,
  system_ticks : @core.SystemTicks,
) -> Bool {
  world.is_changed_by_key(entity, @light.ecs_key_rect_light, system_ticks) ||
  world.is_changed_by_key(entity, @transform.ecs_key_transform, system_ticks) ||
  world.is_changed_by_key(
    entity, @transform.ecs_key_global_transform, system_ticks,
  ) ||
  world.is_changed_by_key(
    entity, @visibility.ecs_key_view_visibility, system_ticks,
  )
}

///|
fn light_extract_render_entity(
  source_world : @ecs.World,
  source_entity : @core.Entity,
) -> @core.Entity? {
  match
    (try! source_world.get_by_key(
      source_entity, @render_gpu.ecs_key_render_entity,
    )) {
    Some(render_entity) => Some(render_entity.id())
    None => None
  }
}

///|
fn light_extract_set_point_light(
  render_world : @ecs.World,
  render_entity : @core.Entity,
  light : ExtractedPointLight3d,
) -> Unit {
  try! render_world.set_by_key(
    render_entity, ecs_key_extracted_point_light3d, light,
  )
  try! render_world.set_by_key(
    render_entity,
    @render_gpu.ecs_key_main_entity,
    @render_gpu.MainEntity::new(light.entity),
  )
}

///|
fn light_extract_remove_point_light(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> Unit {
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_extracted_point_light3d) catch {
      _ => false
    },
  )
}

///|
fn light_extract_set_directional_light(
  render_world : @ecs.World,
  render_entity : @core.Entity,
  light : ExtractedDirectionalLight3d,
) -> Unit {
  try! render_world.set_by_key(
    render_entity, ecs_key_extracted_directional_light3d, light,
  )
  try! render_world.set_by_key(
    render_entity,
    @render_gpu.ecs_key_main_entity,
    @render_gpu.MainEntity::new(light.entity),
  )
}

///|
fn light_extract_remove_directional_light(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> Unit {
  ignore(
    render_world.remove_by_key(
      render_entity, ecs_key_extracted_directional_light3d,
    ) catch {
      _ => false
    },
  )
  ignore(
    render_world.remove_by_key(
      render_entity, @render_view_visibility.ecs_key_render_extracted_shadow_map_visible_entities,
    ) catch {
      _ => false
    },
  )
}

///|
fn light_extract_rect_light(
  world : @ecs.World,
  entity : @core.Entity,
  rect_light : @light.RectLight,
) -> ExtractedRectLight3d {
  let transform = render3d_extract_light_transform(world, entity)
  let (scale, _, _) = match
    (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) =>
      global_transform.affine().to_scale_rotation_translation()
    None => (transform.scale, transform.rotation, transform.translation)
  }
  let effective_width = rect_light.width() * scale.x.abs()
  let effective_height = rect_light.height() * scale.y.abs()
  ExtractedRectLight3d::{
    entity,
    color: rect_light.color(),
    intensity: rect_light.intensity() /
    (effective_width * effective_height * @math.pi()),
    range: rect_light.range(),
    width: effective_width,
    height: effective_height,
    transform,
  }
}

///|
fn light_extract_set_rect_light(
  render_world : @ecs.World,
  render_entity : @core.Entity,
  light : ExtractedRectLight3d,
) -> Unit {
  try! render_world.set_by_key(
    render_entity, ecs_key_extracted_rect_light3d, light,
  )
  try! render_world.set_by_key(
    render_entity,
    @render_gpu.ecs_key_main_entity,
    @render_gpu.MainEntity::new(light.entity),
  )
}

///|
fn light_extract_remove_rect_light(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> Unit {
  ignore(
    render_world.remove_by_key(render_entity, ecs_key_extracted_rect_light3d) catch {
      _ => false
    },
  )
}

///|
fn extract_point_lights(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  let point_light_texel_size = render3d_point_light_shadow_texel_size(
    source_world,
  )
  source_world.for_each_component(@light.ecs_key_point_light, fn(
    entity,
    light,
  ) {
    guard extract_point_light_changed(source_world, entity, system_ticks) else {
      return
    }
    guard light_extract_render_entity(source_world, entity)
      is Some(render_entity) else {
      return
    }
    if !render3d_light_is_view_visible(source_world, entity) {
      light_extract_remove_point_light(render_world, render_entity)
      return
    }
    if !light.shadow_maps_enabled {
      light_sync_target_remove_common_shadow_components(
        render_world, render_entity,
      )
    }
    let volumetric = (try! source_world.get_by_key(
        entity, @light.ecs_key_volumetric_light,
      ))
      is Some(_)
    light_extract_set_point_light(
      render_world,
      render_entity,
      render3d_extract_point_light(
        source_world, entity, light, volumetric, point_light_texel_size,
      ),
    )
  })
}

///|
fn extract_spot_lights(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  let directional_light_shadow_map_size = render3d_directional_light_shadow_map_size(
    source_world,
  )
  source_world.for_each_component(@light.ecs_key_spot_light, fn(entity, light) {
    guard extract_spot_light_changed(source_world, entity, system_ticks) else {
      return
    }
    guard light_extract_render_entity(source_world, entity)
      is Some(render_entity) else {
      return
    }
    if !render3d_light_is_view_visible(source_world, entity) {
      light_extract_remove_point_light(render_world, render_entity)
      return
    }
    if !light.shadow_maps_enabled {
      light_sync_target_remove_common_shadow_components(
        render_world, render_entity,
      )
    }
    let volumetric = (try! source_world.get_by_key(
        entity, @light.ecs_key_volumetric_light,
      ))
      is Some(_)
    light_extract_set_point_light(
      render_world,
      render_entity,
      render3d_extract_spot_light(
        source_world, entity, light, volumetric, directional_light_shadow_map_size,
      ),
    )
  })
}

///|
fn extract_directional_lights(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  source_world.for_each_component(@light.ecs_key_directional_light, fn(
    entity,
    light,
  ) {
    guard extract_directional_light_changed(source_world, entity, system_ticks) else {
      return
    }
    guard light_extract_render_entity(source_world, entity)
      is Some(render_entity) else {
      return
    }
    if !render3d_light_is_view_visible(source_world, entity) {
      light_extract_remove_directional_light(render_world, render_entity)
      return
    }
    if !light.shadow_maps_enabled {
      light_sync_target_remove_common_shadow_components(
        render_world, render_entity,
      )
    }
    let volumetric = (try! source_world.get_by_key(
        entity, @light.ecs_key_volumetric_light,
      ))
      is Some(_)
    light_extract_set_directional_light(
      render_world,
      render_entity,
      render3d_extract_directional_light(
        source_world, entity, light, volumetric,
      ),
    )
  })
}

///|
fn extract_rect_lights(
  source_world : @ecs.World,
  render_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Unit {
  source_world.for_each_component(@light.ecs_key_rect_light, fn(entity, light) {
    guard extract_rect_light_changed(source_world, entity, system_ticks) else {
      return
    }
    guard light_extract_render_entity(source_world, entity)
      is Some(render_entity) else {
      return
    }
    if !render3d_light_is_view_visible(source_world, entity) {
      light_extract_remove_rect_light(render_world, render_entity)
      return
    }
    light_extract_set_rect_light(
      render_world,
      render_entity,
      light_extract_rect_light(source_world, entity, light),
    )
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::extract_lights`.
pub fn extract_lights(render_world : @ecs.World) -> Unit {
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_extracted_point_light3d),
  )
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_extracted_directional_light3d),
  )
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_extracted_rect_light3d),
  )
  let source_world = @render_gpu.render_source_world(render_world)
  let system_ticks = light_extraction_system_ticks(render_world, source_world)
  extract_shadow_map_resources_from_worlds(
    source_world, render_world, system_ticks,
  )
  extract_point_lights(source_world, render_world, system_ticks)
  extract_spot_lights(source_world, render_world, system_ticks)
  extract_directional_lights(source_world, render_world, system_ticks)
  extract_rect_lights(source_world, render_world, system_ticks)
  light_extraction_set_last_source_change_tick(
    render_world,
    source_world.read_change_tick(),
  )
}

///|
pub fn render3d_collect_extracted_point_lights(
  world : @ecs.World,
) -> Array[ExtractedPointLight3d] {
  let extracted : Array[ExtractedPointLight3d] = []
  world.for_each_component(ecs_key_extracted_point_light3d, fn(_entity, light) {
    if light.spot_light_angles is None {
      extracted.push(light)
    }
  })
  extracted.sort_by(fn(left, right) {
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
pub fn render3d_collect_extracted_spot_lights(
  world : @ecs.World,
) -> Array[ExtractedPointLight3d] {
  let extracted : Array[ExtractedPointLight3d] = []
  world.for_each_component(ecs_key_extracted_point_light3d, fn(_entity, light) {
    if light.spot_light_angles is Some(_) {
      extracted.push(light)
    }
  })
  extracted.sort_by(fn(left, right) {
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
fn render3d_clusterable_light_sort_by_key(
  left_order : Int,
  left : ExtractedPointLight3d,
  right_order : Int,
  right : ExtractedPointLight3d,
) -> Int {
  let type_cmp = cmp_int(left_order, right_order)
  if type_cmp != 0 {
    return type_cmp
  }
  let id_cmp = cmp_int(left.entity.id, right.entity.id)
  if id_cmp != 0 {
    return id_cmp
  }
  cmp_int(left.entity.generation, right.entity.generation)
}

///|
pub fn render3d_collect_extracted_clusterable_point_lights(
  world : @ecs.World,
) -> Array[ExtractedClusterablePointLight3d] {
  let combined : Array[(Int, ExtractedPointLight3d)] = []
  for point in render3d_collect_extracted_point_lights(world) {
    combined.push((0, point))
  }
  for spot in render3d_collect_extracted_spot_lights(world) {
    combined.push((1, spot))
  }
  combined.sort_by(fn(left, right) {
    render3d_clusterable_light_sort_by_key(left.0, left.1, right.0, right.1)
  })
  combined.map(fn(item) {
    ExtractedClusterablePointLight3d::{
      clusterable_type_order: item.0,
      light: item.1,
    }
  })
}

///|
pub fn render3d_collect_extracted_rect_lights(
  world : @ecs.World,
) -> Array[ExtractedRectLight3d] {
  let extracted : Array[ExtractedRectLight3d] = []
  world.for_each_component(ecs_key_extracted_rect_light3d, fn(_, light) {
    extracted.push(light)
  })
  extracted.sort_by(fn(left, right) {
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
pub fn render3d_collect_extracted_directional_lights(
  world : @ecs.World,
) -> Array[ExtractedDirectionalLight3d] {
  let extracted : Array[ExtractedDirectionalLight3d] = []
  world.for_each_component(ecs_key_extracted_directional_light3d, fn(_, light) {
    extracted.push(light)
  })
  extracted.sort_by(fn(left, right) {
    let volumetric_cmp = cmp_int(
      render3d_bool_sort_key(left.volumetric),
      render3d_bool_sort_key(right.volumetric),
    )
    if volumetric_cmp != 0 {
      return volumetric_cmp
    }
    let shadow_cmp = cmp_int(
      render3d_bool_sort_key(left.shadow_maps_enabled),
      render3d_bool_sort_key(right.shadow_maps_enabled),
    )
    if shadow_cmp != 0 {
      return shadow_cmp
    }
    let id_cmp = cmp_int(left.entity.id, right.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    cmp_int(left.entity.generation, right.entity.generation)
  })
  extracted
}

///|
fn render3d_directional_light_requested_cascade_count(
  item : ExtractedDirectionalLight3d,
) -> Int {
  if !item.shadow_maps_enabled || item.cascade_count <= 0 {
    0
  } else if item.cascade_count > MAX_CASCADES_PER_LIGHT {
    MAX_CASCADES_PER_LIGHT
  } else {
    item.cascade_count
  }
}

///|
fn render3d_directional_light_shadow_state(
  item : ExtractedDirectionalLight3d,
  current_depth_texture_base_index : Int,
  max_texture_array_layers : Int,
) -> (Bool, Int) {
  if !item.shadow_maps_enabled {
    return (false, 0)
  }
  let requested_cascades = render3d_directional_light_requested_cascade_count(
    item,
  )
  if current_depth_texture_base_index + requested_cascades <=
    max_texture_array_layers {
    (true, requested_cascades)
  } else {
    (false, 0)
  }
}

///|
fn render3d_directional_lights_volumetric_enabled_count(
  directional : Array[ExtractedDirectionalLight3d],
  max_texture_array_layers : Int,
) -> Int {
  let max_count = if directional.length() < MAX_DIRECTIONAL_LIGHTS {
    directional.length()
  } else {
    MAX_DIRECTIONAL_LIGHTS
  }
  let mut count = 0
  for index in 0..<max_count {
    if directional[index].volumetric {
      count += 1
    }
  }
  render3d_min_int(count, max_texture_array_layers / MAX_CASCADES_PER_LIGHT)
}

///|
fn render3d_gpu_directional_cascade_default() -> GpuDirectionalCascade3d {
  GpuDirectionalCascade3d::{
    far_bound: 0.0F,
    texel_size: 1.0F,
    clip_from_world: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
  }
}

///|
fn render3d_gpu_directional_light_default() -> GpuDirectionalLight3d {
  let cascades : Array[GpuDirectionalCascade3d] = []
  while cascades.length() < MAX_CASCADES_PER_LIGHT {
    cascades.push(render3d_gpu_directional_cascade_default())
  }
  GpuDirectionalLight3d::{
    cascades,
    color: @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    dir_to_light: @math.Vec3::new(0.0F, 0.0F, 1.0F),
    flags: DIRECTIONAL_LIGHT_FLAG_UNINITIALIZED,
    soft_shadow_size: 0.0F,
    shadow_depth_bias: 0.0F,
    shadow_normal_bias: 0.0F,
    num_cascades: 0,
    cascades_overlap_proportion: 0.0F,
    depth_texture_base_index: 0,
    decal_index: -1,
    sun_disk_angular_size: 0.0F,
    sun_disk_intensity: 0.0F,
  }
}

///|
priv struct Render3dClusterCameraSelection {
  mut preferred : @core.Entity?
  mut fallback : @core.Entity?
}

///|
priv struct Render3dClusterViewFallback {
  mut view : (Int, Int)?
}

///|
priv struct Render3dProjectionRuntimeFallback {
  mut runtime : ProjectionRuntime3d?
}

///|
priv struct Render3dClusterRangeState {
  mut max_range : Float
}

///|
priv struct Render3dClusterRuntimeFallback {
  mut runtime : (Int, Int, Int, Float, Float)?
}

///|
priv struct Render3dVisibleClusterableObjectsFallback {
  mut camera : @light_cluster.VisibleClusterableObjects?
}

///|
fn render3d_cluster_camera_entity(world : @ecs.World) -> @core.Entity? {
  let selection = Render3dClusterCameraSelection::{
    preferred: None,
    fallback: None,
  }
  world.for_each_component(@camera_camera.ecs_key_camera, fn(entity, camera) {
    if !camera.is_active {
      return
    }
    if selection.fallback is None {
      selection.fallback = Some(entity)
    }
    if selection.preferred is Some(_) {
      return
    }
    let has_cluster_components = (try! world.contains_by_key(
        entity,
        @light_cluster.Clusters::component(),
      )) ||
      (try! world.contains_by_key(
        entity,
        @light_cluster.ClusterConfig::component(),
      ))
    if has_cluster_components {
      selection.preferred = Some(entity)
    }
  })
  match selection.preferred {
    Some(entity) => Some(entity)
    None => selection.fallback
  }
}

///|
fn render3d_cluster_view_render_layers(
  world : @ecs.World,
) -> @camera_render_layers.RenderLayers {
  match render3d_cluster_camera_entity(world) {
    Some(entity) =>
      match
        (try! world.get_by_key(
          entity, @camera_render_layers.ecs_key_render_layers,
        )) {
        Some(layers) => layers
        None => @camera_render_layers.RenderLayers::RenderLayers()
      }
    None => @camera_render_layers.RenderLayers::RenderLayers()
  }
}

///|
fn render3d_cluster_view_info(world : @ecs.World) -> (Int, Int) {
  if render3d_cluster_camera_entity(world) is Some(entity) &&
    (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
    is Some(camera) &&
    camera.physical_viewport_size() is Some(viewport_size) {
    let width = if viewport_size.x <= 0 { 0 } else { viewport_size.x }
    let height = if viewport_size.y <= 0 { 0 } else { viewport_size.y }
    if width > 0 && height > 0 {
      return (width, height)
    }
  }
  let fallback_view = Render3dClusterViewFallback::{ view: None }
  world.for_each_component(@camera_camera.ecs_key_camera, fn(_entity, camera) {
    if fallback_view.view is Some(_) {
      return
    }
    if !camera.is_active {
      return
    }
    if camera.physical_viewport_size() is Some(viewport_size) {
      let width = if viewport_size.x <= 0 { 0 } else { viewport_size.x }
      let height = if viewport_size.y <= 0 { 0 } else { viewport_size.y }
      if width > 0 && height > 0 {
        fallback_view.view = Some((width, height))
      }
    }
  })
  if fallback_view.view is Some(view) {
    return view
  }
  let width = @window.window_physical_width_for(
    world,
    @window.WindowRef::Primary,
  )
  let height = @window.window_physical_height_for(
    world,
    @window.WindowRef::Primary,
  )
  if width > 0 && height > 0 {
    (width, height)
  } else {
    (1280, 720)
  }
}

///|
fn render3d_cluster_projection_runtime(
  world : @ecs.World,
) -> ProjectionRuntime3d? {
  if render3d_cluster_camera_entity(world) is Some(entity) &&
    (try! world.get_by_key(entity, ecs_key_projection_runtime3d))
    is Some(runtime) {
    return Some(runtime)
  }
  let fallback = Render3dProjectionRuntimeFallback::{ runtime: None }
  world.for_each_component(ecs_key_projection_runtime3d, fn(entity, runtime) {
    if fallback.runtime is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
      is Some(camera) &&
      camera.is_active {
      fallback.runtime = Some(runtime)
    }
  })
  fallback.runtime
}

///|
fn render3d_cluster_config(world : @ecs.World) -> @light_cluster.ClusterConfig {
  if render3d_cluster_camera_entity(world) is Some(entity) &&
    (try! world.get_by_key(entity, @light_cluster.ClusterConfig::component()))
    is Some(config) {
    return config
  }
  @light_cluster.ClusterConfig::default()
}

///|
fn render3d_cluster_camera_depth_context(
  world : @ecs.World,
) -> (@math.Vec3, @math.Vec3, Float)? {
  match render3d_cluster_camera_entity(world) {
    Some(entity) => {
      let transform = render3d_extract_light_transform(world, entity)
      let view_scale_z = if transform.scale.z == 0.0F {
        1.0F
      } else {
        1.0F / transform.scale.z
      }
      Some((transform.translation, transform.back(), view_scale_z))
    }
    None => None
  }
}

///|
fn render3d_clusterable_object_view_range(
  world : @ecs.World,
  entity : @core.Entity,
  object_range : Float,
  depth_context : (@math.Vec3, @math.Vec3, Float)?,
) -> Float {
  match depth_context {
    Some((camera_position, camera_back, view_scale_z)) => {
      let object_transform = render3d_extract_light_transform(world, entity)
      let camera_to_object = object_transform.translation.sub(camera_position)
      let view_depth = -camera_back.dot(camera_to_object)
      view_depth + object_range * view_scale_z
    }
    None => object_range
  }
}

///|
fn render3d_clusterable_light_range(
  world : @ecs.World,
  entity : @core.Entity,
) -> Float? {
  if (try! world.get_by_key(entity, @light.ecs_key_point_light)) is Some(light) {
    return Some(light.range)
  }
  if (try! world.get_by_key(entity, @light.ecs_key_spot_light)) is Some(light) {
    return Some(light.range)
  }
  None
}

///|
fn render3d_clusterable_object_max_range(world : @ecs.World) -> Float {
  let depth_context = render3d_cluster_camera_depth_context(world)
  if render3d_visible_clusterable_objects(world) is Some(visible) {
    let range_state = Render3dClusterRangeState::{ max_range: 0.0F }
    for entity in visible.point_and_spot_entities() {
      if render3d_clusterable_light_range(world, entity) is Some(light_range) {
        let view_range = render3d_clusterable_object_view_range(
          world, entity, light_range, depth_context,
        )
        if view_range > range_state.max_range {
          range_state.max_range = view_range
        }
      }
    }
    if range_state.max_range > 0.0F {
      return range_state.max_range
    }
  }
  let range_state = Render3dClusterRangeState::{ max_range: 0.0F }
  world.for_each_component(@light.ecs_key_point_light, fn(entity, light) {
    if !render3d_light_is_view_visible(world, entity) {
      return
    }
    let view_range = render3d_clusterable_object_view_range(
      world,
      entity,
      light.range,
      depth_context,
    )
    if view_range > range_state.max_range {
      range_state.max_range = view_range
    }
  })
  world.for_each_component(@light.ecs_key_spot_light, fn(entity, light) {
    if !render3d_light_is_view_visible(world, entity) {
      return
    }
    let view_range = render3d_clusterable_object_view_range(
      world,
      entity,
      light.range,
      depth_context,
    )
    if view_range > range_state.max_range {
      range_state.max_range = view_range
    }
  })
  range_state.max_range
}

///|
fn render3d_cluster_runtime(
  world : @ecs.World,
) -> (Int, Int, Int, Float, Float)? {
  if render3d_cluster_camera_entity(world) is Some(entity) &&
    (try! world.get_by_key(entity, @light_cluster.Clusters::component()))
    is Some(clusters) {
    return Some(
      (
        clusters.dimensions_x,
        clusters.dimensions_y,
        clusters.dimensions_z,
        clusters.near,
        clusters.far,
      ),
    )
  }
  let fallback = Render3dClusterRuntimeFallback::{ runtime: None }
  world.for_each_component(@light_cluster.Clusters::component(), fn(
    entity,
    clusters,
  ) {
    if fallback.runtime is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
      is Some(camera) &&
      camera.is_active {
      fallback.runtime = Some(
        (
          clusters.dimensions_x,
          clusters.dimensions_y,
          clusters.dimensions_z,
          clusters.near,
          clusters.far,
        ),
      )
    }
  })
  fallback.runtime
}

///|
fn render3d_visible_clusterable_objects(
  world : @ecs.World,
) -> @light_cluster.VisibleClusterableObjects? {
  if render3d_cluster_camera_entity(world) is Some(entity) &&
    (try! world.get_by_key(
      entity,
      @light_cluster.VisibleClusterableObjects::component(),
    ))
    is Some(visible) {
    return Some(visible)
  }
  let fallback = Render3dVisibleClusterableObjectsFallback::{ camera: None }
  world.for_each_component(
    @light_cluster.VisibleClusterableObjects::component(),
    fn(entity, visible) {
      if fallback.camera is Some(_) {
        return
      }
      if (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
        is Some(camera) &&
        camera.is_active {
        fallback.camera = Some(visible)
      }
    },
  )
  fallback.camera
}

///|
pub fn render3d_collect_gpu_lights(world : @ecs.World) -> GpuLights3d {
  let directional = render3d_collect_extracted_directional_lights(world)
  let rect_lights = render3d_collect_extracted_rect_lights(world)
  let clusterable_point_lights = render3d_collect_extracted_clusterable_point_lights(
    world,
  )
  let mut point_light_count = 0
  for item in clusterable_point_lights {
    if item.is_point_light() {
      point_light_count += 1
    }
  }
  let ambient = if world.get_resource(@light.ecs_key_global_ambient_light)
    is Some(v) {
    v
  } else {
    @light.GlobalAmbientLight::GlobalAmbientLight()
  }
  let (cluster_screen_width, cluster_screen_height) = render3d_cluster_view_info(
    world,
  )
  let cluster_projection_runtime = render3d_cluster_projection_runtime(world)
  let cluster_is_orthographic = if cluster_projection_runtime is Some(runtime) {
    runtime.is_orthographic
  } else {
    false
  }
  let mut cluster_dimensions_x = 16
  let mut cluster_dimensions_y = 9
  let mut cluster_dimensions_z = 24
  let mut cluster_near = 0.1F
  let mut cluster_far = 1000.0F
  if render3d_cluster_runtime(world)
    is Some(
      (
        runtime_dimensions_x,
        runtime_dimensions_y,
        runtime_dimensions_z,
        runtime_near,
        runtime_far,
      )
    ) {
    cluster_dimensions_x = runtime_dimensions_x
    cluster_dimensions_y = runtime_dimensions_y
    cluster_dimensions_z = runtime_dimensions_z
    cluster_near = runtime_near
    cluster_far = runtime_far
  } else {
    let cluster_config = render3d_cluster_config(world)
    let (config_dimensions_x, config_dimensions_y, config_dimensions_z) = @light_cluster.cluster_config_dimensions_for_screen_size(
      cluster_config, cluster_screen_width, cluster_screen_height,
    )
    cluster_dimensions_x = config_dimensions_x
    cluster_dimensions_y = config_dimensions_y
    cluster_dimensions_z = config_dimensions_z
    cluster_near = @light_cluster.cluster_config_first_slice_depth(
      cluster_config,
    )
    if cluster_projection_runtime is Some(runtime) && runtime.is_orthographic {
      cluster_near = runtime.orthographic_first_slice_depth
    }
    cluster_far = match
      @light_cluster.cluster_config_far_z_mode(cluster_config) {
      @light_cluster.ClusterFarZMode::Constant(far) => far
      @light_cluster.ClusterFarZMode::MaxClusterableObjectRange =>
        render3d_clusterable_object_max_range(world)
    }
    if !cluster_is_orthographic &&
      cluster_dimensions_z == 1 &&
      cluster_far > cluster_near {
      cluster_near = cluster_far
    }
    if cluster_far < cluster_near {
      cluster_far = cluster_near
    }
  }
  let n_clusters = cluster_dimensions_x *
    cluster_dimensions_y *
    cluster_dimensions_z
  let cluster_factors_xy = if cluster_screen_width <= 0 ||
    cluster_screen_height <= 0 {
    @math.Vec2::new(0.0F, 0.0F)
  } else {
    @math.Vec2::new(
      Float::from_double(cluster_dimensions_x.to_double()) /
      Float::from_double(cluster_screen_width.to_double()),
      Float::from_double(cluster_dimensions_y.to_double()) /
      Float::from_double(cluster_screen_height.to_double()),
    )
  }
  let cluster_factors_zw = if n_clusters <= 0 {
    @math.Vec2::new(0.0F, 0.0F)
  } else {
    @light_cluster.calculate_cluster_factors(
      cluster_near,
      cluster_far,
      Float::from_double(cluster_dimensions_z.to_double()),
      cluster_is_orthographic,
    )
  }
  let gpu_directional_lights : Array[GpuDirectionalLight3d] = []
  let mut directional_shadow_texture_base_index = 0
  let view_render_layers = render3d_cluster_view_render_layers(world)
  let max_texture_array_layers = render3d_lights_max_texture_array_layers(world)
  let directional_volumetric_enabled_count = render3d_directional_lights_volumetric_enabled_count(
    directional, max_texture_array_layers,
  )
  let mut directional_source_index = 0
  while directional_source_index < directional.length() &&
        gpu_directional_lights.length() < MAX_DIRECTIONAL_LIGHTS {
    let item = directional[directional_source_index]
    directional_source_index += 1
    if !item.render_layers.intersects(view_render_layers) {
      continue
    }
    let visible_directional_index = gpu_directional_lights.length()
    let (shadow_maps_enabled, num_cascades) = render3d_directional_light_shadow_state(
      item, directional_shadow_texture_base_index, max_texture_array_layers,
    )
    let volumetric_enabled = item.volumetric &&
      shadow_maps_enabled &&
      visible_directional_index < directional_volumetric_enabled_count
    let cascades : Array[GpuDirectionalCascade3d] = []
    for _ in 0..<num_cascades {
      cascades.push(render3d_gpu_directional_cascade_default())
    }
    while cascades.length() < MAX_CASCADES_PER_LIGHT {
      cascades.push(render3d_gpu_directional_cascade_default())
    }
    gpu_directional_lights.push(GpuDirectionalLight3d::{
      cascades,
      color: render3d_scale_color(item.color, item.illuminance),
      dir_to_light: item.transform.back(),
      flags: render3d_directional_light_flags_for_gpu(
        item, shadow_maps_enabled, volumetric_enabled,
      ),
      soft_shadow_size: item.soft_shadow_size.unwrap_or(0.0F),
      shadow_depth_bias: item.shadow_depth_bias,
      shadow_normal_bias: item.shadow_normal_bias,
      num_cascades,
      cascades_overlap_proportion: item.cascade_overlap_proportion,
      depth_texture_base_index: directional_shadow_texture_base_index,
      decal_index: render3d_directional_light_decal_index(world, item.entity),
      sun_disk_angular_size: item.sun_disk_angular_size,
      sun_disk_intensity: item.sun_disk_intensity,
    })
    directional_shadow_texture_base_index += num_cascades
  }
  let directional_count = gpu_directional_lights.length()
  while gpu_directional_lights.length() < MAX_DIRECTIONAL_LIGHTS {
    gpu_directional_lights.push(render3d_gpu_directional_light_default())
  }
  let gpu_rect_lights : Array[GpuRectLight3d] = []
  let rect_light_count = if rect_lights.length() < MAX_RECT_LIGHTS {
    rect_lights.length()
  } else {
    MAX_RECT_LIGHTS
  }
  for i in 0..<rect_light_count {
    let rect_light = rect_lights[i]
    gpu_rect_lights.push(GpuRectLight3d::{
      color: render3d_scale_color(rect_light.color, rect_light.intensity),
      position: rect_light.transform.translation,
      width: rect_light.width,
      right: rect_light.transform.right(),
      height: rect_light.height,
      up: rect_light.transform.up(),
      range: rect_light.range,
    })
  }
  while gpu_rect_lights.length() < MAX_RECT_LIGHTS {
    gpu_rect_lights.push(render3d_gpu_rect_light_default())
  }
  GpuLights3d::{
    directional_lights: gpu_directional_lights,
    ambient_color: render3d_scale_color(ambient.color, ambient.brightness),
    cluster_dimensions: (
      cluster_dimensions_x, cluster_dimensions_y, cluster_dimensions_z, n_clusters,
    ),
    cluster_factors: @math.Vec4::new(
      cluster_factors_xy.x,
      cluster_factors_xy.y,
      cluster_factors_zw.x,
      cluster_factors_zw.y,
    ),
    n_directional_lights: directional_count,
    spot_light_shadowmap_offset: directional_shadow_texture_base_index -
    point_light_count,
    ambient_light_affects_lightmapped_meshes: if ambient.affects_lightmapped_meshes {
      1
    } else {
      0
    },
    n_rect_lights: rect_light_count,
    rect_lights: gpu_rect_lights,
  }
}

///|
pub fn render3d_default_lighting_state() -> Render3dLightingState {
  Render3dLightingState::{
    ambient_color: @color.Color::white(),
    ambient_brightness: 80.0F,
    directional_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    directional_color: @color.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    directional_illuminance: 0.0F,
    directional_entity: None,
    directional_transform: @transform.Transform::identity(),
    directional_shadow_maps_enabled: false,
    directional_shadow_depth_bias: 0.02F,
    directional_shadow_normal_bias: 0.6F * render3d_sqrt2(),
    directional_shadow_soft_size: 0.0F,
    directional_cascade_bounds: [],
    directional_cascade_overlap_proportion: 0.0F,
    directional_cascade_minimum_distance: 0.1F,
    directional_cascades: @light.Cascades::Cascades(),
    directional_occlusion_culling: false,
    point_entity: None,
    point_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    point_color: @color.Color::white(),
    point_intensity: 0.0F,
    point_range: 1.0F,
    point_light_index: 0,
    point_shadow_maps_enabled: false,
    point_shadow_depth_bias: 0.08F,
    point_shadow_map_near_z: 0.1F,
    spot_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    spot_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    spot_color: @color.Color::white(),
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.7853981633974483F,
    spot_entity: None,
    spot_transform: @transform.Transform::identity(),
    spot_light_index: 0,
    spot_shadow_maps_enabled: false,
    spot_shadow_depth_bias: 0.02F,
    spot_shadow_normal_bias: 0.0F,
    spot_shadow_map_near_z: 0.1F,
    gpu_lights: None,
    gpu_clustered_lights_bytes: None,
    gpu_clusterable_object_index_lists_bytes: None,
    gpu_cluster_offsets_and_counts_bytes: None,
  }
}

///|
pub fn render3d_collect_lighting(world : @ecs.World) -> Render3dLightingState {
  let mut lighting = render3d_default_lighting_state()
  if world.get_resource(@light.ecs_key_global_ambient_light) is Some(ambient) {
    lighting = Render3dLightingState::{
      ..lighting,
      ambient_color: ambient.color,
      ambient_brightness: ambient.brightness,
    }
  }
  let directional_lights = render3d_collect_extracted_directional_lights(world)
  if directional_lights.length() > 0 {
    let directional = directional_lights[0]
    lighting = Render3dLightingState::{
      ..lighting,
      directional_dir: directional.transform.back(),
      directional_color: directional.color,
      directional_illuminance: directional.illuminance,
      directional_entity: Some(directional.entity),
      directional_transform: directional.transform,
      directional_shadow_maps_enabled: directional.shadow_maps_enabled,
      directional_shadow_depth_bias: directional.shadow_depth_bias,
      directional_shadow_normal_bias: directional.shadow_normal_bias,
      directional_shadow_soft_size: directional.soft_shadow_size.unwrap_or(0.0F),
      directional_cascade_bounds: directional.cascade_bounds,
      directional_cascade_overlap_proportion: directional.cascade_overlap_proportion,
      directional_cascade_minimum_distance: directional.cascade_minimum_distance,
      directional_cascades: directional.cascades,
      directional_occlusion_culling: directional.occlusion_culling,
    }
  }
  let point_lights = render3d_collect_extracted_point_lights(world)
  if point_lights.length() > 0 {
    let point = point_lights[0]
    lighting = Render3dLightingState::{
      ..lighting,
      point_entity: Some(point.entity),
      point_pos: point.transform.translation,
      point_color: point.color,
      point_intensity: point.intensity,
      point_range: point.range,
      point_shadow_maps_enabled: point.shadow_maps_enabled,
      point_shadow_depth_bias: point.shadow_depth_bias,
      point_shadow_map_near_z: point.shadow_map_near_z,
    }
    let point_flags = render3d_point_light_flags(point)
    point_flags |> ignore
  }
  let spot_lights = render3d_collect_extracted_spot_lights(world)
  if spot_lights.length() > 0 {
    let spot = spot_lights[0]
    let spot_flags = render3d_point_light_flags(spot)
    spot_flags |> ignore
    match spot.spot_light_angles {
      Some((inner, outer)) =>
        lighting = Render3dLightingState::{
          ..lighting,
          spot_pos: spot.transform.translation,
          spot_dir: render3d_transform_forward(spot.transform),
          spot_color: spot.color,
          spot_intensity: spot.intensity,
          spot_range: spot.range,
          spot_inner_angle: inner,
          spot_outer_angle: outer,
          spot_entity: Some(spot.entity),
          spot_transform: spot.transform,
          spot_shadow_maps_enabled: spot.shadow_maps_enabled,
          spot_shadow_depth_bias: spot.shadow_depth_bias,
          spot_shadow_normal_bias: spot.shadow_normal_bias,
          spot_shadow_map_near_z: spot.shadow_map_near_z,
        }
      None =>
        lighting = Render3dLightingState::{
          ..lighting,
          spot_pos: spot.transform.translation,
          spot_dir: render3d_transform_forward(spot.transform),
          spot_color: spot.color,
          spot_intensity: spot.intensity,
          spot_range: spot.range,
          spot_entity: Some(spot.entity),
          spot_transform: spot.transform,
          spot_shadow_maps_enabled: spot.shadow_maps_enabled,
          spot_shadow_depth_bias: spot.shadow_depth_bias,
          spot_shadow_normal_bias: spot.shadow_normal_bias,
          spot_shadow_map_near_z: spot.shadow_map_near_z,
        }
    }
  }
  let gpu_lights = render3d_collect_gpu_lights(world)
  let (
    gpu_clustered_lights_bytes,
    gpu_clusterable_object_index_lists_bytes,
    gpu_cluster_offsets_and_counts_bytes,
  ) = render3d_gpu_cluster_buffers(
    world,
    None,
    render3d_collect_extracted_clusterable_point_lights(world),
    render3d_clustered_reflection_probe_indices(world),
    render3d_clustered_irradiance_volume_indices(world),
  )
  Render3dLightingState::{
    ..lighting,
    gpu_lights: Some(gpu_lights),
    gpu_clustered_lights_bytes: Some(gpu_clustered_lights_bytes),
    gpu_clusterable_object_index_lists_bytes: Some(
      gpu_clusterable_object_index_lists_bytes,
    ),
    gpu_cluster_offsets_and_counts_bytes: Some(
      gpu_cluster_offsets_and_counts_bytes,
    ),
  }
}

///|
pub fn render3d_point_shadow_face_transform(
  light_position : @math.Vec3,
  face_index : Int,
) -> @transform.Transform {
  let face = match @camera_primitives.cube_map_face(face_index) {
    Some(face) => face
    None => abort("invalid cubemap face index")
  }
  let forward = face.target()
  let up = face.up()
  @transform.Transform::from_xyz(
    light_position.x,
    light_position.y,
    light_position.z,
  ).looking_at(light_position.add(forward), up)
}
