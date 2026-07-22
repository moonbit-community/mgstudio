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
fn global_translation_eq(
  global_transform : GlobalTransform,
  x : Float,
  y : Float,
  z? : Float = 0.0F,
) -> Bool {
  let translation = global_transform.translation()
  approx_eq(translation.x, x) &&
  approx_eq(translation.y, y) &&
  approx_eq(translation.z, z)
}

///|
fn next_system_ticks(world : @ecs.World) -> @core.SystemTicks {
  let this_run = world.increment_change_tick()
  let last_run = world.get_tick_context().ticks().this_run
  let tick = @core.SystemTicks::new(last_run, this_run)
  let ctx = @core.SystemTickContext::new()
  ctx.set(tick)
  world.set_tick_context(ctx)
  tick
}

///|
fn prepare_transform_world(world : @ecs.World) -> Unit {
  @hierarchy.hierarchy_install_component_metadata()
  transform_install_component_metadata()
  if !world.resource(static_transform_optimizations_resource_key).is_present() {
    world.insert_resource(
      static_transform_optimizations_resource_key,
      StaticTransformOptimizations(),
    )
  }
}

///|
test "transform ecs: root global matches local" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
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
  debug_inspect(global_translation_eq(gt, 1.0F, 2.0F), content="true")
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
  defer world.close()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  world.insert_resource(
    static_transform_optimizations_resource_key,
    StaticTransformOptimizations::enabled(),
  )
  next_system_ticks(world) |> ignore
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
  debug_inspect(global_translation_eq(gt, 1.0F, 2.0F), content="true")
}

///|
test "transform ecs: propagate preserves global transform until inputs change" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  // First run: insert Transform, propagate writes GlobalTransform.
  next_system_ticks(world) |> ignore
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
  debug_inspect(global_translation_eq(first_global, 1.0F, 0.0F), content="true")

  // Second run: no local changes, the propagated value should stay stable.
  next_system_ticks(world) |> ignore
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let second_global = (try! world.get_by_key(entity, ecs_key_global_transform)).unwrap()
  debug_inspect(
    second_global.to_json() == first_global.to_json(),
    content="true",
  )

  // Third run: local change, should update.
  next_system_ticks(world) |> ignore
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
  debug_inspect(global_translation_eq(gt, 2.0F, 0.0F), content="true")
}

///|
test "transform ecs: propagation does not mark unchanged root global changed" {
  let world = @ecs.World::new()
  defer world.close()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  world.insert_resource(
    static_transform_optimizations_resource_key,
    StaticTransformOptimizations::disabled(),
  )
  next_system_ticks(world) |> ignore
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

  let second_ticks = next_system_ticks(world)
  mark_dirty_trees(world)
  propagate_parent_transforms(world)
  guard world.entity_table_location(parent) is Some((table_id, row_index)) else {
    fail("expected parent table row")
  }
  guard world.component_column(ecs_key_global_transform) is Some(global_column) else {
    fail("expected global transform column")
  }
  guard global_column.table_column(table_id) is Some(global_table_column) else {
    fail("expected global transform table column")
  }
  debug_inspect(
    global_table_column.is_changed_at_row(row_index, second_ticks),
    content="false",
  )
}

///|
test "transform ecs: sync simple transforms updates orphaned entity once parent is removed" {
  let world = @ecs.World::new()
  defer world.close()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
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
  debug_inspect(global_translation_eq(child_before, 3.0F, 0.0F), content="true")

  next_system_ticks(world) |> ignore
  try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)
  let child_after = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(global_translation_eq(child_after, 1.0F, 0.0F), content="true")
}

