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
const MESHLET_MESH_FLAGS_LOD_INDEX_NONE : UInt = 0xFFFFU

///|
const MESHLET_MESH_FLAGS_SHADOW_RECEIVER : UInt = 1U << 29

///|
const MESHLET_MESH_FLAGS_SIGN_DETERMINANT_MODEL_3X3 : UInt = 1U << 31

///|
pub(all) struct MeshletMaterialKey {
  material_asset_id : Int
  extension : @material.ExtendedMaterialMetadata3d?
}

///|
pub struct MeshletSceneMaterial {
  material_id : Int
  material_asset_id : Int
  extension : @material.ExtendedMaterialMetadata3d?
}

///|
fn meshlet_material_key(
  material_asset_id : Int,
  extension : @material.ExtendedMaterialMetadata3d?,
) -> MeshletMaterialKey {
  MeshletMaterialKey::{ material_asset_id: non_negative(material_asset_id), extension }
}

///|
fn meshlet_alpha_mode_equal(
  left : @material.AlphaMode3d,
  right : @material.AlphaMode3d,
) -> Bool {
  match (left, right) {
    (@material.AlphaMode3d::Opaque, @material.AlphaMode3d::Opaque) => true
    (@material.AlphaMode3d::Mask(left), @material.AlphaMode3d::Mask(right)) =>
      left == right
    (@material.AlphaMode3d::Blend, @material.AlphaMode3d::Blend) => true
    (@material.AlphaMode3d::Premultiplied, @material.AlphaMode3d::Premultiplied) =>
      true
    (@material.AlphaMode3d::AlphaToCoverage, @material.AlphaMode3d::AlphaToCoverage) =>
      true
    (@material.AlphaMode3d::Add, @material.AlphaMode3d::Add) => true
    (@material.AlphaMode3d::Multiply, @material.AlphaMode3d::Multiply) => true
    _ => false
  }
}

///|
fn meshlet_alpha_mode_option_equal(
  left : @material.AlphaMode3d?,
  right : @material.AlphaMode3d?,
) -> Bool {
  match (left, right) {
    (None, None) => true
    (Some(left), Some(right)) => meshlet_alpha_mode_equal(left, right)
    _ => false
  }
}

///|
fn meshlet_material_extension_equal(
  left : @material.ExtendedMaterialMetadata3d?,
  right : @material.ExtendedMaterialMetadata3d?,
) -> Bool {
  match (left, right) {
    (None, None) => true
    (Some(left), Some(right)) =>
      left.extension_tag == right.extension_tag &&
      left.vertex_shader_path == right.vertex_shader_path &&
      left.fragment_shader_path == right.fragment_shader_path &&
      left.prepass_vertex_shader_path == right.prepass_vertex_shader_path &&
      left.prepass_fragment_shader_path == right.prepass_fragment_shader_path &&
      left.deferred_vertex_shader_path == right.deferred_vertex_shader_path &&
      left.deferred_fragment_shader_path == right.deferred_fragment_shader_path &&
      left.meshlet_fragment_shader_path == right.meshlet_fragment_shader_path &&
      left.meshlet_prepass_fragment_shader_path ==
      right.meshlet_prepass_fragment_shader_path &&
      left.meshlet_deferred_fragment_shader_path ==
      right.meshlet_deferred_fragment_shader_path &&
      meshlet_alpha_mode_option_equal(
        left.alpha_mode_override, right.alpha_mode_override,
      ) &&
      left.opaque_render_method_override == right.opaque_render_method_override &&
      left.requires_depth_prepass == right.requires_depth_prepass &&
      left.requires_deferred_prepass == right.requires_deferred_prepass &&
      left.disable_shadows == right.disable_shadows
    _ => false
  }
}

///|
fn meshlet_material_key_equal(
  left : MeshletMaterialKey,
  right : MeshletMaterialKey,
) -> Bool {
  left.material_asset_id == right.material_asset_id &&
  meshlet_material_extension_equal(left.extension, right.extension)
}

///|
pub struct MeshletInstanceUniform {
  world_from_local : @math.Affine3
  previous_world_from_local : @math.Affine3
  material_slot : Int
  flags : UInt
}

