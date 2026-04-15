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
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn approx_eq(a : Float, b : Float) -> Bool {
  abs_float(a - b) < 0.0001F
}

///|
fn next_system_sequence(world : @ecs.World) -> @core.SystemSequence {
  let this_run = world.advance_sequence()
  let last_run = world.get_sequence_context().sequence().this_run
  let sequence = @core.SystemSequence::new(last_run, this_run)
  let ctx = @core.SystemSequenceContext::new()
  ctx.set(sequence)
  world.set_sequence_context(ctx)
  sequence
}

///|
fn prepare_transform_world(world : @ecs.World) -> Unit {
  try! register_transform_required_components(world)
  if !world.resource(static_transform_optimizations_resource_key()).is_present() {
    world.insert_resource(
      static_transform_optimizations_resource_key(),
      StaticTransformOptimizations::default(),
    )
  }
}

///|
test "transform ecs: root global matches local" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    entity,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let gt = (try! world.get_by_key(entity, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform affine2: translation after scale preserves full affine uv transform semantics" {
  let transform = Affine2::from_translation(@math.Vec2::new(0.25F, -0.5F)).mul(
    Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)),
  )
  let point = transform.transform_point2(@math.Vec2::new(0.5F, 0.25F))
  debug_inspect(approx_eq(point.x, 1.25F), content="true")
  debug_inspect(approx_eq(point.y, 0.25F), content="true")
}

///|
test "transform ecs: parent translation affects child global translation" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  world.insert_resource(
    static_transform_optimizations_resource_key(),
    StaticTransformOptimizations::enabled(),
  )
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let gt = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs: propagate preserves global transform until inputs change" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  // First run: insert Transform, propagate writes GlobalTransform.
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    entity,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let first_global = (try! world.get_by_key(entity, ecs_key_global_transform)).unwrap()
  debug_inspect(approx_eq(first_global.affine.tx, 1.0F), content="true")

  // Second run: no local changes, the propagated value should stay stable.
  next_system_sequence(world) |> ignore
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let second_global = (try! world.get_by_key(entity, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(second_global.affine.tx, first_global.affine.tx) &&
    approx_eq(second_global.affine.ty, first_global.affine.ty),
    content="true",
  )

  // Third run: local change, should update.
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    entity,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let gt = (try! world.get_by_key(entity, ecs_key_global_transform)).unwrap()
  debug_inspect(approx_eq(gt.affine.tx, 2.0F), content="true")
}

///|
test "transform ecs: sync simple transforms updates orphaned entity once parent is removed" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let child_before = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(approx_eq(child_before.affine.tx, 3.0F), content="true")

  next_system_sequence(world) |> ignore
  try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let child_after = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(approx_eq(child_after.affine.tx, 1.0F), content="true")
}

///|
test "transform ecs: removing parent updates orphaned parent and child globals" {
  let world = @ecs.World::new()
  let root = world.spawn_empty()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    root,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.3F, 3.3F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(4.4F, 4.4F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(5.5F, 5.5F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    parent,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let parent_before = (try! world.get_by_key(parent, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(parent_before.affine.tx, 7.7F) &&
    approx_eq(parent_before.affine.ty, 7.7F),
    content="true",
  )

  next_system_sequence(world) |> ignore
  try! (world.remove_by_key(parent, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let parent_after = (try! world.get_by_key(parent, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(parent_after.affine.tx, 4.4F) &&
    approx_eq(parent_after.affine.ty, 4.4F),
    content="true",
  )

  next_system_sequence(world) |> ignore
  try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let child_after = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(child_after.affine.tx, 5.5F) &&
    approx_eq(child_after.affine.ty, 5.5F),
    content="true",
  )
}

///|
test "transform ecs: inserting Transform auto-inserts required components" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    entity,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(9.0F, 10.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_global_transform)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_transform_tree_changed)) is Some(_),
    content="true",
  )
}

///|
test "transform ecs: component access insert also inserts required components" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_sequence(world) |> ignore
  world.set_by_key(
    entity,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(4.0F, 6.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_global_transform)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_transform_tree_changed)) is Some(_),
    content="true",
  )
}

