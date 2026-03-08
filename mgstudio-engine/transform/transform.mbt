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
/// Bevy-like transform propagation (2D-first).
///
/// This package provides:
/// - `GlobalTransform` component (computed world-space transform)
/// - systems to maintain `Children` from `Parent` and propagate transforms

///|
pub struct Affine2 {
  a : Float
  b : Float
  c : Float
  d : Float
  tx : Float
  ty : Float
}

///|
pub fn Affine2::identity() -> Affine2 {
  Affine2::{ a: 1.0F, b: 0.0F, c: 0.0F, d: 1.0F, tx: 0.0F, ty: 0.0F }
}

///|
pub fn Affine2::from_scale(scale : @math.Vec2) -> Affine2 {
  Affine2::{ a: scale.x, b: 0.0F, c: 0.0F, d: scale.y, tx: 0.0F, ty: 0.0F }
}

///|
pub fn Affine2::from_translation(translation : @math.Vec2) -> Affine2 {
  Affine2::{
    a: 1.0F,
    b: 0.0F,
    c: 0.0F,
    d: 1.0F,
    tx: translation.x,
    ty: translation.y,
  }
}

///|
pub fn Affine2::from_scale_translation(
  scale : @math.Vec2,
  translation : @math.Vec2,
) -> Affine2 {
  Affine2::{
    a: scale.x,
    b: 0.0F,
    c: 0.0F,
    d: scale.y,
    tx: translation.x,
    ty: translation.y,
  }
}

///|
pub fn Affine2::mul(self : Affine2, other : Affine2) -> Affine2 {
  // (A, t) * (B, u) = (A*B, A*u + t)
  let a = self.a * other.a + self.c * other.b
  let b = self.b * other.a + self.d * other.b
  let c = self.a * other.c + self.c * other.d
  let d = self.b * other.c + self.d * other.d
  let tx = self.a * other.tx + self.c * other.ty + self.tx
  let ty = self.b * other.tx + self.d * other.ty + self.ty
  Affine2::{ a, b, c, d, tx, ty }
}

///|
pub fn Affine2::transform_point2(
  self : Affine2,
  point : @math.Vec2,
) -> @math.Vec2 {
  @math.Vec2::new(
    self.a * point.x + self.c * point.y + self.tx,
    self.b * point.x + self.d * point.y + self.ty,
  )
}

///|
pub struct GlobalTransform {
  affine : Affine2
  z : Float
}

///|
pub fn GlobalTransform::identity() -> GlobalTransform {
  GlobalTransform::{ affine: Affine2::identity(), z: 0.0F }
}

///|
pub impl Default for GlobalTransform with default() {
  GlobalTransform::identity()
}

///|
pub impl ToJson for GlobalTransform with to_json(self) {
  (
    self.affine.a,
    self.affine.b,
    self.affine.c,
    self.affine.d,
    self.affine.tx,
    self.affine.ty,
    self.z,
  ).to_json()
}

///|
pub impl @json.FromJson for GlobalTransform with from_json(json, path) {
  let (a, b, c, d, tx, ty, z) : (
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
  ) = @json.from_json(json, path~)
  GlobalTransform::{ affine: Affine2::{ a, b, c, d, tx, ty }, z }
}

///|
pub fn GlobalTransform::from_transform(
  transform : @math.Transform,
) -> GlobalTransform {
  let rot_z = transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let sx = transform.scale.x
  let sy = transform.scale.y
  let a = cosv * sx
  let b = sinv * sx
  let c = -sinv * sy
  let d = cosv * sy
  GlobalTransform::{
    affine: Affine2::{
      a,
      b,
      c,
      d,
      tx: transform.translation.x,
      ty: transform.translation.y,
    },
    z: transform.translation.z,
  }
}

///|
pub fn GlobalTransform::mul(
  self : GlobalTransform,
  other : GlobalTransform,
) -> GlobalTransform {
  GlobalTransform::{
    affine: self.affine.mul(other.affine),
    z: self.z + other.z,
  }
}

///|
pub fn GlobalTransform::to_transform_approx(
  self : GlobalTransform,
) -> @math.Transform {
  // Best-effort TRS decomposition for a 2D affine matrix.
  // This ignores shear in the returned Transform, but preserves translation.
  let a = self.affine.a
  let b = self.affine.b
  let c = self.affine.c
  let d = self.affine.d
  let scale_x = @math.sqrt(a * a + b * b)
  let rotation = if scale_x == 0.0F { 0.0F } else { @math.atan2(b, a) }
  let det = a * d - b * c
  let scale_y = if scale_x == 0.0F { 0.0F } else { det / scale_x }
  @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(self.affine.tx, self.affine.ty),
    rotation,
    @math.Vec2::new(scale_x, scale_y),
    z=self.z,
  )
}

