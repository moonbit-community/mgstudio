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
// Bevy source: `bevy/crates/bevy_pbr/src/cluster.rs`.

///|
pub const MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS : Int = 204

///|
pub const CLUSTERED_FORWARD_STORAGE_BUFFER_COUNT : UInt = 3U

///|
pub const GPU_CLUSTERING_INITIAL_Z_SLICE_LIST_CAPACITY : Int = 1024

///|
pub const GPU_CLUSTERING_INITIAL_INDEX_LIST_CAPACITY : Int = 65536

///|
pub const VIEW_CLUSTER_BINDINGS_MAX_OFFSETS : Int = 16384 / 4

///|
pub const VIEW_CLUSTER_BINDINGS_MAX_INDICES : Int = 16384

///|
const CLUSTER_COUNT_SIZE : Int = 9

///|
pub struct GpuClusteredLight {
  light_custom_data : @math.Vec4
  color_inverse_square_range : @math.Vec4
  position_radius : @math.Vec4
  flags : UInt
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  spot_light_tan_angle : Float
  soft_shadow_size : Float
  shadow_map_near_z : Float
  decal_index : UInt
  range : Float
}

///|
pub(all) struct GpuClusteredLights {
  data : Array[GpuClusteredLight]
  is_storage_buffer : Bool
  mut gpu_buffer : @wgpu.Buffer?
  mut gpu_capacity : UInt64
}

///|
pub fn GpuClusteredLight::GpuClusteredLight() -> GpuClusteredLight {
  GpuClusteredLight::{
    light_custom_data: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    color_inverse_square_range: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    position_radius: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    flags: 0U,
    shadow_depth_bias: 0.0F,
    shadow_normal_bias: 0.0F,
    spot_light_tan_angle: 0.0F,
    soft_shadow_size: 0.0F,
    shadow_map_near_z: 0.0F,
    decal_index: 0U,
    range: 0.0F,
  }
}

///|
pub fn GpuClusteredLights::from_binding_type(
  binding_type : UInt,
) -> GpuClusteredLights {
  if binding_type == @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE {
    GpuClusteredLights::{
      data: [],
      is_storage_buffer: true,
      gpu_buffer: None,
      gpu_capacity: 0UL,
    }
  } else {
    GpuClusteredLights::{
      data: [],
      is_storage_buffer: false,
      gpu_buffer: None,
      gpu_capacity: 0UL,
    }
  }
}

///|
pub fn GpuClusteredLights::binding_type(self : GpuClusteredLights) -> UInt {
  if self.is_storage_buffer {
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE
  } else {
    @wgpu.BUFFER_BINDING_TYPE_UNIFORM
  }
}

///|
pub fn GpuClusteredLights::clear(self : GpuClusteredLights) -> Unit {
  self.data.clear()
}

///|
pub fn GpuClusteredLights::len(self : GpuClusteredLights) -> Int {
  self.data.length()
}

///|
pub fn GpuClusteredLights::add(
  self : GpuClusteredLights,
  light : GpuClusteredLight,
) -> Unit {
  if self.is_storage_buffer ||
    self.data.length() < MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS {
    self.data.push(light)
  }
}

///|
pub fn GpuClusteredLights::is_storage_buffer(self : GpuClusteredLights) -> Bool {
  self.is_storage_buffer
}

///|
pub fn GpuClusteredLights::binding(self : GpuClusteredLights) -> @wgpu.Buffer? {
  self.gpu_buffer
}

///|
pub fn GpuClusteredLights::gpu_capacity(self : GpuClusteredLights) -> UInt64 {
  self.gpu_capacity
}

///|
pub fn GpuClusteredLights::max_clustered_lights(
  self : GpuClusteredLights,
) -> Int? {
  if self.is_storage_buffer {
    None
  } else {
    Some(MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS)
  }
}

