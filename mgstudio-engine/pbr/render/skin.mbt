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
  phase_state_ref : Ref[Render3dPhaseState],
  entity : @core.Entity,
) -> Bool {
  match phase_state_ref.val.prepared_skin_bindings.get(entity.id) {
    Some(binding) => binding.entity_generation == entity.generation
    None => false
  }
}

///|
fn render3d_phase_remove_skin(
  phase_state_ref : Ref[Render3dPhaseState],
  entity : @core.Entity,
) -> Unit {
  match phase_state_ref.val.prepared_skin_bindings.get(entity.id) {
    Some(binding) =>
      if binding.entity_generation == entity.generation {
        phase_state_ref.val.prepared_skin_bindings.remove(entity.id) |> ignore
      }
    None => ()
  }
  let skin_key = render3d_skin_entity_key(entity)
  match phase_state_ref.val.skin_joint_count_by_skin.get(skin_key) {
    Some(joint_count) =>
      if joint_count > 0 {
        let remaining = phase_state_ref.val.total_skin_joints - joint_count
        phase_state_ref.val.total_skin_joints = if remaining > 0 {
          remaining
        } else {
          0
        }
      }
    None => ()
  }
  phase_state_ref.val.skin_joint_count_by_skin.remove(skin_key)
  match phase_state_ref.val.skin_joints_by_skin.get(skin_key) {
    Some(joints) =>
      for joint in joints {
        let joint_key = render3d_skin_entity_key(joint)
        match phase_state_ref.val.skin_joint_to_skins.get(joint_key) {
          Some(skins) => {
            render3d_skin_entity_array_remove_all(skins, entity)
            if skins.length() == 0 {
              phase_state_ref.val.skin_joint_to_skins.remove(joint_key)
              |> ignore
            } else {
              phase_state_ref.val.skin_joint_to_skins.set(joint_key, skins)
            }
          }
          None => ()
        }
      }
    None => ()
  }
  phase_state_ref.val.skin_joints_by_skin.remove(skin_key)
}

///|
fn render3d_phase_register_skin(
  phase_state_ref : Ref[Render3dPhaseState],
  entity : @core.Entity,
  skinned_mesh : @mesh.SkinnedMesh,
) -> Unit {
  render3d_phase_remove_skin(phase_state_ref, entity)
  let joints = skinned_mesh.joints()
  let skin_key = render3d_skin_entity_key(entity)
  phase_state_ref.val.skin_joints_by_skin.set(skin_key, joints)
  phase_state_ref.val.skin_joint_count_by_skin.set(skin_key, joints.length())
  phase_state_ref.val.total_skin_joints = phase_state_ref.val.total_skin_joints +
    joints.length()
  for joint in joints {
    let joint_key = render3d_skin_entity_key(joint)
    let mapped_skins = match
      phase_state_ref.val.skin_joint_to_skins.get(joint_key) {
      Some(existing) => existing
      None => []
    }
    if !render3d_skin_entity_array_contains(mapped_skins, entity) {
      mapped_skins.push(entity)
    }
    phase_state_ref.val.skin_joint_to_skins.set(joint_key, mapped_skins)
  }
}

///|
fn render3d_phase_mark_skin_prepared(
  phase_state_ref : Ref[Render3dPhaseState],
  entity : @core.Entity,
) -> Unit {
  phase_state_ref.val.prepared_skin_bindings.set(entity.id, PreparedSkinBinding3d::{
    entity_generation: entity.generation,
    key_hi: entity.id,
    key_lo: entity.generation,
  })
}

