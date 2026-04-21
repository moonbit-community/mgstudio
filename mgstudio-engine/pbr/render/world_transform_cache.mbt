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
pub fn render3d_rotate_by_quat(v : @math.Vec3, q : @math.Quat) -> @math.Vec3 {
  let q_vec = @math.Vec3::new(q.x, q.y, q.z)
  let t = q_vec.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(q_vec.cross(t))
}

///|
pub fn render3d_transform_point(
  transform : @transform.Transform,
  local_point : @math.Vec3,
) -> @math.Vec3 {
  let scaled = local_point.mul(transform.scale)
  transform.translation.add(render3d_rotate_by_quat(scaled, transform.rotation))
}

///|
pub fn render3d_compose_transform(
  parent : @transform.Transform,
  local_transform : @transform.Transform,
) -> @transform.Transform {
  let scaled_translation = local_transform.translation.mul(parent.scale)
  let world_translation = parent.translation.add(
    render3d_rotate_by_quat(scaled_translation, parent.rotation),
  )
  @transform.Transform::new(
    world_translation,
    parent.rotation.mul(local_transform.rotation).normalize(),
    parent.scale.mul(local_transform.scale),
  )
}

///|
pub struct Render3dWorldTransformCache {
  mut frame_stamp : Int
  transforms : Array[@transform.Transform?]
  generations : Array[Int]
  visiting : Array[Bool]
  stamps : Array[Int]
  local_transforms : Array[@transform.Transform?]
  local_generations : Array[Int]
  local_stamps : Array[Int]
  parent_entities : Array[@core.Entity?]
  parent_generations : Array[Int]
  parent_stamps : Array[Int]
  skinning_matrices : Array[Array[Float]?]
  skinning_generations : Array[Int]
  skinning_stamps : Array[Int]
}

///|
fn render3d_world_transform_cache_new() -> Render3dWorldTransformCache {
  {
    frame_stamp: 0,
    transforms: [],
    generations: [],
    visiting: [],
    stamps: [],
    local_transforms: [],
    local_generations: [],
    local_stamps: [],
    parent_entities: [],
    parent_generations: [],
    parent_stamps: [],
    skinning_matrices: [],
    skinning_generations: [],
    skinning_stamps: [],
  }
}

///|
pub(all) struct Render3dTransformColumns {
  transform : @ecs.ComponentColumn[@transform.Transform]?
  global : @ecs.ComponentColumn[@transform.GlobalTransform]?
  parent : @ecs.ComponentColumn[@hierarchy.Parent]?
}

///|
fn[T] render3d_register_transform_component(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[T],
) -> Unit {
  ignore(
    world.components_registrator().register_component_by_key(component_key),
  )
}

///|
pub fn render3d_transform_columns(
  world : @ecs.World,
) -> Render3dTransformColumns {
  render3d_register_transform_component(world, @transform.ecs_key_transform)
  render3d_register_transform_component(
    world, @transform.ecs_key_global_transform,
  )
  render3d_register_transform_component(world, @hierarchy.ecs_key_parent)
  {
    transform: world.component_column(@transform.ecs_key_transform),
    global: world.component_column(@transform.ecs_key_global_transform),
    parent: world.component_column(@hierarchy.ecs_key_parent),
  }
}

///|
let render3d_world_transform_cache_key : @ecs.ResourceKey[
  Render3dWorldTransformCache,
] = @ecs.register_resource(debug_name="mgstudio.render3d.world_transform_cache")

///|
impl @app.Resource for Render3dWorldTransformCache with resource() {
  render3d_world_transform_cache_key
}

///|
pub fn render3d_world_transform_cache_ref(
  world : @ecs.World,
) -> Ref[Render3dWorldTransformCache] {
  if (try! world.get_resource(Render3dWorldTransformCache::resource())) is None {
    world.insert_resource(
      Render3dWorldTransformCache::resource(),
      render3d_world_transform_cache_new(),
    )
  }
  match (try! world.get_resource_mut(Render3dWorldTransformCache::resource())) {
    Some(cache_ref) => Ref::new(cache_ref.peek())
    None => abort("Missing Render3dWorldTransformCache resource")
  }
}

