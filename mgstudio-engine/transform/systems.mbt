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
  (@ecs.ReadValue[Transform], @ecs.Write[GlobalTransform]),
  (
    @ecs.Without[@hierarchy.Parent],
    @ecs.Without[@hierarchy.Children],
    @ecs.Or[(@ecs.Changed[Transform], @ecs.Added[GlobalTransform])],
  ),
]

///|
type SimpleTransformOrphanQuery = @ecs.Query[
  (@ecs.Read[Transform], @ecs.Write[GlobalTransform]),
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
  @ecs.Write[TransformTreeChanged],
  @ecs.All,
]

///|
type TransformParentQuery = @ecs.Query[@ecs.Read[@hierarchy.Parent], @ecs.All]

///|
priv struct TransformPropagationColumns {
  transform : @ecs.ComponentColumn[Transform]
  global : @ecs.ComponentColumn[GlobalTransform]
  tree_changed : @ecs.ComponentColumn[TransformTreeChanged]
  children : @ecs.ComponentColumn[@hierarchy.Children]
  parent : @ecs.ComponentColumn[@hierarchy.Parent]?
}

///|
fn transform_dense_entity_slot(
  world : @ecs.World,
  entity : @core.Entity,
) -> (Int, Int)? {
  world.entity_table_location(entity)
}

///|
priv struct TransformPropagationStackItem {
  entity : @core.Entity
  table_id : Int
  row_index : Int
  parent : @core.Entity
  parent_global : GlobalTransform
  parent_global_changed : Bool
}

///|
priv struct TransformPropagationTableColumns {
  transform : @ecs.ComponentTableColumn[Transform]?
  global : @ecs.ComponentTableColumn[GlobalTransform]?
  tree_changed : @ecs.ComponentTableColumn[TransformTreeChanged]?
  children : @ecs.ComponentTableColumn[@hierarchy.Children]?
  parent : @ecs.ComponentTableColumn[@hierarchy.Parent]?
}

///|
priv struct TransformPropagationNode {
  transform : Transform
  global : GlobalTransform
  tree_changed_column : @ecs.ComponentTableColumn[TransformTreeChanged]?
  children : @hierarchy.Children?
  parent : @hierarchy.Parent?
}

///|
priv struct TransformPropagationScratch {
  dense_stack : Array[TransformPropagationStackItem]
  table_columns : Array[TransformPropagationTableColumns?]
}

///|
fn transform_propagation_scratch_default() -> TransformPropagationScratch {
  { dense_stack: [], table_columns: [] }
}

