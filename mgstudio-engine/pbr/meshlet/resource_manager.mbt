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
pub struct ResourceManager {
  mut frame_index : Int
  mut meshlet_buffer_count : Int
}

///|
pub fn ResourceManager::default() -> ResourceManager {
  ResourceManager::{ frame_index: 0, meshlet_buffer_count: 0 }
}

///|
pub fn ResourceManager::advance_frame(self : ResourceManager) -> Unit {
  self.frame_index = self.frame_index + 1
}

///|
pub fn ResourceManager::set_meshlet_buffer_count(
  self : ResourceManager,
  count : Int,
) -> Unit {
  self.meshlet_buffer_count = if count < 0 { 0 } else { count }
}

///|
pub struct MeshletViewResources {
  view_entity : Int
  meshlet_count : Int
}

///|
pub fn MeshletViewResources::new(
  view_entity : Int,
  meshlet_count : Int,
) -> MeshletViewResources {
  MeshletViewResources::{ view_entity, meshlet_count }
}

///|
pub struct MeshletViewBindGroups {
  view_entity : Int
  bind_group_count : Int
}

///|
pub fn MeshletViewBindGroups::new(
  view_entity : Int,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  MeshletViewBindGroups::{ view_entity, bind_group_count }
}

///|
pub fn prepare_meshlet_per_frame_resources(
  manager : ResourceManager,
  meshlet_buffer_count : Int,
) -> Unit {
  manager.set_meshlet_buffer_count(meshlet_buffer_count)
  manager.advance_frame()
}

///|
pub fn prepare_meshlet_view_bind_groups(
  view_entity : Int,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  MeshletViewBindGroups::new(view_entity, bind_group_count)
}

///|
pub fn meshlet_resource_manager_runtime_available() -> Bool {
  meshlet_runtime_available()
}
