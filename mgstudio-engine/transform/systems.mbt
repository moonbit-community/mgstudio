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
priv struct TransformPropagationColumns {
  transform : @ecs.ComponentColumn[Transform]
  global : @ecs.ComponentColumn[GlobalTransform]
  children : @ecs.ComponentColumn[@hierarchy.Children]
  parent : @ecs.ComponentColumn[@hierarchy.Parent]?
}

///|
priv struct TransformPropagationScratch {
  transform_changed : Array[Bool]
  transform_changed_touched : Array[Int]
  global_added : Array[Bool]
  global_added_touched : Array[Int]
  parent_changed : Array[Bool]
  parent_changed_touched : Array[Int]
  tree_changed : Array[Bool]
  tree_changed_touched : Array[Int]
  orphaned_roots : Array[Bool]
  orphaned_roots_touched : Array[Int]
}

///|
fn transform_propagation_scratch_default() -> TransformPropagationScratch {
  {
    transform_changed: [],
    transform_changed_touched: [],
    global_added: [],
    global_added_touched: [],
    parent_changed: [],
    parent_changed_touched: [],
    tree_changed: [],
    tree_changed_touched: [],
    orphaned_roots: [],
    orphaned_roots_touched: [],
  }
}

///|
let ecs_key_transform_propagation_scratch : @ecs.ResourceKey[
  TransformPropagationScratch,
] = @ecs.register_resource(
  debug_name="mgstudio_transform::TransformPropagationScratch",
)

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
  if (try! world.get_resource(ecs_key_transform_propagation_scratch)) is None {
    world.insert_resource(
      ecs_key_transform_propagation_scratch,
      transform_propagation_scratch_default(),
    )
  }
}

