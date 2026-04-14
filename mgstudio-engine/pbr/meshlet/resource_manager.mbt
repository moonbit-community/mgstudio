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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/resource_manager.rs`.

///|
fn meshlet_resource_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub struct ResourceManager {
  mut frame_index : Int
  mut cluster_buffer_slots : Int
  mut cull_queue_rightmost_slot : Int
  mut meshlet_buffer_count : Int
  previous_depth_pyramids : Map[Int, Int]
  mut prepared_view_bind_groups : Map[UInt64, MeshletViewBindGroups]
  clear_visibility_buffer_bind_group_layout_id : Int
  clear_visibility_buffer_shadow_view_bind_group_layout_id : Int
  first_instance_cull_bind_group_layout_id : Int
  second_instance_cull_bind_group_layout_id : Int
  first_bvh_cull_bind_group_layout_id : Int
  second_bvh_cull_bind_group_layout_id : Int
  first_meshlet_cull_bind_group_layout_id : Int
  second_meshlet_cull_bind_group_layout_id : Int
  visibility_buffer_raster_bind_group_layout_id : Int
  visibility_buffer_raster_shadow_view_bind_group_layout_id : Int
  downsample_depth_bind_group_layout_id : Int
  downsample_depth_shadow_view_bind_group_layout_id : Int
  resolve_depth_bind_group_layout_id : Int
  resolve_depth_shadow_view_bind_group_layout_id : Int
  resolve_material_depth_bind_group_layout_id : Int
  material_shade_bind_group_layout_id : Int
  fill_counts_bind_group_layout_id : Int
  remap_1d_to_2d_dispatch_bind_group_layout_id : Int?
}

///|
pub fn ResourceManager::default() -> ResourceManager {
  ResourceManager::new(0)
}

///|
pub fn ResourceManager::new(cluster_buffer_slots : Int) -> ResourceManager {
  let safe_slots = meshlet_resource_non_negative(cluster_buffer_slots)
  ResourceManager::{
    frame_index: 0,
    cluster_buffer_slots: safe_slots,
    cull_queue_rightmost_slot: if safe_slots <= 0 {
      0
    } else {
      safe_slots - 1
    },
    meshlet_buffer_count: 0,
    previous_depth_pyramids: {},
    prepared_view_bind_groups: {},
    clear_visibility_buffer_bind_group_layout_id: -1,
    clear_visibility_buffer_shadow_view_bind_group_layout_id: -1,
    first_instance_cull_bind_group_layout_id: -1,
    second_instance_cull_bind_group_layout_id: -1,
    first_bvh_cull_bind_group_layout_id: -1,
    second_bvh_cull_bind_group_layout_id: -1,
    first_meshlet_cull_bind_group_layout_id: -1,
    second_meshlet_cull_bind_group_layout_id: -1,
    visibility_buffer_raster_bind_group_layout_id: -1,
    visibility_buffer_raster_shadow_view_bind_group_layout_id: -1,
    downsample_depth_bind_group_layout_id: -1,
    downsample_depth_shadow_view_bind_group_layout_id: -1,
    resolve_depth_bind_group_layout_id: -1,
    resolve_depth_shadow_view_bind_group_layout_id: -1,
    resolve_material_depth_bind_group_layout_id: -1,
    material_shade_bind_group_layout_id: -1,
    fill_counts_bind_group_layout_id: -1,
    remap_1d_to_2d_dispatch_bind_group_layout_id: None,
  }
}

///|
pub fn ResourceManager::advance_frame(self : ResourceManager) -> Unit {
  self.frame_index = self.frame_index + 1
}

///|
pub fn ResourceManager::frame_index(self : ResourceManager) -> Int {
  self.frame_index
}

///|
pub fn ResourceManager::cluster_buffer_slots(self : ResourceManager) -> Int {
  self.cluster_buffer_slots
}

///|
pub fn ResourceManager::cull_queue_rightmost_slot(
  self : ResourceManager,
) -> Int {
  self.cull_queue_rightmost_slot
}

///|
pub fn ResourceManager::set_cluster_buffer_slots(
  self : ResourceManager,
  cluster_buffer_slots : Int,
) -> Unit {
  let safe_slots = meshlet_resource_non_negative(cluster_buffer_slots)
  self.cluster_buffer_slots = safe_slots
  self.cull_queue_rightmost_slot = if safe_slots <= 0 {
    0
  } else {
    safe_slots - 1
  }
}

///|
pub fn ResourceManager::set_meshlet_buffer_count(
  self : ResourceManager,
  count : Int,
) -> Unit {
  self.meshlet_buffer_count = meshlet_resource_non_negative(count)
}

///|
pub fn ResourceManager::meshlet_buffer_count(self : ResourceManager) -> Int {
  self.meshlet_buffer_count
}

///|
pub fn ResourceManager::set_previous_depth_pyramid(
  self : ResourceManager,
  view_entity : Int,
  texture_view_id : Int,
) -> Unit {
  self.previous_depth_pyramids.set(
    meshlet_resource_non_negative(view_entity),
    meshlet_resource_non_negative(texture_view_id),
  )
}

///|
pub fn ResourceManager::previous_depth_pyramid(
  self : ResourceManager,
  view_entity : Int,
) -> Int? {
  self.previous_depth_pyramids.get(meshlet_resource_non_negative(view_entity))
}

///|
pub fn ResourceManager::clear_stale_previous_depth_pyramids(
  self : ResourceManager,
  active_view_entities : Array[Int],
) -> Unit {
  let active : Map[Int, Bool] = {}
  for view_entity in active_view_entities {
    active.set(meshlet_resource_non_negative(view_entity), true)
  }
  let stale_keys : Array[Int] = []
  for key in self.previous_depth_pyramids.keys() {
    if active.get(key) is None {
      stale_keys.push(key)
    }
  }
  for stale_key in stale_keys {
    self.previous_depth_pyramids.remove(stale_key)
  }
}

///|
pub fn ResourceManager::bind_group_layout_count(self : ResourceManager) -> Int {
  let base_count = [
    self.clear_visibility_buffer_bind_group_layout_id,
    self.clear_visibility_buffer_shadow_view_bind_group_layout_id,
    self.first_instance_cull_bind_group_layout_id,
    self.second_instance_cull_bind_group_layout_id,
    self.first_bvh_cull_bind_group_layout_id,
    self.second_bvh_cull_bind_group_layout_id,
    self.first_meshlet_cull_bind_group_layout_id,
    self.second_meshlet_cull_bind_group_layout_id,
    self.visibility_buffer_raster_bind_group_layout_id,
    self.visibility_buffer_raster_shadow_view_bind_group_layout_id,
    self.downsample_depth_bind_group_layout_id,
    self.downsample_depth_shadow_view_bind_group_layout_id,
    self.resolve_depth_bind_group_layout_id,
    self.resolve_depth_shadow_view_bind_group_layout_id,
    self.resolve_material_depth_bind_group_layout_id,
    self.material_shade_bind_group_layout_id,
    self.fill_counts_bind_group_layout_id,
  ].fold(init=0, fn(acc, id) { if id >= 0 { acc + 1 } else { acc } })
  let optional_count = if self.remap_1d_to_2d_dispatch_bind_group_layout_id
    is Some(_) {
    1
  } else {
    0
  }
  base_count + optional_count
}

///|
pub struct MeshletViewResources {
  view_entity : @core.Entity
  meshlet_count : Int
}

///|
pub fn MeshletViewResources::new(
  view_entity : @core.Entity,
  meshlet_count : Int,
) -> MeshletViewResources {
  MeshletViewResources::{
    view_entity,
    meshlet_count: meshlet_resource_non_negative(meshlet_count),
  }
}

///|
pub struct MeshletViewBindGroups {
  view_entity : @core.Entity
  bind_group_count : Int
}

///|
pub fn MeshletViewBindGroups::new(
  view_entity : @core.Entity,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  MeshletViewBindGroups::{
    view_entity,
    bind_group_count: meshlet_resource_non_negative(bind_group_count),
  }
}

///|
pub fn ResourceManager::set_prepared_view_bind_groups(
  self : ResourceManager,
  bind_groups : MeshletViewBindGroups,
) -> Unit {
  self.prepared_view_bind_groups.set(
    bind_groups.view_entity.to_bits(),
    bind_groups,
  )
}

///|
pub fn ResourceManager::prepared_view_bind_groups(
  self : ResourceManager,
  view_entity : @core.Entity,
) -> MeshletViewBindGroups? {
  self.prepared_view_bind_groups.get(view_entity.to_bits())
}

///|
pub fn ResourceManager::prepared_view_bind_group_count(
  self : ResourceManager,
) -> Int {
  self.prepared_view_bind_groups.length()
}

///|
pub fn ResourceManager::clear_stale_prepared_view_bind_groups(
  self : ResourceManager,
  active_view_entities : Array[@core.Entity],
) -> Unit {
  let active : Map[UInt64, Bool] = {}
  for view_entity in active_view_entities {
    active.set(view_entity.to_bits(), true)
  }
  let stale_keys : Array[UInt64] = []
  for key in self.prepared_view_bind_groups.keys() {
    if active.get(key) is None {
      stale_keys.push(key)
    }
  }
  for stale_key in stale_keys {
    self.prepared_view_bind_groups.remove(stale_key)
  }
}

///|
pub fn prepare_meshlet_per_frame_resources(
  manager : ResourceManager,
  meshlet_buffer_count : Int,
) -> Unit {
  manager.set_meshlet_buffer_count(meshlet_buffer_count)
  let slots = manager.cluster_buffer_slots()
  if slots <= 0 || meshlet_buffer_count <= 0 {
    manager.cull_queue_rightmost_slot = 0
  } else {
    let limited_count = if meshlet_buffer_count > slots {
      slots
    } else {
      meshlet_buffer_count
    }
    manager.cull_queue_rightmost_slot = limited_count - 1
  }
  manager.advance_frame()
}

///|
pub fn prepare_meshlet_view_bind_groups(
  view_entity : @core.Entity,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  MeshletViewBindGroups::new(view_entity, bind_group_count)
}

///|
pub fn prepare_meshlet_view_bind_groups_for_view(
  manager : ResourceManager,
  view_entity : @core.Entity,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  let bind_groups = prepare_meshlet_view_bind_groups(
    view_entity, bind_group_count,
  )
  manager.set_prepared_view_bind_groups(bind_groups)
  bind_groups
}