///|
fn pbr_gpu_clustered_lights_push_vec4(
  out : Array[Byte],
  value : @math.Vec4,
) -> Unit {
  pbr_gpu_clustering_push_u32_le(out, value.x.reinterpret_as_uint())
  pbr_gpu_clustering_push_u32_le(out, value.y.reinterpret_as_uint())
  pbr_gpu_clustering_push_u32_le(out, value.z.reinterpret_as_uint())
  pbr_gpu_clustering_push_u32_le(out, value.w.reinterpret_as_uint())
}

///|
fn pbr_gpu_clustered_lights_bytes(lights : Array[GpuClusteredLight]) -> Bytes {
  let out : Array[Byte] = []
  for light in lights {
    pbr_gpu_clustered_lights_push_vec4(out, light.light_custom_data)
    pbr_gpu_clustered_lights_push_vec4(out, light.color_inverse_square_range)
    pbr_gpu_clustered_lights_push_vec4(out, light.position_radius)
    pbr_gpu_clustering_push_u32_le(out, light.flags)
    pbr_gpu_clustering_push_u32_le(
      out,
      light.shadow_depth_bias.reinterpret_as_uint(),
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      light.shadow_normal_bias.reinterpret_as_uint(),
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      light.spot_light_tan_angle.reinterpret_as_uint(),
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      light.soft_shadow_size.reinterpret_as_uint(),
    )
    pbr_gpu_clustering_push_u32_le(
      out,
      light.shadow_map_near_z.reinterpret_as_uint(),
    )
    pbr_gpu_clustering_push_u32_le(out, light.decal_index)
    pbr_gpu_clustering_push_u32_le(out, light.range.reinterpret_as_uint())
  }
  Bytes::from_array(out)
}

///|
pub fn GpuClusteredLights::write_buffer(
  self : GpuClusteredLights,
  render_device : @renderer.RenderDevice,
  render_queue : @renderer.RenderQueue,
) -> Unit {
  if self.is_storage_buffer {
    if self.data.length() == 0 {
      self.data.push(GpuClusteredLight::GpuClusteredLight())
    }
  } else {
    while self.data.length() < MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS {
      self.data.push(GpuClusteredLight::GpuClusteredLight())
    }
  }
  let bytes = pbr_gpu_clustered_lights_bytes(self.data)
  let usage = if self.is_storage_buffer {
    @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST
  } else {
    @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST
  }
  let (buffer, capacity) = pbr_gpu_clustering_write_buffer(
    render_device,
    render_queue,
    self.gpu_buffer,
    self.gpu_capacity,
    bytes,
    "clustered lights buffer",
    usage_bits=usage,
  )
  self.gpu_buffer = Some(buffer)
  self.gpu_capacity = capacity
}

///|
pub(all) struct GlobalClusterableObjectMeta {
  gpu_clustered_lights : GpuClusteredLights
  entity_to_index : Map[UInt64, Int]
}

///|
pub let ecs_key_global_clusterable_object_meta : @ecs.ResourceKey[
  GlobalClusterableObjectMeta,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::GlobalClusterableObjectMeta",
)

///|
pub impl @app.Resource for GlobalClusterableObjectMeta with fn resource() {
  ecs_key_global_clusterable_object_meta
}

///|
pub fn GlobalClusterableObjectMeta::new(
  binding_type : UInt,
) -> GlobalClusterableObjectMeta {
  GlobalClusterableObjectMeta::{
    gpu_clustered_lights: GpuClusteredLights::from_binding_type(binding_type),
    entity_to_index: {},
  }
}

///|
pub fn GlobalClusterableObjectMeta::gpu_clustered_lights(
  self : GlobalClusterableObjectMeta,
) -> GpuClusteredLights {
  self.gpu_clustered_lights
}

///|
pub fn GlobalClusterableObjectMeta::entity_to_index_len(
  self : GlobalClusterableObjectMeta,
) -> Int {
  self.entity_to_index.length()
}