///|
pub fn render3d_world_transform_cache_begin_frame(
  cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  cache_ref.val.frame_stamp = cache_ref.val.frame_stamp + 1
  if cache_ref.val.frame_stamp <= 0 {
    cache_ref.val.frame_stamp = 1
    for i in 0..<cache_ref.val.stamps.length() {
      cache_ref.val.stamps[i] = 0
    }
    for i in 0..<cache_ref.val.skinning_stamps.length() {
      cache_ref.val.skinning_stamps[i] = 0
    }
    for i in 0..<cache_ref.val.local_stamps.length() {
      cache_ref.val.local_stamps[i] = 0
    }
    for i in 0..<cache_ref.val.parent_stamps.length() {
      cache_ref.val.parent_stamps[i] = 0
    }
  }
}

///|
fn render3d_world_transform_cache_ensure_entity_slot(
  cache_ref : Ref[Render3dWorldTransformCache],
  entity_id : Int,
) -> Unit {
  if entity_id < 0 {
    return
  }
  let required_len = entity_id + 1
  while cache_ref.val.transforms.length() < required_len {
    cache_ref.val.transforms.push(None)
    cache_ref.val.generations.push(0)
    cache_ref.val.visiting.push(false)
    cache_ref.val.stamps.push(0)
    cache_ref.val.local_transforms.push(None)
    cache_ref.val.local_generations.push(0)
    cache_ref.val.local_stamps.push(0)
    cache_ref.val.parent_entities.push(None)
    cache_ref.val.parent_generations.push(0)
    cache_ref.val.parent_stamps.push(0)
    cache_ref.val.skinning_matrices.push(None)
    cache_ref.val.skinning_generations.push(0)
    cache_ref.val.skinning_stamps.push(0)
  }
}

///|
fn render3d_entity_global_transform(
  columns : Render3dTransformColumns,
  entity : @core.Entity,
) -> @transform.Transform? {
  match columns.global {
    Some(global_column) =>
      match global_column.get(entity) {
        Some(global_transform) => Some(global_transform.to_transform_approx())
        None => None
      }
    None => None
  }
}

///|
fn render3d_entity_local_transform_cached_with_columns(
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
  columns : Render3dTransformColumns,
) -> @transform.Transform {
  if entity.id < 0 {
    return @transform.Transform::identity()
  }
  render3d_world_transform_cache_ensure_entity_slot(cache_ref, entity.id)
  let frame_stamp = cache_ref.val.frame_stamp
  if cache_ref.val.local_stamps[entity.id] == frame_stamp &&
    cache_ref.val.local_generations[entity.id] == entity.generation {
    if cache_ref.val.local_transforms[entity.id] is Some(cached) {
      return cached
    }
    return @transform.Transform::identity()
  }
  let local_transform = match columns.transform {
    Some(transform_column) =>
      match transform_column.get(entity) {
        Some(value) => value
        None => @transform.Transform::identity()
      }
    None => @transform.Transform::identity()
  }
  cache_ref.val.local_transforms[entity.id] = Some(local_transform)
  cache_ref.val.local_generations[entity.id] = entity.generation
  cache_ref.val.local_stamps[entity.id] = frame_stamp
  local_transform
}

///|
pub fn render3d_entity_local_transform_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  let columns = render3d_transform_columns(world)
  render3d_entity_local_transform_cached_with_columns(
    entity, cache_ref, columns,
  )
}

///|
fn render3d_entity_parent_cached_with_columns(
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
  columns : Render3dTransformColumns,
) -> @core.Entity? {
  if entity.id < 0 {
    return None
  }
  render3d_world_transform_cache_ensure_entity_slot(cache_ref, entity.id)
  let frame_stamp = cache_ref.val.frame_stamp
  if cache_ref.val.parent_stamps[entity.id] == frame_stamp &&
    cache_ref.val.parent_generations[entity.id] == entity.generation {
    return cache_ref.val.parent_entities[entity.id]
  }
  let parent_entity = match columns.parent {
    Some(parent_column) =>
      match parent_column.get(entity) {
        Some(parent) => Some(parent.entity())
        None => None
      }
    None => None
  }
  cache_ref.val.parent_entities[entity.id] = parent_entity
  cache_ref.val.parent_generations[entity.id] = entity.generation
  cache_ref.val.parent_stamps[entity.id] = frame_stamp
  parent_entity
}

///|
pub fn render3d_entity_parent_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @core.Entity? {
  let columns = render3d_transform_columns(world)
  render3d_entity_parent_cached_with_columns(entity, cache_ref, columns)
}