///|
fn transform_propagation_scratch_ref_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[TransformPropagationScratch] {
  ensure_transform_runtime_resources(world)
  match (try! world.get_resource_mut(ecs_key_transform_propagation_scratch)) {
    Some(scratch_ref) => scratch_ref
    None => abort("Missing TransformPropagationScratch resource")
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
fn transform_id_flags_set_tracked(
  flags : Array[Bool],
  touched : Array[Int],
  entity : @core.Entity,
) -> Unit {
  let id = entity.id
  if id < 0 {
    return
  }
  while flags.length() <= id {
    flags.push(false)
  }
  if !flags[id] {
    flags[id] = true
    touched.push(id)
  }
}

///|
fn transform_id_flags_reset(flags : Array[Bool], touched : Array[Int]) -> Unit {
  for id in touched {
    if id >= 0 && id < flags.length() {
      flags[id] = false
    }
  }
  touched.clear()
}

///|
fn transform_id_flags_contains(
  flags : Array[Bool],
  entity : @core.Entity,
) -> Bool {
  let id = entity.id
  id >= 0 && id < flags.length() && flags[id]
}

///|
fn transform_propagation_columns(
  world : @ecs.World,
) -> TransformPropagationColumns? {
  match
    (
      world.component_column(ecs_key_transform),
      world.component_column(ecs_key_global_transform),
      world.component_column(@hierarchy.ecs_key_children),
    ) {
    (Some(transform), Some(global), Some(children)) =>
      Some({
        transform,
        global,
        children,
        parent: world.component_column(@hierarchy.ecs_key_parent),
      })
    _ => None
  }
}

///|
fn propagate_descendants_dense(
  columns : TransformPropagationColumns,
  parent_column : @ecs.ComponentColumn[@hierarchy.Parent],
  parent : @core.Entity,
  parent_global : GlobalTransform,
  children : @hierarchy.Children,
) -> Unit {
  for child in children.entities() {
    guard columns.transform.get(child) is Some(local_transform) else {
      continue
    }
    let child_parent = match parent_column.get(child) {
      Some(child_parent) => child_parent
      None => continue
    }
    if !entity_eq(child_parent.entity(), parent) {
      transform_abort_malformed_hierarchy()
    }
    let child_global = parent_global.mul_transform(local_transform)
    if !columns.global.set_sequence_only(child, child_global) {
      continue
    }
    match columns.children.get(child) {
      Some(grand_children) =>
        propagate_descendants_dense(
          columns, parent_column, child, child_global, grand_children,
        )
      None => ()
    }
  }
}

///|
fn propagate_parent_transforms_dense(
  columns : TransformPropagationColumns,
) -> Unit {
  guard columns.parent is Some(parent_column) else { return }
  columns.children.for_each(fn(entity, children) {
    if parent_column.contains(entity) {
      return
    }
    guard columns.transform.get(entity) is Some(root_transform) else { return }
    let root_global = GlobalTransform::from_transform(root_transform)
    if !columns.global.set_sequence_only(entity, root_global) {
      return
    }
    propagate_descendants_dense(
      columns, parent_column, entity, root_global, children,
    )
  })
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
  let parent_column = world.component_column(@hierarchy.ecs_key_parent)
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
      match parent_column {
        Some(parent_store) =>
          match parent_store.get(next) {
            Some(parent) => next = parent.entity()
            None => break
          }
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
  columns : TransformPropagationColumns,
  parent : @core.Entity,
  parent_global : GlobalTransform,
  children : @hierarchy.Children,
  static_optimizations_enabled : Bool,
  transform_changed : Array[Bool],
  global_added : Array[Bool],
  parent_changed : Array[Bool],
  tree_changed : Array[Bool],
  parent_global_changed : Bool,
) -> Unit {
  for child in children.entities() {
    guard columns.transform.get(child) is Some(local_transform) else {
      continue
    }
    let child_parent = match columns.parent {
      Some(parent_column) =>
        match parent_column.get(child) {
          Some(child_parent) => child_parent
          None => continue
        }
      None => continue
    }
    if !entity_eq(child_parent.entity(), parent) {
      transform_abort_malformed_hierarchy()
    }
    if static_optimizations_enabled {
      let child_tree_changed = transform_id_flags_contains(tree_changed, child)
      if !child_tree_changed && !parent_global_changed {
        continue
      }
    }
    let child_changed = parent_global_changed ||
      transform_id_flags_contains(transform_changed, child) ||
      transform_id_flags_contains(global_added, child) ||
      transform_id_flags_contains(parent_changed, child)
    let next_global = if child_changed {
      let computed = parent_global.mul_transform(local_transform)
      if !columns.global.set_sequence_only(child, computed) {
        continue
      }
      computed
    } else {
      guard columns.global.get(child) is Some(current_global) else { continue }
      current_global
    }
    match columns.children.get(child) {
      Some(grand_children) =>
        propagate_descendants(
          columns, child, next_global, grand_children, static_optimizations_enabled,
          transform_changed, global_added, parent_changed, tree_changed, child_changed,
        )
      None => ()
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let sequence = world.get_sequence_context().sequence()
  let static_optimizations = read_static_transform_optimizations(world)
  let transform_changed_entities = world
    .changed_components(ecs_key_transform, sequence)
    .read()
  if !static_optimizations.enabled && transform_changed_entities.length() >= 256 {
    guard transform_propagation_columns(world) is Some(columns) else { return }
    propagate_parent_transforms_dense(columns)
    return
  }
  let scratch_ref = transform_propagation_scratch_ref_or_init(world)
  let scratch = scratch_ref.peek()
  transform_id_flags_reset(
    scratch.transform_changed,
    scratch.transform_changed_touched,
  )
  transform_id_flags_reset(scratch.global_added, scratch.global_added_touched)
  transform_id_flags_reset(
    scratch.parent_changed,
    scratch.parent_changed_touched,
  )
  transform_id_flags_reset(scratch.tree_changed, scratch.tree_changed_touched)
  transform_id_flags_reset(
    scratch.orphaned_roots,
    scratch.orphaned_roots_touched,
  )

  let transform_changed = scratch.transform_changed
  let global_added = scratch.global_added
  let parent_changed = scratch.parent_changed
  let tree_changed = scratch.tree_changed
  let orphaned_roots = scratch.orphaned_roots
  for entity in transform_changed_entities {
    transform_id_flags_set_tracked(
      transform_changed,
      scratch.transform_changed_touched,
      entity,
    )
  }
  for
    entity in world.added_components(ecs_key_global_transform, sequence).read() {
    transform_id_flags_set_tracked(
      global_added,
      scratch.global_added_touched,
      entity,
    )
  }
  for
    entity in world
    .changed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    transform_id_flags_set_tracked(
      parent_changed,
      scratch.parent_changed_touched,
      entity,
    )
  }
  for
    entity in world.added_components(@hierarchy.ecs_key_parent, sequence).read() {
    transform_id_flags_set_tracked(
      parent_changed,
      scratch.parent_changed_touched,
      entity,
    )
  }
  if static_optimizations.enabled {
    for
      entity in world
      .changed_components(ecs_key_transform_tree_changed, sequence)
      .read() {
      transform_id_flags_set_tracked(
        tree_changed,
        scratch.tree_changed_touched,
        entity,
      )
    }
    for
      entity in world
      .added_components(ecs_key_transform_tree_changed, sequence)
      .read() {
      transform_id_flags_set_tracked(
        tree_changed,
        scratch.tree_changed_touched,
        entity,
      )
    }
  }
  for
    entity in world
    .removed_components(@hierarchy.ecs_key_parent, sequence)
    .read() {
    if !world.is_alive(entity) {
      continue
    }
    transform_id_flags_set_tracked(
      orphaned_roots,
      scratch.orphaned_roots_touched,
      entity,
    )
  }
  guard transform_propagation_columns(world) is Some(columns) else { return }
  columns.children.for_each(fn(entity, children) {
    if columns.parent is Some(parent_column) && parent_column.contains(entity) {
      return
    }
    guard columns.transform.get(entity) is Some(root_transform) else { return }
    if static_optimizations.enabled {
      let root_tree_changed = transform_id_flags_contains(tree_changed, entity)
      if !root_tree_changed {
        return
      }
    }
    let root_changed = transform_id_flags_contains(transform_changed, entity) ||
      transform_id_flags_contains(global_added, entity) ||
      transform_id_flags_contains(orphaned_roots, entity)
    let next_root_global = if root_changed {
      let computed = GlobalTransform::from_transform(root_transform)
      if !columns.global.set_sequence_only(entity, computed) {
        return
      }
      computed
    } else {
      guard columns.global.get(entity) is Some(current_root_global) else {
        return
      }
      current_root_global
    }
    propagate_descendants(
      columns,
      entity,
      next_root_global,
      children,
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
