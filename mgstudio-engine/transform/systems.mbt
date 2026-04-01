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
type SimpleTransformChangedQuery = @ecs.Query[
  (@ecs.Comp[Transform], @ecs.Comp[GlobalTransform]),
  (
    @ecs.Without[@hierarchy.Parent],
    @ecs.Without[@hierarchy.Children],
    @ecs.Changed[Transform],
  ),
]

///|
type SimpleTransformOrphanQuery = @ecs.Query[
  (@ecs.Comp[Transform], @ecs.Comp[GlobalTransform]),
  (@ecs.Without[@hierarchy.Parent], @ecs.Without[@hierarchy.Children]),
]

///|
fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn transform_abort_malformed_hierarchy() -> Unit {
  abort(
    "Malformed hierarchy. This probably means that your hierarchy has been improperly maintained, or contains a cycle",
  )
}

///|
fn transform_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
priv struct TransformBootstrapState {
  completed : Bool
}

///|
let transform_bootstrap_state_resource_key : @ecs.ResourceKey[
  TransformBootstrapState
] = @ecs.register_resource(
  debug_name="mgstudio.transform.TransformBootstrapState",
)

///|
fn ensure_transform_runtime_resources(world : @ecs.World) -> Unit {
  let key = static_transform_optimizations_resource_key()
  if !world.resource(key).is_present() {
    world.insert_resource(key, StaticTransformOptimizations::disabled())
  }
  if !world.resource(transform_bootstrap_state_resource_key).is_present() {
    world.insert_resource(
      transform_bootstrap_state_resource_key,
      TransformBootstrapState::{ completed: false },
    )
  }
}

///|
fn read_static_transform_optimizations(
  world : @ecs.World,
) -> StaticTransformOptimizations {
  ensure_transform_runtime_resources(world)
  world
  .resource(static_transform_optimizations_resource_key())
  .get()
  .unwrap_or(StaticTransformOptimizations::disabled())
}

///|
fn write_static_transform_optimizations(
  world : @ecs.World,
  value : StaticTransformOptimizations,
) -> Unit {
  world.insert_resource(static_transform_optimizations_resource_key(), value)
}

///|
fn transform_bootstrap_completed(world : @ecs.World) -> Bool {
  ensure_transform_runtime_resources(world)
  match world.resource(transform_bootstrap_state_resource_key).get() {
    Some(state) => state.completed
    None => false
  }
}

///|
fn mark_transform_bootstrap_completed(world : @ecs.World) -> Unit {
  world.insert_resource(
    transform_bootstrap_state_resource_key,
    TransformBootstrapState::{ completed: true },
  )
}

///|
fn affine2_eq(a : Affine2, b : Affine2) -> Bool {
  a.a == b.a &&
  a.b == b.b &&
  a.c == b.c &&
  a.d == b.d &&
  a.tx == b.tx &&
  a.ty == b.ty
}

///|
fn global_transform_eq(a : GlobalTransform, b : GlobalTransform) -> Bool {
  affine2_eq(a.affine, b.affine) && a.z == b.z
}

///|
fn sync_simple_transforms_apply(world : @ecs.World) -> Unit {
  let sequence = world.get_sequence_context().sequence()
  let processed : Map[UInt64, Bool] = {}
  fn sync_entity_if_needed(world : @ecs.World, entity : @core.Entity) -> Unit {
    guard world.is_alive(entity) else { return }
    guard !(try! world.contains_by_key(entity, @hierarchy.ecs_key_parent)) else {
      return
    }
    guard !(try! world.contains_by_key(entity, @hierarchy.ecs_key_children)) else {
      return
    }
    guard (try! world.get_by_key(entity, ecs_key_transform)) is Some(transform) else {
      return
    }
    guard (try! world.get_by_key(entity, ecs_key_global_transform))
      is Some(current_global) else {
      return
    }
    let next_global = GlobalTransform::from_transform(transform)
    if !global_transform_eq(current_global, next_global) {
      try! (world.replace(entity, ecs_key_global_transform, next_global)
      |> ignore)
    }
  }
  for entity in world.changed_components(ecs_key_transform, sequence).read() {
    let key = transform_entity_key(entity)
    if processed.contains(key) {
      continue
    }
    processed.set(key, true)
    sync_entity_if_needed(world, entity)
  }
  for entity in world.added_components(ecs_key_transform, sequence).read() {
    let key = transform_entity_key(entity)
    if processed.contains(key) {
      continue
    }
    processed.set(key, true)
    sync_entity_if_needed(world, entity)
  }
  for
    entity in world
    .removed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    let key = transform_entity_key(entity)
    if processed.contains(key) {
      continue
    }
    processed.set(key, true)
    sync_entity_if_needed(world, entity)
  }
}

