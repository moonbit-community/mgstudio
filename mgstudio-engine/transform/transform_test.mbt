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
fn next_system_ticks(world : @ecs.World) -> @core.SystemTicks {
  let this_run = world.increment_change_tick()
  let last_run = world.get_system_context().ticks().this_run
  let ticks = @core.SystemTicks::new(last_run, this_run)
  let ctx = @core.SystemContext::new()
  ctx.set(ticks)
  world.set_system_context(ctx)
  ticks
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
  next_system_ticks(world) |> ignore
  try! world.set(
    entity,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let gt = (try! world.get(entity, ecs_key_global_transform)).unwrap()
  inspect(
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
  inspect(approx_eq(point.x, 1.25F), content="true")
  inspect(approx_eq(point.y, 0.25F), content="true")
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
  next_system_ticks(world) |> ignore
  try! world.set(
    parent,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let gt = (try! world.get(child, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs: propagate updates only when inputs change" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  // First run: insert Transform, propagate writes GlobalTransform at tick1.
  let tick1 = next_system_ticks(world).this_run
  try! world.set(
    entity,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let gt_tick1 = world
    .component(ecs_key_global_transform)
    .get_ticks(entity)
    .unwrap()
  inspect(gt_tick1.is_changed(@core.SystemTicks::new(0, tick1)), content="true")

  // Second run: no changes, propagate should not touch GlobalTransform.
  let tick2 = next_system_ticks(world).this_run
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let gt_tick2 = world
    .component(ecs_key_global_transform)
    .get_ticks(entity)
    .unwrap()
  inspect(
    gt_tick2.is_changed(@core.SystemTicks::new(tick1, tick2)),
    content="false",
  )

  // Third run: local change, should update.
  next_system_ticks(world) |> ignore
  try! world.set(
    entity,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let gt = (try! world.get(entity, ecs_key_global_transform)).unwrap()
  inspect(approx_eq(gt.affine.tx, 2.0F), content="true")
}

///|
test "transform ecs: sync simple transforms updates orphaned entity once parent is removed" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
  try! world.set(
    parent,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let child_before = (try! world.get(child, ecs_key_global_transform)).unwrap()
  inspect(approx_eq(child_before.affine.tx, 3.0F), content="true")

  next_system_ticks(world) |> ignore
  try! (world.remove(child, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let child_after = (try! world.get(child, ecs_key_global_transform)).unwrap()
  inspect(approx_eq(child_after.affine.tx, 1.0F), content="true")
}

///|
test "transform ecs: inserting Transform auto-inserts required components" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
  try! world.set(
    entity,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(9.0F, 10.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  inspect(
    (try! world.get(entity, ecs_key_global_transform)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(entity, ecs_key_transform_tree_changed)) is Some(_),
    content="true",
  )
}

///|
test "transform ecs: component access insert also inserts required components" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
  world
  .component(@math.ecs_key_transform)
  .insert(
    entity,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(4.0F, 6.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    world.read_change_tick(),
  )

  inspect(
    (try! world.get(entity, ecs_key_global_transform)) is Some(_),
    content="true",
  )
  inspect(
    (try! world.get(entity, ecs_key_transform_tree_changed)) is Some(_),
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
  next_system_ticks(world) |> ignore
  try! world.set(
    parent,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  mark_dirty_trees(world)
  try! propagate_parent_transforms(world)
  sync_simple_transforms_world(world)

  next_system_ticks(world) |> ignore
  try! world.set(
    child,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 4.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  mark_dirty_trees(world)

  inspect(
    (try! world.get_ref(parent, ecs_key_transform_tree_changed))
    .unwrap()
    .is_changed(),
    content="true",
  )
  inspect(
    (try! world.get_ref(child, ecs_key_transform_tree_changed))
    .unwrap()
    .is_changed(),
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
  next_system_ticks(world) |> ignore
  try! world.set(
    entity_a,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    entity_b,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  mark_dirty_trees(world)

  let state = (try! world.get_resource(
    static_transform_optimizations_resource_key(),
  )).unwrap()
  inspect(state.enabled, content="false")
}

///|
test "transform plugin: post startup populates hierarchy globals" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([transform_plugin])
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set(
    parent,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(2.0F, 1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 4.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  try! world.set(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )

  app.run_startup() |> ignore

  let gt = (try! app.world().get(child, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 5.0F) && approx_eq(gt.affine.ty, 5.0F),
    content="true",
  )
}

///|
test "transform plugin: post update reflects update stage transform writes" {
  let entity_ref = Ref::new(@core.Entity::new(0, 0))
  let app = @app.App::new(@ecs.World::new()).add_plugins([transform_plugin])
  let world = app.world()
  let entity = world.spawn_empty()
  entity_ref.val = entity
  try! world.set(
    entity,
    @math.ecs_key_transform,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )

  let app = app.add_system(fn(world : @ecs.World) {
    try! world.set(
      entity_ref.val,
      @math.ecs_key_transform,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(7.0F, 8.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
    )
  })

  app.run_startup() |> ignore
  app.run_once() |> ignore

  let gt = (try! app.world().get(entity, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 7.0F) && approx_eq(gt.affine.ty, 8.0F),
    content="true",
  )
}
