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
fn ensure_transform_runtime_resources(world : @ecs.World) -> Unit {
  let key = static_transform_optimizations_resource_key()
  if !world.resource(key).is_present() {
    world.insert_resource(key, StaticTransformOptimizations::default())
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
  .unwrap_or(StaticTransformOptimizations::default())
}

///|
fn write_static_transform_optimizations(
  world : @ecs.World,
  value : StaticTransformOptimizations,
) -> Unit {
  world.insert_resource(static_transform_optimizations_resource_key(), value)
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
fn transform_set_contains(
  set : Map[UInt64, Bool],
  entity : @core.Entity,
) -> Bool {
  set.contains(transform_entity_key(entity))
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
  for
    entity in world.added_components(ecs_key_global_transform, sequence).read() {
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
    let transform_changed = world.is_changed_by_key(
      entity, ecs_key_transform, sequence,
    )
    let global_added = world.is_added_by_key(
      entity, ecs_key_global_transform, sequence,
    )
    if transform_changed || global_added {
      continue
    }
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
  let sequence = world.get_sequence_context().sequence()
  let static_optimizations = read_static_transform_optimizations(world)
  let threshold = if static_optimizations.threshold < 0.0F {
    0.0F
  } else if static_optimizations.threshold > 1.0F {
    1.0F
  } else {
    static_optimizations.threshold
  }
  if threshold == 0.0F {
    static_optimizations.enabled = false
    write_static_transform_optimizations(world, static_optimizations)
    return
  }
  let total = Float::from_int(
    world.component_count(ecs_key_transform_tree_changed),
  )
  if threshold == 1.0F || total == 0.0F {
    static_optimizations.enabled = true
  } else {
    let dynamic_count = world
      .changed_components(ecs_key_transform, sequence)
      .len() +
      world.changed_components(@hierarchy.ecs_key_parent, sequence).len() +
      world.added_components(ecs_key_global_transform, sequence).len() +
      world.removed_components(@hierarchy.ecs_key_parent, sequence).len()
    static_optimizations.enabled = Float::from_int(dynamic_count) / total <=
      threshold
  }
  write_static_transform_optimizations(world, static_optimizations)
  if !static_optimizations.enabled {
    return
  }
  let mark_tree_changed_chain = fn(entity : @core.Entity) {
    let mut next = entity
    while true {
      if !world.is_alive(next) {
        break
      }
      if !(try! world.contains_by_key(next, ecs_key_transform_tree_changed)) {
        break
      }
      let already_changed = world.is_changed_by_key(
        next, ecs_key_transform_tree_changed, sequence,
      )
      let was_added = world.is_added_by_key(
        next, ecs_key_transform_tree_changed, sequence,
      )
      if already_changed && !was_added {
        break
      }
      try! (world.replace(
        next,
        ecs_key_transform_tree_changed,
        TransformTreeChanged::default(),
      )
      |> ignore)
      match (try! world.get_by_key(next, @hierarchy.ecs_key_parent)) {
        Some(parent) => next = parent.entity()
        None => break
      }
    }
  }
  for entity in world.changed_components(ecs_key_transform, sequence).read() {
    mark_tree_changed_chain(entity)
  }
  for
    entity in world
    .changed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    mark_tree_changed_chain(entity)
  }
  for
    entity in world.added_components(ecs_key_global_transform, sequence).read() {
    mark_tree_changed_chain(entity)
  }
  for
    entity in world
    .removed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    mark_tree_changed_chain(entity)
  }
}

///|
fn propagate_descendants(
  world : @ecs.World,
  parent : @core.Entity,
  parent_global : GlobalTransform,
  children : @hierarchy.Children,
  static_optimizations_enabled : Bool,
  transform_changed : Map[UInt64, Bool],
  global_added : Map[UInt64, Bool],
  parent_changed : Map[UInt64, Bool],
  tree_changed : Map[UInt64, Bool],
  parent_global_changed : Bool,
) -> Unit {
  for child in children.entities() {
    guard (try! world.get_by_key(child, @hierarchy.ecs_key_parent))
      is Some(child_parent) else {
      transform_abort_malformed_hierarchy()
    }
    if !entity_eq(child_parent.entity(), parent) {
      transform_abort_malformed_hierarchy()
    }
    if static_optimizations_enabled {
      let child_tree_changed = transform_set_contains(tree_changed, child)
      if !child_tree_changed && !parent_global_changed {
        continue
      }
    }
    guard (try! world.get_by_key(child, ecs_key_transform))
      is Some(local_transform) else {
      continue
    }
    guard (try! world.get_by_key(child, ecs_key_global_transform))
      is Some(current_global) else {
      continue
    }
    let child_changed = if static_optimizations_enabled {
      parent_global_changed ||
      transform_set_contains(transform_changed, child) ||
      transform_set_contains(global_added, child) ||
      transform_set_contains(parent_changed, child)
    } else {
      true
    }
    let next_global = if child_changed {
      parent_global.mul(GlobalTransform::from_transform(local_transform))
    } else {
      current_global
    }
    if child_changed && !global_transform_eq(current_global, next_global) {
      try! (world.replace(child, ecs_key_global_transform, next_global)
      |> ignore)
    }
    if (try! world.get_by_key(child, @hierarchy.ecs_key_children))
      is Some(grand_children) {
      propagate_descendants(
        world, child, next_global, grand_children, static_optimizations_enabled,
        transform_changed, global_added, parent_changed, tree_changed, child_changed,
      )
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let sequence = world.get_sequence_context().sequence()
  let static_optimizations = read_static_transform_optimizations(world)
  let transform_changed : Map[UInt64, Bool] = {}
  let global_added : Map[UInt64, Bool] = {}
  let parent_changed : Map[UInt64, Bool] = {}
  let tree_changed : Map[UInt64, Bool] = {}
  if static_optimizations.enabled {
    for entity in world.changed_components(ecs_key_transform, sequence).read() {
      transform_changed.set(transform_entity_key(entity), true)
    }
    for
      entity in world
      .added_components(ecs_key_global_transform, sequence)
      .read() {
      global_added.set(transform_entity_key(entity), true)
    }
    for
      entity in world
      .changed_components(@hierarchy.ecs_key_parent, sequence)
      .read() {
      parent_changed.set(transform_entity_key(entity), true)
    }
    for
      entity in world
      .added_components(@hierarchy.ecs_key_parent, sequence)
      .read() {
      parent_changed.set(transform_entity_key(entity), true)
    }
    for
      entity in world
      .changed_components(ecs_key_transform_tree_changed, sequence)
      .read() {
      tree_changed.set(transform_entity_key(entity), true)
    }
    for
      entity in world
      .added_components(ecs_key_transform_tree_changed, sequence)
      .read() {
      tree_changed.set(transform_entity_key(entity), true)
    }
  }
  let orphaned_roots : Map[UInt64, Bool] = {}
  for
    entity in world
    .removed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    if !world.is_alive(entity) {
      continue
    }
    if static_optimizations.enabled {
      orphaned_roots.set(transform_entity_key(entity), true)
    }
  }
  // Anchor root iteration on `Children` to avoid full-Transform scans in large static scenes.
  let roots : @ecs.Query[
    (
      @ecs.Comp[@hierarchy.Children],
      @ecs.Comp[Transform],
      @ecs.Comp[GlobalTransform],
    ),
    @ecs.Without[@hierarchy.Parent],
  ] = @ecs.query_filtered(world, @ecs.Without::new(@hierarchy.ecs_key_parent))
  try! roots.for_each(fn(entity, root_data) {
    let (children, root_transform, root_global) = root_data
    if static_optimizations.enabled {
      let root_tree_changed = transform_set_contains(tree_changed, entity)
      if !root_tree_changed {
        return
      }
    }
    let root_changed = if static_optimizations.enabled {
      transform_set_contains(transform_changed, entity) ||
      transform_set_contains(global_added, entity) ||
      orphaned_roots.contains(transform_entity_key(entity))
    } else {
      true
    }
    let next_root_global = if root_changed {
      GlobalTransform::from_transform(root_transform.value())
    } else {
      root_global.value()
    }
    if root_changed &&
      !global_transform_eq(root_global.value(), next_root_global) {
      try! (world.replace(entity, ecs_key_global_transform, next_root_global)
      |> ignore)
    }
    propagate_descendants(
      world,
      entity,
      next_root_global,
      children.value(),
      static_optimizations.enabled,
      transform_changed,
      global_added,
      parent_changed,
      tree_changed,
      root_changed,
    )
  })
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
