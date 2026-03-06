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
test "transform ecs: root global matches local" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

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

  update_children_system(world)
  propagate_transforms_system(world)

  let gt = (try! world.get(entity, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 1.0F) && approx_eq(gt.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs: parent translation affects child global translation" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

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

  update_children_system(world)
  propagate_transforms_system(world)

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
  update_children_system(world)
  propagate_transforms_system(world)
  let gt_tick1 = world
    .component(ecs_key_global_transform)
    .get_ticks(entity)
    .unwrap()
  inspect(gt_tick1.is_changed(@core.SystemTicks::new(0, tick1)), content="true")

  // Second run: no changes, propagate should not touch GlobalTransform.
  let tick2 = next_system_ticks(world).this_run
  update_children_system(world)
  propagate_transforms_system(world)
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
  update_children_system(world)
  propagate_transforms_system(world)
  let gt = (try! world.get(entity, ecs_key_global_transform)).unwrap()
  inspect(approx_eq(gt.affine.tx, 2.0F), content="true")
}

///|
test "transform plugin: post startup populates hierarchy globals" {
  let world = @ecs.World::new()
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

  let app = @app.App::new(world).add_plugins([transform_plugin])
  app.run_startup() |> ignore

  let gt = (try! app.world.get(child, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 5.0F) && approx_eq(gt.affine.ty, 5.0F),
    content="true",
  )
}

///|
test "transform plugin: post update reflects update stage transform writes" {
  let entity_ref = Ref::new(@core.Entity::new(0, 0))
  let world = @ecs.World::new()
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

  let app = @app.App::new(world)
    .add_plugins([transform_plugin])
    .add_system(fn(world : @ecs.World) {
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

  let gt = (try! app.world.get(entity, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq(gt.affine.tx, 7.0F) && approx_eq(gt.affine.ty, 8.0F),
    content="true",
  )
}
