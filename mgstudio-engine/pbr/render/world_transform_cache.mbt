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
  match
    (try! world.get_resource_ref_mut(Render3dWorldTransformCache::resource())) {
    Some(cache_ref) => cache_ref
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
pub fn render3d_entity_local_transform_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
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
  let local_transform = match
    (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
    Some(value) => value
    None => @transform.Transform::identity()
  }
  cache_ref.val.local_transforms[entity.id] = Some(local_transform)
  cache_ref.val.local_generations[entity.id] = entity.generation
  cache_ref.val.local_stamps[entity.id] = frame_stamp
  local_transform
}

///|
pub fn render3d_entity_parent_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
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
  let parent_entity = match
    (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
    Some(parent) => Some(parent.entity())
    None => None
  }
  cache_ref.val.parent_entities[entity.id] = parent_entity
  cache_ref.val.parent_generations[entity.id] = entity.generation
  cache_ref.val.parent_stamps[entity.id] = frame_stamp
  parent_entity
}

///|
pub fn render3d_entity_world_transform_cached(
  world : @ecs.World,
  entity : @core.Entity,
  cache_ref : Ref[Render3dWorldTransformCache],
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
    return render3d_entity_local_transform_cached(world, entity, cache_ref)
  }
  cache_ref.val.stamps[entity.id] = frame_stamp
  cache_ref.val.visiting[entity.id] = true
  let local_transform = render3d_entity_local_transform_cached(
    world, entity, cache_ref,
  )
  let composed = match render3d_entity_parent_cached(world, entity, cache_ref) {
    Some(parent_entity) => {
      let parent_transform = render3d_entity_world_transform_cached(
        world, parent_entity, cache_ref,
      )
      render3d_compose_transform(parent_transform, local_transform)
    }
    None => local_transform
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
  let composed = match render3d_entity_parent_cached(world, entity, cache_ref) {
    Some(parent_entity) => {
      let parent_transform = render3d_entity_world_transform_cached(
        world, parent_entity, cache_ref,
      )
      render3d_compose_transform(parent_transform, local_transform)
    }
    None => local_transform
  }
  cache_ref.val.visiting[entity.id] = false
  cache_ref.val.transforms[entity.id] = Some(composed)
  cache_ref.val.generations[entity.id] = entity.generation
  cache_ref.val.stamps[entity.id] = frame_stamp
  composed
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
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global) => global.to_transform_approx()
    None =>
      render3d_entity_world_transform_cached(
        world, entity, world_transform_cache_ref,
      )
  }
}

///|
pub fn render3d_extract_skinning_matrices(
  world : @ecs.World,
  entity : @core.Entity,
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Array[Float]? {
  guard (try! world.get_by_key(entity, @mesh.SkinnedMesh::component()))
    is Some(skinned_mesh) else {
    return None
  }
  let inverse_bindposes_assets_key : @ecs.ResourceKey[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  let inverse_bindposes_assets = match
    (try! world.get_resource(inverse_bindposes_assets_key)) {
    Some(assets) => assets
    None => return None
  }
  let inverse_bindposes_handle = skinned_mesh.inverse_bindposes()
  let inverse_bindposes_asset = match
    inverse_bindposes_assets.get(inverse_bindposes_handle) {
    Some(asset) => asset
    None => return None
  }
  let joints = skinned_mesh.joints()
  if joints.length() == 0 {
    return None
  }
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
  let out = match world_transform_cache_ref.val.skinning_matrices[entity.id] {
    Some(values) => {
      values.clear()
      values
    }
    None => {
      let values : Array[Float] = []
      world_transform_cache_ref.val.skinning_matrices[entity.id] = Some(values)
      values
    }
  }
  let mesh_world = render3d_entity_global_or_cached_transform(
    world, entity, world_transform_cache_ref,
  )
  let mesh_world_inverse = @mesh.SkinningMat4::inverse_transform(mesh_world)
  let capped_joint_count = if joints.length() < RENDER3D_MAX_SKINNING_JOINTS {
    joints.length()
  } else {
    RENDER3D_MAX_SKINNING_JOINTS
  }
  let identity_inverse_bindpose = @mesh.SkinningMat4::identity()
  for joint_index in 0..<capped_joint_count {
    let joint_entity = joints[joint_index]
    let joint_world = render3d_entity_global_or_cached_transform(
      world, joint_entity, world_transform_cache_ref,
    )
    let inverse_bindpose = match inverse_bindposes_asset.get(joint_index) {
      Some(inverse_bindpose) => inverse_bindpose
      None => identity_inverse_bindpose
    }
    let joint_matrix = mesh_world_inverse
      .mul(@mesh.SkinningMat4::from_transform(joint_world))
      .mul(inverse_bindpose)
    joint_matrix.append_row_major_f32(out)
  }
  world_transform_cache_ref.val.skinning_generations[entity.id] = entity.generation
  world_transform_cache_ref.val.skinning_stamps[entity.id] = frame_stamp
  world_transform_cache_ref.val.skinning_matrices[entity.id] = Some(out)
  Some(out)
}
