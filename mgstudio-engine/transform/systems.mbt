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
priv struct TransformDenseTableCache {
  loaded : Array[Bool]
  transform_values : Array[Array[Transform]?]
  global_values : Array[Array[GlobalTransform]?]
  children_values : Array[Array[@hierarchy.Children]?]
}

///|
fn transform_dense_table_cache_default() -> TransformDenseTableCache {
  {
    loaded: [],
    transform_values: [],
    global_values: [],
    children_values: [],
  }
}

///|
fn transform_dense_entity_slot(
  world : @ecs.World,
  entity : @core.Entity,
) -> (Int, Int)? {
  let entity_id = entity.id
  guard entity_id >= 0 &&
    entity_id < world.entity_table_ids.length() &&
    entity_id < world.entity_table_rows.length() else {
    return None
  }
  let table_id = world.entity_table_ids[entity_id]
  let row_index = world.entity_table_rows[entity_id]
  if table_id < 0 || row_index < 0 {
    return None
  }
  Some((table_id, row_index))
}

///|
fn transform_dense_table_cache_prepare(
  columns : TransformPropagationColumns,
  cache : Ref[TransformDenseTableCache],
  table_id : Int,
) -> Bool {
  if table_id < 0 {
    return false
  }
  while cache.val.loaded.length() <= table_id {
    cache.val.loaded.push(false)
    cache.val.transform_values.push(None)
    cache.val.global_values.push(None)
    cache.val.children_values.push(None)
  }
  if !cache.val.loaded[table_id] {
    cache.val.transform_values[table_id] = columns.transform.table_values(table_id)
    cache.val.global_values[table_id] = columns.global.table_values(table_id)
    cache.val.children_values[table_id] = columns.children.table_values(table_id)
    cache.val.loaded[table_id] = true
  }
  cache.val.transform_values[table_id] is Some(_) &&
  cache.val.global_values[table_id] is Some(_)
}

///|
priv struct TransformPropagationScratch {
  transform_changed : Array[Bool]
  transform_changed_touched : Array[Int]
  tree_changed : Array[Bool]
  tree_changed_touched : Array[Int]
  dense_stack_entities : Array[@core.Entity]
  dense_stack_parents : Array[@core.Entity]
  dense_stack_parent_globals : Array[GlobalTransform]
  dense_stack_parent_global_changed : Array[Bool]
}

