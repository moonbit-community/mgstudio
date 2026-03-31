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
fn ensure_transform_runtime_resources(world : @ecs.World) -> Unit {
  let key = static_transform_optimizations_resource_key()
  if !world.resource(key).is_present() {
    world.insert_resource(key, StaticTransformOptimizations::disabled())
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
  let entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_global_transform, fn(entity, _global) {
    if (try! world.contains_by_key(entity, ecs_key_transform)) &&
      !(try! world.contains_by_key(entity, @hierarchy.ecs_key_parent)) &&
      !(try! world.contains_by_key(entity, @hierarchy.ecs_key_children)) {
      entities.push(entity)
    }
  })
  for entity in entities {
    if (try! world.get_by_key(entity, ecs_key_transform)) is Some(transform) {
      let next_global = GlobalTransform::from_transform(transform)
      if (try! world.get_by_key(entity, ecs_key_global_transform))
        is Some(current_global) {
        if !global_transform_eq(current_global, next_global) {
          try! (world.replace(entity, ecs_key_global_transform, next_global)
          |> ignore)
        }
      }
    }
  }
}

///|
pub fn sync_simple_transforms(
  query : @app.ParamSet2[
    SimpleTransformChangedQuery,
    SimpleTransformOrphanQuery,
  ],
  orphaned : @ecs.RemovedComponents[@hierarchy.Parent],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }

  fn sync_entity_if_needed(
    world : @ecs.World,
    transform : @ecs.Comp[Transform],
    global : @ecs.Comp[GlobalTransform],
    entity : @core.Entity,
  ) -> Unit {
    let next_global = GlobalTransform::from_transform(transform.value())
    if !global_transform_eq(global.value(), next_global) {
      try! (world.replace(entity, ecs_key_global_transform, next_global)
      |> ignore)
    }
  }

  let changed = query.p0()
  try! changed.for_each(fn(entity, data) {
    let (transform, global) = data
    sync_entity_if_needed(world, transform, global, entity)
  })

  if orphaned.is_empty() {
    return
  }
  let orphan_query = query.p1()
  for entity in orphaned.read() {
    if (orphan_query.get(entity) catch { _ => None })
      is Some((transform, global)) {
      sync_entity_if_needed(world, transform, global, entity)
    }
  }
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
    if !global_transform_eq(current_global, next_global) {
      try! (world.replace(child, ecs_key_global_transform, next_global)
      |> ignore)
    }
    if (try! world.get_by_key(child, @hierarchy.ecs_key_children))
      is Some(grand_children) {
      propagate_descendants(world, child, next_global, grand_children)
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let roots : Array[@core.Entity] = []
  world.for_each_component(ecs_key_global_transform, fn(entity, _global) {
    if (try! world.contains_by_key(entity, ecs_key_transform)) &&
      !(try! world.contains_by_key(entity, @hierarchy.ecs_key_parent)) {
      roots.push(entity)
    }
  })
  for entity in roots {
    guard (try! world.get_by_key(entity, ecs_key_transform))
      is Some(local_transform) else {
      continue
    }
    guard (try! world.get_by_key(entity, ecs_key_global_transform))
      is Some(current_global) else {
      continue
    }
    let next_global = GlobalTransform::from_transform(local_transform)
    if !global_transform_eq(current_global, next_global) {
      try! (world.replace(entity, ecs_key_global_transform, next_global)
      |> ignore)
    }
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      propagate_descendants(world, entity, next_global, children)
    }
  }
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
