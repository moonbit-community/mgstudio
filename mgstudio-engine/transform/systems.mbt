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
priv struct TransformPropagationColumns {
  transform : @ecs.ComponentColumn[Transform]
  global : @ecs.ComponentColumn[GlobalTransform]
  tree_changed : @ecs.ComponentColumn[TransformTreeChanged]
  children : @ecs.ComponentColumn[@hierarchy.Children]
  parent : @ecs.ComponentColumn[@hierarchy.Parent]?
}

///|
priv struct TransformDenseTableCache {
  loaded : Array[Bool]
  transform_values : Array[Array[Transform]?]
  global_values : Array[Array[GlobalTransform]?]
  children_values : Array[Array[@hierarchy.Children]?]
  parent_values : Array[Array[@hierarchy.Parent]?]
}

///|
fn transform_dense_table_cache_default() -> TransformDenseTableCache {
  {
    loaded: [],
    transform_values: [],
    global_values: [],
    children_values: [],
    parent_values: [],
  }
}

///|
fn transform_dense_table_cache_reset(
  cache : Ref[TransformDenseTableCache],
) -> Unit {
  for table_id in 0..<cache.val.loaded.length() {
    cache.val.loaded[table_id] = false
    cache.val.transform_values[table_id] = None
    cache.val.global_values[table_id] = None
    cache.val.children_values[table_id] = None
    cache.val.parent_values[table_id] = None
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
    cache.val.parent_values.push(None)
  }
  if !cache.val.loaded[table_id] {
    cache.val.transform_values[table_id] = columns.transform.table_values(
      table_id,
    )
    cache.val.global_values[table_id] = columns.global.table_values(table_id)
    cache.val.children_values[table_id] = columns.children.table_values(
      table_id,
    )
    cache.val.parent_values[table_id] = match columns.parent {
      Some(parent_column) => parent_column.table_values(table_id)
      None => None
    }
    cache.val.loaded[table_id] = true
  }
  cache.val.transform_values[table_id] is Some(_) &&
  cache.val.global_values[table_id] is Some(_)
}

///|
priv struct TransformPropagationScratch {
  dense_stack_entities : Array[@core.Entity]
  dense_stack_parents : Array[@core.Entity]
  dense_stack_parent_globals : Array[GlobalTransform]
  dense_stack_parent_global_changed : Array[Bool]
  dense_table_cache : TransformDenseTableCache
}

///|
fn transform_propagation_scratch_default() -> TransformPropagationScratch {
  {
    dense_stack_entities: [],
    dense_stack_parents: [],
    dense_stack_parent_globals: [],
    dense_stack_parent_global_changed: [],
    dense_table_cache: transform_dense_table_cache_default(),
  }
}

