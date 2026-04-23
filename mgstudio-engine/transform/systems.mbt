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
  (@ecs.Comp[Transform], @ecs.Mut[GlobalTransform]),
  (
    @ecs.Without[@hierarchy.Parent],
    @ecs.Without[@hierarchy.Children],
    @ecs.Or[(@ecs.Changed[Transform], @ecs.Added[GlobalTransform])],
  ),
]

///|
type SimpleTransformOrphanQuery = @ecs.Query[
  (@ecs.Comp[Transform], @ecs.Mut[GlobalTransform]),
  (@ecs.Without[@hierarchy.Parent], @ecs.Without[@hierarchy.Children]),
]

///|
type TransformDirtyTriggerQuery = @ecs.Query[
  @core.Entity,
  @ecs.Or[
    (
      @ecs.Changed[Transform],
      @ecs.Changed[@hierarchy.Parent],
      @ecs.Added[GlobalTransform],
    ),
  ],
]

///|
type TransformTreeChangedMutQuery = @ecs.Query[
  @ecs.Mut[TransformTreeChanged],
  @ecs.All,
]

///|
type TransformParentQuery = @ecs.Query[@ecs.Comp[@hierarchy.Parent], @ecs.All]

///|
type PropagateRootQuery = @ecs.Query[
  (@ecs.Comp[@hierarchy.Children], @ecs.Comp[Transform], @ecs.Mut[GlobalTransform]),
  @ecs.Without[@hierarchy.Parent],
]

///|
type PropagateNodeQuery = @ecs.Query[
  (
    @ecs.Comp[@hierarchy.Parent],
    @ecs.Comp[Transform],
    @ecs.Mut[GlobalTransform],
    @ecs.Comp[@hierarchy.Children]?,
  ),
  @ecs.With[GlobalTransform],
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
fn vec3_eq(a : @math.Vec3, b : @math.Vec3) -> Bool {
  a.x == b.x && a.y == b.y && a.z == b.z
}

///|
fn mat3_eq(a : @math.Mat3, b : @math.Mat3) -> Bool {
  vec3_eq(a.x_axis, b.x_axis) &&
  vec3_eq(a.y_axis, b.y_axis) &&
  vec3_eq(a.z_axis, b.z_axis)
}

///|
fn affine3_eq(a : @math.Affine3, b : @math.Affine3) -> Bool {
  mat3_eq(a.matrix3, b.matrix3) && vec3_eq(a.translation, b.translation)
}

///|
fn global_transform_eq(a : GlobalTransform, b : GlobalTransform) -> Bool {
  affine3_eq(a.affine(), b.affine())
}

///|
fn transform_set_global_if_neq_mut(
  global_transform : @ecs.Mut[GlobalTransform],
  next_global : GlobalTransform,
) -> Bool {
  if global_transform_eq(global_transform.peek(), next_global) {
    false
  } else {
    global_transform.set(next_global)
    true
  }
}

///|
fn sync_simple_transforms_changed(query : SimpleTransformChangedQuery) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (transform, global_transform) = data
    global_transform.set(GlobalTransform::from_transform(transform.value()))
  })
}

///|
fn sync_simple_transforms_orphaned(
  query : SimpleTransformOrphanQuery,
  orphaned : Array[@core.Entity],
) -> Unit {
  let iter = query.iter_many(orphaned)
  while true {
    match (try! iter.fetch_next()) {
      Some((_entity, data)) => {
        let (transform, global_transform) = data
        if !transform.is_changed() && !global_transform.is_added() {
          global_transform.set(GlobalTransform::from_transform(transform.value()))
        }
      }
      None => break
    }
  }
}

///|
fn sync_simple_transforms_apply(world : @ecs.World) -> Unit {
  let changed_query : SimpleTransformChangedQuery = @ecs.query_filtered(
    world,
    (
      @ecs.Without::new(@hierarchy.ecs_key_parent),
      @ecs.Without::new(@hierarchy.ecs_key_children),
      @ecs.Or::new(
        (
          @ecs.Changed::new(ecs_key_transform),
          @ecs.Added::new(ecs_key_global_transform),
        ),
      ),
    ),
  )
  let orphan_query : SimpleTransformOrphanQuery = @ecs.query_filtered(
    world,
    (
      @ecs.Without::new(@hierarchy.ecs_key_parent),
      @ecs.Without::new(@hierarchy.ecs_key_children),
    ),
  )
  sync_simple_transforms_changed(changed_query)
  sync_simple_transforms_orphaned(
    orphan_query,
    world.removed_components(
      @hierarchy.ecs_key_parent,
      world.get_sequence_context().sequence(),
    ).read(),
  )
}