///|
fn render3d_entity_world_transform_cached_with_columns(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
  columns : Render3dTransformColumns,
) -> @transform.Transform {
  if entity.id < 0 {
    return @transform.Transform::identity()
  }
  render3d_world_transform_cache_ensure_entity_slot(cache_ref, entity.id)
  let frame_stamp = cache_ref.val.frame_stamp
  if cache_ref.val.stamps[entity.id] == frame_stamp &&
    cache_ref.val.generations[entity.id] == entity.generation {
    if cache_ref.val.transforms[entity.id] is Some(cached) {
      return cached
    }
  }
  if cache_ref.val.stamps[entity.id] == frame_stamp &&
    cache_ref.val.visiting[entity.id] {
    return render3d_entity_local_transform_cached_with_columns(
      entity, cache_ref, columns,
    )
  }
  cache_ref.val.stamps[entity.id] = frame_stamp
  cache_ref.val.visiting[entity.id] = true
  let composed = match render3d_entity_global_transform(columns, entity) {
    Some(global_transform) => global_transform
    None => {
      let local_transform = render3d_entity_local_transform_cached_with_columns(
        entity, cache_ref, columns,
      )
      match
        render3d_entity_parent_cached_with_columns(entity, cache_ref, columns) {
        Some(parent_entity) => {
          let parent_transform = render3d_entity_world_transform_cached_with_columns(
            world, parent_entity, cache_ref, columns,
          )
          render3d_compose_transform(parent_transform, local_transform)
        }
        None => local_transform
      }
    }
  }
  cache_ref.val.visiting[entity.id] = false
  cache_ref.val.transforms[entity.id] = Some(composed)
  cache_ref.val.generations[entity.id] = entity.generation
  cache_ref.val.stamps[entity.id] = frame_stamp
  composed
}

///|
pub fn render3d_entity_world_transform_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  let columns = render3d_transform_columns(world)
  render3d_entity_world_transform_cached_with_columns(
    world, entity, cache_ref, columns,
  )
}

///|
fn render3d_entity_world_transform_cached_with_local_with_columns(
  world : @ecs.World,
  entity : @core.Entity,
  local_transform : @transform.Transform,
  cache_ref : Ref[Render3dWorldTransformCache],
  columns : Render3dTransformColumns,
) -> @transform.Transform {
  if entity.id < 0 {
    return @transform.Transform::identity()
  }
  render3d_world_transform_cache_ensure_entity_slot(cache_ref, entity.id)
  let frame_stamp = cache_ref.val.frame_stamp
  if cache_ref.val.stamps[entity.id] == frame_stamp &&
    cache_ref.val.generations[entity.id] == entity.generation {
    if cache_ref.val.transforms[entity.id] is Some(cached) {
      return cached
    }
  }
  if cache_ref.val.stamps[entity.id] == frame_stamp &&
    cache_ref.val.visiting[entity.id] {
    return local_transform
  }
  cache_ref.val.stamps[entity.id] = frame_stamp
  cache_ref.val.visiting[entity.id] = true
  cache_ref.val.local_transforms[entity.id] = Some(local_transform)
  cache_ref.val.local_generations[entity.id] = entity.generation
  cache_ref.val.local_stamps[entity.id] = frame_stamp
  let composed = match render3d_entity_global_transform(columns, entity) {
    Some(global_transform) => global_transform
    None =>
      match
        render3d_entity_parent_cached_with_columns(entity, cache_ref, columns) {
        Some(parent_entity) => {
          let parent_transform = render3d_entity_world_transform_cached_with_columns(
            world, parent_entity, cache_ref, columns,
          )
          render3d_compose_transform(parent_transform, local_transform)
        }
        None => local_transform
      }
  }
  cache_ref.val.visiting[entity.id] = false
  cache_ref.val.transforms[entity.id] = Some(composed)
  cache_ref.val.generations[entity.id] = entity.generation
  cache_ref.val.stamps[entity.id] = frame_stamp
  composed
}

///|
pub fn render3d_entity_world_transform_cached_with_local(
  world : @ecs.World,
  entity : @core.Entity,
  local_transform : @transform.Transform,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  let columns = render3d_transform_columns(world)
  render3d_entity_world_transform_cached_with_local_with_columns(
    world, entity, local_transform, cache_ref, columns,
  )
}

///|
pub fn render3d_entity_world_transform_from_components(
  world : @ecs.World,
  entity : @core.Entity,
  local_transform : @transform.Transform,
  cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  render3d_entity_world_transform_cached_with_local(
    world, entity, local_transform, cache_ref,
  )
}

