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
// - `bevy/crates/bevy_pbr/src/render/skin.rs` (`SkinUniforms`, `SkinUniformInfo`).
pub struct SkinBindingFreeRange {
  offset : Int
  length : Int
}

///|
pub struct SkinUniformInfo {
  entity_generation : Int
  key_hi : Int
  key_lo : Int
  joints : Array[@core.Entity]
}

///|
pub struct SkinUniforms {
  skin_uniform_info : Map[Int, SkinUniformInfo]
  mut next_skin_binding_index : Int
  mut skin_binding_free_ranges : Array[SkinBindingFreeRange]
  joint_to_skins : Map[UInt64, Array[@core.Entity]]
  current_skins : Map[UInt64, Bool]
  previous_skins : Map[UInt64, Bool]
  current_staging_buffer : Array[Float]
  mut total_joints : Int
  skin_upload_queue : Array[@core.Entity]
}

///|
pub fn SkinUniforms::new() -> SkinUniforms {
  SkinUniforms::{
    skin_uniform_info: {},
    next_skin_binding_index: 0,
    skin_binding_free_ranges: [],
    joint_to_skins: {},
    current_skins: {},
    previous_skins: {},
    current_staging_buffer: [],
    total_joints: 0,
    skin_upload_queue: [],
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
  match (try! world.get_resource_ref_mut(SkinUniforms::resource())) {
    Some(state) => state
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
  for entry in skin_uniforms_ref.val.current_skins.iter() {
    let (skin_key, exists) = entry
    skin_uniforms_ref.val.previous_skins.set(skin_key, exists)
  }
}

///|
fn render3d_skin_is_visible(world : @ecs.World, entity : @core.Entity) -> Bool {
  if (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility))
    is Some(view_visibility) {
    view_visibility.is_visible()
  } else {
    true
  }
}

///|
fn render3d_has_prepared_skin_binding(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
) -> Bool {
  match skin_uniforms_ref.val.skin_uniform_info.get(entity.id) {
    Some(binding) => binding.entity_generation == entity.generation
    None => false
  }
}

///|
const RENDER3D_SKIN_ALLOCATION_UNIT_MATRICES : Int = 4

///|
fn render3d_skin_allocation_matrix_count(joint_count : Int) -> Int {
  let clamped_joint_count = if joint_count <= 0 { 1 } else { joint_count }
  let unit = RENDER3D_SKIN_ALLOCATION_UNIT_MATRICES
  (clamped_joint_count + unit - 1) / unit * unit
}

///|
fn render3d_phase_insert_skin_free_range(
  skin_uniforms_ref : Ref[SkinUniforms],
  offset : Int,
  length : Int,
) -> Unit {
  if offset < 0 || length <= 0 {
    return
  }
  skin_uniforms_ref.val.skin_binding_free_ranges.push(SkinBindingFreeRange::{
    offset,
    length,
  })
  skin_uniforms_ref.val.skin_binding_free_ranges.sort_by(fn(lhs, rhs) {
    lhs.offset - rhs.offset
  })
  if skin_uniforms_ref.val.skin_binding_free_ranges.length() <= 1 {
    return
  }
  let merged : Array[SkinBindingFreeRange] = []
  for range in skin_uniforms_ref.val.skin_binding_free_ranges {
    if merged.is_empty() {
      merged.push(range)
      continue
    }
    let last_index = merged.length() - 1
    let last = merged[last_index]
    let last_end = last.offset + last.length
    if range.offset <= last_end {
      let merged_end = if last_end >= range.offset + range.length {
        last_end
      } else {
        range.offset + range.length
      }
      merged[last_index] = SkinBindingFreeRange::{
        offset: last.offset,
        length: merged_end - last.offset,
      }
    } else {
      merged.push(range)
    }
  }
  skin_uniforms_ref.val.skin_binding_free_ranges = merged
}

///|
fn render3d_phase_trim_skin_free_ranges(
  skin_uniforms_ref : Ref[SkinUniforms],
) -> Unit {
  let mut changed = true
  while changed {
    changed = false
    match skin_uniforms_ref.val.skin_binding_free_ranges.last() {
      Some(range) =>
        if range.offset + range.length ==
          skin_uniforms_ref.val.next_skin_binding_index {
          skin_uniforms_ref.val.next_skin_binding_index = range.offset
          skin_uniforms_ref.val.skin_binding_free_ranges.pop() |> ignore
          changed = true
        }
      None => ()
    }
  }
}

///|
fn render3d_phase_allocate_skin_binding_index(
  skin_uniforms_ref : Ref[SkinUniforms],
  joint_count : Int,
) -> Int {
  let allocation_matrix_count = render3d_skin_allocation_matrix_count(
    joint_count,
  )
  let free_range_count = skin_uniforms_ref.val.skin_binding_free_ranges.length()
  for index in 0..<free_range_count {
    let range = skin_uniforms_ref.val.skin_binding_free_ranges[index]
    if range.length < allocation_matrix_count {
      continue
    }
    let offset = range.offset
    if range.length == allocation_matrix_count {
      skin_uniforms_ref.val.skin_binding_free_ranges.remove(index) |> ignore
    } else {
      skin_uniforms_ref.val.skin_binding_free_ranges[index] = SkinBindingFreeRange::{
        offset: range.offset + allocation_matrix_count,
        length: range.length - allocation_matrix_count,
      }
    }
    return offset
  }
  let offset = skin_uniforms_ref.val.next_skin_binding_index
  skin_uniforms_ref.val.next_skin_binding_index = offset +
    allocation_matrix_count
  offset
}

///|
fn render3d_phase_remove_skin(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
) -> Unit {
  let skin_key = render3d_skin_entity_key(entity)
  let mut removed_skin_binding_index : Int? = None
  let mut removed_joints : Array[@core.Entity]? = None
  match skin_uniforms_ref.val.skin_uniform_info.get(entity.id) {
    Some(binding) =>
      if binding.entity_generation == entity.generation {
        skin_uniforms_ref.val.skin_uniform_info.remove(entity.id) |> ignore
        removed_skin_binding_index = Some(binding.key_hi)
        removed_joints = Some(binding.joints)
      }
    None => ()
  }
  match removed_skin_binding_index {
    Some(offset) => {
      let joint_count = match removed_joints {
        Some(joints) => joints.length()
        None => 0
      }
      render3d_phase_insert_skin_free_range(
        skin_uniforms_ref,
        offset,
        render3d_skin_allocation_matrix_count(joint_count),
      )
      render3d_phase_trim_skin_free_ranges(skin_uniforms_ref)
    }
    None => ()
  }
  match removed_joints {
    Some(joints) =>
      if joints.length() > 0 {
        let remaining = skin_uniforms_ref.val.total_joints - joints.length()
        skin_uniforms_ref.val.total_joints = if remaining > 0 {
          remaining
        } else {
          0
        }
      }
    None => ()
  }
  skin_uniforms_ref.val.previous_skins.remove(skin_key)
  skin_uniforms_ref.val.current_skins.remove(skin_key)
  match removed_joints {
    Some(joints) =>
      for joint in joints {
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
    None => ()
  }
}

///|
fn render3d_phase_register_skin(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
  skinned_mesh : @mesh.SkinnedMesh,
) -> Unit {
  render3d_phase_remove_skin(skin_uniforms_ref, entity)
  let joints = skinned_mesh.joints()
  skin_uniforms_ref.val.skin_uniform_info.set(entity.id, SkinUniformInfo::{
    entity_generation: entity.generation,
    key_hi: -1,
    key_lo: -1,
    joints,
  })
  skin_uniforms_ref.val.total_joints = skin_uniforms_ref.val.total_joints +
    joints.length()
  for joint in joints {
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
}

///|
fn render3d_phase_mark_skin_prepared(
  skin_uniforms_ref : Ref[SkinUniforms],
  entity : @core.Entity,
) -> Unit {
  let info = match skin_uniforms_ref.val.skin_uniform_info.get(entity.id) {
    Some(info) => info
    None => return
  }
  let skin_key = render3d_skin_entity_key(entity)
  if info.entity_generation == entity.generation && info.key_hi >= 0 {
    skin_uniforms_ref.val.current_skins.set(skin_key, true)
    return
  }
  if info.key_hi >= 0 {
    render3d_phase_insert_skin_free_range(
      skin_uniforms_ref,
      info.key_hi,
      render3d_skin_allocation_matrix_count(info.joints.length()),
    )
  }
  let joint_count = info.joints.length()
  let offset = render3d_phase_allocate_skin_binding_index(
    skin_uniforms_ref, joint_count,
  )
  skin_uniforms_ref.val.skin_uniform_info.set(entity.id, SkinUniformInfo::{
    entity_generation: entity.generation,
    key_hi: offset,
    key_lo: 0,
    joints: info.joints,
  })
  skin_uniforms_ref.val.current_skins.set(skin_key, true)
}

///|
fn render3d_phase_enqueue_skin_upload(
  skin_uniforms_ref : Ref[SkinUniforms],
  upload_seen : Map[UInt64, Bool],
  entity : @core.Entity,
) -> Unit {
  let key = render3d_skin_entity_key(entity)
  if upload_seen.contains(key) {
    return
  }
  upload_seen.set(key, true)
  skin_uniforms_ref.val.skin_upload_queue.push(entity)
}

///|
fn render3d_cached_skinning_matrices(
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  entity : @core.Entity,
) -> Array[Float]? {
  if entity.id < 0 {
    return None
  }
  if entity.id >= world_transform_cache_ref.val.skinning_matrices.length() {
    return None
  }
  if world_transform_cache_ref.val.skinning_generations[entity.id] !=
    entity.generation {
    return None
  }
  if world_transform_cache_ref.val.skinning_stamps[entity.id] !=
    world_transform_cache_ref.val.frame_stamp {
    return None
  }
  world_transform_cache_ref.val.skinning_matrices[entity.id]
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
fn render3d_copy_skinning_rows_into_staging(
  skin_uniforms_ref : Ref[SkinUniforms],
  matrix_index : Int,
  skinning_matrices : Array[Float],
) -> Unit {
  let base = render3d_skin_matrix_row_offset(matrix_index)
  if base < 0 {
    return
  }
  let required_rows = base + skinning_matrices.length()
  render3d_ensure_skin_staging_rows(skin_uniforms_ref, required_rows)
  for i in 0..<skinning_matrices.length() {
    skin_uniforms_ref.val.current_staging_buffer[base + i] = skinning_matrices[i]
  }
  let matrix_count = (skinning_matrices.length() + 15) / 16
  let padded_matrix_count = render3d_skin_allocation_matrix_count(matrix_count)
  render3d_ensure_skin_staging_rows(
    skin_uniforms_ref,
    base + padded_matrix_count * 16,
  )
  for allocation_matrix_index in matrix_count..<padded_matrix_count {
    let row_base = base + allocation_matrix_index * 16
    if row_base + 15 >= skin_uniforms_ref.val.current_staging_buffer.length() {
      break
    }
    skin_uniforms_ref.val.current_staging_buffer[row_base] = 1.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 1] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 2] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 3] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 4] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 5] = 1.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 6] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 7] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 8] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 9] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 10] = 1.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 11] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 12] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 13] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 14] = 0.0F
    skin_uniforms_ref.val.current_staging_buffer[row_base + 15] = 1.0F
  }
}

