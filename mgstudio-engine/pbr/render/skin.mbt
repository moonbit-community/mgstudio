// Copyright 2025 International Digital Economy Academy
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
// Bevy source:
// - `bevy/crates/bevy_pbr/src/render/skin.rs`.
const RENDER3D_SKIN_JOINTS_PER_ALLOCATION_UNIT : Int = 4

///|
const RENDER3D_SKIN_MAX_TOTAL_JOINTS : Int = 1024 * 1024 * 1024

///|
pub(all) struct SkinAllocation {
  offset : Int
  size : Int
}

///|
fn SkinAllocation::matrix_offset(self : SkinAllocation) -> Int {
  self.offset * RENDER3D_SKIN_JOINTS_PER_ALLOCATION_UNIT
}

///|
pub(all) struct SkinOffsetFreeRange {
  offset : Int
  size : Int
}

///|
pub(all) struct SkinOffsetAllocator {
  mut next_offset : Int
  mut free_ranges : Array[SkinOffsetFreeRange]
}

///|
fn SkinOffsetAllocator::new() -> SkinOffsetAllocator {
  SkinOffsetAllocator::{ next_offset: 0, free_ranges: [] }
}

///|
fn SkinOffsetAllocator::allocate(
  self : SkinOffsetAllocator,
  size : Int,
) -> SkinAllocation? {
  if size <= 0 {
    return Some(SkinAllocation::{ offset: 0, size: 0 })
  }
  let free_range_count = self.free_ranges.length()
  for index in 0..<free_range_count {
    let range = self.free_ranges[index]
    if range.size < size {
      continue
    }
    let allocation = SkinAllocation::{ offset: range.offset, size }
    if range.size == size {
      self.free_ranges.remove(index) |> ignore
    } else {
      self.free_ranges[index] = SkinOffsetFreeRange::{
        offset: range.offset + size,
        size: range.size - size,
      }
    }
    return Some(allocation)
  }
  if self.next_offset + size > RENDER3D_SKIN_MAX_TOTAL_JOINTS {
    return None
  }
  let allocation = SkinAllocation::{ offset: self.next_offset, size }
  self.next_offset = self.next_offset + size
  Some(allocation)
}

///|
fn SkinOffsetAllocator::free(
  self : SkinOffsetAllocator,
  allocation : SkinAllocation,
) -> Unit {
  if allocation.size <= 0 {
    return
  }
  self.free_ranges.push(SkinOffsetFreeRange::{
    offset: allocation.offset,
    size: allocation.size,
  })
  self.free_ranges.sort_by(fn(lhs, rhs) { lhs.offset - rhs.offset })
  if self.free_ranges.length() > 1 {
    let merged : Array[SkinOffsetFreeRange] = []
    for range in self.free_ranges {
      if merged.is_empty() {
        merged.push(range)
        continue
      }
      let last_index = merged.length() - 1
      let last = merged[last_index]
      let last_end = last.offset + last.size
      if range.offset <= last_end {
        let merged_end = if last_end >= range.offset + range.size {
          last_end
        } else {
          range.offset + range.size
        }
        merged[last_index] = SkinOffsetFreeRange::{
          offset: last.offset,
          size: merged_end - last.offset,
        }
      } else {
        merged.push(range)
      }
    }
    self.free_ranges = merged
  }
  let mut changed = true
  while changed {
    changed = false
    match self.free_ranges.last() {
      Some(range) =>
        if range.offset + range.size == self.next_offset {
          self.next_offset = range.offset
          self.free_ranges.pop() |> ignore
          changed = true
        }
      None => ()
    }
  }
}

///|
pub struct SkinUniformInfo {
  allocation : SkinAllocation
  joints : Array[@core.Entity]
  joint_table_ids : Array[Int]
  joint_row_indices : Array[Int]
}

///|
fn SkinUniformInfo::offset(self : SkinUniformInfo) -> Int {
  self.allocation.matrix_offset()
}

///|
pub struct SkinUniforms {
  skin_uniform_info : Map[UInt64, SkinUniformInfo]
  allocator : SkinOffsetAllocator
  joint_to_skins : Map[UInt64, Array[@core.Entity]]
  current_skins : @hashset.HashSet[UInt64]
  previous_skins : @hashset.HashSet[UInt64]
  current_staging_buffer : Array[Float]
  mut total_joints : Int
}