///|
let ecs_key_transform_propagation_scratch : @ecs.ResourceKey[
  TransformPropagationScratch,
] = @ecs.register_resource(
  debug_name="mgstudio_transform::TransformPropagationScratch",
)

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
  if (try! world.get_resource(ecs_key_transform_propagation_scratch)) is None {
    world.insert_resource(
      ecs_key_transform_propagation_scratch,
      transform_propagation_scratch_default(),
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
  for entity in orphaned {
    match (query.get(entity) catch { _ => None }) {
      Some((transform, global_transform)) =>
        if !transform.is_changed() && !global_transform.is_added() {
          global_transform.set(
            GlobalTransform::from_transform(transform.value()),
          )
        }
      None => ()
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
    world
    .removed_components(
      @hierarchy.ecs_key_parent,
      world.get_sequence_context().sequence(),
    )
    .read(),
  )
}

///|
pub fn sync_simple_transforms(
  query : @app.ParamSet2[
    SimpleTransformChangedQuery,
    SimpleTransformOrphanQuery,
  ],
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
    guard (parents.get(next) catch { _ => None }) is Some(parent) else { break }
    next = parent.value().entity()
  }
}

///|
fn mark_dirty_trees_enabled_state(
  static_optimizations : StaticTransformOptimizations,
  dynamic_count : () -> Int,
  total : () -> Int,
) -> StaticTransformOptimizations {
  let threshold = clamp_static_transform_threshold(
    static_optimizations.threshold,
  )
  if threshold == 0.0F {
    static_optimizations.enabled = false
  } else if threshold == 1.0F {
    static_optimizations.enabled = true
  } else {
    static_optimizations.enabled = true
    let total_count = total()
    if total_count > 0 {
      if Float::from_int(dynamic_count()) / Float::from_int(total_count) >
        threshold {
        static_optimizations.enabled = false
      }
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
    fn() { changed_transforms.count() },
    fn() { transforms.count() },
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
  let orphaned_entities = world
    .removed_components(
      @hierarchy.ecs_key_parent,
      world.get_sequence_context().sequence(),
    )
    .read()
  let transforms : TransformTreeChangedMutQuery = @ecs.query(world)
  let parents : TransformParentQuery = @ecs.query(world)

  let static_optimizations = mark_dirty_trees_enabled_state(
    read_static_transform_optimizations(world),
    fn() { changed_transforms.count() },
    fn() { transforms.count() },
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
fn transform_propagation_columns(
  world : @ecs.World,
) -> TransformPropagationColumns? {
  match
    (
      world.component_column(ecs_key_transform),
      world.component_column(ecs_key_global_transform),
      world.component_column(ecs_key_transform_tree_changed),
      world.component_column(@hierarchy.ecs_key_children),
    ) {
    (Some(transform), Some(global), Some(tree_changed), Some(children)) =>
      Some({
        transform,
        global,
        tree_changed,
        children,
        parent: world.component_column(@hierarchy.ecs_key_parent),
      })
    _ => None
  }
}

///|
fn transform_set_global_hot_at_row(
  columns : TransformPropagationColumns,
  table_id : Int,
  global_values : Array[GlobalTransform],
  row_index : Int,
  next_global : GlobalTransform,
  sequence : @core.Sequence,
) -> Bool {
  if row_index < 0 || row_index >= global_values.length() {
    return false
  }
  global_values[row_index] = next_global
  columns.global.record_changed_hot_at_table_row(table_id, row_index, sequence)
}

///|
fn propagate_descendants_dense(
  _world : @ecs.World,
  columns : TransformPropagationColumns,
  scratch : TransformPropagationScratch,
  cache : Ref[TransformDenseTableCache],
  sequence : @core.Sequence,
  static_optimizations_enabled : Bool,
  system_sequence : @core.SystemSequence,
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
    guard transform_dense_entity_slot(_world, child)
      is Some((table_id, row_index)) else {
      continue
    }
    if static_optimizations_enabled &&
      !columns.tree_changed.table_is_changed_at_row(
        table_id, row_index, system_sequence,
      ) &&
      !current_parent_global_changed {
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
    guard cache.val.parent_values[table_id] is Some(parent_values) else {
      continue
    }
    if row_index >= transform_values.length() ||
      row_index >= global_values.length() ||
      row_index >= parent_values.length() {
      continue
    }
    if !entity_eq(parent_values[row_index].entity(), current_parent) {
      transform_abort_malformed_hierarchy()
    }
    let local_transform = transform_values[row_index]
    let child_global = current_parent_global.mul_transform(local_transform)
    let child_global_changed = transform_set_global_hot_at_row(
      columns, table_id, global_values, row_index, child_global, sequence,
    )
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
          scratch.dense_stack_parent_globals.push(child_global)
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
  let system_sequence = world.get_sequence_context().sequence()
  let scratch_ref = transform_propagation_scratch_ref_or_init(world)
  let scratch = scratch_ref.peek()
  let cache = Ref::new(scratch.dense_table_cache)
  transform_dense_table_cache_reset(cache)
  columns.children.for_each_without_fast(parent_column, fn(entity, children) {
    guard transform_dense_entity_slot(world, entity)
      is Some((table_id, row_index)) else {
      return
    }
    if static_optimizations_enabled &&
      !columns.tree_changed.table_is_changed_at_row(
        table_id, row_index, system_sequence,
      ) {
      return
    }
    guard transform_dense_table_cache_prepare(columns, cache, table_id) else {
      return
    }
    guard cache.val.transform_values[table_id] is Some(transform_values) else {
      return
    }
    guard cache.val.global_values[table_id] is Some(global_values) else {
      return
    }
    if row_index >= transform_values.length() ||
      row_index >= global_values.length() {
      return
    }
    let root_transform = transform_values[row_index]
    let root_global = GlobalTransform::from_transform(root_transform)
    let root_global_changed = transform_set_global_hot_at_row(
      columns, table_id, global_values, row_index, root_global, sequence,
    )
    propagate_descendants_dense(
      world, columns, scratch, cache, sequence, static_optimizations_enabled, system_sequence,
      entity, root_global, root_global_changed, children,
    )
  })
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  guard transform_propagation_columns(world) is Some(columns) else { return }
  let static_optimizations = read_static_transform_optimizations(world)
  propagate_parent_transforms_dense(
    world,
    columns,
    static_optimizations.enabled,
  )
}

///|
pub fn propagate_parent_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