///|
pub fn sync_simple_transforms(
  _query : @app.ParamSet2[
    SimpleTransformChangedQuery,
    SimpleTransformOrphanQuery,
  ],
  _orphaned : @ecs.RemovedComponents[@hierarchy.Parent],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  sync_simple_transforms_apply(world)
}

///|
pub fn sync_simple_transforms_world(world : @ecs.World) -> Unit {
  sync_simple_transforms_apply(world)
}

///|
pub fn mark_dirty_trees(world : @ecs.World) -> Unit {
  let static_optimizations = read_static_transform_optimizations(world)
  static_optimizations.enabled = false
  write_static_transform_optimizations(world, static_optimizations)
}

///|
fn propagate_descendants(
  world : @ecs.World,
  parent : @core.Entity,
  parent_global : GlobalTransform,
  children : @hierarchy.Children,
  processed : Map[UInt64, Bool],
) -> Unit {
  for child in children.entities() {
    guard (try! world.get_by_key(child, @hierarchy.ecs_key_parent))
      is Some(child_parent) else {
      transform_abort_malformed_hierarchy()
    }
    if !entity_eq(child_parent.entity(), parent) {
      transform_abort_malformed_hierarchy()
    }
    guard (try! world.get_by_key(child, ecs_key_transform))
      is Some(local_transform) else {
      continue
    }
    guard (try! world.get_by_key(child, ecs_key_global_transform))
      is Some(current_global) else {
      continue
    }
    let next_global = parent_global.mul(
      GlobalTransform::from_transform(local_transform),
    )
    processed.set(transform_entity_key(child), true)
    if !global_transform_eq(current_global, next_global) {
      try! (world.replace(child, ecs_key_global_transform, next_global)
      |> ignore)
    }
    if (try! world.get_by_key(child, @hierarchy.ecs_key_children))
      is Some(grand_children) {
      propagate_descendants(
        world, child, next_global, grand_children, processed,
      )
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let processed : Map[UInt64, Bool] = {}
  let sequence = world.get_sequence_context().sequence()
  fn propagate_entity_if_needed(
    world : @ecs.World,
    entity : @core.Entity,
  ) -> Unit {
    guard world.is_alive(entity) else { return }
    guard (try! world.get_by_key(entity, ecs_key_transform))
      is Some(local_transform) else {
      return
    }
    guard (try! world.get_by_key(entity, ecs_key_global_transform))
      is Some(current_global) else {
      return
    }
    let next_global = match
      (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
      Some(parent) => {
        let parent_global = match
          (try! world.get_by_key(parent.entity(), ecs_key_global_transform)) {
          Some(value) => value
          None => GlobalTransform::identity()
        }
        parent_global.mul(GlobalTransform::from_transform(local_transform))
      }
      None => GlobalTransform::from_transform(local_transform)
    }
    processed.set(transform_entity_key(entity), true)
    if !global_transform_eq(current_global, next_global) {
      try! (world.replace(entity, ecs_key_global_transform, next_global)
      |> ignore)
    }
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      propagate_descendants(world, entity, next_global, children, processed)
    }
  }
  for entity in world.changed_components(ecs_key_transform, sequence).read() {
    if processed.contains(transform_entity_key(entity)) {
      continue
    }
    propagate_entity_if_needed(world, entity)
  }
  for entity in world.added_components(ecs_key_transform, sequence).read() {
    if processed.contains(transform_entity_key(entity)) {
      continue
    }
    propagate_entity_if_needed(world, entity)
  }
  for
    entity in world
    .changed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    if processed.contains(transform_entity_key(entity)) {
      continue
    }
    propagate_entity_if_needed(world, entity)
  }
  for
    entity in world
    .added_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    if processed.contains(transform_entity_key(entity)) {
      continue
    }
    propagate_entity_if_needed(world, entity)
  }
  for
    entity in world
    .removed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    if processed.contains(transform_entity_key(entity)) {
      continue
    }
    if !world.is_alive(entity) {
      continue
    }
    propagate_entity_if_needed(world, entity)
  }
  if !transform_bootstrap_completed(world) {
    let all_transforms : @ecs.Query[@ecs.Comp[Transform], @ecs.All] = @ecs.query(
      world,
    )
    try! all_transforms.for_each(fn(entity, _transform) {
      if processed.contains(transform_entity_key(entity)) {
        return
      }
      propagate_entity_if_needed(world, entity)
    })
    mark_transform_bootstrap_completed(world)
  }
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
