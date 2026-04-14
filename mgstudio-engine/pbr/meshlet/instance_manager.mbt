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
  mut instances : Array[(UInt64, Int, Bool)]
  mut instance_uniform_material_slots : Array[Int]
  mut instance_aabbs : Array[MeshletAabb]
  mut instance_material_ids : Array[Int]
  mut instance_material_asset_ids : Array[Int]
  mut instance_bvh_root_nodes : Array[Int]
  mut view_instance_visibility : Map[UInt64, Array[Int]]
  mut next_material_id : Int
  material_id_lookup : Map[Int, Int]
  material_ids_present_in_scene : Map[Int, Bool]
}

///|
pub struct ExtractedMeshletInstance {
  instance : @core.Entity
  material_asset_id : Int
  root_bvh_node : Int
  aabb : MeshletAabb
  bvh_depth : Int
  render_layer_mask : Int
  not_shadow_caster : Bool
  material_slot : Int
}

///|
pub fn InstanceManager::default() -> InstanceManager {
  InstanceManager::{
    scene_instance_count: 0,
    max_bvh_depth: 0,
    instances: [],
    instance_uniform_material_slots: [],
    instance_aabbs: [],
    instance_material_ids: [],
    instance_material_asset_ids: [],
    instance_bvh_root_nodes: [],
    view_instance_visibility: {},
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
  instance : @core.Entity,
  material_asset_id : Int,
  root_bvh_node : Int,
  aabb : MeshletAabb,
  bvh_depth : Int,
  render_layer_mask? : Int = 1,
  not_shadow_caster? : Bool = false,
  material_slot? : Int = 0,
) -> Unit {
  self.instances.push(
    (instance.to_bits(), render_layer_mask, not_shadow_caster),
  )
  self.instance_uniform_material_slots.push(non_negative(material_slot))
  self.instance_aabbs.push(aabb)
  self.instance_material_ids.push(0)
  self.instance_material_asset_ids.push(non_negative(material_asset_id))
  self.instance_bvh_root_nodes.push(non_negative(root_bvh_node))
  self.scene_instance_count = self.instances.length()
  let safe_depth = non_negative(bvh_depth)
  if safe_depth > self.max_bvh_depth {
    self.max_bvh_depth = safe_depth
  }
}

///|
pub fn InstanceManager::reset(
  self : InstanceManager,
  active_views? : Array[@core.Entity] = [],
) -> Unit {
  let retained_visibility : Map[UInt64, Array[Int]] = {}
  for view_entity in active_views {
    let key = view_entity.to_bits()
    match self.view_instance_visibility.get(key) {
      Some(visibility) => {
        visibility.clear()
        retained_visibility.set(key, visibility)
      }
      None => ()
    }
  }

  self.scene_instance_count = 0
  self.max_bvh_depth = 0
  self.instances = []
  self.instance_uniform_material_slots = []
  self.instance_aabbs = []
  self.instance_material_ids = []
  self.instance_material_asset_ids = []
  self.instance_bvh_root_nodes = []
  self.view_instance_visibility = retained_visibility
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
pub fn InstanceManager::material_id_for_asset(
  self : InstanceManager,
  material_asset_id : Int,
) -> Int? {
  self.material_id_lookup.get(non_negative(material_asset_id))
}

///|
pub fn InstanceManager::present_material_asset_ids(
  self : InstanceManager,
) -> Array[Int] {
  let ids = []
  for material_asset_id in self.material_id_lookup.keys() {
    match self.material_id_lookup.get(material_asset_id) {
      Some(material_id) =>
        if self.material_present_in_scene(material_id) {
          ids.push(material_asset_id)
        }
      None => ()
    }
  }
  ids.sort()
  ids
}

///|
pub fn InstanceManager::present_material_count(self : InstanceManager) -> Int {
  self.material_ids_present_in_scene.length()
}

///|
pub fn InstanceManager::present_material_ids(
  self : InstanceManager,
) -> Array[Int] {
  let ids = []
  for material_id in self.material_ids_present_in_scene.keys() {
    ids.push(material_id)
  }
  ids.sort()
  ids
}

///|
pub fn InstanceManager::instance_material_ids(
  self : InstanceManager,
) -> Array[Int] {
  let ids = []
  for material_id in self.instance_material_ids {
    ids.push(material_id)
  }
  ids
}

///|
pub fn InstanceManager::instance_bvh_root_nodes(
  self : InstanceManager,
) -> Array[Int] {
  let root_nodes = []
  for root_node in self.instance_bvh_root_nodes {
    root_nodes.push(root_node)
  }
  root_nodes
}

///|
pub fn InstanceManager::view_visibility_count(self : InstanceManager) -> Int {
  self.view_instance_visibility.length()
}

///|
pub fn InstanceManager::set_view_instance_visibility(
  self : InstanceManager,
  view_entity : @core.Entity,
  visibility : Array[Int],
) -> Unit {
  self.view_instance_visibility.set(view_entity.to_bits(), visibility)
}

///|
pub fn ExtractedMeshletInstance::new(
  instance : @core.Entity,
  material_asset_id : Int,
) -> ExtractedMeshletInstance {
  ExtractedMeshletInstance::{
    instance,
    material_asset_id: non_negative(material_asset_id),
    root_bvh_node: 0,
    aabb: MeshletAabb::default(),
    bvh_depth: 0,
    render_layer_mask: 1,
    not_shadow_caster: false,
    material_slot: 0,
  }
}

///|
pub fn ExtractedMeshletInstance::with_bvh(
  self : ExtractedMeshletInstance,
  root_bvh_node : Int,
  bvh_depth : Int,
) -> ExtractedMeshletInstance {
  ExtractedMeshletInstance::{
    ..self,
    root_bvh_node: non_negative(root_bvh_node),
    bvh_depth: non_negative(bvh_depth),
  }
}

///|
pub fn ExtractedMeshletInstance::with_aabb(
  self : ExtractedMeshletInstance,
  aabb : MeshletAabb,
) -> ExtractedMeshletInstance {
  ExtractedMeshletInstance::{ ..self, aabb, }
}

///|
pub fn ExtractedMeshletInstance::with_render_layers(
  self : ExtractedMeshletInstance,
  render_layer_mask : Int,
) -> ExtractedMeshletInstance {
  ExtractedMeshletInstance::{
    ..self,
    render_layer_mask: non_negative(render_layer_mask),
  }
}

///|
pub fn ExtractedMeshletInstance::with_not_shadow_caster(
  self : ExtractedMeshletInstance,
  not_shadow_caster : Bool,
) -> ExtractedMeshletInstance {
  ExtractedMeshletInstance::{ ..self, not_shadow_caster, }
}

///|
pub fn ExtractedMeshletInstance::with_material_slot(
  self : ExtractedMeshletInstance,
  material_slot : Int,
) -> ExtractedMeshletInstance {
  ExtractedMeshletInstance::{
    ..self,
    material_slot: non_negative(material_slot),
  }
}

///|
pub fn extract_meshlet_mesh_entities_from_instances(
  extracted_instances : Array[ExtractedMeshletInstance],
) -> InstanceManager {
  let manager = InstanceManager::default()
  for extracted_instance in extracted_instances {
    manager.add_instance(
      extracted_instance.instance,
      extracted_instance.material_asset_id,
      extracted_instance.root_bvh_node,
      extracted_instance.aabb,
      extracted_instance.bvh_depth,
      render_layer_mask=extracted_instance.render_layer_mask,
      not_shadow_caster=extracted_instance.not_shadow_caster,
      material_slot=extracted_instance.material_slot,
    )
  }
  manager
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
pub fn queue_material_meshlet_meshes_with_present_material_assets(
  instance_manager : InstanceManager,
) -> Int {
  queue_material_meshlet_meshes_with_material_assets(
    instance_manager,
    instance_manager.instance_material_asset_ids,
  )
}

///|
pub fn queue_material_meshlet_meshes(instance_manager : InstanceManager) -> Int {
  instance_manager.material_ids_present_in_scene.clear()
  for index in 0..<instance_manager.instance_material_ids.length() {
    instance_manager.instance_material_ids[index] = 0
  }
  for index in 0..<instance_manager.instance_material_asset_ids.length() {
    let material_asset_id = instance_manager.instance_material_asset_ids[index]
    match instance_manager.material_id_lookup.get(material_asset_id) {
      Some(material_id) => {
        instance_manager.mark_material_present_in_scene(material_id)
        instance_manager.instance_material_ids[index] = material_id
      }
      None => ()
    }
  }
  instance_manager.present_material_count()
}