///|
pub fn SkinUniforms::new() -> SkinUniforms {
  SkinUniforms::{
    skin_uniform_info: {},
    allocator: SkinOffsetAllocator::new(),
    joint_to_skins: {},
    current_skins: @hashset.HashSet::new(),
    previous_skins: @hashset.HashSet::new(),
    current_staging_buffer: [],
    total_joints: 0,
  }
}

///|
pub let skin_uniforms_key : @ecs.ResourceKey[SkinUniforms] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SkinUniforms",
)

///|
pub impl @app.Resource for SkinUniforms with resource() {
  skin_uniforms_key
}

///|
pub fn ensure_skin_uniforms_resource(world : @ecs.World) -> Unit {
  if (try! world.get_resource(SkinUniforms::resource())) is None {
    world.insert_resource(SkinUniforms::resource(), SkinUniforms::new())
  }
}

///|
pub fn skin_uniforms_ref_or_abort(world : @ecs.World) -> Ref[SkinUniforms] {
  ensure_skin_uniforms_resource(world)
  match (try! world.get_resource_mut(SkinUniforms::resource())) {
    Some(state) => Ref::new(state.peek())
    None => abort("Missing SkinUniforms resource in render world")
  }
}

///|
fn render3d_skin_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xffffffffUL
  (hi << 32) | lo
}

///|
fn render3d_skin_entities_equal(lhs : @core.Entity, rhs : @core.Entity) -> Bool {
  lhs.id == rhs.id && lhs.generation == rhs.generation
}

