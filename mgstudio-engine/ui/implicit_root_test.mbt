// Copyright 2026 International Digital Economy Academy
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
fn seed_ui_context_for_implicit_root_test(world : @ecs.World) -> Int {
  let tick = world.advance_sequence()
  ignore(tick)
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      None,
      @transform.Transform::identity(),
      1.0F,
      None,
      false,
    ),
  )
  tick
}

///|
fn implicit_root_camera_with_target_info(
  order : Int,
  physical_size : @math.IVec2,
  scale_factor : Float,
) -> @sprite.Camera {
  let target_info_json : Json = (
    (physical_size.x, physical_size.y).to_json(),
    scale_factor,
  ).to_json()
  let maybe_target_info : Json? = Some(target_info_json)
  let no_viewport_json : Json? = None
  let no_old_viewport_json : Json? = None
  let computed_json : Json = (maybe_target_info, no_old_viewport_json).to_json()
  let clear_color_json : Json = (0, Json::null()).to_json()
  let camera_json : Json = (
    no_viewport_json, order, true, computed_json, clear_color_json,
  ).to_json()
  try! @json.from_json(camera_json)
}

///|
test "ui: unparented node acts as implicit root for layout" {
  let world = @ecs.World::new()
  let tick = seed_ui_context_for_implicit_root_test(world)
  ignore(tick)
  let root = world.spawn_empty()
  try! world.set_by_key(
    root,
    ecs_key_node,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(24.0F))
    .with_top(Val::Px(32.0F))
    .with_width(Val::Px(120.0F))
    .with_height(Val::Px(48.0F)),
  )

  ui_layout_system(world)

  let rect = try! world.get_by_key(root, ecs_key_ui_layout).unwrap().rect
  debug_inspect(rect.min.x == 24.0F && rect.min.y == 32.0F, content="true")
  debug_inspect(rect.max.x == 144.0F && rect.max.y == 80.0F, content="true")
  let transform = try! world
    .get_by_key(root, @transform.ecs_key_transform)
    .unwrap()
  debug_inspect(transform.translation.x == -316.0F, content="true")
  debug_inspect(transform.translation.y == 244.0F, content="true")
}

///|
test "ui: unparented ghost node acts as implicit root for layout" {
  let world = @ecs.World::new()
  let tick = seed_ui_context_for_implicit_root_test(world)
  ignore(tick)
  let ghost_root = world.spawn_empty()
  try! world.set_by_key(ghost_root, ecs_key_ghost_node, GhostNode::default())
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost_root),
  )
  try! world.set_by_key(
    child,
    ecs_key_node,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(24.0F))
    .with_top(Val::Px(32.0F))
    .with_width(Val::Px(120.0F))
    .with_height(Val::Px(48.0F)),
  )

  ui_layout_system(world)

  debug_inspect(
    try! (world.get_by_key(ghost_root, ecs_key_ui_layout) is None),
    content="true",
  )
  let rect = try! world.get_by_key(child, ecs_key_ui_layout).unwrap().rect
  debug_inspect(rect.min.x == 24.0F && rect.min.y == 32.0F, content="true")
  debug_inspect(rect.max.x == 144.0F && rect.max.y == 80.0F, content="true")
}

///|
test "ui: unparented node acts as implicit root for target camera propagation" {
  let world = @ecs.World::new()
  let tick = seed_ui_context_for_implicit_root_test(world)
  ignore(tick)
  get_ui_scale_resource(world).insert(UiScale::new(2.0F))

  let target_camera = world.spawn_empty()
  try! world.set_by_key(
    target_camera,
    @sprite.ecs_key_camera,
    implicit_root_camera_with_target_info(0, @math.IVec2::new(640, 360), 2.0F),
  )

  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_node, Node::default())
  try! world.set_by_key(
    root,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(target_camera),
  )

  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    root,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([child]),
  )

  ui_propagate_target_cameras_system(world)

  debug_inspect(
    try! (world
    .get_by_key(root, ecs_key_computed_ui_target_camera)
    .unwrap()
    .get() ==
    Some(target_camera)),
    content="true",
  )
  debug_inspect(
    try! (world
    .get_by_key(child, ecs_key_computed_ui_target_camera)
    .unwrap()
    .get() ==
    Some(target_camera)),
    content="true",
  )
}

///|
test "ui: unparented ghost node acts as implicit root for target camera propagation" {
  let world = @ecs.World::new()
  let tick = seed_ui_context_for_implicit_root_test(world)
  ignore(tick)
  get_ui_scale_resource(world).insert(UiScale::new(2.0F))

  let target_camera = world.spawn_empty()
  try! world.set_by_key(
    target_camera,
    @sprite.ecs_key_camera,
    implicit_root_camera_with_target_info(0, @math.IVec2::new(640, 360), 2.0F),
  )

  let ghost_root = world.spawn_empty()
  try! world.set_by_key(ghost_root, ecs_key_ghost_node, GhostNode::default())
  try! world.set_by_key(
    ghost_root,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(target_camera),
  )

  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ghost_root),
  )

  ui_propagate_target_cameras_system(world)

  debug_inspect(
    try! (world
    .get_by_key(ghost_root, ecs_key_computed_ui_target_camera)
    .unwrap()
    .get() ==
    Some(target_camera)),
    content="true",
  )
  debug_inspect(
    try! (world
    .get_by_key(child, ecs_key_computed_ui_target_camera)
    .unwrap()
    .get() ==
    Some(target_camera)),
    content="true",
  )
}