///|
pub struct TransformTreeChanged {} derive(Eq, Show, ToJson, FromJson)

///|
pub impl Default for TransformTreeChanged with default() {
  TransformTreeChanged::{  }
}

///|
pub struct StaticTransformOptimizations {
  threshold : Float
  mut enabled : Bool
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn StaticTransformOptimizations::from_threshold(
  threshold : Float,
) -> StaticTransformOptimizations {
  { threshold, enabled: true }
}

///|
pub fn StaticTransformOptimizations::disabled() -> StaticTransformOptimizations {
  { threshold: 0.0F, enabled: false }
}

///|
pub fn StaticTransformOptimizations::enabled() -> StaticTransformOptimizations {
  { threshold: 1.0F, enabled: true }
}

///|
pub impl Default for StaticTransformOptimizations with default() {
  { threshold: 0.3F, enabled: true }
}

///|
pub fn static_transform_optimizations_resource_key() -> @ecs.ResourceKey[
  StaticTransformOptimizations,
] {
  @ecs.register_resource(
    debug_name="bevy_transform::StaticTransformOptimizations",
  )
}

///|
type SimpleTransformChangedFilter = (
  @ecs.Or[(@ecs.Changed[@math.Transform], @ecs.Added[GlobalTransform])],
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
  @math.Transform,
  GlobalTransform,
  SimpleTransformChangedFilter,
]

///|
type SimpleTransformOrphanQuery = @ecs.Query2RefMutFiltered[
  @math.Transform,
  GlobalTransform,
  SimpleTransformFilter,
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
    @math.ecs_key_transform,
    ecs_key_global_transform,
    (
      @ecs.Or::new(
        (
          @ecs.Changed::new(@math.ecs_key_transform),
          @ecs.Added::new(ecs_key_global_transform),
        ),
      ),
      @ecs.Without::new(@hierarchy.ecs_key_parent),
      @ecs.Without::new(@hierarchy.ecs_key_children),
    ),
  )
  let orphan_query = world.query2_ref_mut_filtered(
    @math.ecs_key_transform,
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
        @ecs.Changed::new(@math.ecs_key_transform),
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
  world : @ecs.World,
  parent : @core.Entity,
  parent_global_transform : GlobalTransform,
  children : @hierarchy.Children,
  parent_changed : Bool,
  static_optimizations : StaticTransformOptimizations,
) -> Unit raise @ecs.EcsError {
  let child_query = world.query1_filtered(
    @hierarchy.ecs_key_parent,
    @ecs.With::new(ecs_key_global_transform),
  )
  let node_query = world.query3_ref_mut_optional_filtered(
    @math.ecs_key_transform,
    ecs_key_global_transform,
    @hierarchy.ecs_key_children,
    @ecs.With::new(@hierarchy.ecs_key_parent),
  )
  let child_iter = match
    (try? child_query.iter_many_unique_ref(children.entities())) {
    Ok(iter) => iter
    Err(_) => {
      transform_abort_malformed_hierarchy()
      return
    }
  }

  while true {
    guard (try! child_iter.fetch_next()) is Some((child, child_of)) else {
      break
    }
    if child_of.value().entity().id != parent.id ||
      child_of.value().entity().generation != parent.generation {
      transform_abort_malformed_hierarchy()
    }
    guard (try! world.get_ref(child, ecs_key_transform_tree_changed))
      is Some(transform_tree) else {
      continue
    }
    if static_optimizations.enabled &&
      !transform_tree.is_changed() &&
      !parent_changed {
      continue
    }

    guard (try! node_query.get_unchecked(child))
      is Some((local_transform, global_transform, grand_children)) else {
      continue
    }

    let changed = parent_changed ||
      child_of.is_changed() ||
      local_transform.is_changed() ||
      global_transform.is_added()
    let next_global = parent_global_transform.mul(
      GlobalTransform::from_transform(local_transform.value()),
    )
    if changed && global_transform.get().to_json() != next_global.to_json() {
      global_transform.get_ref().val = next_global
    }

    if grand_children is Some(grand_children) {
      propagate_descendants(
        world,
        child,
        if changed {
          next_global
        } else {
          global_transform.get()
        },
        grand_children.value(),
        changed,
        static_optimizations,
      )
    }
  }
}

///|
pub fn propagate_parent_transforms(
  world : @ecs.World,
) -> Unit raise @ecs.EcsError {
  let orphaned = world.removed_components(
    @hierarchy.ecs_key_parent,
    world.get_system_context().ticks(),
  )
  let orphaned_entities = orphaned.read()
  sort_entities_by_id(orphaned_entities)

  let root_query = world.query3_ref_mut_optional_filtered(
    @math.ecs_key_transform,
    ecs_key_global_transform,
    @hierarchy.ecs_key_children,
    @ecs.Without::new(@hierarchy.ecs_key_parent),
  )
  let static_optimizations = read_static_transform_optimizations(world)
  let roots : Array[@core.Entity] = []
  world
  .query_entities_filtered(@ecs.Without::new(@hierarchy.ecs_key_parent))
  .view(fn(entity) { roots.push(entity) })
  for entity in roots {
    guard (try! root_query.get_unchecked(entity))
      is Some((transform, global_transform, children)) else {
      continue
    }
    guard (try! world.get_ref(entity, ecs_key_transform_tree_changed))
      is Some(transform_tree) else {
      continue
    }
    if static_optimizations.enabled && !transform_tree.is_changed() {
      continue
    }

    let changed = transform.is_changed() ||
      global_transform.is_added() ||
      entity_array_contains(orphaned_entities, entity)
    let next_global = GlobalTransform::from_transform(transform.value())
    if changed && global_transform.get().to_json() != next_global.to_json() {
      global_transform.get_ref().val = next_global
    }
    if children is Some(children) {
      try! propagate_descendants(
        world,
        entity,
        if changed {
          next_global
        } else {
          global_transform.get()
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
  try! propagate_parent_transforms(world)
}

///|
pub let transform_set_mark_dirty_trees : @app.SystemSet = @app.system_set(
  "mgstudio.transform.mark_dirty_trees",
)

///|
pub let transform_set_propagate : @app.SystemSet = @app.system_set(
  "mgstudio.transform.propagate",
)

///|
pub let transform_set_sync_simple_transforms : @app.SystemSet = @app.system_set(
  "mgstudio.transform.sync_simple_transforms",
)

///|
pub fn register_transform_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components(
    @math.ecs_key_transform, ecs_key_global_transform,
  )
  world.register_required_components(
    @math.ecs_key_transform, ecs_key_transform_tree_changed,
  )
}

///|
pub fn transform_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  try! register_transform_required_components(app.world())
  ensure_transform_runtime_resources(app.world())
  let validate_parent_plugin : @app.ValidateParentHasComponentPlugin[
    GlobalTransform,
  ] = @app.ValidateParentHasComponentPlugin::default()
  app
  .add_plugins([
    @app.validate_parent_has_component_plugin(validate_parent_plugin),
  ])
  .add_post_startup_system_config(
    @app.system(fn(world : @ecs.World) { mark_dirty_trees(world) }).in_set(
      transform_set_mark_dirty_trees,
    ),
  )
  .add_post_startup_system_config(
    @app.system(fn(world : @ecs.World) {
      try! propagate_parent_transforms(world)
    }).in_set(transform_set_propagate),
  )
  .add_post_startup_system_config(
    @app.system(@app.system_param2(sync_simple_transforms)).in_set(
      transform_set_sync_simple_transforms,
    ),
  )
  .configure_set(@app.PostStartup, transform_set_mark_dirty_trees, before=[
    transform_set_propagate,
  ])
  .configure_set(@app.PostStartup, transform_set_propagate, before=[
    transform_set_sync_simple_transforms,
  ])
  .add_post_update_system_config(
    @app.system(fn(world : @ecs.World) { mark_dirty_trees(world) }).in_set(
      transform_set_mark_dirty_trees,
    ),
  )
  .add_post_update_system_config(
    @app.system(fn(world : @ecs.World) {
      try! propagate_parent_transforms(world)
    }).in_set(transform_set_propagate),
  )
  .add_post_update_system_config(
    @app.system(@app.system_param2(sync_simple_transforms)).in_set(
      transform_set_sync_simple_transforms,
    ),
  )
  .configure_set(@app.PostUpdate, transform_set_mark_dirty_trees, before=[
    transform_set_propagate,
  ])
  .configure_set(@app.PostUpdate, transform_set_propagate, before=[
    transform_set_sync_simple_transforms,
  ])
}