///|
pub fn MeshletInstanceUniform::MeshletInstanceUniform() -> MeshletInstanceUniform {
  MeshletInstanceUniform::{
    world_from_local: @math.Affine3::identity(),
    previous_world_from_local: @math.Affine3::identity(),
    material_slot: 0,
    flags: MESHLET_MESH_FLAGS_LOD_INDEX_NONE |
    MESHLET_MESH_FLAGS_SHADOW_RECEIVER |
    MESHLET_MESH_FLAGS_SIGN_DETERMINANT_MODEL_3X3,
  }
}

///|
pub struct InstanceManager {
  mut scene_instance_count : Int
  mut max_bvh_depth : Int
  mut instances : Array[(UInt64, Int, Bool)]
  mut instance_uniforms : Array[MeshletInstanceUniform]
  mut instance_uniform_material_slots : Array[Int]
  mut instance_aabbs : Array[MeshletAabb]
  mut instance_material_ids : Array[Int]
  mut instance_material_asset_ids : Array[Int]
  mut instance_material_keys : Array[MeshletMaterialKey]
  mut instance_bvh_root_nodes : Array[Int]
  mut view_instance_visibility : Map[UInt64, Array[Int]]
  mut next_material_id : Int
  material_id_lookup : Map[Int, Int]
  mut material_keys : Array[(MeshletMaterialKey, Int)]
  material_ids_present_in_scene : @utils.IntBitSet
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
pub fn InstanceManager::InstanceManager() -> InstanceManager {
  InstanceManager::{
    scene_instance_count: 0,
    max_bvh_depth: 0,
    instances: [],
    instance_uniforms: [],
    instance_uniform_material_slots: [],
    instance_aabbs: [],
    instance_material_ids: [],
    instance_material_asset_ids: [],
    instance_material_keys: [],
    instance_bvh_root_nodes: [],
    view_instance_visibility: {},
    next_material_id: 0,
    material_id_lookup: {},
    material_keys: [],
    material_ids_present_in_scene: @utils.IntBitSet::new(),
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
  world_from_local? : @math.Affine3 = @math.Affine3::identity(),
  previous_world_from_local? : @math.Affine3 = @math.Affine3::identity(),
  not_shadow_receiver? : Bool = false,
  material_extension? : @material.ExtendedMaterialMetadata3d? = None,
) -> Unit {
  self.instances.push(
    (instance.to_bits(), render_layer_mask, not_shadow_caster),
  )
  let safe_material_slot = non_negative(material_slot)
  let mut flags = MESHLET_MESH_FLAGS_LOD_INDEX_NONE
  if !not_shadow_receiver {
    flags = flags | MESHLET_MESH_FLAGS_SHADOW_RECEIVER
  }
  if world_from_local.matrix3.determinant() >= 0.0F {
    flags = flags | MESHLET_MESH_FLAGS_SIGN_DETERMINANT_MODEL_3X3
  }
  self.instance_uniforms.push(MeshletInstanceUniform::{
    world_from_local,
    previous_world_from_local,
    material_slot: safe_material_slot,
    flags,
  })
  self.instance_uniform_material_slots.push(safe_material_slot)
  self.instance_aabbs.push(aabb)
  self.instance_material_ids.push(0)
  self.instance_material_asset_ids.push(non_negative(material_asset_id))
  self.instance_material_keys.push(
    meshlet_material_key(material_asset_id, material_extension),
  )
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
  self.instance_uniforms = []
  self.instance_uniform_material_slots = []
  self.instance_aabbs = []
  self.instance_material_ids = []
  self.instance_material_asset_ids = []
  self.instance_material_keys = []
  self.instance_bvh_root_nodes = []
  self.view_instance_visibility = retained_visibility
  self.next_material_id = 0
  self.material_id_lookup.clear()
  self.material_keys = []
  self.material_ids_present_in_scene.clear()
}

///|
fn InstanceManager::material_id_for_key(
  self : InstanceManager,
  key : MeshletMaterialKey,
) -> Int? {
  for entry in self.material_keys {
    let (stored_key, material_id) = entry
    if meshlet_material_key_equal(stored_key, key) {
      return Some(material_id)
    }
  }
  None
}

///|
fn InstanceManager::get_material_id_for_key(
  self : InstanceManager,
  key : MeshletMaterialKey,
) -> Int {
  match self.material_id_for_key(key) {
    Some(id) => id
    None => {
      self.next_material_id = self.next_material_id + 1
      let id = self.next_material_id
      self.material_keys.push((key, id))
      id
    }
  }
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
      let material_key = meshlet_material_key(key, None)
      let id = match self.material_id_for_key(material_key) {
        Some(existing) => existing
        None => self.get_material_id_for_key(material_key)
      }
      self.material_id_lookup.set(key, id)
      id
    }
  }
}

