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
fn seed_ui_context(world : @ecs.World) -> Int {
  let tick = world.advance_sequence()
  ignore(tick)
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
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
fn camera_with_target_info(
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
  let camera : @sprite.Camera = try! @json.from_json(camera_json)
  camera
}

///|
test "ui: single IsDefaultUiCamera wins over higher-order fallback camera" {
  let world = @ecs.World::new()
  let tick = seed_ui_context(world)
  ignore(tick)

  let fallback = world.spawn_empty()
  try! world.set_by_key(
    fallback,
    @sprite.ecs_key_camera,
    camera_with_target_info(10, @math.IVec2::new(800, 600), 1.0F),
  )

  let marked = world.spawn_empty()
  try! world.set_by_key(
    marked,
    @sprite.ecs_key_camera,
    camera_with_target_info(-5, @math.IVec2::new(640, 360), 1.0F),
  )
  try! world.set_by_key(
    marked,
    ecs_key_is_default_ui_camera,
    IsDefaultUiCamera::default(),
  )

  ui_update_context_system(world)
  inspect(
    get_ui_context_resource(world).get().unwrap().camera_entity == Some(marked),
    content="true",
  )
}

///|
test "ui: multiple default markers fall back to highest-order primary-window camera" {
  let world = @ecs.World::new()
  let tick = seed_ui_context(world)
  ignore(tick)

  let primary_window = @window.Window::default()
  primary_window.resolution.set_physical_resolution(960, 540)
  primary_window.resolution.set_scale_factor(1.0F)
  let primary_window_entity = world.spawn()
  try! (world.entity_mut(primary_window_entity).insert_component(primary_window)
  |> ignore)
  try! (world
  .entity_mut(primary_window_entity)
  .insert_component(@window.PrimaryWindow::{  })
  |> ignore)

  let marked_a = world.spawn_empty()
  try! world.set_by_key(
    marked_a,
    @sprite.ecs_key_camera,
    camera_with_target_info(2, @math.IVec2::new(960, 540), 1.0F),
  )
  try! world.set_by_key(
    marked_a,
    ecs_key_is_default_ui_camera,
    IsDefaultUiCamera::default(),
  )

  let marked_b = world.spawn_empty()
  try! world.set_by_key(
    marked_b,
    @sprite.ecs_key_camera,
    camera_with_target_info(20, @math.IVec2::new(512, 512), 1.0F),
  )
  try! world.set_by_key(
    marked_b,
    @sprite.ecs_key_render_target,
    @sprite.RenderTarget::Image(@asset.Handle::new(7)),
  )
  try! world.set_by_key(
    marked_b,
    ecs_key_is_default_ui_camera,
    IsDefaultUiCamera::default(),
  )

  let primary_ref = world.spawn_empty()
  try! world.set_by_key(
    primary_ref,
    @sprite.ecs_key_camera,
    camera_with_target_info(5, @math.IVec2::new(960, 540), 1.0F),
  )
  try! world.set_by_key(
    primary_ref,
    @sprite.ecs_key_render_target,
    @sprite.RenderTarget::Window(@window.WindowRef::Primary),
  )

  let primary_entity = world.spawn_empty()
  try! world.set_by_key(
    primary_entity,
    @sprite.ecs_key_camera,
    camera_with_target_info(9, @math.IVec2::new(960, 540), 1.0F),
  )
  try! world.set_by_key(
    primary_entity,
    @sprite.ecs_key_render_target,
    @sprite.RenderTarget::Window(
      @window.WindowRef::Entity(primary_window_entity),
    ),
  )

  ui_update_context_system(world)
  inspect(
    get_ui_context_resource(world).get().unwrap().camera_entity ==
    Some(primary_entity),
    content="true",
  )
}

///|
test "ui: explicit UiTargetCamera propagates from root and drives logical render target info" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  get_ui_scale_resource(world).insert(UiScale::new(2.0F))

  let target_camera = world.spawn_empty()
  try! world.set_by_key(
    target_camera,
    @sprite.ecs_key_camera,
    camera_with_target_info(0, @math.IVec2::new(640, 360), 2.0F),
  )

  let ignored_child_target = world.spawn_empty()
  try! world.set_by_key(
    ignored_child_target,
    @sprite.ecs_key_camera,
    camera_with_target_info(1, @math.IVec2::new(320, 180), 1.0F),
  )

  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
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
  try! world.set_by_key(
    child,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(ignored_child_target),
  )

  ui_propagate_target_cameras_system(world)

  inspect(
    try! (world
    .get_by_key(root, ecs_key_computed_ui_target_camera)
    .unwrap()
    .get() ==
    Some(target_camera)),
    content="true",
  )
  inspect(
    try! (world
    .get_by_key(child, ecs_key_computed_ui_target_camera)
    .unwrap()
    .get() ==
    Some(target_camera)),
    content="true",
  )
  let child_target_info = try! world
    .get_by_key(child, ecs_key_computed_ui_render_target_info)
    .unwrap()
  inspect(child_target_info.scale_factor() == 4.0F, content="true")
  let logical_size = child_target_info.logical_size()
  inspect(logical_size.x == 160.0F && logical_size.y == 90.0F, content="true")
}

