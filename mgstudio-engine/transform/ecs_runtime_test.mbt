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
fn next_system_sequence_ecs(world : @ecs.World) -> Unit {
  let this_run = world.advance_sequence()
  let last_run = world.get_sequence_context().sequence().this_run
  let sequence = @core.SystemSequence::new(last_run, this_run)
  let ctx = @core.SystemSequenceContext::new()
  ctx.set(sequence)
  world.set_sequence_context(ctx)
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
  next_system_sequence_ecs(world)
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

  mark_dirty_trees_ecs(world)
  propagate_transforms_system_ecs(world)
  sync_simple_transforms_world(world)

  let children = (try! world.get_by_key(parent, @hierarchy.ecs_key_children)).unwrap()
  inspect(children.entities().length(), content="1")
  inspect(
    children.entities()[0].id == child.id &&
    children.entities()[0].generation == child.generation,
    content="true",
  )

  let child_global = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  inspect(
    approx_eq_ecs(child_global.affine.tx, 1.0F) &&
    approx_eq_ecs(child_global.affine.ty, 2.0F),
    content="true",
  )
}

///|
test "transform ecs world: hierarchy hooks clear stale Children components" {
  let world = @ecs.World::new()
  let parent = world.spawn()
  let child = world.spawn()

  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  inspect(
    (try! world.get_by_key(parent, @hierarchy.ecs_key_children)) is Some(_),
    content="true",
  )

  try! world.despawn(child)
  inspect(
    (try! world.get_by_key(parent, @hierarchy.ecs_key_children)) is None,
    content="true",
  )
}

///|
test "transform plugin: sync_simple_transforms skips dead entities from removed Parent" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([transform_plugin])
  let world = app.world()
  let parent = world.spawn()
  let child = world.spawn()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  app.update() |> ignore
  try! world.despawn(child)
  app.update() |> ignore
  inspect(world.is_alive(parent), content="true")
  inspect(world.is_alive(child), content="false")
}
