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
fn abs_float_ecs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn approx_eq_ecs(a : Float, b : Float) -> Bool {
  abs_float_ecs(a - b) < 0.0001F
}

///|
fn next_system_ticks_ecs(world : @ecs.World) -> Unit {
  let this_run = world.increment_change_tick()
  let last_run = world.get_system_context().ticks().this_run
  let ticks = @core.SystemTicks::new(last_run, this_run)
  let ctx = @core.SystemContext::new()
  ctx.set(ticks)
  world.set_system_context(ctx)
}

///|
fn prepare_transform_world_ecs(world : @ecs.World) -> Unit {
  try! register_transform_required_components(world)
  if !world.resource(static_transform_optimizations_resource_key()).is_present() {
    world.insert_resource(
      static_transform_optimizations_resource_key(),
      StaticTransformOptimizations::default(),
    )
  }
}

///|
test "transform ecs world: child global uses parent and local transforms" {
  let world = @ecs.World::new()
  let parent = world.spawn()
  let child = world.spawn()

  prepare_transform_world_ecs(world)
  next_system_ticks_ecs(world)
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

  update_children_system_ecs(world)
  mark_dirty_trees_ecs(world)
  propagate_transforms_system_ecs(world)
  sync_simple_transforms_world(world)

  let children = (try! world.get(parent, @hierarchy.ecs_key_children)).unwrap()
  inspect(children.entities().length(), content="1")
  inspect(
    children.entities()[0].id == child.id &&
    children.entities()[0].generation == child.generation,
    content="true",
  )

  let child_global = (try! world.get(child, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq_ecs(child_global.affine.tx, 1.0F) &&
    approx_eq_ecs(child_global.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs world: update_children clears stale Children components" {
  let world = @ecs.World::new()
  let parent = world.spawn()
  let child = world.spawn()

  try! world.set(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  update_children_system_ecs(world)
  inspect(
    (try! world.get(parent, @hierarchy.ecs_key_children)) is Some(_),
    content="true",
  )

  try! world.despawn(child)
  update_children_system_ecs(world)
  inspect(
    (try! world.get(parent, @hierarchy.ecs_key_children)) is None,
    content="true",
  )
}