///|
pub fn InstanceManager::get_material_id_with_extension(
  self : InstanceManager,
  material_asset_id : Int,
  extension : @material.ExtendedMaterialMetadata3d?,
) -> Int {
  let key = meshlet_material_key(material_asset_id, extension)
  if extension is None {
    return self.get_material_id(material_asset_id)
  }
  self.get_material_id_for_key(key)
}

///|
pub fn InstanceManager::mark_material_present_in_scene(
  self : InstanceManager,
  material_id : Int,
) -> Unit {
  self.material_ids_present_in_scene.insert(non_negative(material_id))
}

///|
pub fn InstanceManager::material_present_in_scene(
  self : InstanceManager,
  material_id : Int,
) -> Bool {
  self.material_ids_present_in_scene.contains(non_negative(material_id))
}

///|
pub fn InstanceManager::material_id_for_asset(
  self : InstanceManager,
  material_asset_id : Int,
) -> Int? {
  self.material_id_for_key(meshlet_material_key(material_asset_id, None))
}

///|
pub fn InstanceManager::material_asset_id_for_id(
  self : InstanceManager,
  material_id : Int,
) -> Int? {
  let safe_material_id = non_negative(material_id)
  for entry in self.material_keys {
    let (key, id) = entry
    if id == safe_material_id {
      return Some(key.material_asset_id)
    }
  }
  None
}

///|
pub fn InstanceManager::material_extension_for_id(
  self : InstanceManager,
  material_id : Int,
) -> @material.ExtendedMaterialMetadata3d? {
  let safe_material_id = non_negative(material_id)
  for entry in self.material_keys {
    let (key, id) = entry
    if id == safe_material_id {
      return key.extension
    }
  }
  None
}

///|
pub fn InstanceManager::scene_material_asset_ids(
  self : InstanceManager,
) -> Array[Int] {
  let id_set = @utils.IntBitSet::new()
  for material_asset_id in self.instance_material_asset_ids {
    id_set.insert(non_negative(material_asset_id))
  }
  let ids = id_set.to_array()
  ids.sort()
  ids
}

