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
type TransformTreeChangedQuery = @ecs.Query[
  @ecs.Comp[TransformTreeChanged],
  @ecs.All,
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
  (
    @ecs.Comp[Transform],
    @ecs.Mut[GlobalTransform],
    @ecs.Comp[@hierarchy.Children],
    @ecs.Comp[TransformTreeChanged],
  ),
  @ecs.Without[@hierarchy.Parent],
]

///|
type PropagateNodeQuery = @ecs.Query[
  (
    @ecs.Comp[Transform],
    @ecs.Mut[GlobalTransform],
    @ecs.Comp[TransformTreeChanged],
    @ecs.Comp[@hierarchy.Children]?,
  ),
  @ecs.With[@hierarchy.Parent],
]

///|
type PropagateChildParentQuery = @ecs.Query[
  @ecs.Comp[@hierarchy.Parent],
  @ecs.With[GlobalTransform],
]

///|
priv struct TransformPropagationScratch {
  dense_stack_entities : Array[@core.Entity]
  dense_stack_parents : Array[@core.Entity]
  dense_stack_parent_globals : Array[GlobalTransform]
  dense_stack_parent_global_changed : Array[Bool]
}

///|
fn transform_propagation_scratch_default() -> TransformPropagationScratch {
  {
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
fn transform_tree_changed_dirty(
  tree_changed : @ecs.Comp[TransformTreeChanged],
) -> Bool {
  tree_changed.is_changed() || tree_changed.is_added()
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
  for entity in orphaned {
    match (query.get(entity) catch { _ => None }) {
      Some((transform, global_transform)) =>
        if !transform.is_changed() && !global_transform.is_added() {
          global_transform.set(GlobalTransform::from_transform(transform.value()))
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
fn mark_dirty_tree_chain(
  world : @ecs.World,
  transforms : TransformTreeChangedMutQuery,
  parents : TransformParentQuery,
  start : @core.Entity,
) -> Unit {
  let mut next = start
  while world.is_alive(next) {
    guard (try! transforms.get(next)) is Some(tree_changed) else { break }
    if tree_changed.is_changed() && !tree_changed.is_added() {
      break
    }
    tree_changed.set_changed()
    guard (try! parents.get(next)) is Some(parent) else { break }
    next = parent.value().entity()
  }
}

///|
pub fn mark_dirty_trees(world : @ecs.World) -> Unit {
  let dirty_triggers : TransformDirtyTriggerQuery = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.Changed::new(ecs_key_transform),
        @ecs.Changed::new(@hierarchy.ecs_key_parent),
        @ecs.Added::new(ecs_key_global_transform),
      ),
    ),
  )
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
    let transforms : TransformTreeChangedQuery = @ecs.query(world)
    let total = Float::from_int(transforms.count())
    if total > 0.0F {
      let dynamic_count = Float::from_int(dirty_triggers.count())
      if dynamic_count / total > threshold {
        static_optimizations.enabled = false
      }
    }
  }
  write_static_transform_optimizations(world, static_optimizations)
  if !static_optimizations.enabled {
    return
  }
  let changed_entities : Array[@core.Entity] = []
  try! dirty_triggers.for_each(fn(_entity, changed_entity) {
    changed_entities.push(changed_entity)
  })
  let transforms : TransformTreeChangedMutQuery = @ecs.query(world)
  let parents : TransformParentQuery = @ecs.query(world)
  for entity in changed_entities {
    mark_dirty_tree_chain(world, transforms, parents, entity)
  }
}

///|
fn propagate_descendants_query(
  world : @ecs.World,
  scratch : TransformPropagationScratch,
  nodes : PropagateNodeQuery,
  child_parents : PropagateChildParentQuery,
  static_optimizations_enabled : Bool,
  parent : @core.Entity,
  parent_global : GlobalTransform,
  parent_changed : Bool,
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
    scratch.dense_stack_parent_global_changed.push(parent_changed)
  }
  while scratch.dense_stack_entities.length() > 0 {
    let child = match scratch.dense_stack_entities.pop() {
      Some(entity) => entity
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
    let current_parent_changed = match
      scratch.dense_stack_parent_global_changed.pop() {
      Some(changed) => changed
      None => break
    }
    guard world.is_alive(child) else { continue }
    guard (try! child_parents.get(child)) is Some(child_parent) else {
      continue
    }
    if !entity_eq(child_parent.value().entity(), current_parent) {
      transform_abort_malformed_hierarchy()
    }
    guard (try! nodes.get(child))
      is Some((transform, global_transform, tree_changed, node_children)) else {
      continue
    }
    let node_dirty = transform_tree_changed_dirty(tree_changed)
    if static_optimizations_enabled && !current_parent_changed && !node_dirty {
      continue
    }
    let next_global = current_parent_global.mul_transform(transform.value())
    let global_changed = transform_set_global_if_neq_mut(
      global_transform,
      next_global,
    )
    match node_children {
      Some(children_comp) => {
        let grand_children = children_comp.value().entities()
        for index in 0..<grand_children.length() {
          let reverse_index = grand_children.length() - 1 - index
          scratch.dense_stack_entities.push(grand_children[reverse_index])
          scratch.dense_stack_parents.push(child)
          scratch.dense_stack_parent_globals.push(next_global)
          scratch.dense_stack_parent_global_changed.push(global_changed)
        }
      }
      None => ()
    }
  }
}

///|
pub fn propagate_parent_transforms(world : @ecs.World) -> Unit {
  let static_optimizations = read_static_transform_optimizations(world)
  let roots : PropagateRootQuery = @ecs.query_filtered(
    world,
    @ecs.Without::new(@hierarchy.ecs_key_parent),
  )
  let nodes : PropagateNodeQuery = @ecs.query_filtered(
    world,
    @ecs.With::new(@hierarchy.ecs_key_parent),
  )
  let child_parents : PropagateChildParentQuery = @ecs.query_filtered(
    world,
    @ecs.With::new(ecs_key_global_transform),
  )
  let scratch_ref = transform_propagation_scratch_ref_or_init(world)
  let scratch = scratch_ref.peek()
  try! roots.for_each(fn(root, data) {
    let (transform, global_transform, children, tree_changed) = data
    let tree_dirty = transform_tree_changed_dirty(tree_changed)
    let next_global = GlobalTransform::from_transform(transform.value())
    let global_changed = transform_set_global_if_neq_mut(
      global_transform,
      next_global,
    )
    if static_optimizations.enabled && !tree_dirty && !global_changed {
      return
    }
    propagate_descendants_query(
      world,
      scratch,
      nodes,
      child_parents,
      static_optimizations.enabled,
      root,
      next_global,
      global_changed,
      children.value(),
    )
  })
}

///|
pub fn propagate_transforms_system(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}
