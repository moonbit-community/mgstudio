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
// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh.rs`.

///|
pub struct RenderMeshQueueData {
  mesh_asset_id : Int
  current_uniform_index : UInt
  should_batch : Bool
}

///|
pub fn RenderMeshQueueData::new(
  mesh_asset_id : Int,
  current_uniform_index : UInt,
  should_batch : Bool,
) -> RenderMeshQueueData {
  RenderMeshQueueData::{ mesh_asset_id, current_uniform_index, should_batch }
}

///|
pub fn RenderMeshQueueData::mesh_asset_id(self : RenderMeshQueueData) -> Int {
  self.mesh_asset_id
}

///|
pub fn RenderMeshQueueData::current_uniform_index(
  self : RenderMeshQueueData,
) -> UInt {
  self.current_uniform_index
}

///|
pub fn RenderMeshQueueData::should_batch(self : RenderMeshQueueData) -> Bool {
  self.should_batch
}

///|
pub struct RenderMeshInstances {
  entries : Map[UInt64, RenderMeshQueueData]
}

///|
pub fn RenderMeshInstances::RenderMeshInstances() -> RenderMeshInstances {
  RenderMeshInstances::{ entries: {} }
}

///|
pub let ecs_key_render_mesh_instances : @ecs.ResourceKey[RenderMeshInstances] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderMeshInstances",
)

///|
pub impl @app.Resource for RenderMeshInstances with fn resource() {
  ecs_key_render_mesh_instances
}

///|
pub fn RenderMeshInstances::len(self : RenderMeshInstances) -> Int {
  self.entries.length()
}

///|
pub fn RenderMeshInstances::insert(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
  data : RenderMeshQueueData,
) -> Unit {
  self.entries.set(entity.id().to_bits(), data)
}

///|
pub fn RenderMeshInstances::remove(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  let key = entity.id().to_bits()
  let value = self.entries.get(key)
  self.entries.remove(key)
  value
}

///|
pub fn RenderMeshInstances::mesh_asset_id(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
) -> Int? {
  self.render_mesh_queue_data(entity).map(fn(data) { data.mesh_asset_id() })
}

///|
pub fn RenderMeshInstances::render_mesh_queue_data(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  self.entries.get(entity.id().to_bits())
}