///|
pub fn GlobalClusterableObjectMeta::gpu_clustered_light_count(
  self : GlobalClusterableObjectMeta,
) -> Int {
  self.gpu_clustered_lights.len()
}

///|
pub fn GlobalClusterableObjectMeta::add_gpu_clustered_light(
  self : GlobalClusterableObjectMeta,
  light : GpuClusteredLight,
) -> Unit {
  self.gpu_clustered_lights.add(light)
}

///|
pub fn GlobalClusterableObjectMeta::write_gpu_clustered_lights_buffer(
  self : GlobalClusterableObjectMeta,
  render_device : @renderer.RenderDevice,
  render_queue : @renderer.RenderQueue,
) -> Unit {
  self.gpu_clustered_lights.write_buffer(render_device, render_queue)
}

///|
pub fn GlobalClusterableObjectMeta::gpu_clustered_lights_binding(
  self : GlobalClusterableObjectMeta,
) -> @wgpu.Buffer? {
  self.gpu_clustered_lights.binding()
}

///|
pub fn GlobalClusterableObjectMeta::gpu_clustered_lights_gpu_capacity(
  self : GlobalClusterableObjectMeta,
) -> UInt64 {
  self.gpu_clustered_lights.gpu_capacity()
}

///|
pub fn init_global_clusterable_object_meta(world : @ecs.World) -> Unit {
  guard world.get_resource(@render.render_device_resource_key)
    is Some(render_device) else {
    return
  }
  let binding_type = render_device.get_supported_read_only_binding_type_u32(
    CLUSTERED_FORWARD_STORAGE_BUFFER_COUNT,
  )
  world.insert_resource(
    ecs_key_global_clusterable_object_meta,
    GlobalClusterableObjectMeta::new(binding_type),
  )
}

///|
const CLUSTER_OFFSET_BITS : Int = 32 - CLUSTER_COUNT_SIZE * 2

///|
const CLUSTER_OFFSET_MASK : UInt = (1U << CLUSTER_OFFSET_BITS) - 1U

///|
const CLUSTER_COUNT_MASK : UInt = (1U << CLUSTER_COUNT_SIZE) - 1U