///|
fn render3d_phase_enqueue_skin_upload(
  phase_state_ref : Ref[Render3dPhaseState],
  upload_seen : Map[UInt64, Bool],
  entity : @core.Entity,
) -> Unit {
  let key = render3d_skin_entity_key(entity)
  if upload_seen.contains(key) {
    return
  }
  upload_seen.set(key, true)
  phase_state_ref.val.skin_upload_queue.push(entity)
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
pub fn render3d_extract_skin_bindings(
  source_world : @ecs.World,
  phase_state_ref : Ref[Render3dPhaseState],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  phase_state_ref.val.skin_upload_queue.clear()
  if source_world.component_count(@mesh.SkinnedMesh::component()) == 0 {
    phase_state_ref.val.prepared_skin_bindings.clear()
    phase_state_ref.val.skin_joint_to_skins.clear()
    phase_state_ref.val.skin_joints_by_skin.clear()
    phase_state_ref.val.skin_joint_count_by_skin.clear()
    phase_state_ref.val.total_skin_joints = 0
    return
  }
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
    render3d_phase_remove_skin(phase_state_ref, entity)
    if !view_visibility_comp.value().is_visible() {
      return
    }
    let skinned_mesh = skinned_mesh_comp.value()
    if render3d_extract_skinning_matrices(
        source_world, entity, world_transform_cache_ref,
      )
      is Some(_skinning_matrices) {
      render3d_phase_register_skin(phase_state_ref, entity, skinned_mesh)
      render3d_phase_mark_skin_prepared(phase_state_ref, entity)
      render3d_phase_enqueue_skin_upload(phase_state_ref, upload_seen, entity)
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
    render3d_phase_remove_skin(phase_state_ref, entity)
  }
  let changed_joint_entities = source_world
    .changed_components(@transform.ecs_key_global_transform, sequence)
    .read()
  if phase_state_ref.val.total_skin_joints <= 0 {
    return
  }
  let threshold = phase_state_ref.val.total_skin_joints / 4
  let must_extract_all = changed_joint_entities.length() > threshold
  if must_extract_all {
    source_world.for_each_component(skinned_mesh_key, fn(
      entity,
      _skinned_mesh,
    ) {
      if entity.id < 0 {
        return
      }
      if !render3d_has_prepared_skin_binding(phase_state_ref, entity) {
        return
      }
      if !render3d_skin_is_visible(source_world, entity) {
        return
      }
      if render3d_extract_skinning_matrices(
          source_world, entity, world_transform_cache_ref,
        )
        is Some(_skinning_matrices) {
        render3d_phase_enqueue_skin_upload(phase_state_ref, upload_seen, entity)
      }
    })
    return
  }
  for joint_entity in changed_joint_entities {
    let joint_key = render3d_skin_entity_key(joint_entity)
    match phase_state_ref.val.skin_joint_to_skins.get(joint_key) {
      Some(skins) =>
        for skin_entity in skins {
          let skin_key = render3d_skin_entity_key(skin_entity)
          if changed_skin_entities.contains(skin_key) {
            continue
          }
          if !source_world.is_alive(skin_entity) {
            render3d_phase_remove_skin(phase_state_ref, skin_entity)
            continue
          }
          if !render3d_has_prepared_skin_binding(phase_state_ref, skin_entity) {
            continue
          }
          if !render3d_skin_is_visible(source_world, skin_entity) {
            continue
          }
          if render3d_extract_skinning_matrices(
              source_world, skin_entity, world_transform_cache_ref,
            )
            is Some(_skinning_matrices) {
            render3d_phase_enqueue_skin_upload(
              phase_state_ref, upload_seen, skin_entity,
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
  phase_state_ref : Ref[Render3dPhaseState],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  if phase_state_ref.val.skin_upload_queue.length() == 0 {
    return
  }
  for entity in phase_state_ref.val.skin_upload_queue {
    let (key_hi, key_lo) = render3d_prepared_skin_binding_keys(
      phase_state_ref, entity,
    )
    if key_hi < 0 || key_lo < 0 {
      return
    }
    if render3d_cached_skinning_matrices(world_transform_cache_ref, entity)
      is Some(skinning_matrices) {
      @render_gpu.host_gpu_prepare_mesh3d_skin_binding(
        key_hi~,
        key_lo~,
        skinning_matrices~,
      )
    }
  }
}

///|
pub fn render3d_prepared_skin_binding_keys(
  phase_state_ref : Ref[Render3dPhaseState],
  entity : @core.Entity,
) -> (Int, Int) {
  if entity.id < 0 {
    return (-1, -1)
  }
  match phase_state_ref.val.prepared_skin_bindings.get(entity.id) {
    Some(binding) =>
      if binding.entity_generation == entity.generation {
        (binding.key_hi, binding.key_lo)
      } else {
        (-1, -1)
      }
    None => (-1, -1)
  }
}
