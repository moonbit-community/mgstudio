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
const RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS : Int = 64

///|
fn render3d_morph_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn render3d_morph_is_visible(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  if (try! source_world.get_by_key(entity, @visibility.ecs_key_view_visibility))
    is Some(view_visibility) {
    view_visibility.is_visible()
  } else {
    true
  }
}

///|
fn render3d_resolved_morph_weights(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> Array[Float] {
  let animation_weights : @animation.AnimationWeights? = try! source_world
    .entity(entity)
    .get()
  let morph_weights_component : @mesh.MorphWeights? = try! source_world
    .entity(entity)
    .get()
  match animation_weights {
    Some(weights) => {
      let values = weights.values()
      try! source_world.set_by_key(
        entity,
        @mesh.MorphWeights::component(),
        @mesh.MorphWeights::new(values),
      )
      values
    }
    None =>
      match morph_weights_component {
        Some(weights) => weights.values()
        None => []
      }
  }
}

///|
fn render3d_push_morph_weights_to_uniform_buffer(
  uniform_weights : Array[Float],
  weights : Array[Float],
) -> UInt {
  let start = uniform_weights.length()
  let normalized = @pbr_render.render3d_normalize_morph_weights(weights)
  let limit = if normalized.length() < RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS {
    normalized.length()
  } else {
    RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS
  }
  for index in 0..<limit {
    uniform_weights.push(normalized[index])
  }
  let target_len = start + RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS
  while uniform_weights.length() < target_len {
    uniform_weights.push(0.0F)
  }
  start.reinterpret_as_uint() * 4U
}

///|
fn render3d_read_morph_weights_from_uniform_buffer(
  uniform_weights : Array[Float],
  byte_offset : UInt,
) -> Array[Float] {
  let start = (byte_offset / 4U).reinterpret_as_int()
  let end = start + RENDER3D_MORPH_UNIFORM_STRIDE_WEIGHTS
  let clamped_end = if end < uniform_weights.length() {
    end
  } else {
    uniform_weights.length()
  }
  let values : Array[Float] = []
  if start >= clamped_end {
    return values
  }
  for index in start..<clamped_end {
    values.push(uniform_weights[index])
  }
  values
}

///|
fn render3d_clone_mesh3d_geometry(
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  for position in geometry.positions {
    positions.push(position)
  }
  let uvs : Array[@math.Vec2] = []
  for uv in geometry.uvs {
    uvs.push(uv)
  }
  let indices = match geometry.indices {
    Some(existing) => {
      let next : Array[Int] = []
      for index in existing {
        next.push(index)
      }
      Some(next)
    }
    None => None
  }
  let colors = match geometry.colors {
    Some(existing) => {
      let next : Array[@math.Vec4] = []
      for color in existing {
        next.push(color)
      }
      Some(next)
    }
    None => None
  }
  let mut cloned = @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    indices,
    geometry.topology,
  ).with_colors(colors)
  if geometry.joint_indices is Some(joint_indices) {
    let copied_indices : Array[@mesh.MeshJointIndices] = []
    for joint_index in joint_indices {
      copied_indices.push(joint_index)
    }
    let copied_weights = match geometry.joint_weights {
      Some(existing) => {
        let next : Array[@math.Vec4] = []
        for weight in existing {
          next.push(weight)
        }
        Some(next)
      }
      None => None
    }
    cloned = cloned.with_joint_data(Some(copied_indices), copied_weights)
  } else if geometry.joint_weights is Some(existing) {
    let next : Array[@math.Vec4] = []
    for weight in existing {
      next.push(weight)
    }
    cloned = cloned.with_joint_data(None, Some(next))
  }
  if geometry.morph_target_positions is Some(morph_targets) {
    let copied_targets : Array[Array[@math.Vec3]] = []
    for morph_target in morph_targets {
      let copied_positions : Array[@math.Vec3] = []
      for position in morph_target {
        copied_positions.push(position)
      }
      copied_targets.push(copied_positions)
    }
    let copied_names = match geometry.morph_target_names {
      Some(existing) => {
        let next : Array[String] = []
        for name in existing {
          next.push(name)
        }
        Some(next)
      }
      None => None
    }
    cloned = cloned.with_morph_targets(
      Some(copied_targets),
      morph_target_names=copied_names,
    )
  }
  for attribute in geometry.custom_attributes_vec3 {
    let values : Array[@math.Vec3] = []
    for value in attribute.values() {
      values.push(value)
    }
    cloned = cloned.with_custom_attribute_vec3(attribute.name(), values)
  }
  if geometry.tangents is Some(existing) {
    let copied : Array[@math.Vec4] = []
    for tangent in existing {
      copied.push(tangent)
    }
    ignore(cloned.replace_tangents(Some(copied)))
  }
  cloned
}

