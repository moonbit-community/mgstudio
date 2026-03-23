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
type SimpleTransformChangedQuery = @ecs.Query2[Transform, GlobalTransform]

///|
type SimpleTransformOrphanQuery = @ecs.Query2[Transform, GlobalTransform]

///|
fn sort_entities_by_id(entities : Array[@core.Entity]) -> Unit {
  let mut i = 1
  while i < entities.length() {
    let current = entities[i]
    let mut j = i
    while j > 0 && entities[j - 1].id > current.id {
      entities[j] = entities[j - 1]
      j = j - 1
    }
    entities[j] = current
    i = i + 1
  }
}

///|
fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn entity_array_contains(
  entities : Array[@core.Entity],
  target : @core.Entity,
) -> Bool {
  for entity in entities {
    if entity_eq(entity, target) {
      return true
    }
  }
  false
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
  let transform_access = world.component(ecs_key_transform)
  let global_access = world.component(ecs_key_global_transform)
  let parent_access = world.component(@hierarchy.ecs_key_parent)
  let child_access = world.component(@hierarchy.ecs_key_children)
  let entities : Array[@core.Entity] = []
  global_access.for_each(fn(entity, _global) {
    if transform_access.contains(entity) &&
      !parent_access.contains(entity) &&
      !child_access.contains(entity) {
      entities.push(entity)
    }
  })
  sort_entities_by_id(entities)
  for entity in entities {
    if transform_access.get(entity) is Some(transform) {
      let next_global = GlobalTransform::from_transform(transform)
      if global_access.get(entity) is Some(current_global) {
        if !global_transform_eq(current_global, next_global) {
          global_access.set(entity, next_global) |> ignore
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
  ignore(query)
  ignore(orphaned)
  if @app.current_world() is Some(world) {
    sync_simple_transforms_apply(world)
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
  ancestors : Array[@core.Entity],
) -> Unit {
  let transform_access = world.component(ecs_key_transform)
  let global_access = world.component(ecs_key_global_transform)
  let parent_access = world.component(@hierarchy.ecs_key_parent)
  let children_access = world.component(@hierarchy.ecs_key_children)
  let child_entities = children.entities().copy()
  sort_entities_by_id(child_entities)
  for child in child_entities {
    if entity_array_contains(ancestors, child) {
      transform_abort_malformed_hierarchy()
    }
    guard parent_access.get(child) is Some(child_parent) else {
      transform_abort_malformed_hierarchy()
    }
    if !entity_eq(child_parent.entity(), parent) {
      transform_abort_malformed_hierarchy()
    }
    guard transform_access.get(child) is Some(local_transform) else { continue }
    guard global_access.get(child) is Some(current_global) else { continue }
    let next_global = parent_global.mul(
      GlobalTransform::from_transform(local_transform),
    )
    if !global_transform_eq(current_global, next_global) {
      global_access.set(child, next_global) |> ignore
    }
    if children_access.get(child) is Some(grand_children) {
      ancestors.push(child)
      propagate_descendants(
        world, child, next_global, grand_children, ancestors,
      )
      ancestors.pop() |> ignore
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let transform_access = world.component(ecs_key_transform)
  let global_access = world.component(ecs_key_global_transform)
  let parent_access = world.component(@hierarchy.ecs_key_parent)
  let children_access = world.component(@hierarchy.ecs_key_children)
  let roots : Array[@core.Entity] = []
  global_access.for_each(fn(entity, _global) {
    if transform_access.contains(entity) && !parent_access.contains(entity) {
      roots.push(entity)
    }
  })
  sort_entities_by_id(roots)
  for entity in roots {
    guard transform_access.get(entity) is Some(local_transform) else {
      continue
    }
    guard global_access.get(entity) is Some(current_global) else { continue }
    let next_global = GlobalTransform::from_transform(local_transform)
    if !global_transform_eq(current_global, next_global) {
      global_access.set(entity, next_global) |> ignore
    }
    if children_access.get(entity) is Some(children) {
      let ancestors = [entity]
      propagate_descendants(world, entity, next_global, children, ancestors)
    }
  }
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
