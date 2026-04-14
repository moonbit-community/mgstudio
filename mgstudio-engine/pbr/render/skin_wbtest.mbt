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
fn skin_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xffffffffUL
  (hi << 32) | lo
}

///|
fn ensure_skin_cache_slot(
  cache_ref : Ref[Render3dWorldTransformCache],
  entity_id : Int,
) -> Unit {
  let required_len = entity_id + 1
  while cache_ref.val.skinning_matrices.length() < required_len {
    cache_ref.val.skinning_matrices.push(None)
    cache_ref.val.skinning_generations.push(0)
    cache_ref.val.skinning_stamps.push(0)
  }
}

///|
test "pbr render skin: upload skips invalid skin keys without aborting later skins" {
  let world = @ecs.World::new()
  let phase_state_ref = render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref(world)
  world_transform_cache_ref.val.frame_stamp = 1

  let missing_binding_entity = @core.Entity::new(100, 1)
  let valid_entity = @core.Entity::new(3, 2)
  phase_state_ref.val.skin_upload_queue.clear()
  phase_state_ref.val.skin_upload_queue.push(missing_binding_entity)
  phase_state_ref.val.skin_upload_queue.push(valid_entity)
  phase_state_ref.val.prepared_skin_bindings.set(valid_entity.id, PreparedSkinBinding3d::{
    entity_generation: valid_entity.generation,
    key_hi: 4,
    key_lo: 0,
  })

  ensure_skin_cache_slot(world_transform_cache_ref, valid_entity.id)
  world_transform_cache_ref.val.skinning_matrices[valid_entity.id] = Some([
    1.0F,
    2.0F,
    3.0F,
    4.0F,
  ])
  world_transform_cache_ref.val.skinning_generations[valid_entity.id] =
    valid_entity.generation
  world_transform_cache_ref.val.skinning_stamps[valid_entity.id] =
    world_transform_cache_ref.val.frame_stamp

  render3d_prepare_skin_bindings_upload(
    world,
    phase_state_ref,
    world_transform_cache_ref,
  )

  inspect(
    phase_state_ref.val.skin_previous_matrices.contains(skin_entity_key(valid_entity)),
    content="true",
  )
}
