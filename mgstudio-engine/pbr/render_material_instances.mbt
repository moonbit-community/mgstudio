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
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs`.

///|
pub const DUMMY_MESH_MATERIAL_ID : Int = -1

///|
pub struct RenderMaterialInstance {
  asset_id : Int
  last_change_tick : @core.Tick
}

///|
pub fn RenderMaterialInstance::new(
  asset_id : Int,
  last_change_tick : @core.Tick,
) -> RenderMaterialInstance {
  RenderMaterialInstance::{ asset_id, last_change_tick }
}

///|
pub fn RenderMaterialInstance::asset_id(self : RenderMaterialInstance) -> Int {
  self.asset_id
}

///|
pub fn RenderMaterialInstance::last_change_tick(
  self : RenderMaterialInstance,
) -> @core.Tick {
  self.last_change_tick
}

///|
pub struct RenderMaterialInstances {
  instances : Map[UInt64, RenderMaterialInstance]
  mut current_change_tick : @core.Tick
  mut last_source_change_tick : @core.Tick
}

///|
pub fn RenderMaterialInstances::RenderMaterialInstances() -> RenderMaterialInstances {
  RenderMaterialInstances::{
    instances: {},
    current_change_tick: 0,
    last_source_change_tick: 0,
  }
}

///|
pub let ecs_key_render_material_instances : @ecs.ResourceKey[
  RenderMaterialInstances,
] = @ecs.register_resource(debug_name="mgstudio_pbr::RenderMaterialInstances")

///|
pub fn RenderMaterialInstances::len(self : RenderMaterialInstances) -> Int {
  self.instances.length()
}

///|
pub fn RenderMaterialInstances::current_change_tick(
  self : RenderMaterialInstances,
) -> @core.Tick {
  self.current_change_tick
}

///|
fn RenderMaterialInstances::source_system_ticks(
  self : RenderMaterialInstances,
  source_world : @ecs.World,
) -> @core.SystemTicks {
  @core.SystemTicks::new(
    self.last_source_change_tick,
    source_world.read_change_tick(),
  )
}

///|
fn RenderMaterialInstances::set_last_source_change_tick(
  self : RenderMaterialInstances,
  tick : @core.Tick,
) -> Unit {
  self.last_source_change_tick = tick
}

///|
pub fn RenderMaterialInstances::get(
  self : RenderMaterialInstances,
  entity : @core.Entity,
) -> RenderMaterialInstance? {
  self.instances.get(entity.to_bits())
}

///|
pub fn RenderMaterialInstances::mesh_material(
  self : RenderMaterialInstances,
  entity : @core.Entity,
) -> Int {
  match self.get(entity) {
    Some(instance) => instance.asset_id()
    None => DUMMY_MESH_MATERIAL_ID
  }
}

///|
pub fn RenderMaterialInstances::extract_mesh_material(
  self : RenderMaterialInstances,
  entity : @core.Entity,
  view_visible : Bool,
  material : MeshMaterial3d,
) -> Unit {
  let key = entity.to_bits()
  if view_visible {
    self.instances.set(
      key,
      RenderMaterialInstance::new(
        material.material.id(),
        self.current_change_tick,
      ),
    )
  } else {
    ignore(self.instances.remove(key))
  }
}

///|
pub fn RenderMaterialInstances::remove_mesh_material(
  self : RenderMaterialInstances,
  entity : @core.Entity,
) -> Bool {
  let key = entity.to_bits()
  let existed = self.instances.contains(key)
  self.instances.remove(key)
  existed
}

///|
pub fn RenderMaterialInstances::early_sweep_removed_mesh_material(
  self : RenderMaterialInstances,
  entity : @core.Entity,
) -> Bool {
  let key = entity.to_bits()
  match self.instances.get(key) {
    Some(instance) =>
      if instance.last_change_tick() != self.current_change_tick {
        ignore(self.instances.remove(key))
        true
      } else {
        false
      }
    None => false
  }
}

///|
pub fn RenderMaterialInstances::late_sweep_removed_mesh3d(
  self : RenderMaterialInstances,
  entity : @core.Entity,
) -> Bool {
  self.early_sweep_removed_mesh_material(entity)
}

///|
pub fn RenderMaterialInstances::advance_change_tick(
  self : RenderMaterialInstances,
) -> Unit {
  self.current_change_tick = @core.tick_wrapping_add(
    self.current_change_tick,
    1,
  )
}