///|
test "ui: propagated target info falls back to camera target when computed info is empty" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  get_ui_scale_resource(world).insert(UiScale::new(1.0F))

  let primary_window = @window.Window::default()
  primary_window.resolution.set_physical_resolution(960, 540)
  primary_window.resolution.set_scale_factor(1.5F)
  let primary_window_entity = world.spawn()
  try! (world.entity_mut(primary_window_entity).insert_component(primary_window)
  |> ignore)
  try! (world
  .entity_mut(primary_window_entity)
  .insert_component(@window.PrimaryWindow::{  })
  |> ignore)

  let target_camera = world.spawn_empty()
  try! world.set_by_key(
    target_camera,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )

  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
  try! world.set_by_key(
    root,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(target_camera),
  )

  ui_propagate_target_cameras_system(world)

  let target_info = try! world
    .get_by_key(root, ecs_key_computed_ui_render_target_info)
    .unwrap()
  inspect(target_info.scale_factor() == 1.5F, content="true")
  let logical_size = target_info.logical_size()
  inspect(logical_size.x == 640.0F && logical_size.y == 360.0F, content="true")
}

///|
test "ui: perspective target camera keeps overlays in screen space" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)

  let target_camera = world.spawn_empty()
  try! world.set_by_key(
    target_camera,
    @sprite.ecs_key_camera,
    camera_with_target_info(0, @math.IVec2::new(640, 360), 1.0F),
  )
  try! world.set_by_key(
    target_camera,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(123.0F, 456.0F, 789.0F),
  )

  let root = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_ui_root, UiRoot::default())
  try! world.set_by_key(
    root,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(target_camera),
  )
  try! world.set_by_key(root, ecs_key_node, Node::default())

  ui_propagate_target_cameras_system(world)
  ui_layout_system(world)

  let transform = try! world
    .get_by_key(root, @transform.ecs_key_transform)
    .unwrap()
  inspect(
    transform.translation.x == 0.0F && transform.translation.y == 0.0F,
    content="true",
  )
}

///|
test "ui: layout resolves each root against its propagated target viewport" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)

  let camera_a = world.spawn_empty()
  try! world.set_by_key(
    camera_a,
    @sprite.ecs_key_camera,
    camera_with_target_info(0, @math.IVec2::new(200, 100), 1.0F),
  )
  let camera_b = world.spawn_empty()
  try! world.set_by_key(
    camera_b,
    @sprite.ecs_key_camera,
    camera_with_target_info(1, @math.IVec2::new(600, 300), 2.0F),
  )

  let root_a = world.spawn_empty()
  try! world.set_by_key(root_a, ecs_key_ui_root, UiRoot::default())
  try! world.set_by_key(
    root_a,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(camera_a),
  )
  try! world.set_by_key(root_a, ecs_key_node, Node::default())

  let root_b = world.spawn_empty()
  try! world.set_by_key(root_b, ecs_key_ui_root, UiRoot::default())
  try! world.set_by_key(
    root_b,
    ecs_key_ui_target_camera,
    UiTargetCamera::new(camera_b),
  )
  try! world.set_by_key(root_b, ecs_key_node, Node::default())

  ui_propagate_target_cameras_system(world)
  ui_layout_system(world)

  let rect_a = try! world.get_by_key(root_a, ecs_key_ui_layout).unwrap().rect
  let rect_b = try! world.get_by_key(root_b, ecs_key_ui_layout).unwrap().rect
  inspect(
    rect_a.size().x == 200.0F && rect_a.size().y == 100.0F,
    content="true",
  )
  inspect(
    rect_b.size().x == 300.0F && rect_b.size().y == 150.0F,
    content="true",
  )
}