///|
fn transform_propagation_scratch_default() -> TransformPropagationScratch {
  {
    transform_changed: [],
    transform_changed_touched: [],
    tree_changed: [],
    tree_changed_touched: [],
    dense_stack_entities: [],
    dense_stack_parents: [],
    dense_stack_parent_globals: [],
    dense_stack_parent_global_changed: [],
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
fn transform_set_global_if_neq_hot_at_row(
  columns : TransformPropagationColumns,
  entity : @core.Entity,
  global_values : Array[GlobalTransform],
  row_index : Int,
  next_global : GlobalTransform,
  sequence : @core.Sequence,
) -> Bool {
  if row_index < 0 || row_index >= global_values.length() {
    return false
  }
  if global_transform_eq(global_values[row_index], next_global) {
    return false
  }
  columns.global.set_sequence_only_hot_at_row(
    entity,
    global_values,
    row_index,
    next_global,
    sequence,
  )
}

///|
fn propagate_descendants_dense(
  world : @ecs.World,
  columns : TransformPropagationColumns,
  scratch : TransformPropagationScratch,
  cache : Ref[TransformDenseTableCache],
  sequence : @core.Sequence,
  static_optimizations_enabled : Bool,
  tree_changed : Array[Bool],
  parent : @core.Entity,
  parent_global : GlobalTransform,
  parent_global_changed : Bool,
  children : @hierarchy.Children,
) -> Unit {
  scratch.dense_stack_entities.clear()
  scratch.dense_stack_parents.clear()
  scratch.dense_stack_parent_globals.clear()
  scratch.dense_stack_parent_global_changed.clear()
  let root_children = children.entities()
  for index in 0..<root_children.length() {
    let reverse_index = root_children.length() - 1 - index
    scratch.dense_stack_entities.push(root_children[reverse_index])
    scratch.dense_stack_parents.push(parent)
    scratch.dense_stack_parent_globals.push(parent_global)
    scratch.dense_stack_parent_global_changed.push(parent_global_changed)
  }
  while scratch.dense_stack_entities.length() > 0 {
    let child = match scratch.dense_stack_entities.pop() {
      Some(child) => child
      None => break
    }
    let current_parent = match scratch.dense_stack_parents.pop() {
      Some(entity) => entity
      None => break
    }
    let current_parent_global = match scratch.dense_stack_parent_globals.pop() {
      Some(global) => global
      None => break
    }
    let current_parent_global_changed = match
      scratch.dense_stack_parent_global_changed.pop() {
      Some(changed) => changed
      None => break
    }
    let child_parent = match columns.parent {
      Some(parent_column) =>
        match parent_column.get(child) {
          Some(child_parent) => child_parent
          None => continue
        }
      None => continue
    }
    if !entity_eq(child_parent.entity(), current_parent) {
      transform_abort_malformed_hierarchy()
    }
    if static_optimizations_enabled &&
      !transform_id_flags_contains(tree_changed, child) &&
      !current_parent_global_changed {
      continue
    }
    guard transform_dense_entity_slot(world, child) is Some((table_id, row_index)) else {
      continue
    }
    guard transform_dense_table_cache_prepare(columns, cache, table_id) else {
      continue
    }
    guard cache.val.transform_values[table_id] is Some(transform_values) else {
      continue
    }
    guard cache.val.global_values[table_id] is Some(global_values) else {
      continue
    }
    if row_index >= transform_values.length() ||
      row_index >= global_values.length() {
      continue
    }
    let local_transform = transform_values[row_index]
    let child_global = current_parent_global.mul_transform(local_transform)
    let child_global_changed = transform_set_global_if_neq_hot_at_row(
      columns,
      child,
      global_values,
      row_index,
      child_global,
      sequence,
    )
    let next_parent_global = if child_global_changed {
      child_global
    } else {
      global_values[row_index]
    }
    match cache.val.children_values[table_id] {
      Some(children_values) => {
        if row_index >= children_values.length() {
          continue
        }
        let grand_children = children_values[row_index]
        let grandchildren = grand_children.entities()
        for index in 0..<grandchildren.length() {
          let reverse_index = grandchildren.length() - 1 - index
          scratch.dense_stack_entities.push(grandchildren[reverse_index])
          scratch.dense_stack_parents.push(child)
          scratch.dense_stack_parent_globals.push(next_parent_global)
          scratch.dense_stack_parent_global_changed.push(child_global_changed)
        }
      }
      None => ()
    }
  }
}

///|
fn propagate_parent_transforms_dense(
  world : @ecs.World,
  columns : TransformPropagationColumns,
  static_optimizations_enabled : Bool,
  tree_changed : Array[Bool],
) -> Unit {
  guard columns.parent is Some(parent_column) else { return }
  let sequence = {
    let tick = world.read_sequence()
    if tick > 0 {
      tick
    } else {
      1
    }
  }
  let scratch_ref = transform_propagation_scratch_ref_or_init(world)
  let scratch = scratch_ref.peek()
  let cache = Ref::new(transform_dense_table_cache_default())
  columns.children.for_each_without_fast(parent_column, fn(entity, children) {
    if static_optimizations_enabled &&
      !transform_id_flags_contains(tree_changed, entity) {
      return
    }
    guard transform_dense_entity_slot(world, entity) is Some((table_id, row_index)) else {
      return
    }
    guard transform_dense_table_cache_prepare(columns, cache, table_id) else {
      return
    }
    guard cache.val.transform_values[table_id] is Some(transform_values) else {
      return
    }
    guard cache.val.global_values[table_id] is Some(global_values) else { return }
    if row_index >= transform_values.length() ||
      row_index >= global_values.length() {
      return
    }
    let root_transform = transform_values[row_index]
    let root_global = GlobalTransform::from_transform(root_transform)
    let root_global_changed = transform_set_global_if_neq_hot_at_row(
      columns,
      entity,
      global_values,
      row_index,
      root_global,
      sequence,
    )
    let next_root_global = if root_global_changed {
      root_global
    } else {
      global_values[row_index]
    }
    propagate_descendants_dense(
      world,
      columns,
      scratch,
      cache,
      sequence,
      static_optimizations_enabled,
      tree_changed,
      entity,
      next_root_global,
      root_global_changed,
      children,
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
  let changed_transform_entities = world.changed_components(
    ecs_key_transform,
    sequence,
  ).read()
  let changed_parent_entities = world.changed_components(
    @hierarchy.ecs_key_parent,
    sequence,
  ).read()
  let added_global_entities = world.added_components(
    ecs_key_global_transform,
    sequence,
  ).read()
  let orphaned_entities = world.removed_components(
    @hierarchy.ecs_key_parent,
    sequence,
  ).read()
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
  } else if threshold == 1.0F {
    static_optimizations.enabled = true
  } else {
    static_optimizations.enabled = true
    let total = Float::from_int(
      world.component_count(ecs_key_transform_tree_changed),
    )
    if total > 0.0F {
      let scratch_ref = transform_propagation_scratch_ref_or_init(world)
      let scratch = scratch_ref.peek()
      transform_id_flags_reset(
        scratch.transform_changed,
        scratch.transform_changed_touched,
      )
      for entity in changed_transform_entities {
        transform_id_flags_set_tracked(
          scratch.transform_changed,
          scratch.transform_changed_touched,
          entity,
        )
      }
      for entity in changed_parent_entities {
        transform_id_flags_set_tracked(
          scratch.transform_changed,
          scratch.transform_changed_touched,
          entity,
        )
      }
      for entity in added_global_entities {
        transform_id_flags_set_tracked(
          scratch.transform_changed,
          scratch.transform_changed_touched,
          entity,
        )
      }
      let dynamic_count = Float::from_int(scratch.transform_changed_touched.length())
      if dynamic_count / total > threshold {
        static_optimizations.enabled = false
      }
    }
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
      guard
        (try! world.get_mut(next, key=ecs_key_transform_tree_changed))
        is Some(tree_changed_mut) else {
        break
      }
      if tree_changed_mut.is_changed() && !tree_changed_mut.is_added() {
        break
      }
      tree_changed_mut.set_changed()
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
  for entity in changed_transform_entities {
    mark_tree_changed_chain(entity)
  }
  for entity in changed_parent_entities {
    mark_tree_changed_chain(entity)
  }
  for entity in added_global_entities {
    mark_tree_changed_chain(entity)
  }
  for entity in orphaned_entities {
    mark_tree_changed_chain(entity)
  }
}

pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  guard transform_propagation_columns(world) is Some(columns) else { return }
  let static_optimizations = read_static_transform_optimizations(world)
  let sequence = world.get_sequence_context().sequence()
  let tree_changed : Array[Bool] = if static_optimizations.enabled {
    let scratch_ref = transform_propagation_scratch_ref_or_init(world)
    let scratch = scratch_ref.peek()
    transform_id_flags_reset(scratch.tree_changed, scratch.tree_changed_touched)
    for
      entity in world
      .changed_components(ecs_key_transform_tree_changed, sequence)
      .read() {
      transform_id_flags_set_tracked(
        scratch.tree_changed,
        scratch.tree_changed_touched,
        entity,
      )
    }
    for
      entity in world
      .added_components(ecs_key_transform_tree_changed, sequence)
      .read() {
      transform_id_flags_set_tracked(
        scratch.tree_changed,
        scratch.tree_changed_touched,
        entity,
      )
    }
    scratch.tree_changed
  } else {
    []
  }
  propagate_parent_transforms_dense(
    world,
    columns,
    static_optimizations.enabled,
    tree_changed,
  )
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