///|
pub fn sync_simple_transforms(
  query : @app.ParamSet2[SimpleTransformChangedQuery, SimpleTransformOrphanQuery],
  orphaned : @ecs.RemovedComponents[@hierarchy.Parent],
) -> Unit {
  sync_simple_transforms_changed(query.p0())
  sync_simple_transforms_orphaned(query.p1(), orphaned.read())
}

///|
pub fn sync_simple_transforms_world(world : @ecs.World) -> Unit {
  sync_simple_transforms_apply(world)
}

///|
fn clamp_static_transform_threshold(threshold : Float) -> Float {
  if threshold < 0.0F {
    0.0F
  } else if threshold > 1.0F {
    1.0F
  } else {
    threshold
  }
}

///|
fn entity_sort_compare(left : @core.Entity, right : @core.Entity) -> Int {
  if left.id < right.id {
    -1
  } else if left.id > right.id {
    1
  } else if left.generation < right.generation {
    -1
  } else if left.generation > right.generation {
    1
  } else {
    0
  }
}

///|
fn entity_sort_unstable_for_lookup(entities : Array[@core.Entity]) -> Unit {
  entities.sort_by(entity_sort_compare)
}

///|
fn entity_binary_search(
  entities : Array[@core.Entity],
  target : @core.Entity,
) -> Bool {
  let mut left = 0
  let mut right = entities.length()
  while left < right {
    let mid = left + (right - left) / 2
    let order = entity_sort_compare(entities[mid], target)
    if order < 0 {
      left = mid + 1
    } else if order > 0 {
      right = mid
    } else {
      return true
    }
  }
  false
}

///|
fn mark_dirty_tree_chain(
  transforms : TransformTreeChangedMutQuery,
  parents : TransformParentQuery,
  start : @core.Entity,
) -> Unit {
  let mut next = start
  while true {
    guard (transforms.get(next) catch { _ => None }) is Some(tree_changed) else {
      break
    }
    if tree_changed.is_changed() && !tree_changed.is_added() {
      break
    }
    tree_changed.set_changed()
    guard (parents.get(next) catch { _ => None }) is Some(parent) else {
      break
    }
    next = parent.value().entity()
  }
}

///|
fn mark_dirty_trees_enabled_state(
  static_optimizations : StaticTransformOptimizations,
  dynamic_count : Int,
  total : Int,
) -> StaticTransformOptimizations {
  let threshold = clamp_static_transform_threshold(static_optimizations.threshold)
  if threshold == 0.0F {
    static_optimizations.enabled = false
  } else if threshold == 1.0F {
    static_optimizations.enabled = true
  } else {
    static_optimizations.enabled = true
    if Float::from_int(dynamic_count) / Float::from_int(total) > threshold {
      static_optimizations.enabled = false
    }
  }
  static_optimizations
}

///|
pub fn mark_dirty_trees_system(
  changed_transforms : TransformDirtyTriggerQuery,
  orphaned : @ecs.RemovedComponents[@hierarchy.Parent],
  query_set : @app.ParamSet2[TransformTreeChangedMutQuery, TransformParentQuery],
  static_optimizations_ref : @app.ResMut[StaticTransformOptimizations],
) -> Unit {
  let transforms = query_set.p0()
  let parents = query_set.p1()
  let static_optimizations = mark_dirty_trees_enabled_state(
    static_optimizations_ref.peek(),
    changed_transforms.count(),
    transforms.count(),
  )
  ignore(static_optimizations_ref.set_if_neq(static_optimizations))
  if !static_optimizations.enabled {
    return
  }

  try! changed_transforms.for_each(fn(_entity, changed_entity) {
    mark_dirty_tree_chain(transforms, parents, changed_entity)
  })
  for entity in orphaned.read() {
    mark_dirty_tree_chain(transforms, parents, entity)
  }
}