///|
fn transform_propagation_table_columns(
  columns : TransformPropagationColumns,
  scratch : TransformPropagationScratch,
  table_id : Int,
) -> TransformPropagationTableColumns? {
  guard table_id >= 0 else { return None }
  while scratch.table_columns.length() <= table_id {
    scratch.table_columns.push(None)
  }
  match scratch.table_columns[table_id] {
    Some(table_columns) => Some(table_columns)
    None => {
      let table_columns = TransformPropagationTableColumns::{
        transform: columns.transform.table_column(table_id),
        global: columns.global.table_column(table_id),
        tree_changed: columns.tree_changed.table_column(table_id),
        children: columns.children.table_column(table_id),
        parent: match columns.parent {
          Some(parent_column) => parent_column.table_column(table_id)
          None => None
        },
      }
      scratch.table_columns[table_id] = Some(table_columns)
      Some(table_columns)
    }
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
  match world.get_resource_mut(ecs_key_transform_propagation_scratch) {
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
  let key = static_transform_optimizations_resource_key
  if !world.resource(key).is_present() {
    world.insert_resource(
      key,
      StaticTransformOptimizations::StaticTransformOptimizations(),
    )
  }
  if world.get_resource(ecs_key_transform_propagation_scratch) is None {
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
  .resource(static_transform_optimizations_resource_key)
  .get()
  .unwrap_or(StaticTransformOptimizations::StaticTransformOptimizations())
}

///|
fn sync_simple_transforms_changed(query : SimpleTransformChangedQuery) -> Unit {
  let used_batch = try! query.try_for_each_filtered_table(fn(batch, rows) {
    let transforms = batch.read(ecs_key_transform).unwrap()
    let global_transforms = batch.write(ecs_key_global_transform).unwrap()
    try! rows.for_each(fn(row_index) {
      global_transforms.set(
        row_index,
        GlobalTransform::from_transform(transforms.value(row_index)),
      )
    })
  })
  if !used_batch {
    try! query.for_each(fn(_entity, data) {
      let (transform, global_transform) = data
      global_transform.set(GlobalTransform::from_transform(transform.value()))
    })
  }
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
      world.get_tick_context().ticks(),
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
pub fn mark_dirty_trees_system(
  changed_transforms : TransformDirtyTriggerQuery,
  orphaned : @ecs.RemovedComponents[@hierarchy.Parent],
  query_set : @app.ParamSet2[TransformTreeChangedMutQuery, TransformParentQuery],
  static_optimizations : @app.Res[StaticTransformOptimizations],
) -> Unit {
  if !static_optimizations.get().is_enabled() {
    return
  }
  let transforms = query_set.p0()
  let parents = query_set.p1()

  let used_batch = try! changed_transforms.try_for_each_filtered_table(fn(
    batch,
    rows,
  ) {
    try! rows.for_each(fn(row_index) {
      mark_dirty_tree_chain(transforms, parents, batch.entity(row_index))
    })
  })
  if !used_batch {
    try! changed_transforms.for_each(fn(_entity, changed_entity) {
      mark_dirty_tree_chain(transforms, parents, changed_entity)
    })
  }
  for entity in orphaned.read() {
    mark_dirty_tree_chain(transforms, parents, entity)
  }
}

///|
pub fn mark_dirty_trees(world : @ecs.World) -> Unit {
  if !read_static_transform_optimizations(world).is_enabled() {
    return
  }
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
      world.get_tick_context().ticks(),
    )
    .read()
  let transforms : TransformTreeChangedMutQuery = @ecs.query(world)
  let parents : TransformParentQuery = @ecs.query(world)

  let used_batch = try! changed_transforms.try_for_each_filtered_table(fn(
    batch,
    rows,
  ) {
    try! rows.for_each(fn(row_index) {
      mark_dirty_tree_chain(transforms, parents, batch.entity(row_index))
    })
  })
  if !used_batch {
    try! changed_transforms.for_each(fn(_entity, changed_entity) {
      mark_dirty_tree_chain(transforms, parents, changed_entity)
    })
  }
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
fn transform_node_tree_changed_at_row(
  table_columns : TransformPropagationTableColumns,
  row_index : Int,
  system_ticks : @core.SystemTicks,
) -> Bool {
  match table_columns.tree_changed {
    Some(tree_changed_column) =>
      tree_changed_column.is_changed_at_row(row_index, system_ticks)
    None => false
  }
}

///|
fn transform_fetch_node_at_row(
  table_columns : TransformPropagationTableColumns,
  row_index : Int,
  require_parent : Bool,
) -> TransformPropagationNode? {
  guard row_index >= 0 else { return None }
  guard table_columns.transform is Some(transform_column) else { return None }
  guard transform_column.value_at_row_unchecked(row_index) is Some(transform) else {
    return None
  }
  guard table_columns.global is Some(global_column) else { return None }
  guard global_column.value_at_row_unchecked(row_index) is Some(global) else {
    return None
  }
  let parent = match table_columns.parent {
    Some(parent_column) => parent_column.value_at_row_unchecked(row_index)
    None => None
  }
  if require_parent && parent is None {
    return None
  }
  Some(TransformPropagationNode::{
    transform,
    global,
    tree_changed_column: table_columns.tree_changed,
    children: match table_columns.children {
      Some(children_column) => children_column.value_at_row_unchecked(row_index)
      None => None
    },
    parent,
  })
}

///|
fn transform_node_tree_changed(
  node : TransformPropagationNode,
  row_index : Int,
  system_ticks : @core.SystemTicks,
) -> Bool {
  match node.tree_changed_column {
    Some(tree_changed_column) =>
      tree_changed_column.is_changed_at_row(row_index, system_ticks)
    None => false
  }
}

///|
priv struct TransformPropagationCounters {
  mut roots_scanned : Int
  mut descendants_visited : Int
  mut table_row_fetches : Int
  mut global_transform_writes : Int
}

///|
fn TransformPropagationCounters::TransformPropagationCounters() -> TransformPropagationCounters {
  {
    roots_scanned: 0,
    descendants_visited: 0,
    table_row_fetches: 0,
    global_transform_writes: 0,
  }
}

///|
fn propagate_descendants_dense(
  _world : @ecs.World,
  columns : TransformPropagationColumns,
  scratch : TransformPropagationScratch,
  tick : @core.Tick,
  static_optimizations_enabled : Bool,
  system_ticks : @core.SystemTicks,
  parent : @core.Entity,
  parent_global : GlobalTransform,
  parent_global_changed : Bool,
  children : @hierarchy.Children,
  counters : TransformPropagationCounters,
) -> Unit {
  scratch.dense_stack.clear()
  let root_children = children.entities()
  for index in 0..<root_children.length() {
    let reverse_index = root_children.length() - 1 - index
    counters.table_row_fetches = counters.table_row_fetches + 1
    let (table_id, row_index) = match
      children.entity_table_row_cached(_world, reverse_index) {
      Some(location) => location
      None => (-1, -1)
    }
    scratch.dense_stack.push(TransformPropagationStackItem::{
      entity: root_children[reverse_index],
      table_id,
      row_index,
      parent,
      parent_global,
      parent_global_changed,
    })
  }
  while scratch.dense_stack.length() > 0 {
    let stack_item = match scratch.dense_stack.pop() {
      Some(item) => item
      None => break
    }
    counters.descendants_visited = counters.descendants_visited + 1
    let child = stack_item.entity
    let table_id = stack_item.table_id
    let row_index = stack_item.row_index
    if table_id < 0 || row_index < 0 {
      continue
    }
    guard transform_propagation_table_columns(columns, scratch, table_id)
      is Some(table_columns) else {
      continue
    }
    if static_optimizations_enabled &&
      !stack_item.parent_global_changed &&
      !transform_node_tree_changed_at_row(
        table_columns, row_index, system_ticks,
      ) {
      continue
    }
    guard transform_fetch_node_at_row(table_columns, row_index, true)
      is Some(node) else {
      continue
    }
    guard node.parent is Some(parent_value) else { continue }
    if !entity_eq(parent_value.entity(), stack_item.parent) {
      transform_abort_malformed_hierarchy()
    }
    let child_global = node.global
    let child_global_changed = if node.global.set_mul_transform_if_neq(
        stack_item.parent_global,
        node.transform,
      ) {
      counters.global_transform_writes = counters.global_transform_writes + 1
      guard table_columns.global is Some(global_column) else { false }
      global_column.record_changed_at_row(row_index, tick)
    } else {
      false
    }
    match node.children {
      Some(grand_children) => {
        let grandchildren = grand_children.entities()
        for index in 0..<grandchildren.length() {
          let reverse_index = grandchildren.length() - 1 - index
          counters.table_row_fetches = counters.table_row_fetches + 1
          let (table_id, row_index) = match
            grand_children.entity_table_row_cached(_world, reverse_index) {
            Some(location) => location
            None => (-1, -1)
          }
          scratch.dense_stack.push(TransformPropagationStackItem::{
            entity: grandchildren[reverse_index],
            table_id,
            row_index,
            parent: child,
            parent_global: child_global,
            parent_global_changed: child_global_changed,
          })
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
  let tick = {
    let tick = world.read_change_tick()
    if tick > 0 {
      tick
    } else {
      1
    }
  }
  let system_ticks = world.get_tick_context().ticks()
  let scratch_ref = transform_propagation_scratch_ref_or_init(world)
  let scratch = scratch_ref.peek()
  let trace_enabled = @app.timeline_trace_enabled()
  let trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "transform_propagate_dense",
  )
  let mut descendants_trace_first_us = -1L
  let mut descendants_trace_total_us = 0L
  let counters = TransformPropagationCounters::TransformPropagationCounters()
  columns.children.for_each_without_fast(parent_column, fn(entity, children) {
    counters.roots_scanned = counters.roots_scanned + 1
    counters.table_row_fetches = counters.table_row_fetches + 1
    guard transform_dense_entity_slot(world, entity)
      is Some((table_id, row_index)) else {
      return
    }
    guard transform_propagation_table_columns(columns, scratch, table_id)
      is Some(table_columns) else {
      return
    }
    guard transform_fetch_node_at_row(table_columns, row_index, false)
      is Some(root_node) else {
      return
    }
    if static_optimizations_enabled &&
      !transform_node_tree_changed(root_node, row_index, system_ticks) {
      return
    }
    let root_global = GlobalTransform::from_transform(root_node.transform)
    guard table_columns.global is Some(global_column) else { return }
    let root_global_changed = if root_node.global.set_from_if_neq(root_global) {
      global_column.record_changed_at_row(row_index, tick)
    } else {
      false
    }
    if root_global_changed {
      counters.global_transform_writes = counters.global_transform_writes + 1
    }
    let descendants_start_us = if trace_enabled {
      let now = @app.timeline_trace_now_us()
      if descendants_trace_first_us < 0L {
        descendants_trace_first_us = now
      }
      now
    } else {
      -1L
    }
    propagate_descendants_dense(
      world, columns, scratch, tick, static_optimizations_enabled, system_ticks,
      entity, root_global, root_global_changed, children, counters,
    )
    if descendants_start_us >= 0L {
      let descendants_end_us = @app.timeline_trace_now_us()
      if descendants_end_us >= descendants_start_us {
        descendants_trace_total_us += descendants_end_us - descendants_start_us
      }
    }
  })
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "transform_propagate_dense",
    trace_start_us,
  )
  if descendants_trace_first_us >= 0L {
    @app.timeline_trace_emit_complete_span(
      @app.TimelineTraceCategory::RenderQueue,
      "transform_propagate_descendants",
      descendants_trace_first_us,
      descendants_trace_total_us,
    )
  }
  @app.timeline_trace_emit_counter_int(
    "transform.propagation.roots_scanned",
    counters.roots_scanned,
  )
  @app.timeline_trace_emit_counter_int(
    "transform.propagation.descendants_visited",
    counters.descendants_visited,
  )
  @app.timeline_trace_emit_counter_int(
    "transform.propagation.table_row_fetches",
    counters.table_row_fetches,
  )
  @app.timeline_trace_emit_counter_int(
    "transform.propagation.global_transform_writes",
    counters.global_transform_writes,
  )
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  guard transform_propagation_columns(world) is Some(columns) else { return }
  let static_optimizations = read_static_transform_optimizations(world)
  propagate_parent_transforms_dense(
    world,
    columns,
    static_optimizations.is_enabled(),
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
