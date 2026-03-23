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
  let tick = world.increment_change_tick()
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
    tick,
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
  let root = world.spawn_empty()
  get_node_store(world).insert(
    root,
    Node::default()
    .with_position_type(PositionType::Absolute)
    .with_left(Val::Px(24.0F))
    .with_top(Val::Px(32.0F))
    .with_width(Val::Px(120.0F))
    .with_height(Val::Px(48.0F)),
    tick,
  )

  ui_layout_system(world)

  let rect = get_ui_layout_store(world).get(root).unwrap().rect
  inspect(rect.min.x == 24.0F && rect.min.y == 32.0F, content="true")
  inspect(rect.max.x == 144.0F && rect.max.y == 80.0F, content="true")
  let transform = @transform.get_transform_store(world).get(root).unwrap()
  inspect(transform.translation.x == -316.0F, content="true")
  inspect(transform.translation.y == 244.0F, content="true")
}

///|
test "ui: unparented node acts as implicit root for target camera propagation" {
  let world = @ecs.World::new()
  let tick = seed_ui_context_for_implicit_root_test(world)
  get_ui_scale_resource(world).insert(UiScale::new(2.0F), tick)

  let target_camera = world.spawn_empty()
  @sprite.get_camera_store(world).insert(
    target_camera,
    implicit_root_camera_with_target_info(0, @math.IVec2::new(640, 360), 2.0F),
    tick,
  )

  let root = world.spawn_empty()
  get_node_store(world).insert(root, Node::default(), tick)
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
}