///|
test "transform ecs: removing parent updates orphaned parent and child globals" {
  let world = @ecs.World::new()
  defer world.close()
  let root = world.spawn_empty()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
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
    global_translation_eq(parent_before, 7.7F, 7.7F),
    content="true",
  )

  next_system_ticks(world) |> ignore
  try! (world.remove_by_key(parent, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let parent_after = (try! world.get_by_key(parent, ecs_key_global_transform)).unwrap()
  debug_inspect(global_translation_eq(parent_after, 4.4F, 4.4F), content="true")

  next_system_ticks(world) |> ignore
  try! (world.remove_by_key(child, @hierarchy.ecs_key_parent) |> ignore)
  mark_dirty_trees(world)
  propagate_transforms_system(world)
  sync_simple_transforms_world(world)

  let child_after = (try! world.get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(global_translation_eq(child_after, 5.5F, 5.5F), content="true")
}

///|
test "transform ecs: inserting Transform auto-inserts required components" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
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
  defer world.close()
  let entity = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
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
  defer world.close()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  world.insert_resource(
    static_transform_optimizations_resource_key,
    StaticTransformOptimizations::enabled(),
  )
  next_system_ticks(world) |> ignore
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

  next_system_ticks(world) |> ignore
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
test "transform ecs: static optimization mode is explicit" {
  debug_inspect(
    StaticTransformOptimizations::StaticTransformOptimizations().is_enabled(),
    content="true",
  )
  debug_inspect(
    StaticTransformOptimizations::disabled().is_enabled(),
    content="false",
  )
}

///|
test "transform plugin: post startup populates hierarchy globals" {
  let lifecycle_world_539_0 = @ecs.World::new()
  defer lifecycle_world_539_0.close()
  let app = @app.App::new(lifecycle_world_539_0).add_plugins(
    @transform.TransformPlugin::TransformPlugin(),
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
  debug_inspect(global_translation_eq(gt, 5.0F, 5.0F), content="true")
}

///|
test "transform plugin: queues parent validation for missing parent GlobalTransform" {
  let lifecycle_world_578_0 = @ecs.World::new()
  defer lifecycle_world_578_0.close()
  let app = @app.App::new(lifecycle_world_578_0).add_plugins(
    @transform.TransformPlugin::TransformPlugin(),
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
    cursor=MessageCursor(),
  )
  debug_inspect(reader.len(), content="1")
}

///|
test "transform plugin: keeps preinserted static optimization resource" {
  let lifecycle_world_609_0 = @ecs.World::new()
  defer lifecycle_world_609_0.close()
  let app = @app.App::new(lifecycle_world_609_0)
    .insert_resource(StaticTransformOptimizations::disabled())
    .add_plugins(@transform.TransformPlugin::TransformPlugin())
  let value = app
    .world()
    .get_resource(static_transform_optimizations_resource_key)
    .unwrap()
  debug_inspect(value.is_enabled(), content="false")
}

///|
test "transform plugin: post update reflects update stage transform writes" {
  let entity_ref = Ref(@core.Entity::new(0, 0))
  let lifecycle_world_621_0 = @ecs.World::new()
  defer lifecycle_world_621_0.close()
  let app = @app.App::new(lifecycle_world_621_0).add_plugins(
    @transform.TransformPlugin::TransformPlugin(),
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
  debug_inspect(global_translation_eq(gt, 7.0F, 8.0F), content="true")
}

///|
test "transform plugin: post update reflects hierarchy root transform writes" {
  let parent_ref = Ref(@core.Entity::new(0, 0))
  let lifecycle_world_659_0 = @ecs.World::new()
  defer lifecycle_world_659_0.close()
  let app = @app.App::new(lifecycle_world_659_0).add_plugins(
    @transform.TransformPlugin::TransformPlugin(),
  )
  let world = app.world()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()
  parent_ref.val = parent
  try! world.set_by_key(
    parent,
    ecs_key_transform,
    Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
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

  let app = app.add_system(fn(world : @ecs.World) {
    try! world.set_by_key(
      parent_ref.val,
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

  let parent_gt = (try! app.world().get_by_key(parent, ecs_key_global_transform)).unwrap()
  let child_gt = (try! app.world().get_by_key(child, ecs_key_global_transform)).unwrap()
  debug_inspect(global_translation_eq(parent_gt, 7.0F, 8.0F), content="true")
  debug_inspect(global_translation_eq(child_gt, 10.0F, 12.0F), content="true")
}

///|
test "transform ecs: reparenting in the same frame preserves global transform" {
  let world = @ecs.World::new()
  defer world.close()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  prepare_transform_world(world)
  next_system_ticks(world) |> ignore
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

  next_system_ticks(world) |> ignore
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