///|
pub fn InstanceManager::scene_materials(self : InstanceManager) -> Array[MeshletSceneMaterial] {
  let materials : Array[MeshletSceneMaterial] = []
  for key in self.instance_material_keys {
    let material_id = self.get_material_id_for_key(key)
    let mut exists = false
    for material in materials {
      if material.material_id == material_id {
        exists = true
      }
    }
    if !exists {
      materials.push(MeshletSceneMaterial::{
        material_id,
        material_asset_id: key.material_asset_id,
        extension: key.extension,
      })
    }
  }
  materials.sort_by(fn(left, right) { left.material_id - right.material_id })
  materials
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
  for material_id in self.material_ids_present_in_scene.to_array() {
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
fn meshlet_push_affine3_transpose(
  out : Array[Byte],
  affine : @math.Affine3,
) -> Unit {
  meshlet_push_f32_le(out, affine.matrix3.x_axis.x)
  meshlet_push_f32_le(out, affine.matrix3.y_axis.x)
  meshlet_push_f32_le(out, affine.matrix3.z_axis.x)
  meshlet_push_f32_le(out, affine.translation.x)
  meshlet_push_f32_le(out, affine.matrix3.x_axis.y)
  meshlet_push_f32_le(out, affine.matrix3.y_axis.y)
  meshlet_push_f32_le(out, affine.matrix3.z_axis.y)
  meshlet_push_f32_le(out, affine.translation.y)
  meshlet_push_f32_le(out, affine.matrix3.x_axis.z)
  meshlet_push_f32_le(out, affine.matrix3.y_axis.z)
  meshlet_push_f32_le(out, affine.matrix3.z_axis.z)
  meshlet_push_f32_le(out, affine.translation.z)
}

///|
fn meshlet_push_local_from_world_transpose(
  out : Array[Byte],
  world_from_local : @math.Affine3,
) -> Unit {
  let local_from_world = world_from_local.inverse().matrix3
  meshlet_push_f32_le(out, local_from_world.x_axis.x)
  meshlet_push_f32_le(out, local_from_world.x_axis.y)
  meshlet_push_f32_le(out, local_from_world.x_axis.z)
  meshlet_push_f32_le(out, local_from_world.y_axis.x)
  meshlet_push_f32_le(out, local_from_world.y_axis.y)
  meshlet_push_f32_le(out, local_from_world.y_axis.z)
  meshlet_push_f32_le(out, local_from_world.z_axis.x)
  meshlet_push_f32_le(out, local_from_world.z_axis.y)
  meshlet_push_f32_le(out, local_from_world.z_axis.z)
}

///|
fn meshlet_push_instance_uniform(
  out : Array[Byte],
  uniform : MeshletInstanceUniform,
) -> Unit {
  meshlet_push_affine3_transpose(out, uniform.world_from_local)
  meshlet_push_affine3_transpose(out, uniform.previous_world_from_local)
  meshlet_push_local_from_world_transpose(out, uniform.world_from_local)
  meshlet_push_u32_le(out, uniform.flags)
  meshlet_push_u32_le(out, 0U)
  meshlet_push_u32_le(out, 0U)
  meshlet_push_u32_le(out, 0U)
  meshlet_push_u32_le(out, 0xFFFF_FFFFU)
  meshlet_push_u32_le(out, uniform.material_slot.reinterpret_as_uint())
  meshlet_push_u32_le(out, 0U)
  meshlet_push_u32_le(out, 0U)
  for _ in 0..<3 {
    meshlet_push_u32_le(out, 0U)
  }
}

///|
fn meshlet_push_instance_aabb(out : Array[Byte], aabb : MeshletAabb) -> Unit {
  meshlet_push_f32_le(out, aabb.center_x)
  meshlet_push_f32_le(out, aabb.center_y)
  meshlet_push_f32_le(out, aabb.center_z)
  meshlet_push_f32_le(out, 0.0)
  meshlet_push_f32_le(out, aabb.half_extent_x)
  meshlet_push_f32_le(out, aabb.half_extent_y)
  meshlet_push_f32_le(out, aabb.half_extent_z)
  meshlet_push_f32_le(out, 0.0)
}

///|
priv struct MeshletInstanceGpuBufferPayload {
  instance_uniforms : Bytes
  instance_aabbs : Bytes
  instance_material_ids : Bytes
  instance_bvh_root_nodes : Bytes
}

///|
fn InstanceManager::gpu_buffer_payload(
  self : InstanceManager,
) -> MeshletInstanceGpuBufferPayload {
  let instance_uniforms : Array[Byte] = []
  let instance_aabbs : Array[Byte] = []
  let instance_material_ids : Array[Byte] = []
  let instance_bvh_root_nodes : Array[Byte] = []
  for uniform in self.instance_uniforms {
    meshlet_push_instance_uniform(instance_uniforms, uniform)
  }
  for aabb in self.instance_aabbs {
    meshlet_push_instance_aabb(instance_aabbs, aabb)
  }
  for material_id in self.instance_material_ids {
    meshlet_push_u32_le(
      instance_material_ids,
      material_id.reinterpret_as_uint(),
    )
  }
  for root_node in self.instance_bvh_root_nodes {
    meshlet_push_u32_le(
      instance_bvh_root_nodes,
      root_node.reinterpret_as_uint(),
    )
  }
  MeshletInstanceGpuBufferPayload::{
    instance_uniforms: Bytes::from_array(instance_uniforms),
    instance_aabbs: Bytes::from_array(instance_aabbs),
    instance_material_ids: Bytes::from_array(instance_material_ids),
    instance_bvh_root_nodes: Bytes::from_array(instance_bvh_root_nodes),
  }
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
pub fn InstanceManager::view_instance_visibility(
  self : InstanceManager,
  view_entity : @core.Entity,
) -> Array[Int]? {
  self.view_instance_visibility.get(view_entity.to_bits())
}

///|
pub fn InstanceManager::view_instance_visibility_bytes(
  self : InstanceManager,
  view_entity : @core.Entity,
) -> Bytes {
  let out : Array[Byte] = []
  match self.view_instance_visibility.get(view_entity.to_bits()) {
    Some(visibility) =>
      for word in visibility {
        meshlet_push_u32_le(out, word.reinterpret_as_uint())
      }
    None => ()
  }
  if out.length() == 0 {
    meshlet_push_u32_le(out, 0U)
  }
  Bytes::from_array(out)
}

///|
fn meshlet_instance_hidden_for_view(
  instance_render_layer_mask : Int,
  view_render_layer_mask : Int,
  shadow_view : Bool,
  not_shadow_caster : Bool,
) -> Bool {
  (instance_render_layer_mask & view_render_layer_mask) == 0 ||
  (shadow_view && not_shadow_caster)
}

///|
fn meshlet_set_view_visibility_hidden_bit(
  visibility : Array[Int],
  instance_index : Int,
) -> Unit {
  if instance_index < 0 {
    return
  }
  let word_index = instance_index / 32
  let bit = instance_index - word_index * 32
  while visibility.length() <= word_index {
    visibility.push(0)
  }
  visibility[word_index] = visibility[word_index] | (1 << bit)
}

///|
pub fn InstanceManager::prepare_view_instance_visibility(
  self : InstanceManager,
  view_entity : @core.Entity,
  view_render_layer_mask? : Int = 1,
  shadow_view? : Bool = false,
) -> Array[Int] {
  let visibility = match
    self.view_instance_visibility.get(view_entity.to_bits()) {
    Some(existing) => {
      existing.clear()
      existing
    }
    None => []
  }
  let safe_view_render_layer_mask = non_negative(view_render_layer_mask)
  for index in 0..<self.instances.length() {
    let (_, instance_render_layer_mask, not_shadow_caster) = self.instances[index]
    if meshlet_instance_hidden_for_view(
        instance_render_layer_mask, safe_view_render_layer_mask, shadow_view, not_shadow_caster,
      ) {
      meshlet_set_view_visibility_hidden_bit(visibility, index)
    }
  }
  self.view_instance_visibility.set(view_entity.to_bits(), visibility)
  visibility
}

///|
pub fn InstanceManager::view_instance_hidden(
  self : InstanceManager,
  view_entity : @core.Entity,
  instance_index : Int,
) -> Bool {
  guard instance_index >= 0 else { false }
  match self.view_instance_visibility.get(view_entity.to_bits()) {
    Some(visibility) => {
      let word_index = instance_index / 32
      let bit = instance_index - word_index * 32
      if word_index >= visibility.length() {
        false
      } else {
        (visibility[word_index] & (1 << bit)) != 0
      }
    }
    None => false
  }
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
    aabb: MeshletAabb::MeshletAabb(),
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
  let manager = InstanceManager::InstanceManager()
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
  let manager = InstanceManager::InstanceManager()
  manager.set_instance_count(instance_count)
  manager
}

///|
pub fn queue_material_meshlet_meshes(instance_manager : InstanceManager) -> Int {
  instance_manager.material_ids_present_in_scene.clear()
  for index in 0..<instance_manager.instance_material_ids.length() {
    instance_manager.instance_material_ids[index] = 0
  }
  for index in 0..<instance_manager.instance_material_keys.length() {
    let material_id = instance_manager.get_material_id_for_key(
      instance_manager.instance_material_keys[index],
    )
    instance_manager.mark_material_present_in_scene(material_id)
    instance_manager.instance_material_ids[index] = material_id
  }
  instance_manager.present_material_count()
}