///|
fn render3d_skin_entity_array_contains(
  entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Bool {
  for candidate in entities {
    if render3d_skin_entities_equal(candidate, entity) {
      return true
    }
  }
  false
}

///|
fn render3d_skin_entity_array_remove_all(
  entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Unit {
  let mut index = entities.length() - 1
  while index >= 0 {
    if render3d_skin_entities_equal(entities[index], entity) {
      entities.remove(index) |> ignore
    }
    index = index - 1
  }
}

///|
fn render3d_phase_begin_skin_frame(
  skin_uniforms_ref : Ref[SkinUniforms],
) -> Unit {
  skin_uniforms_ref.val.previous_skins.clear()
  for skin_key in skin_uniforms_ref.val.current_skins.iter() {
    skin_uniforms_ref.val.previous_skins.add(skin_key)
  }
}

///|
fn render3d_phase_sync_previous_skin_flags(
  skin_uniforms_ref : Ref[SkinUniforms],
) -> Unit {
  skin_uniforms_ref.val.previous_skins.clear()
  for skin_key in skin_uniforms_ref.val.current_skins.iter() {
    skin_uniforms_ref.val.previous_skins.add(skin_key)
  }
}

///|
fn render3d_has_prepared_skin_binding(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
) -> Bool {
  skin_uniforms_ref.val.skin_uniform_info.contains(
    render3d_skin_entity_key(entity),
  )
}

///|
fn render3d_skin_allocation_unit_count(joint_count : Int) -> Int {
  if joint_count <= 0 {
    return 0
  }
  let unit = RENDER3D_SKIN_JOINTS_PER_ALLOCATION_UNIT
  (joint_count + unit - 1) / unit
}

///|
fn render3d_phase_remove_skin(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
) -> Unit {
  let skin_key = render3d_skin_entity_key(entity)
  let old_info = match skin_uniforms_ref.val.skin_uniform_info.get(skin_key) {
    Some(info) => info
    None => return
  }
  skin_uniforms_ref.val.skin_uniform_info.remove(skin_key) |> ignore
  skin_uniforms_ref.val.allocator.free(old_info.allocation)
  let remaining = skin_uniforms_ref.val.total_joints - old_info.joints.length()
  skin_uniforms_ref.val.total_joints = if remaining > 0 { remaining } else { 0 }
  skin_uniforms_ref.val.current_skins.remove(skin_key)
  skin_uniforms_ref.val.previous_skins.remove(skin_key)
  for joint in old_info.joints {
    let joint_key = render3d_skin_entity_key(joint)
    match skin_uniforms_ref.val.joint_to_skins.get(joint_key) {
      Some(skins) => {
        render3d_skin_entity_array_remove_all(skins, entity)
        if skins.length() == 0 {
          skin_uniforms_ref.val.joint_to_skins.remove(joint_key) |> ignore
        } else {
          skin_uniforms_ref.val.joint_to_skins.set(joint_key, skins)
        }
      }
      None => ()
    }
  }
}

///|
fn render3d_skin_matrix_row_offset(matrix_index : Int) -> Int {
  if matrix_index < 0 {
    return -1
  }
  matrix_index * 16
}

///|
fn render3d_skin_identity_row_at(row_index : Int) -> Float {
  match row_index % 16 {
    0 => 1.0F
    5 => 1.0F
    10 => 1.0F
    15 => 1.0F
    _ => 0.0F
  }
}

///|
fn render3d_ensure_skin_staging_rows(
  skin_uniforms_ref : Ref[SkinUniforms],
  required_rows : Int,
) -> Unit {
  if required_rows <= skin_uniforms_ref.val.current_staging_buffer.length() {
    return
  }
  while skin_uniforms_ref.val.current_staging_buffer.length() < required_rows {
    let row_index = skin_uniforms_ref.val.current_staging_buffer.length()
    skin_uniforms_ref.val.current_staging_buffer.push(
      render3d_skin_identity_row_at(row_index),
    )
  }
}

///|
fn render3d_write_identity_skin_matrix(
  skin_uniforms_ref : Ref[SkinUniforms],
  matrix_index : Int,
) -> Unit {
  let base = render3d_skin_matrix_row_offset(matrix_index)
  if base < 0 {
    return
  }
  render3d_ensure_skin_staging_rows(skin_uniforms_ref, base + 16)
  for i in 0..<16 {
    skin_uniforms_ref.val.current_staging_buffer[base + i] = render3d_skin_identity_row_at(
      i,
    )
  }
}

///|
fn render3d_write_skin_matrix(
  skin_uniforms_ref : Ref[SkinUniforms],
  matrix_index : Int,
  joint_global : @transform.GlobalTransform,
  inverse_bindpose : @mesh.SkinningMat4,
) -> Unit {
  let base = render3d_skin_matrix_row_offset(matrix_index)
  if base < 0 {
    return
  }
  render3d_ensure_skin_staging_rows(skin_uniforms_ref, base + 16)
  // Bevy `bevy_pbr::render::skin::extract_joints_for_skin` writes
  // `joint_transform.affine() * inverse_bindpose` directly into the staging
  // buffer. Avoid constructing a transient `SkinningMat4` per joint here.
  inverse_bindpose.write_affine3_mul_row_major_f32(
    joint_global.affine(),
    skin_uniforms_ref.val.current_staging_buffer,
    base,
  )
}

///|
fn render3d_write_skin_joint_matrix(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  transform_columns : Render3dTransformColumns,
  matrix_index : Int,
  joint_index : Int,
  joint : @core.Entity,
  inverse_bindpose : @mesh.SkinningMat4,
  joint_table_ids : Array[Int],
  joint_row_indices : Array[Int],
) -> Unit {
  match transform_columns.global {
    Some(column) => {
      if joint_index >= 0 &&
        joint_index < joint_table_ids.length() &&
        joint_index < joint_row_indices.length() {
        let table_id = joint_table_ids[joint_index]
        let row_index = joint_row_indices[joint_index]
        if table_id >= 0 && row_index >= 0 {
          match
            column.table_value_at_cached_entity_row(joint, table_id, row_index) {
            Some(joint_global) => {
              render3d_write_skin_matrix(
                skin_uniforms_ref, matrix_index, joint_global, inverse_bindpose,
              )
              return
            }
            None => ()
          }
        }
      }
      match column.get_fast(joint) {
        Some(joint_global) => {
          match column.table_row_location(joint) {
            Some((table_id, row_index)) =>
              if joint_index >= 0 &&
                joint_index < joint_table_ids.length() &&
                joint_index < joint_row_indices.length() {
                joint_table_ids[joint_index] = table_id
                joint_row_indices[joint_index] = row_index
              }
            None => ()
          }
          render3d_write_skin_matrix(
            skin_uniforms_ref, matrix_index, joint_global, inverse_bindpose,
          )
          return
        }
        None => ()
      }
    }
    None => ()
  }
  let joint_world = render3d_entity_world_transform_cached_with_columns(
    source_world, joint, world_transform_cache_ref, transform_columns,
  )
  let base = render3d_skin_matrix_row_offset(matrix_index)
  if base < 0 {
    return
  }
  render3d_ensure_skin_staging_rows(skin_uniforms_ref, base + 16)
  @mesh.SkinningMat4::from_transform(joint_world).mul_write_row_major_f32(
    inverse_bindpose,
    skin_uniforms_ref.val.current_staging_buffer,
    base,
  )
}

///|
fn render3d_pad_skin_allocation(
  skin_uniforms_ref : Ref[SkinUniforms],
  matrix_offset : Int,
  joint_count : Int,
  allocation : SkinAllocation,
) -> Unit {
  let padded_joint_count = allocation.size *
    RENDER3D_SKIN_JOINTS_PER_ALLOCATION_UNIT
  render3d_ensure_skin_staging_rows(
    skin_uniforms_ref,
    render3d_skin_matrix_row_offset(matrix_offset + padded_joint_count),
  )
  for joint_index in joint_count..<padded_joint_count {
    render3d_write_identity_skin_matrix(
      skin_uniforms_ref,
      matrix_offset + joint_index,
    )
  }
}

///|
fn render3d_add_skin(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  entity : @core.Entity,
  skinned_mesh : @mesh.SkinnedMesh,
  inverse_bindposes_assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  transform_columns : Render3dTransformColumns,
) -> Unit {
  let joints = skinned_mesh.joints()
  let allocation_size = render3d_skin_allocation_unit_count(joints.length())
  let allocation = match
    skin_uniforms_ref.val.allocator.allocate(allocation_size) {
    Some(allocation) => allocation
    None => return
  }
  let joint_table_ids = Array::make(joints.length(), -1)
  let joint_row_indices = Array::make(joints.length(), -1)
  match transform_columns.global {
    Some(column) =>
      for joint_index in 0..<joints.length() {
        match column.table_row_location(joints[joint_index]) {
          Some((table_id, row_index)) => {
            joint_table_ids[joint_index] = table_id
            joint_row_indices[joint_index] = row_index
          }
          None => ()
        }
      }
    None => ()
  }
  let info = SkinUniformInfo::{
    allocation,
    joints,
    joint_table_ids,
    joint_row_indices,
  }
  let matrix_offset = info.offset()
  let inverse_bindposes_asset = inverse_bindposes_assets.get(
    skinned_mesh.inverse_bindposes(),
  )
  let inverse_bindposes_values = match inverse_bindposes_asset {
    Some(asset) => Some(asset.values())
    None => None
  }
  for joint_index in 0..<joints.length() {
    let joint = joints[joint_index]
    let inverse_bindpose = match inverse_bindposes_values {
      Some(values) =>
        if joint_index < values.length() {
          Some(values[joint_index])
        } else {
          None
        }
      None => None
    }
    match inverse_bindpose {
      Some(inverse_bindpose) =>
        render3d_write_skin_joint_matrix(
          source_world,
          skin_uniforms_ref,
          world_transform_cache_ref,
          transform_columns,
          matrix_offset + joint_index,
          joint_index,
          joint,
          inverse_bindpose,
          joint_table_ids,
          joint_row_indices,
        )
      None =>
        render3d_write_identity_skin_matrix(
          skin_uniforms_ref,
          matrix_offset + joint_index,
        )
    }
    let joint_key = render3d_skin_entity_key(joint)
    let mapped_skins = match
      skin_uniforms_ref.val.joint_to_skins.get(joint_key) {
      Some(existing) => existing
      None => []
    }
    if !render3d_skin_entity_array_contains(mapped_skins, entity) {
      mapped_skins.push(entity)
    }
    skin_uniforms_ref.val.joint_to_skins.set(joint_key, mapped_skins)
  }
  render3d_pad_skin_allocation(
    skin_uniforms_ref,
    matrix_offset,
    joints.length(),
    allocation,
  )
  let skin_key = render3d_skin_entity_key(entity)
  skin_uniforms_ref.val.skin_uniform_info.set(skin_key, info)
  skin_uniforms_ref.val.current_skins.add(skin_key)
  skin_uniforms_ref.val.total_joints = skin_uniforms_ref.val.total_joints +
    joints.length()
}

///|
fn render3d_add_or_delete_skins(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  inverse_bindposes_assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  transform_columns : Render3dTransformColumns,
) -> @hashset.HashSet[UInt64] {
  let skinned_mesh_key = @mesh.SkinnedMesh::component()
  let changed_visibility_filter = @ecs.Changed::new(
    @visibility.ecs_key_view_visibility,
  )
  let changed_skinned_mesh_filter = @ecs.Changed::new(skinned_mesh_key)
  let changed_skinned_query : @ecs.Query[
    (@ecs.Comp[@visibility.ViewVisibility], @ecs.Comp[@mesh.SkinnedMesh]),
    @ecs.Or[
      (
        @ecs.Changed[@visibility.ViewVisibility],
        @ecs.Changed[@mesh.SkinnedMesh],
      ),
    ],
  ] = @ecs.query_filtered(
    source_world,
    @ecs.Or::new((changed_visibility_filter, changed_skinned_mesh_filter)),
  )
  let changed_skin_entities = @hashset.HashSet::new()
  try! changed_skinned_query.view(fn(entity, data) {
    if entity.id < 0 {
      return
    }
    let (view_visibility_comp, skinned_mesh_comp) = data
    let skin_key = render3d_skin_entity_key(entity)
    changed_skin_entities.add(skin_key)
    render3d_phase_remove_skin(skin_uniforms_ref, entity)
    if !view_visibility_comp.value().is_visible() {
      return
    }
    render3d_add_skin(
      source_world,
      skin_uniforms_ref,
      world_transform_cache_ref,
      entity,
      skinned_mesh_comp.value(),
      inverse_bindposes_assets,
      transform_columns,
    )
  })
  changed_skin_entities
}

///|
fn render3d_extract_joints_for_skin(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  skin_entity : @core.Entity,
  skinned_mesh : @mesh.SkinnedMesh,
  changed_skin_entities : @hashset.HashSet[UInt64],
  inverse_bindposes_assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  transform_columns : Render3dTransformColumns,
) -> Unit {
  let skin_key = render3d_skin_entity_key(skin_entity)
  if changed_skin_entities.contains(skin_key) {
    return
  }
  let info = match skin_uniforms_ref.val.skin_uniform_info.get(skin_key) {
    Some(info) => info
    None => return
  }
  let inverse_bindposes_asset = match
    inverse_bindposes_assets.get(skinned_mesh.inverse_bindposes()) {
    Some(asset) => asset
    None => return
  }
  let inverse_bindposes_values = inverse_bindposes_asset.values()
  let joints = skinned_mesh.joints()
  let joint_count = if joints.length() < info.joints.length() {
    joints.length()
  } else {
    info.joints.length()
  }
  let joint_count = if joint_count < inverse_bindposes_values.length() {
    joint_count
  } else {
    inverse_bindposes_values.length()
  }
  let matrix_offset = info.offset()
  let joint_table_ids = info.joint_table_ids
  let joint_row_indices = info.joint_row_indices
  for joint_index in 0..<joint_count {
    let joint = joints[joint_index]
    let inverse_bindpose = inverse_bindposes_values[joint_index]
    render3d_write_skin_joint_matrix(
      source_world,
      skin_uniforms_ref,
      world_transform_cache_ref,
      transform_columns,
      matrix_offset + joint_index,
      joint_index,
      joint,
      inverse_bindpose,
      joint_table_ids,
      joint_row_indices,
    )
  }
}

///|
fn render3d_extract_joints(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  changed_skin_entities : @hashset.HashSet[UInt64],
  inverse_bindposes_assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  transform_columns : Render3dTransformColumns,
) -> Unit {
  if skin_uniforms_ref.val.total_joints <= 0 {
    return
  }
  let sequence = source_world.get_sequence_context().sequence()
  let threshold = skin_uniforms_ref.val.total_joints / 4
  let skinned_mesh_key = @mesh.SkinnedMesh::component()
  let dirty_skins : Map[UInt64, @core.Entity] = {}
  let mut changed_transform_count = 0
  let mut must_extract_all = false
  match transform_columns.global {
    Some(global_column) =>
      ignore(
        global_column.for_each_changed_table_entity(sequence, fn(
          changed_entity,
          _table_id,
          _row_index,
        ) {
          changed_transform_count += 1
          if changed_transform_count > threshold {
            must_extract_all = true
            return false
          }
          let changed_key = render3d_skin_entity_key(changed_entity)
          match skin_uniforms_ref.val.joint_to_skins.get(changed_key) {
            Some(skins) =>
              for skin_entity in skins {
                dirty_skins.set(
                  render3d_skin_entity_key(skin_entity),
                  skin_entity,
                )
              }
            None => ()
          }
          true
        }),
      )
    None =>
      for entry in skin_uniforms_ref.val.joint_to_skins.iter() {
        let (joint_key, skins) = entry
        let joint_entity = @core.Entity::from_bits(joint_key)
        if !source_world.is_changed_by_key(
            joint_entity, @transform.ecs_key_global_transform, sequence,
          ) {
          continue
        }
        changed_transform_count += 1
        if changed_transform_count > threshold {
          must_extract_all = true
          break
        }
        for skin_entity in skins {
          dirty_skins.set(render3d_skin_entity_key(skin_entity), skin_entity)
        }
      }
  }
  if must_extract_all {
    source_world.for_each_component(skinned_mesh_key, fn(entity, skinned_mesh) {
      if entity.id < 0 {
        return
      }
      if !render3d_has_prepared_skin_binding(skin_uniforms_ref, entity) {
        return
      }
      render3d_extract_joints_for_skin(
        source_world, skin_uniforms_ref, world_transform_cache_ref, entity, skinned_mesh,
        changed_skin_entities, inverse_bindposes_assets, transform_columns,
      )
    })
    return
  }
  if dirty_skins.is_empty() {
    return
  }
  let skinned_mesh_column = source_world.component_column(skinned_mesh_key)
  guard skinned_mesh_column is Some(skinned_column) else { return }
  for entry in dirty_skins.iter() {
    let (_skin_key, skin_entity) = entry
    if !source_world.is_alive(skin_entity) {
      render3d_phase_remove_skin(skin_uniforms_ref, skin_entity)
      continue
    }
    if !render3d_has_prepared_skin_binding(skin_uniforms_ref, skin_entity) {
      continue
    }
    guard skinned_column.get_fast(skin_entity) is Some(skinned_mesh) else {
      continue
    }
    render3d_extract_joints_for_skin(
      source_world, skin_uniforms_ref, world_transform_cache_ref, skin_entity, skinned_mesh,
      changed_skin_entities, inverse_bindposes_assets, transform_columns,
    )
  }
}

///|
pub fn render3d_extract_skin_bindings(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  render3d_phase_begin_skin_frame(skin_uniforms_ref)
  let skinned_mesh_key = @mesh.SkinnedMesh::component()
  let inverse_bindposes_assets_key : @ecs.ResourceKey[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  let inverse_bindposes_assets = match
    (try! source_world.get_resource(inverse_bindposes_assets_key)) {
    Some(assets) => assets
    None => return
  }
  let transform_columns = render3d_transform_columns(source_world)
  let changed_skin_entities = render3d_add_or_delete_skins(
    source_world, skin_uniforms_ref, world_transform_cache_ref, inverse_bindposes_assets,
    transform_columns,
  )
  let sequence = source_world.get_sequence_context().sequence()
  let removed_skinned_meshes = source_world.removed_components(
    skinned_mesh_key, sequence,
  )
  for entity in removed_skinned_meshes.read() {
    if changed_skin_entities.contains(render3d_skin_entity_key(entity)) {
      continue
    }
    if source_world.is_alive(entity) &&
      (try! source_world.contains_by_key(entity, skinned_mesh_key)) {
      continue
    }
    render3d_phase_remove_skin(skin_uniforms_ref, entity)
  }
  render3d_extract_joints(
    source_world, skin_uniforms_ref, world_transform_cache_ref, changed_skin_entities,
    inverse_bindposes_assets, transform_columns,
  )
}

///|
pub fn render3d_prepare_skin_bindings_upload(
  _source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  _world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  if skin_uniforms_ref.val.skin_uniform_info.is_empty() {
    skin_uniforms_ref.val.previous_skins.clear()
    return
  }
  render3d_phase_sync_previous_skin_flags(skin_uniforms_ref)
  if skin_uniforms_ref.val.current_staging_buffer.is_empty() {
    return
  }
  @render_gpu.host_gpu_prepare_mesh3d_skin_bindings(
    skinning_rows=skin_uniforms_ref.val.current_staging_buffer,
  )
}

///|
pub fn render3d_prepared_skin_binding_keys(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
) -> (Int, Int) {
  if entity.id < 0 {
    return (-1, -1)
  }
  match
    skin_uniforms_ref.val.skin_uniform_info.get(
      render3d_skin_entity_key(entity),
    ) {
    Some(binding) => (binding.offset(), 0)
    None => (-1, -1)
  }
}

///|
pub fn skins_use_uniform_buffers() -> Bool {
  false
}

///|
pub fn no_automatic_skin_batching(_world : @ecs.World) -> Unit {
  if !skins_use_uniform_buffers() {
    return
  }
}
