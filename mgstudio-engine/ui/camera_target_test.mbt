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
  let tick = world.increment_change_tick()
  get_ui_context_resource(world).insert(
    UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
      None,
      @math.Transform::identity(),
      1.0F,
      None,
      false,
    ),
    tick,
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

  let fallback = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    fallback,
    camera_with_target_info(10, @math.IVec2::new(800, 600), 1.0F),
    tick,
  )

  let marked = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    marked,
    camera_with_target_info(-5, @math.IVec2::new(640, 360), 1.0F),
    tick,
  )
  get_is_default_ui_camera_store(world).insert(
    marked,
    IsDefaultUiCamera::default(),
    tick,
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

  let primary_window = @window.Window::default()
  primary_window.resolution.set_physical_resolution(960, 540)
  primary_window.resolution.set_scale_factor(1.0F)
  let primary_window_entity = world.spawn()
  try! world.set_component(primary_window_entity, primary_window)
  try! world.set_component(primary_window_entity, @window.PrimaryWindow::{  })

  let marked_a = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    marked_a,
    camera_with_target_info(2, @math.IVec2::new(960, 540), 1.0F),
    tick,
  )
  get_is_default_ui_camera_store(world).insert(
    marked_a,
    IsDefaultUiCamera::default(),
    tick,
  )

  let marked_b = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    marked_b,
    camera_with_target_info(20, @math.IVec2::new(512, 512), 1.0F),
    tick,
  )
  @sprite.get_render_target_store(world).insert(
    marked_b,
    @sprite.RenderTarget::Image(@asset.Handle::new(7)),
    tick,
  )
  get_is_default_ui_camera_store(world).insert(
    marked_b,
    IsDefaultUiCamera::default(),
    tick,
  )

  let primary_ref = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    primary_ref,
    camera_with_target_info(5, @math.IVec2::new(960, 540), 1.0F),
    tick,
  )
  @sprite.get_render_target_store(world).insert(
    primary_ref,
    @sprite.RenderTarget::Window(@window.WindowRef::Primary),
    tick,
  )

  let primary_entity = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    primary_entity,
    camera_with_target_info(9, @math.IVec2::new(960, 540), 1.0F),
    tick,
  )
  @sprite.get_render_target_store(world).insert(
    primary_entity,
    @sprite.RenderTarget::Window(
      @window.WindowRef::Entity(primary_window_entity),
    ),
    tick,
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
  let tick = world.increment_change_tick()
  get_ui_scale_resource(world).insert(UiScale::new(2.0F), tick)

  let target_camera = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    target_camera,
    camera_with_target_info(0, @math.IVec2::new(640, 360), 2.0F),
    tick,
  )

  let ignored_child_target = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    ignored_child_target,
    camera_with_target_info(1, @math.IVec2::new(320, 180), 1.0F),
    tick,
  )

  let root = world.spawn_empty()
  get_ui_root_store(world).insert(root, UiRoot::default(), tick)
  get_ui_target_camera_store(world).insert(
    root,
    UiTargetCamera::new(target_camera),
    tick,
  )

  let child = world.spawn_empty()
  @hierarchy.get_parent_store(world).insert(
    child,
    @hierarchy.Parent::new(root),
    tick,
  )
  @hierarchy.get_children_store(world).insert(
    root,
    @hierarchy.Children::new([child]),
    tick,
  )
  get_ui_target_camera_store(world).insert(
    child,
    UiTargetCamera::new(ignored_child_target),
    tick,
  )

  ui_propagate_target_cameras_system(world)

  inspect(
    get_computed_ui_target_camera_store(world).get(root).unwrap().get() ==
    Some(target_camera),
    content="true",
  )
  inspect(
    get_computed_ui_target_camera_store(world).get(child).unwrap().get() ==
    Some(target_camera),
    content="true",
  )
  let child_target_info = get_computed_ui_render_target_info_store(world)
    .get(child)
    .unwrap()
  inspect(child_target_info.scale_factor() == 4.0F, content="true")
  let logical_size = child_target_info.logical_size()
  inspect(logical_size.x == 160.0F && logical_size.y == 90.0F, content="true")
}

///|
test "ui: layout resolves each root against its propagated target viewport" {
  let world = @ecs.World::new()
  let tick = world.increment_change_tick()

  let camera_a = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    camera_a,
    camera_with_target_info(0, @math.IVec2::new(200, 100), 1.0F),
    tick,
  )
  let camera_b = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    camera_b,
    camera_with_target_info(1, @math.IVec2::new(600, 300), 2.0F),
    tick,
  )

  let root_a = world.spawn_empty()
  get_ui_root_store(world).insert(root_a, UiRoot::default(), tick)
  get_ui_target_camera_store(world).insert(
    root_a,
    UiTargetCamera::new(camera_a),
    tick,
  )
  get_node_store(world).insert(root_a, Node::default(), tick)

  let root_b = world.spawn_empty()
  get_ui_root_store(world).insert(root_b, UiRoot::default(), tick)
  get_ui_target_camera_store(world).insert(
    root_b,
    UiTargetCamera::new(camera_b),
    tick,
  )
  get_node_store(world).insert(root_b, Node::default(), tick)

  ui_propagate_target_cameras_system(world)
  ui_layout_system(world)

  let rect_a = get_ui_layout_store(world).get(root_a).unwrap().rect
  let rect_b = get_ui_layout_store(world).get(root_b).unwrap().rect
  inspect(
    rect_a.size().x == 200.0F && rect_a.size().y == 100.0F,
    content="true",
  )
  inspect(
    rect_b.size().x == 300.0F && rect_b.size().y == 150.0F,
    content="true",
  )
}
