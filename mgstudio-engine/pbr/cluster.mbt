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
pub(all) enum GpuClusteredLights {
  StorageBuffer
  UniformBuffer
} derive(Eq, Debug)

///|
pub fn GpuClusteredLights::from_binding_type(
  binding_type : UInt,
) -> GpuClusteredLights {
  if binding_type == @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE {
    StorageBuffer
  } else {
    UniformBuffer
  }
}

///|
pub fn GpuClusteredLights::binding_type(self : GpuClusteredLights) -> UInt {
  match self {
    StorageBuffer => @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE
    UniformBuffer => @wgpu.BUFFER_BINDING_TYPE_UNIFORM
  }
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