///|
fn render3d_apply_morph_targets(
  base_positions : Array[@math.Vec3],
  morph_targets : Array[Array[@math.Vec3]],
  weights : Array[Float],
) -> Array[@math.Vec3] {
  let positions : Array[@math.Vec3] = []
  for position in base_positions {
    positions.push(position)
  }
  let limit = if morph_targets.length() < weights.length() {
    morph_targets.length()
  } else {
    weights.length()
  }
  for morph_index in 0..<limit {
    let weight = weights[morph_index]
    if weight == 0.0F {
      continue
    }
    let morph_target = morph_targets[morph_index]
    let vertex_limit = if morph_target.length() < positions.length() {
      morph_target.length()
    } else {
      positions.length()
    }
    for vertex_index in 0..<vertex_limit {
      positions[vertex_index] = @math.Vec3::add(
        positions[vertex_index],
        @math.Vec3::mul_scalar(morph_target[vertex_index], weight),
      )
    }
  }
  positions
}

///|
pub fn render3d_extract_morphs(
  source_world : @ecs.World,
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
) -> Unit {
  phase_state_ref.val.morph_indices_prev = phase_state_ref.val.morph_indices_current
  phase_state_ref.val.morph_weights_prev = phase_state_ref.val.morph_weights_current
  phase_state_ref.val.morph_indices_current = {}
  phase_state_ref.val.morph_weights_current = []
  if source_world.component_count(@mesh.MorphTargetMesh::component()) == 0 {
    return
  }
  let mesh_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[Mesh3d], @ecs.Comp[@mesh.MorphTargetMesh]),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_query.view(fn(_entity, data) {
    let (entity, _mesh_component, _morph_target_mesh_component) = data
    if !render3d_morph_is_visible(source_world, entity) {
      return
    }
    let active_morph_weights = render3d_resolved_morph_weights(
      source_world, entity,
    )
    let uniform_offset = render3d_push_morph_weights_to_uniform_buffer(
      phase_state_ref.val.morph_weights_current,
      active_morph_weights,
    )
    phase_state_ref.val.morph_indices_current.set(
      render3d_morph_entity_key(entity),
      uniform_offset,
    )
  })
}

///|
pub fn render3d_prepare_morphs(
  source_world : @ecs.World,
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
) -> Unit {
  let mesh_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[Mesh3d], @ecs.Comp[@mesh.MorphTargetMesh]),
    @ecs.All,
  ] = @ecs.query(source_world)
  let mesh_assets_ref = mesh_assets_mut_or_abort()

  try! mesh_query.view(fn(_entity, data) {
    let (entity, mesh_component, morph_target_mesh_component) = data
    let entity_key = render3d_morph_entity_key(entity)
    let morph_weights_offset = match
      phase_state_ref.val.morph_indices_current.get(entity_key) {
      Some(offset) => offset
      None => return
    }
    let source_mesh_handle = morph_target_mesh_component.value().source_mesh()
    let instance_mesh_handle = mesh_component.value().mesh()
    let source_mesh = match mesh_assets_ref.val.get(source_mesh_handle) {
      Some(value) => value
      None => return
    }
    let source_geometry = match source_mesh.as_3d_geometry() {
      Some(value) => value
      None => return
    }

    let active_morph_weights = render3d_read_morph_weights_from_uniform_buffer(
      phase_state_ref.val.morph_weights_current,
      morph_weights_offset,
    )

    let mut positions = source_geometry.positions
    if source_geometry.morph_target_positions() is Some(morph_targets) &&
      active_morph_weights.length() > 0 {
      positions = render3d_apply_morph_targets(
        positions, morph_targets, active_morph_weights,
      )
    }

    let updated_geometry = render3d_clone_mesh3d_geometry(source_geometry)
    guard updated_geometry.replace_positions(positions) else { return }
    guard source_mesh.with_3d_geometry(updated_geometry) is Some(updated_mesh) else {
      return
    }
    ignore(mesh_assets_ref.val.set(instance_mesh_handle, updated_mesh))
  })
}

///|
pub fn render3d_sync_and_apply_deformed_meshes(world : @ecs.World) -> Unit {
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  render3d_extract_morphs(world, phase_state_ref)
  render3d_prepare_morphs(world, phase_state_ref)
}
