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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/instance_manager.rs`.

///|
pub struct InstanceManager {
  mut scene_instance_count : Int
  mut max_bvh_depth : Int
  mut next_material_id : Int
  material_id_lookup : Map[Int, Int]
  material_ids_present_in_scene : Map[Int, Bool]
}

///|
pub fn InstanceManager::default() -> InstanceManager {
  InstanceManager::{
    scene_instance_count: 0,
    max_bvh_depth: 0,
    next_material_id: 0,
    material_id_lookup: {},
    material_ids_present_in_scene: {},
  }
}

///|
fn non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn InstanceManager::set_instance_count(
  self : InstanceManager,
  count : Int,
) -> Unit {
  self.scene_instance_count = non_negative(count)
}

///|
pub fn InstanceManager::instance_count(self : InstanceManager) -> Int {
  self.scene_instance_count
}

///|
pub fn InstanceManager::max_bvh_depth(self : InstanceManager) -> Int {
  self.max_bvh_depth
}

///|
pub fn InstanceManager::set_max_bvh_depth(
  self : InstanceManager,
  bvh_depth : Int,
) -> Unit {
  self.max_bvh_depth = non_negative(bvh_depth)
}

///|
pub fn InstanceManager::add_instance(
  self : InstanceManager,
  bvh_depth : Int,
) -> Unit {
  self.scene_instance_count = self.scene_instance_count + 1
  let safe_depth = non_negative(bvh_depth)
  if safe_depth > self.max_bvh_depth {
    self.max_bvh_depth = safe_depth
  }
}

///|
pub fn InstanceManager::reset(self : InstanceManager) -> Unit {
  self.scene_instance_count = 0
  self.max_bvh_depth = 0
  self.next_material_id = 0
  self.material_id_lookup.clear()
  self.material_ids_present_in_scene.clear()
}

///|
pub fn InstanceManager::get_material_id(
  self : InstanceManager,
  material_asset_id : Int,
) -> Int {
  let key = non_negative(material_asset_id)
  match self.material_id_lookup.get(key) {
    Some(id) => id
    None => {
      self.next_material_id = self.next_material_id + 1
      let id = self.next_material_id
      self.material_id_lookup.set(key, id)
      id
    }
  }
}

///|
pub fn InstanceManager::mark_material_present_in_scene(
  self : InstanceManager,
  material_id : Int,
) -> Unit {
  self.material_ids_present_in_scene.set(non_negative(material_id), true)
}

///|
pub fn InstanceManager::material_present_in_scene(
  self : InstanceManager,
  material_id : Int,
) -> Bool {
  match self.material_ids_present_in_scene.get(non_negative(material_id)) {
    Some(value) => value
    None => false
  }
}

///|
pub fn InstanceManager::present_material_count(self : InstanceManager) -> Int {
  self.material_ids_present_in_scene.length()
}

///|
pub fn InstanceManager::present_material_ids(self : InstanceManager) -> Array[Int] {
  let ids = []
  for material_id in self.material_ids_present_in_scene.keys() {
    ids.push(material_id)
  }
  ids.sort()
  ids
}

///|
pub fn extract_meshlet_mesh_entities(instance_count : Int) -> InstanceManager {
  let manager = InstanceManager::default()
  manager.set_instance_count(instance_count)
  manager
}

///|
pub fn queue_material_meshlet_meshes_with_material_assets(
  instance_manager : InstanceManager,
  material_asset_ids : Array[Int],
) -> Int {
  for material_asset_id in material_asset_ids {
    let material_id = instance_manager.get_material_id(material_asset_id)
    instance_manager.mark_material_present_in_scene(material_id)
  }
  instance_manager.present_material_count()
}

///|
pub fn queue_material_meshlet_meshes(instance_manager : InstanceManager) -> Int {
  instance_manager.present_material_count()
}
