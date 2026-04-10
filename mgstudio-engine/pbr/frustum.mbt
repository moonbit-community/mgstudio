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
pub type HalfSpace = @pbr_render.HalfSpace

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @pbr_render.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @pbr_render.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
pub type ViewFrustum = @pbr_render.ViewFrustum

///|
pub type Frustum = @pbr_render.Frustum

///|
pub fn render3d_update_frusta_system(world : @ecs.World) -> Unit {
  let sequence = world.get_sequence_context().sequence()
  let processed : Map[UInt64, Bool] = {}
  fn entity_key(entity : @core.Entity) -> UInt64 {
    let hi = entity.id.reinterpret_as_uint().to_uint64()
    let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
    (hi << 32) | lo
  }
  fn update_entity(world : @ecs.World, entity : @core.Entity) -> Unit {
    guard world.is_alive(entity) else { return }
    guard (try! world.get_by_key(entity, @transform.ecs_key_transform))
      is Some(transform) else {
      return
    }
    guard (try! world.get_by_key(entity, ecs_key_projection))
      is Some(projection) else {
      return
    }
    let next = projection.compute_frustum(transform)
    if (try! world.get_by_key(entity, ecs_key_frustum)) is Some(current) {
      if current != next {
        try! (world.replace(entity, ecs_key_frustum, next) |> ignore)
      }
    } else {
      try! world.set_by_key(entity, ecs_key_frustum, next)
    }
  }
  for
    entity in world
    .changed_components(@transform.ecs_key_transform, sequence)
    .read() {
    let key = entity_key(entity)
    if processed.contains(key) {
      continue
    }
    processed.set(key, true)
    update_entity(world, entity)
  }
  for entity in world.changed_components(ecs_key_projection, sequence).read() {
    let key = entity_key(entity)
    if processed.contains(key) {
      continue
    }
    processed.set(key, true)
    update_entity(world, entity)
  }
}