///|
pub fn mark_dirty_trees(world : @ecs.World) -> Unit {
  let changed_transforms : TransformDirtyTriggerQuery = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.Changed::new(ecs_key_transform),
        @ecs.Changed::new(@hierarchy.ecs_key_parent),
        @ecs.Added::new(ecs_key_global_transform),
      ),
    ),
  )
  let orphaned_entities = world.removed_components(
    @hierarchy.ecs_key_parent,
    world.get_sequence_context().sequence(),
  ).read()
  let transforms : TransformTreeChangedMutQuery = @ecs.query(world)
  let parents : TransformParentQuery = @ecs.query(world)

  let static_optimizations = mark_dirty_trees_enabled_state(
    read_static_transform_optimizations(world),
    changed_transforms.count(),
    transforms.count(),
  )
  write_static_transform_optimizations(world, static_optimizations)
  if !static_optimizations.enabled {
    return
  }

  try! changed_transforms.for_each(fn(_entity, changed_entity) {
    mark_dirty_tree_chain(transforms, parents, changed_entity)
  })
  for entity in orphaned_entities {
    mark_dirty_tree_chain(transforms, parents, entity)
  }
}

///|
fn propagate_recursive_iter_many(
  parent : @core.Entity,
  parent_global : GlobalTransform,
  nodes : PropagateNodeQuery,
  children : @hierarchy.Children,
  parent_changed : Bool,
) -> Unit {
  let iter = nodes.iter_many(children.entities())
  while true {
    match (try! iter.fetch_next()) {
      Some((child, data)) => {
        let (child_of, transform, global_transform, child_children) = data
        if !entity_eq(child_of.value().entity(), parent) {
          transform_abort_malformed_hierarchy()
        }

        let mut changed = parent_changed || child_of.is_changed()
        changed = changed || transform.is_changed() || global_transform.is_added()

        let next_global = if changed {
          let next = parent_global.mul_transform(transform.value())
          ignore(transform_set_global_if_neq_mut(global_transform, next))
          next
        } else {
          global_transform.peek()
        }

        match child_children {
          Some(grand_children) =>
            propagate_recursive_iter_many(
              child,
              next_global,
              nodes,
              grand_children.value(),
              changed,
            )
          None => ()
        }
      }
      None => break
    }
  }
}

///|
fn propagate_parent_transforms_impl(
  roots : PropagateRootQuery,
  nodes : PropagateNodeQuery,
  orphaned_entities : Array[@core.Entity],
) -> Unit {
  try! roots.for_each(fn(root, data) {
    let (children, transform, global_transform) = data
    let mut changed = transform.is_changed() || global_transform.is_added()
    if entity_binary_search(orphaned_entities, root) {
      changed = true
    }

    let root_global = if changed {
      let next = GlobalTransform::from_transform(transform.value())
      ignore(transform_set_global_if_neq_mut(global_transform, next))
      next
    } else {
      global_transform.peek()
    }

    propagate_recursive_iter_many(
      root,
      root_global,
      nodes,
      children.value(),
      changed,
    )
  })
}

///|
pub fn propagate_parent_transforms_system(
  roots : PropagateRootQuery,
  orphaned : @ecs.RemovedComponents[@hierarchy.Parent],
  nodes : PropagateNodeQuery,
  orphaned_entities_local : @app.Local[Array[@core.Entity]],
) -> Unit {
  let orphaned_entities_ref = orphaned_entities_local.get_ref()
  orphaned_entities_ref.val.clear()
  for entity in orphaned.read() {
    orphaned_entities_ref.val.push(entity)
  }
  entity_sort_unstable_for_lookup(orphaned_entities_ref.val)
  propagate_parent_transforms_impl(
    roots,
    nodes,
    orphaned_entities_ref.val,
  )
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let roots : PropagateRootQuery = @ecs.query_filtered(
    world,
    @ecs.Without::new(@hierarchy.ecs_key_parent),
  )
  let nodes : PropagateNodeQuery = @ecs.query_filtered(
    world,
    @ecs.With::new(ecs_key_global_transform),
  )
  let orphaned_entities = world.removed_components(
    @hierarchy.ecs_key_parent,
    world.get_sequence_context().sequence(),
  ).read()
  let orphaned_sorted : Array[@core.Entity] = []
  for entity in orphaned_entities {
    orphaned_sorted.push(entity)
  }
  entity_sort_unstable_for_lookup(orphaned_sorted)
  propagate_parent_transforms_impl(roots, nodes, orphaned_sorted)
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