///|
pub fn render3d_extract_skin_bindings(
  source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  render3d_phase_begin_skin_frame(skin_uniforms_ref)
  skin_uniforms_ref.val.skin_upload_queue.clear()
  if source_world.component_count(@mesh.SkinnedMesh::component()) == 0 {
    skin_uniforms_ref.val.skin_uniform_info.clear()
    skin_uniforms_ref.val.next_skin_binding_index = 0
    skin_uniforms_ref.val.skin_binding_free_ranges.clear()
    skin_uniforms_ref.val.joint_to_skins.clear()
    skin_uniforms_ref.val.current_skins.clear()
    skin_uniforms_ref.val.previous_skins.clear()
    skin_uniforms_ref.val.current_staging_buffer.clear()
    skin_uniforms_ref.val.total_joints = 0
    return
  }
  let inverse_bindposes_assets_key : @ecs.ResourceKey[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  let inverse_bindposes_assets = match
    (try! source_world.get_resource(inverse_bindposes_assets_key)) {
    Some(assets) => assets
    None => return
  }
  let transform_columns = render3d_transform_columns(source_world)
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
  let changed_skin_entities : Map[UInt64, Bool] = {}
  let upload_seen : Map[UInt64, Bool] = {}
  try! changed_skinned_query.view(fn(entity, data) {
    if entity.id < 0 {
      return
    }
    let (view_visibility_comp, skinned_mesh_comp) = data
    let skin_key = render3d_skin_entity_key(entity)
    changed_skin_entities.set(skin_key, true)
    render3d_phase_remove_skin(skin_uniforms_ref, entity)
    if !view_visibility_comp.value().is_visible() {
      return
    }
    let skinned_mesh = skinned_mesh_comp.value()
    if render3d_extract_skinning_matrices_with_columns(
        source_world, entity, skinned_mesh, inverse_bindposes_assets, world_transform_cache_ref,
        transform_columns,
      )
      is Some(_skinning_matrices) {
      render3d_phase_register_skin(skin_uniforms_ref, entity, skinned_mesh)
      render3d_phase_mark_skin_prepared(skin_uniforms_ref, entity)
      render3d_phase_enqueue_skin_upload(skin_uniforms_ref, upload_seen, entity)
    }
  })
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
  if skin_uniforms_ref.val.total_joints <= 0 {
    return
  }
  let threshold = skin_uniforms_ref.val.total_joints / 4
  let changed_transforms = source_world.changed_components(
    @transform.ecs_key_global_transform, sequence,
  )
  let changed_joint_entities : Array[@core.Entity] = []
  let mut must_extract_all = changed_transforms.len() > threshold
  if !must_extract_all {
    for entry in skin_uniforms_ref.val.joint_to_skins.iter() {
      let (joint_key, _skins) = entry
      let joint_entity = @core.Entity::from_bits(joint_key)
      if source_world.is_changed_by_key(
          joint_entity, @transform.ecs_key_global_transform, sequence,
        ) {
        changed_joint_entities.push(joint_entity)
        if changed_joint_entities.length() > threshold {
          must_extract_all = true
          break
        }
      }
    }
  }
  if must_extract_all {
    source_world.for_each_component(skinned_mesh_key, fn(entity, skinned_mesh) {
      if entity.id < 0 {
        return
      }
      if changed_skin_entities.contains(render3d_skin_entity_key(entity)) {
        return
      }
      if !render3d_has_prepared_skin_binding(skin_uniforms_ref, entity) {
        return
      }
      if !render3d_skin_is_visible(source_world, entity) {
        return
      }
      if render3d_extract_skinning_matrices_with_columns(
          source_world, entity, skinned_mesh, inverse_bindposes_assets, world_transform_cache_ref,
          transform_columns,
        )
        is Some(_skinning_matrices) {
        render3d_phase_enqueue_skin_upload(
          skin_uniforms_ref, upload_seen, entity,
        )
      }
    })
    return
  }
  for joint_entity in changed_joint_entities {
    let joint_key = render3d_skin_entity_key(joint_entity)
    match skin_uniforms_ref.val.joint_to_skins.get(joint_key) {
      Some(skins) =>
        for skin_entity in skins {
          let skin_key = render3d_skin_entity_key(skin_entity)
          if changed_skin_entities.contains(skin_key) {
            continue
          }
          if !source_world.is_alive(skin_entity) {
            render3d_phase_remove_skin(skin_uniforms_ref, skin_entity)
            continue
          }
          if !render3d_has_prepared_skin_binding(skin_uniforms_ref, skin_entity) {
            continue
          }
          if !render3d_skin_is_visible(source_world, skin_entity) {
            continue
          }
          guard (try! source_world.get_by_key(skin_entity, skinned_mesh_key))
            is Some(skinned_mesh) else {
            continue
          }
          if render3d_extract_skinning_matrices_with_columns(
              source_world, skin_entity, skinned_mesh, inverse_bindposes_assets,
              world_transform_cache_ref, transform_columns,
            )
            is Some(_skinning_matrices) {
            render3d_phase_enqueue_skin_upload(
              skin_uniforms_ref, upload_seen, skin_entity,
            )
          }
        }
      None => ()
    }
  }
}

///|
pub fn render3d_prepare_skin_bindings_upload(
  _source_world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  if skin_uniforms_ref.val.skin_uniform_info.is_empty() {
    return
  }
  for entity in skin_uniforms_ref.val.skin_upload_queue {
    let (key_hi, key_lo) = render3d_prepared_skin_binding_keys(
      skin_uniforms_ref, entity,
    )
    if key_hi < 0 || key_lo < 0 {
      continue
    }
    if render3d_cached_skinning_matrices(world_transform_cache_ref, entity)
      is Some(skinning_matrices) {
      let skin_key = render3d_skin_entity_key(entity)
      render3d_copy_skinning_rows_into_staging(
        skin_uniforms_ref, key_hi, skinning_matrices,
      )
      skin_uniforms_ref.val.previous_skins.set(skin_key, true)
    }
  }
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
  match skin_uniforms_ref.val.skin_uniform_info.get(entity.id) {
    Some(binding) =>
      if binding.entity_generation == entity.generation {
        (binding.key_hi, binding.key_lo)
      } else {
        (-1, -1)
      }
    None => (-1, -1)
  }
}