///|
test "transform ecs: mark_dirty_trees marks ancestor chain" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  world.insert_resource(
    static_transform_optimizations_resource_key(),
    StaticTransformOptimizations::enabled(),
  )
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  mark_dirty_trees(world)
  propagate_parent_transforms(world)
  sync_simple_transforms_world(world)

  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 4.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  mark_dirty_trees(world)

  debug_inspect(
    (try! world.get_by_key(parent, ecs_key_transform_tree_changed)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(child, ecs_key_transform_tree_changed)) is Some(_),
    content="true",
  )
}

///|
test "transform ecs: mark_dirty_trees disables static optimization above threshold" {
  let world = @ecs.World::new()
  let entity_a = world.spawn_empty()
  let entity_b = world.spawn_empty()

  prepare_transform_world(world)
  world.insert_resource(
    static_transform_optimizations_resource_key(),
    StaticTransformOptimizations::from_threshold(0.3F),
  )
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    entity_a,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    entity_b,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  mark_dirty_trees(world)

  let state = (try! world.get_resource(
    static_transform_optimizations_resource_key(),
  )).unwrap()
  debug_inspect(state.enabled, content="false")
}

///|
test "transform plugin: post startup populates hierarchy globals" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    TransformPlugin::default(),
  )
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 4.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  app.run_startup() |> ignore

  let gt = (try! app.world().get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(gt.affine.tx, 5.0F) && approx_eq(gt.affine.ty, 5.0F),
    content="true",
  )
}

///|
test "transform plugin: queues parent validation for missing parent GlobalTransform" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    TransformPlugin::default(),
  )
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  let reader = world.message_reader(
    @app.check_parent_has_component_message_key(ecs_key_global_transform),
    Ref::new(0),
  )
  debug_inspect(reader.len(), content="1")
}

///|
test "transform plugin: keeps preinserted static optimization resource" {
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(StaticTransformOptimizations::disabled())
    .add_plugins(TransformPlugin::default())
  let value = (try! app
  .world()
  .get_resource(static_transform_optimizations_resource_key())).unwrap()
  debug_inspect(value.threshold == 0.0F && !value.enabled, content="true")
}

///|
test "transform plugin: post update reflects update stage transform writes" {
  let entity_ref = Ref::new(@core.Entity::new(0, 0))
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    TransformPlugin::default(),
  )
  let world = app.world()
  let entity = world.spawn_empty()
  entity_ref.val = entity
  try! world.set_by_key(
    entity,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  let app = app.add_system(fn(world : @ecs.World) {
    try! world.set_by_key(
      entity_ref.val,
      ecs_key_transform,
      Transform::from_xy_rotation_scale(
        @math.Vec2::new(7.0F, 8.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
    )
  })

  app.run_startup() |> ignore
  app.run_once() |> ignore

  let gt = (try! app.world().get_by_key(entity, ecs_key_global_transform)).unwrap()
  debug_inspect(
    approx_eq(gt.affine.tx, 7.0F) && approx_eq(gt.affine.ty, 8.0F),
    content="true",
  )
}

///|
test "transform ecs: reparenting in the same frame preserves global transform" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_sequence(world) |> ignore
  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let parent_before = (try! world.get_by_key(parent, ecs_key_global_transform)).unwrap()
  let child_before = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()

  next_system_sequence(world) |> ignore
  try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  mark_dirty_trees(world)
  propagate_parent_transforms(world)
  sync_simple_transforms_world(world)

  let parent_after = (try! world.get_by_key(parent, ecs_key_global_transform)).unwrap()
  let child_after = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(
    parent_after.to_json() == parent_before.to_json(),
    content="true",
  )
  debug_inspect(child_after.to_json() == child_before.to_json(), content="true")
}