///|
pub const RENDER3D_MAX_SKINNING_JOINTS : Int = 256

///|
pub fn render3d_entity_global_or_cached_transform(
  world : @ecs.World,
  entity : @core.Entity,
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> @transform.Transform {
  let columns = render3d_transform_columns(world)
  render3d_entity_world_transform_cached_with_columns(
    world, entity, world_transform_cache_ref, columns,
  )
}

///|
fn render3d_resize_skinning_rows(
  out : Array[Float],
  required_len : Int,
) -> Unit {
  while out.length() < required_len {
    out.push(0.0F)
  }
  while out.length() > required_len {
    out.pop() |> ignore
  }
}

///|
pub fn render3d_extract_skinning_matrices(
  world : @ecs.World,
  entity : @core.Entity,
  skinned_mesh : @mesh.SkinnedMesh,
  inverse_bindposes_assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Array[Float]? {
  let columns = render3d_transform_columns(world)
  render3d_extract_skinning_matrices_with_columns(
    world, entity, skinned_mesh, inverse_bindposes_assets, world_transform_cache_ref,
    columns,
  )
}

///|
pub fn render3d_extract_skinning_matrices_with_columns(
  world : @ecs.World,
  entity : @core.Entity,
  skinned_mesh : @mesh.SkinnedMesh,
  inverse_bindposes_assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
  columns : Render3dTransformColumns,
) -> Array[Float]? {
  if entity.id < 0 {
    return None
  }
  render3d_world_transform_cache_ensure_entity_slot(
    world_transform_cache_ref,
    entity.id,
  )
  let frame_stamp = world_transform_cache_ref.val.frame_stamp
  if entity.id < world_transform_cache_ref.val.skinning_stamps.length() &&
    world_transform_cache_ref.val.skinning_stamps[entity.id] == frame_stamp &&
    world_transform_cache_ref.val.skinning_generations[entity.id] ==
    entity.generation {
    return world_transform_cache_ref.val.skinning_matrices[entity.id]
  }
  let joints = skinned_mesh.joints()
  if joints.length() == 0 {
    return None
  }
  let inverse_bindposes_handle = skinned_mesh.inverse_bindposes()
  let inverse_bindposes_asset = match
    inverse_bindposes_assets.get(inverse_bindposes_handle) {
    Some(asset) => asset
    None => return None
  }
  let out = match world_transform_cache_ref.val.skinning_matrices[entity.id] {
    Some(values) => values
    None => {
      let values : Array[Float] = []
      world_transform_cache_ref.val.skinning_matrices[entity.id] = Some(values)
      values
    }
  }
  let capped_joint_count = if joints.length() < RENDER3D_MAX_SKINNING_JOINTS {
    joints.length()
  } else {
    RENDER3D_MAX_SKINNING_JOINTS
  }
  let identity_inverse_bindpose = @mesh.SkinningMat4::identity()
  let global_column = columns.global
  let required_rows_len = capped_joint_count * 16
  render3d_resize_skinning_rows(out, required_rows_len)
  for joint_index in 0..<capped_joint_count {
    let joint_entity = joints[joint_index]
    let out_base = joint_index * 16
    let inverse_bindpose = match inverse_bindposes_asset.get(joint_index) {
      Some(inverse_bindpose) => inverse_bindpose
      None => identity_inverse_bindpose
    }
    match global_column {
      Some(store) =>
        match store.get(joint_entity) {
          Some(joint_global) =>
            @mesh.SkinningMat4::from_global_transform(joint_global).mul_write_row_major_f32(
              inverse_bindpose, out, out_base,
            )
          None => {
            let joint_world = render3d_entity_world_transform_cached_with_columns(
              world, joint_entity, world_transform_cache_ref, columns,
            )
            @mesh.SkinningMat4::from_transform(joint_world).mul_write_row_major_f32(
              inverse_bindpose, out, out_base,
            )
          }
        }
      None => {
        let joint_world = render3d_entity_world_transform_cached_with_columns(
          world, joint_entity, world_transform_cache_ref, columns,
        )
        @mesh.SkinningMat4::from_transform(joint_world).mul_write_row_major_f32(
          inverse_bindpose, out, out_base,
        )
      }
    }
  }
  world_transform_cache_ref.val.skinning_generations[entity.id] = entity.generation
  world_transform_cache_ref.val.skinning_stamps[entity.id] = frame_stamp
  world_transform_cache_ref.val.skinning_matrices[entity.id] = Some(out)
  Some(out)
}
