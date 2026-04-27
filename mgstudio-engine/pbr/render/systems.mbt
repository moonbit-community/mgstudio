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

// Bevy-aligned `pbr/render/systems` container.

///|
pub let render3d_extract_system_label : String = "mgstudio.render3d.extract"

///|
pub let render3d_prepare_system_label : String = "mgstudio.render3d.prepare"

///|
pub let render3d_queue_system_label : String = "mgstudio.render3d.queue"

///|
pub let render3d_execute_system_label : String = "mgstudio.render3d.execute"

///|
pub fn render3d_system_labels() -> Array[String] {
  [
    render3d_extract_system_label, render3d_prepare_system_label, render3d_queue_system_label,
    render3d_execute_system_label,
  ]
}

///|
pub fn[T] render3d_update_frusta_system_by_projection_key(
  world : @ecs.World,
  projection_key : @ecs.ComponentKey[T],
  compute_frustum : (T, @transform.Transform) -> Frustum,
) -> Unit {
  let sequence = world.get_sequence_context().sequence()
  let processed = @hashset.HashSet::new()
  fn entity_key(entity : @core.Entity) -> UInt64 {
    let hi = entity.id.reinterpret_as_uint().to_uint64()
    let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
    (hi << 32) | lo
  }
  fn update_entity(
    world : @ecs.World,
    entity : @core.Entity,
    projection_key : @ecs.ComponentKey[T],
    compute_frustum : (T, @transform.Transform) -> Frustum,
  ) -> Unit {
    guard world.is_alive(entity) else { return }
    guard (try! world.get_by_key(entity, @transform.ecs_key_transform))
      is Some(transform) else {
      return
    }
    guard (try! world.get_by_key(entity, projection_key)) is Some(projection) else {
      return
    }
    let next = compute_frustum(projection, transform)
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
    processed.add(key)
    update_entity(world, entity, projection_key, compute_frustum)
  }
  for entity in world.changed_components(projection_key, sequence).read() {
    let key = entity_key(entity)
    if processed.contains(key) {
      continue
    }
    processed.add(key)
    update_entity(world, entity, projection_key, compute_frustum)
  }
}