///|
pub struct ClusterableObjectCounts3d {
  point_lights : UInt
  spot_lights : UInt
  reflection_probes : UInt
  irradiance_volumes : UInt
  decals : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ClusterableObjectCounts3d::ClusterableObjectCounts3d() -> ClusterableObjectCounts3d {
  ClusterableObjectCounts3d::{
    point_lights: 0U,
    spot_lights: 0U,
    reflection_probes: 0U,
    irradiance_volumes: 0U,
    decals: 0U,
  }
}

///|
pub fn ClusterableObjectCounts3d::new(
  point_lights : UInt,
  spot_lights : UInt,
  reflection_probes : UInt,
  irradiance_volumes : UInt,
  decals : UInt,
) -> ClusterableObjectCounts3d {
  ClusterableObjectCounts3d::{
    point_lights,
    spot_lights,
    reflection_probes,
    irradiance_volumes,
    decals,
  }
}

///|
pub fn ClusterableObjectCounts3d::point_lights(
  self : ClusterableObjectCounts3d,
) -> UInt {
  self.point_lights
}

///|
pub fn ClusterableObjectCounts3d::spot_lights(
  self : ClusterableObjectCounts3d,
) -> UInt {
  self.spot_lights
}

///|
pub fn ClusterableObjectCounts3d::total(
  self : ClusterableObjectCounts3d,
) -> UInt {
  self.point_lights +
  self.spot_lights +
  self.reflection_probes +
  self.irradiance_volumes +
  self.decals
}

///|
pub struct ClusterConfig3d {
  dimensions_x : Int
  dimensions_y : Int
  dimensions_z : Int
  dynamic_resizing : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn pbr_make_global_cluster_settings(
  supports_storage_buffers : Bool,
  clustered_decals_are_usable : Bool,
  gpu_clustering_supported? : Bool = supports_storage_buffers,
) -> @light_cluster.GlobalClusterSettings {
  @light_cluster.GlobalClusterSettings::new(
    supports_storage_buffers,
    clustered_decals_are_usable,
    if gpu_clustering_supported {
      Some(
        @light_cluster.GlobalClusterGpuSettings::new(
          GPU_CLUSTERING_INITIAL_Z_SLICE_LIST_CAPACITY,
          GPU_CLUSTERING_INITIAL_INDEX_LIST_CAPACITY,
        ),
      )
    } else {
      None
    },
    MAX_UNIFORM_BUFFER_CLUSTERABLE_OBJECTS,
    VIEW_CLUSTER_BINDINGS_MAX_INDICES,
  )
}

///|
pub fn pbr_make_global_cluster_settings_from_render_world(
  render_world : @ecs.World,
) -> @light_cluster.GlobalClusterSettings? {
  guard render_world.get_resource(@render.render_device_resource_key)
    is Some(render_device) else {
    return None
  }
  let supports_storage_buffers = render_device.supports_read_only_storage_buffer_binding(
    CLUSTERED_FORWARD_STORAGE_BUFFER_COUNT,
  )
  let clustered_decals_are_usable = @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=0U,
  )
  let gpu_clustering_supported = render_device.limits_max_storage_buffers_per_shader_stage_u32() >
    0U
  Some(
    pbr_make_global_cluster_settings(
      supports_storage_buffers,
      clustered_decals_are_usable,
      gpu_clustering_supported~,
    ),
  )
}

///|
pub struct ExtractedClusterConfig {
  near : Float
  far : Float
  dimensions_x : Int
  dimensions_y : Int
  dimensions_z : Int
} derive(Eq, Debug)

///|
pub fn ExtractedClusterConfig::from_clusters(
  clusters : @light_cluster.Clusters,
) -> ExtractedClusterConfig {
  let dimensions = clusters.dimensions()
  ExtractedClusterConfig::{
    near: clusters.near(),
    far: clusters.far(),
    dimensions_x: dimensions.0,
    dimensions_y: dimensions.1,
    dimensions_z: dimensions.2,
  }
}

///|
pub fn ExtractedClusterConfig::new(
  near : Float,
  far : Float,
  dimensions_x : Int,
  dimensions_y : Int,
  dimensions_z : Int,
) -> ExtractedClusterConfig {
  ExtractedClusterConfig::{
    near,
    far,
    dimensions_x,
    dimensions_y,
    dimensions_z,
  }
}

///|
pub fn ExtractedClusterConfig::near(self : ExtractedClusterConfig) -> Float {
  self.near
}

///|
pub fn ExtractedClusterConfig::far(self : ExtractedClusterConfig) -> Float {
  self.far
}

///|
pub fn ExtractedClusterConfig::dimensions(
  self : ExtractedClusterConfig,
) -> (Int, Int, Int) {
  (self.dimensions_x, self.dimensions_y, self.dimensions_z)
}

///|
pub let ecs_key_extracted_cluster_config : @ecs.ComponentKey[
  ExtractedClusterConfig,
] = @ecs.register_component(debug_name="mgstudio_pbr::ExtractedClusterConfig")

///|
pub impl @ecs.Component for ExtractedClusterConfig with fn component() {
  ecs_key_extracted_cluster_config
}

///|
fn cluster_config_sanitize_dimension(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
pub fn ClusterConfig3d::ClusterConfig3d() -> ClusterConfig3d {
  ClusterConfig3d::{
    dimensions_x: 16,
    dimensions_y: 9,
    dimensions_z: 24,
    dynamic_resizing: true,
  }
}

///|
pub fn ClusterConfig3d::with_dimensions(
  self : ClusterConfig3d,
  dimensions_x : Int,
  dimensions_y : Int,
  dimensions_z : Int,
) -> ClusterConfig3d {
  ClusterConfig3d::{
    ..self,
    dimensions_x: cluster_config_sanitize_dimension(dimensions_x),
    dimensions_y: cluster_config_sanitize_dimension(dimensions_y),
    dimensions_z: cluster_config_sanitize_dimension(dimensions_z),
  }
}

///|
pub fn ClusterConfig3d::with_dynamic_resizing(
  self : ClusterConfig3d,
  dynamic_resizing : Bool,
) -> ClusterConfig3d {
  ClusterConfig3d::{ ..self, dynamic_resizing, }
}

///|
pub fn ClusterConfig3d::dimensions(self : ClusterConfig3d) -> (Int, Int, Int) {
  (self.dimensions_x, self.dimensions_y, self.dimensions_z)
}

///|
pub fn pbr_cluster_tile_count(config : ClusterConfig3d) -> Int {
  let dimensions = config.dimensions()
  dimensions.0 * dimensions.1 * dimensions.2
}

///|
pub struct ClusterOffsetAndCountsPacked3d {
  offset : UInt
  point_lights : UInt
  spot_lights : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ClusterOffsetAndCountsPacked3d::offset(
  self : ClusterOffsetAndCountsPacked3d,
) -> UInt {
  self.offset
}

///|
pub fn ClusterOffsetAndCountsPacked3d::point_lights(
  self : ClusterOffsetAndCountsPacked3d,
) -> UInt {
  self.point_lights
}

///|
pub fn ClusterOffsetAndCountsPacked3d::spot_lights(
  self : ClusterOffsetAndCountsPacked3d,
) -> UInt {
  self.spot_lights
}

///|
pub fn pbr_pack_cluster_offset_and_counts(
  offset : UInt,
  counts : ClusterableObjectCounts3d,
) -> UInt {
  ((offset & CLUSTER_OFFSET_MASK) << (CLUSTER_COUNT_SIZE * 2)) |
  ((counts.point_lights & CLUSTER_COUNT_MASK) << CLUSTER_COUNT_SIZE) |
  (counts.spot_lights & CLUSTER_COUNT_MASK)
}

///|
pub fn pbr_unpack_cluster_offset_and_counts(
  packed : UInt,
) -> ClusterOffsetAndCountsPacked3d {
  ClusterOffsetAndCountsPacked3d::{
    offset: (packed >> (CLUSTER_COUNT_SIZE * 2)) & CLUSTER_OFFSET_MASK,
    point_lights: (packed >> CLUSTER_COUNT_SIZE) & CLUSTER_COUNT_MASK,
    spot_lights: packed & CLUSTER_COUNT_MASK,
  }
}

///|
pub struct ViewClusterBindings3d {
  indices : Array[UInt]
  offsets_and_counts : Array[(UInt, ClusterableObjectCounts3d)]
  max_indices : Int
  max_offsets : Int
}

///|
pub struct GpuClusterOffsetAndCounts {
  offset : UInt
  point_lights : UInt
  spot_lights : UInt
  reflection_probes : UInt
  irradiance_volumes : UInt
  decals : UInt
}

///|
pub struct ViewClusterBindings {
  mut n_indices : Int
  mut n_offsets : Int
  clusterable_object_index_lists : @render_resource.StorageBuffer[UInt]
  cluster_offsets_and_counts : @render_resource.StorageBuffer[
    GpuClusterOffsetAndCounts,
  ]
  mut clusterable_object_index_lists_gpu_buffer : @wgpu.Buffer?
  mut clusterable_object_index_lists_gpu_capacity : UInt64
  mut cluster_offsets_and_counts_gpu_buffer : @wgpu.Buffer?
  mut cluster_offsets_and_counts_gpu_capacity : UInt64
}

///|
pub let ecs_key_view_cluster_bindings : @ecs.ComponentKey[ViewClusterBindings] = @ecs.register_component(
  debug_name="mgstudio_pbr::ViewClusterBindings",
)

///|
pub impl @ecs.Component for ViewClusterBindings with fn component() {
  ecs_key_view_cluster_bindings
}

///|
pub fn GpuClusterOffsetAndCounts::GpuClusterOffsetAndCounts() -> GpuClusterOffsetAndCounts {
  GpuClusterOffsetAndCounts::{
    offset: 0U,
    point_lights: 0U,
    spot_lights: 0U,
    reflection_probes: 0U,
    irradiance_volumes: 0U,
    decals: 0U,
  }
}

///|
pub fn GpuClusterOffsetAndCounts::new(
  offset : UInt,
  counts : ClusterableObjectCounts3d,
) -> GpuClusterOffsetAndCounts {
  GpuClusterOffsetAndCounts::{
    offset,
    point_lights: counts.point_lights,
    spot_lights: counts.spot_lights,
    reflection_probes: counts.reflection_probes,
    irradiance_volumes: counts.irradiance_volumes,
    decals: counts.decals,
  }
}

///|
pub fn ViewClusterBindings::ViewClusterBindings() -> ViewClusterBindings {
  ViewClusterBindings::{
    n_indices: 0,
    n_offsets: 0,
    clusterable_object_index_lists: @render_resource.StorageBuffer::new(),
    cluster_offsets_and_counts: @render_resource.StorageBuffer::new(),
    clusterable_object_index_lists_gpu_buffer: None,
    clusterable_object_index_lists_gpu_capacity: 0UL,
    cluster_offsets_and_counts_gpu_buffer: None,
    cluster_offsets_and_counts_gpu_capacity: 0UL,
  }
}

///|
pub fn ViewClusterBindings::clear(self : ViewClusterBindings) -> Unit {
  self.clusterable_object_index_lists.clear()
  self.cluster_offsets_and_counts.clear()
  self.n_indices = 0
  self.n_offsets = 0
}

///|
pub fn ViewClusterBindings::n_indices(self : ViewClusterBindings) -> Int {
  self.n_indices
}

///|
pub fn ViewClusterBindings::n_offsets(self : ViewClusterBindings) -> Int {
  self.n_offsets
}

///|
pub fn ViewClusterBindings::reserve_clusters(
  self : ViewClusterBindings,
  clusters : Int,
) -> Unit {
  if clusters < 0 {
    abort("ViewClusterBindings::reserve_clusters requires non-negative count")
  }
  for _ in 0..<clusters {
    self.cluster_offsets_and_counts.push(
      GpuClusterOffsetAndCounts::GpuClusterOffsetAndCounts(),
    )
  }
  self.n_offsets += clusters
}

///|
pub fn ViewClusterBindings::reserve_indices(
  self : ViewClusterBindings,
  elements : Int,
) -> Unit {
  if elements < 0 {
    abort("ViewClusterBindings::reserve_indices requires non-negative count")
  }
  for _ in 0..<elements {
    self.clusterable_object_index_lists.push(0U)
  }
  self.n_indices += elements
}

///|
pub fn ViewClusterBindings::cluster_offsets_len(
  self : ViewClusterBindings,
) -> Int {
  self.cluster_offsets_and_counts.len()
}

///|
pub fn ViewClusterBindings::clusterable_object_index_lists_len(
  self : ViewClusterBindings,
) -> Int {
  self.clusterable_object_index_lists.len()
}

///|
pub fn ViewClusterBindings::clusterable_object_index_lists_gpu_buffer(
  self : ViewClusterBindings,
) -> @wgpu.Buffer? {
  self.clusterable_object_index_lists_gpu_buffer
}

///|
pub fn ViewClusterBindings::cluster_offsets_and_counts_gpu_buffer(
  self : ViewClusterBindings,
) -> @wgpu.Buffer? {
  self.cluster_offsets_and_counts_gpu_buffer
}

///|
pub fn ViewClusterBindings::clusterable_object_index_lists_gpu_capacity(
  self : ViewClusterBindings,
) -> UInt64 {
  self.clusterable_object_index_lists_gpu_capacity
}

///|
pub fn ViewClusterBindings::cluster_offsets_and_counts_gpu_capacity(
  self : ViewClusterBindings,
) -> UInt64 {
  self.cluster_offsets_and_counts_gpu_capacity
}

///|
fn pbr_gpu_clustering_buffer_usage(raw : UInt64) -> @wgpu.BufferUsage {
  @wgpu.BufferUsage::from_u64(raw)
}

///|
fn pbr_gpu_clustering_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
fn pbr_gpu_clustering_reuse_or_create_buffer(
  render_device : @renderer.RenderDevice,
  current_buffer : @wgpu.Buffer?,
  current_capacity : UInt64,
  required_size : UInt64,
  usage_bits : UInt64,
  label : String,
) -> (@wgpu.Buffer, UInt64) {
  let safe_size = pbr_gpu_clustering_non_zero_u64(required_size)
  match current_buffer {
    Some(existing) if current_capacity >= safe_size =>
      (existing, current_capacity)
    Some(existing) => {
      existing.release()
      let next = render_device
        .wgpu_device()
        .create_buffer(
          size=safe_size,
          usage=pbr_gpu_clustering_buffer_usage(usage_bits),
        )
      next.set_label(label)
      (next, safe_size)
    }
    None => {
      let next = render_device
        .wgpu_device()
        .create_buffer(
          size=safe_size,
          usage=pbr_gpu_clustering_buffer_usage(usage_bits),
        )
      next.set_label(label)
      (next, safe_size)
    }
  }
}

///|
fn pbr_gpu_clustering_write_buffer(
  render_device : @renderer.RenderDevice,
  render_queue : @renderer.RenderQueue,
  current_buffer : @wgpu.Buffer?,
  current_capacity : UInt64,
  bytes : Bytes,
  label : String,
  usage_bits? : UInt64 = @wgpu.BUFFER_USAGE_STORAGE |
    @wgpu.BUFFER_USAGE_COPY_DST,
) -> (@wgpu.Buffer, UInt64) {
  let (buffer, capacity) = pbr_gpu_clustering_reuse_or_create_buffer(
    render_device,
    current_buffer,
    current_capacity,
    bytes.length().to_uint64(),
    usage_bits,
    label,
  )
  if bytes.length() > 0 {
    render_queue.wgpu_queue().write_buffer(buffer, 0UL, bytes)
  }
  (buffer, capacity)
}

///|
fn pbr_gpu_clustering_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
  out.push(((value >> 16) & 0xFFU).to_byte())
  out.push(((value >> 24) & 0xFFU).to_byte())
}

///|
fn pbr_gpu_clustering_u32_storage_bytes(values : Array[UInt]) -> Bytes {
  let out : Array[Byte] = []
  for value in values {
    pbr_gpu_clustering_push_u32_le(out, value)
  }
  Bytes::from_array(out)
}

///|
fn pbr_gpu_clustering_offsets_and_counts_storage_bytes(
  values : Array[GpuClusterOffsetAndCounts],
) -> Bytes {
  let out : Array[Byte] = []
  for value in values {
    pbr_gpu_clustering_push_u32_le(out, value.offset)
    pbr_gpu_clustering_push_u32_le(out, value.point_lights)
    pbr_gpu_clustering_push_u32_le(out, value.spot_lights)
    pbr_gpu_clustering_push_u32_le(out, value.reflection_probes)
    pbr_gpu_clustering_push_u32_le(out, value.irradiance_volumes)
    pbr_gpu_clustering_push_u32_le(out, value.decals)
    pbr_gpu_clustering_push_u32_le(out, 0U)
    pbr_gpu_clustering_push_u32_le(out, 0U)
  }
  Bytes::from_array(out)
}

///|
pub fn ViewClusterBindings::write_buffers(
  self : ViewClusterBindings,
  render_device : @renderer.RenderDevice,
  render_queue : @renderer.RenderQueue,
) -> Unit {
  let index_bytes = pbr_gpu_clustering_u32_storage_bytes(
    self.clusterable_object_index_lists.values(),
  )
  let (index_buffer, index_capacity) = pbr_gpu_clustering_write_buffer(
    render_device,
    render_queue,
    self.clusterable_object_index_lists_gpu_buffer,
    self.clusterable_object_index_lists_gpu_capacity,
    index_bytes,
    "clusterable object index lists",
  )
  self.clusterable_object_index_lists_gpu_buffer = Some(index_buffer)
  self.clusterable_object_index_lists_gpu_capacity = index_capacity
  let offsets_bytes = pbr_gpu_clustering_offsets_and_counts_storage_bytes(
    self.cluster_offsets_and_counts.values(),
  )
  let (offsets_buffer, offsets_capacity) = pbr_gpu_clustering_write_buffer(
    render_device,
    render_queue,
    self.cluster_offsets_and_counts_gpu_buffer,
    self.cluster_offsets_and_counts_gpu_capacity,
    offsets_bytes,
    "cluster offsets and counts",
  )
  self.cluster_offsets_and_counts_gpu_buffer = Some(offsets_buffer)
  self.cluster_offsets_and_counts_gpu_capacity = offsets_capacity
}

///|
pub fn ViewClusterBindings3d::ViewClusterBindings3d() -> ViewClusterBindings3d {
  ViewClusterBindings3d::{
    indices: [],
    offsets_and_counts: [],
    max_indices: VIEW_CLUSTER_BINDINGS_MAX_INDICES,
    max_offsets: VIEW_CLUSTER_BINDINGS_MAX_OFFSETS,
  }
}

///|
pub fn ViewClusterBindings3d::with_limits(
  max_indices : Int,
  max_offsets : Int,
) -> ViewClusterBindings3d {
  ViewClusterBindings3d::{
    indices: [],
    offsets_and_counts: [],
    max_indices: if max_indices <= 0 {
      1
    } else {
      max_indices
    },
    max_offsets: if max_offsets <= 0 {
      1
    } else {
      max_offsets
    },
  }
}

///|
pub fn ViewClusterBindings3d::clear(self : ViewClusterBindings3d) -> Unit {
  self.indices.clear()
  self.offsets_and_counts.clear()
}

///|
pub fn ViewClusterBindings3d::n_indices(self : ViewClusterBindings3d) -> Int {
  self.indices.length()
}

///|
pub fn ViewClusterBindings3d::n_offsets(self : ViewClusterBindings3d) -> Int {
  self.offsets_and_counts.length()
}

///|
pub fn ViewClusterBindings3d::index(
  self : ViewClusterBindings3d,
  idx : Int,
) -> UInt? {
  if idx < 0 || idx >= self.indices.length() {
    None
  } else {
    Some(self.indices[idx])
  }
}

///|
pub fn ViewClusterBindings3d::push_offset_and_counts(
  self : ViewClusterBindings3d,
  offset : UInt,
  counts : ClusterableObjectCounts3d,
) -> Bool {
  if self.n_offsets() >= self.max_offsets {
    false
  } else {
    self.offsets_and_counts.push((offset, counts))
    true
  }
}

///|
pub fn ViewClusterBindings3d::push_index(
  self : ViewClusterBindings3d,
  index : UInt,
) -> Bool {
  if self.n_indices() >= self.max_indices {
    false
  } else {
    self.indices.push(index)
    true
  }
}

///|
pub fn ViewClusterBindings3d::push_dummy_index(
  self : ViewClusterBindings3d,
) -> Bool {
  self.push_index(0xFFFF_FFFFU)
}

///|
pub fn ViewClusterBindings3d::uniform_packed_offsets_and_counts(
  self : ViewClusterBindings3d,
) -> Array[UInt] {
  self.offsets_and_counts.map(fn(item) {
    let offset = item.0
    let counts = item.1
    pbr_pack_cluster_offset_and_counts(offset, counts)
  })
}
