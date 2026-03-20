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
type SimpleTransformChangedFilter = (
  @ecs.Or[(@ecs.Changed[Transform], @ecs.Added[GlobalTransform])],
  @ecs.Without[@hierarchy.Parent],
  @ecs.Without[@hierarchy.Children],
)

///|
type SimpleTransformFilter = (
  @ecs.Without[@hierarchy.Parent],
  @ecs.Without[@hierarchy.Children],
)

///|
type SimpleTransformChangedQuery = @ecs.Query2ValueMutFiltered[
  Transform,
  GlobalTransform,
  SimpleTransformChangedFilter,
]

///|
type SimpleTransformOrphanQuery = @ecs.Query2RefMutFiltered[
  Transform,
  GlobalTransform,
  SimpleTransformFilter,
]

///|
type PropagationRootQuery = @ecs.Query3RefMutOptionalFiltered[
  Transform,
  GlobalTransform,
  @hierarchy.Children,
  @ecs.Without[@hierarchy.Parent],
]

///|
type PropagationNodeQuery = @ecs.Query3RefMutOptionalFiltered[
  Transform,
  GlobalTransform,
  @hierarchy.Children,
  @ecs.With[@hierarchy.Parent],
]

///|
type PropagationChildQuery = @ecs.Query1Filtered[
  @hierarchy.Parent,
  @ecs.With[GlobalTransform],
]

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
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn entity_array_contains(
  entities : Array[@core.Entity],
  target : @core.Entity,
) -> Bool {
  for entity in entities {
    if entity.id == target.id && entity.generation == target.generation {
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
fn[A, F] query1_iter_many_unique_ref_or_abort(
  query : @ecs.Query1Filtered[A, F],
  entities : Array[@core.Entity],
) -> @ecs.Query1FilteredManyRef[A, F] {
  try query.iter_many_unique_ref(entities) catch {
    _ => {
      transform_abort_malformed_hierarchy()
      abort("unreachable")
    }
  } noraise {
    value => value
  }
}

///|
fn[A, F : @ecs.QueryFilter] query1_fetch_next_or_abort(
  iter : @ecs.Query1FilteredManyRef[A, F],
) -> (@core.Entity, @ecs.ComponentRef[A])? {
  try iter.fetch_next() catch {
    _ => {
      transform_abort_malformed_hierarchy()
      abort("unreachable")
    }
  } noraise {
    value => value
  }
}

///|
fn[A, B, C, F : @ecs.QueryFilter] query3_get_unchecked_or_abort(
  query : @ecs.Query3RefMutOptionalFiltered[A, B, C, F],
  entity : @core.Entity,
) -> (@ecs.ComponentRef[A], @ecs.ComponentMut[B], @ecs.ComponentRef[C]?)? {
  try query.get_unchecked(entity) catch {
    _ => {
      transform_abort_malformed_hierarchy()
      abort("unreachable")
    }
  } noraise {
    value => value
  }
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
fn sync_simple_transforms_apply(
  changed_query : SimpleTransformChangedQuery,
  orphan_query : SimpleTransformOrphanQuery,
  orphaned_entities : Array[@core.Entity],
) -> Unit {
  try! changed_query
  .par_iter_mut()
  .for_each(fn(_entity, transform, global_transform) {
    global_transform.get_ref().val = GlobalTransform::from_transform(transform)
  })

  let iter = orphan_query.iter_many_mut(orphaned_entities)
  while true {
    if (try! iter.fetch_next()) is Some((_entity, transform, global_transform)) {
      if !transform.is_changed() && !global_transform.is_added() {
        global_transform.get_ref().val = GlobalTransform::from_transform(
          transform.value(),
        )
      }
    } else {
      break
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
  sync_simple_transforms_apply(query.p0(), query.p1(), orphaned.read())
}

///|
pub fn sync_simple_transforms_world(world : @ecs.World) -> Unit {
  let changed_query = world.query2_value_mut_filtered(
    ecs_key_transform,
    ecs_key_global_transform,
    (
      @ecs.Or::new(
        (
          @ecs.Changed::new(ecs_key_transform),
          @ecs.Added::new(ecs_key_global_transform),
        ),
      ),
      @ecs.Without::new(@hierarchy.ecs_key_parent),
      @ecs.Without::new(@hierarchy.ecs_key_children),
    ),
  )
  let orphan_query = world.query2_ref_mut_filtered(
    ecs_key_transform,
    ecs_key_global_transform,
    (
      @ecs.Without::new(@hierarchy.ecs_key_parent),
      @ecs.Without::new(@hierarchy.ecs_key_children),
    ),
  )
  sync_simple_transforms_apply(
    changed_query,
    orphan_query,
    world
    .removed_components(
      @hierarchy.ecs_key_parent,
      world.get_system_context().ticks(),
    )
    .read(),
  )
}

///|
pub fn mark_dirty_trees(world : @ecs.World) -> Unit {
  let changed_transforms = world.query_entities_filtered(
    @ecs.Or::new(
      (
        @ecs.Changed::new(ecs_key_transform),
        @ecs.Changed::new(@hierarchy.ecs_key_parent),
        @ecs.Added::new(ecs_key_global_transform),
      ),
    ),
  )
  let orphaned = world.removed_components(
    @hierarchy.ecs_key_parent,
    world.get_system_context().ticks(),
  )
  let tree_access = world.component(ecs_key_transform_tree_changed)
  let parent_access = world.component(@hierarchy.ecs_key_parent)
  let static_optimizations = read_static_transform_optimizations(world)
  let threshold = clamp01(static_optimizations.threshold)
  let enabled = if threshold == 0.0F {
    false
  } else if threshold == 1.0F {
    true
  } else {
    let n_dyn = Float::from_int(changed_transforms.count())
    let total = Float::from_int(tree_access.len())
    total == 0.0F || n_dyn / total <= threshold
  }
  static_optimizations.enabled = enabled
  write_static_transform_optimizations(world, static_optimizations)
  if !enabled {
    return
  }

  let entities_to_mark : Array[@core.Entity] = []
  changed_transforms.view(fn(entity) { entities_to_mark.push(entity) })
  for entity in orphaned.read() {
    entities_to_mark.push(entity)
  }

  for entity in entities_to_mark {
    let mut next = entity
    while true {
      if tree_access.get_ticks(next) is Some(tree_ticks) {
        let system = world.get_system_context().ticks()
        if tree_ticks.is_changed(system) && !tree_ticks.is_added(system) {
          break
        }
        tree_access.set(
          next,
          TransformTreeChanged::{  },
          world.read_change_tick(),
        )
        |> ignore
      } else {
        break
      }

      if parent_access.get(next) is Some(parent) {
        next = parent.entity()
      } else {
        break
      }
    }
  }
}

///|
fn propagate_descendants(
  tree_query : @ecs.Query1Filtered[TransformTreeChanged, @ecs.All],
  node_query : PropagationNodeQuery,
  child_query : PropagationChildQuery,
  parent : @core.Entity,
  parent_global_transform : GlobalTransform,
  children : @hierarchy.Children,
  parent_changed : Bool,
  static_optimizations : StaticTransformOptimizations,
) -> Unit {
  let child_iter = query1_iter_many_unique_ref_or_abort(
    child_query,
    children.entities(),
  )

  while true {
    let child_entry = query1_fetch_next_or_abort(child_iter)
    guard child_entry is Some((child, child_of)) else { break }

    if child_of.value().entity().id != parent.id ||
      child_of.value().entity().generation != parent.generation {
      transform_abort_malformed_hierarchy()
    }
    guard (try! tree_query.get_ref(child)) is Some(transform_tree) else {
      continue
    }
    if static_optimizations.enabled &&
      !transform_tree.is_changed() &&
      !parent_changed {
      continue
    }

    let node_entry = query3_get_unchecked_or_abort(node_query, child)
    guard node_entry
      is Some((local_transform, global_transform, grand_children)) else {
      continue
    }

    let changed = parent_changed ||
      child_of.is_changed() ||
      local_transform.is_changed() ||
      global_transform.is_added()
    let current_global = global_transform.get()
    let next_global = parent_global_transform.mul(
      GlobalTransform::from_transform(local_transform.value()),
    )
    if changed && !global_transform_eq(current_global, next_global) {
      global_transform.get_ref().val = next_global
    }

    if grand_children is Some(grand_children) {
      propagate_descendants(
        tree_query,
        node_query,
        child_query,
        child,
        if changed {
          next_global
        } else {
          current_global
        },
        grand_children.value(),
        changed,
        static_optimizations,
      )
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let orphaned_entities = world
    .removed_components(
      @hierarchy.ecs_key_parent,
      world.get_system_context().ticks(),
    )
    .read()
  sort_entities_by_id(orphaned_entities)

  let root_query : PropagationRootQuery = world.query3_ref_mut_optional_filtered(
    ecs_key_transform,
    ecs_key_global_transform,
    @hierarchy.ecs_key_children,
    @ecs.Without::new(@hierarchy.ecs_key_parent),
  )
  let node_query = world.query3_ref_mut_optional_filtered(
    ecs_key_transform,
    ecs_key_global_transform,
    @hierarchy.ecs_key_children,
    @ecs.With::new(@hierarchy.ecs_key_parent),
  )
  let child_query = world.query1_filtered(
    @hierarchy.ecs_key_parent,
    @ecs.With::new(ecs_key_global_transform),
  )
  let tree_query = world.query1_filtered(
    ecs_key_transform_tree_changed,
    @ecs.All::new(),
  )
  let static_optimizations = read_static_transform_optimizations(world)
  let roots : Array[@core.Entity] = []
  world
  .query_entities_filtered(@ecs.Without::new(@hierarchy.ecs_key_parent))
  .view(fn(entity) { roots.push(entity) })
  for entity in roots {
    let root_entry = query3_get_unchecked_or_abort(root_query, entity)
    guard root_entry is Some((transform, global_transform, children)) else {
      continue
    }
    guard (try! tree_query.get_ref(entity)) is Some(transform_tree) else {
      continue
    }
    if static_optimizations.enabled && !transform_tree.is_changed() {
      continue
    }

    let changed = transform.is_changed() ||
      global_transform.is_added() ||
      entity_array_contains(orphaned_entities, entity)
    let current_global = global_transform.get()
    let next_global = GlobalTransform::from_transform(transform.value())
    if changed && !global_transform_eq(current_global, next_global) {
      global_transform.get_ref().val = next_global
    }
    if children is Some(children) {
      propagate_descendants(
        tree_query,
        node_query,
        child_query,
        entity,
        if changed {
          next_global
        } else {
          current_global
        },
        children.value(),
        changed,
        static_optimizations,
      )
    }
  }
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
