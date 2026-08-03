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
// Bevy source: `bevy/crates/bevy_gizmos/src/transform_gizmo.rs`.
//
// Whitebox tests for the hover and drag systems, driven through a real
// `App::update` so the schedule placement runs too. The world carries the
// minimum the systems read: a `Camera3d` camera, a `TransformGizmoFocus`
// entity, and a primary `Window` whose cursor position the tests place. Mouse
// buttons come from the native input statics, which a test process leaves
// unpressed, so only the paths that need a *held* or *just pressed* button are
// out of reach here; those stay covered by the example.

///|
priv struct GizmoSystemsTestScene {
  app : @app.App[@ecs.World]
  focus : @core.Entity
  window : @core.Entity
}

///|
fn gizmo_systems_test_scene() -> GizmoSystemsTestScene {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    TransformGizmoPlugin::TransformGizmoPlugin(),
  )
  let world = app.world()
  let camera = world.spawn_empty()
  try! world.set_by_key(
    camera,
    @camera_components3d.ecs_key_camera3d,
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! world.set_by_key(
    camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    camera,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 4.0F, 8.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  let focus = world.spawn_empty()
  try! world.set_by_key(
    focus,
    ecs_key_transform_gizmo_focus,
    TransformGizmoFocus::TransformGizmoFocus(),
  )
  try! world.set_by_key(
    focus,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-2.0F, 1.0F, 0.0F),
  )
  let window = world.spawn_empty()
  try! world.set_by_key(window, @window.ecs_key_window, @window.Window::Window())
  try! world.set_by_key(
    window,
    @window.ecs_key_primary_window,
    @window.PrimaryWindow::{  },
  )
  { app, focus, window }
}

///|
fn gizmo_systems_test_place_cursor(
  scene : GizmoSystemsTestScene,
  position : @math.Vec2,
) -> Unit {
  let world = scene.app.world()
  guard (try! world.get_by_key(scene.window, @window.ecs_key_window))
    is Some(window_value) else {
    abort("test window missing")
  }
  window_value.set_physical_cursor_position(Some(position))
  try! world.set_by_key(scene.window, @window.ecs_key_window, window_value)
}

///|
/// Project the midpoint of the X translate handle with the same helpers the
/// hover system uses, so the expected cursor position tracks the settings.
fn gizmo_systems_test_x_handle_screen(
  scene : GizmoSystemsTestScene,
) -> @math.Vec2 {
  let world = scene.app.world()
  guard resolve_gizmo_camera(world) is Some(gizmo_camera) else {
    abort("test camera not resolved")
  }
  let settings = transform_gizmo_settings_of(world)
  guard focused_entity(world) is Some((_, focus_transform)) else {
    abort("test focus not resolved")
  }
  let gizmo_pos = focus_transform.translation
  let rotation = gizmo_rotation(
    focus_transform.rotation,
    effective_space(settings),
  )
  let cam_forward = transform_forward(gizmo_camera.transform)
  let dir = axis_direction(X, rotation, cam_forward)
  let scale = gizmo_screen_scale(
    settings,
    gizmo_camera.transform.translation,
    gizmo_pos,
  )
  let start = gizmo_pos.add(dir.mul_scalar(AXIS_START_OFFSET * scale))
  let endpoint = gizmo_pos.add(dir.mul_scalar(settings.axis_length * scale))
  let midpoint = start.add(endpoint).mul_scalar(0.5F)
  let target_size = camera_target_size(gizmo_camera.camera, 1280, 720)
  guard world_to_viewport(gizmo_camera, target_size, 1.0F, midpoint)
    is Some(screen) else {
    abort("X handle midpoint does not project")
  }
  screen
}

///|
test "transform_gizmo: hover marks the axis under the cursor" {
  let scene = gizmo_systems_test_scene()
  defer scene.app.world().close()
  gizmo_systems_test_place_cursor(scene, gizmo_systems_test_x_handle_screen(scene))
  ignore(scene.app.update())
  let state = transform_gizmo_state_of(scene.app.world())
  debug_inspect(state.hovered_axis is Some(X), content="true")
  debug_inspect(state.active, content="false")
}

///|
test "transform_gizmo: hover clears when the cursor is elsewhere" {
  let scene = gizmo_systems_test_scene()
  defer scene.app.world().close()
  // First frame on the handle, second frame in an empty corner: the hover
  // system must clear the stale axis, not only set fresh ones.
  gizmo_systems_test_place_cursor(scene, gizmo_systems_test_x_handle_screen(scene))
  ignore(scene.app.update())
  gizmo_systems_test_place_cursor(scene, @math.Vec2::new(5.0F, 5.0F))
  ignore(scene.app.update())
  let state = transform_gizmo_state_of(scene.app.world())
  debug_inspect(state.hovered_axis is None, content="true")
}

///|
test "transform_gizmo: hover needs a cursor inside the window" {
  let scene = gizmo_systems_test_scene()
  defer scene.app.world().close()
  // No cursor position at all: the system returns before computing anything.
  ignore(scene.app.update())
  let state = transform_gizmo_state_of(scene.app.world())
  debug_inspect(state.hovered_axis is None, content="true")
}

///|
test "transform_gizmo: drag ends when the button is not held" {
  let scene = gizmo_systems_test_scene()
  defer scene.app.world().close()
  let world = scene.app.world()
  gizmo_systems_test_place_cursor(scene, @math.Vec2::new(640.0F, 360.0F))
  // Seed a drag in progress. Bevy ends a drag on `!pressed` rather than
  // `just_released` so it also ends when the button was released off-window;
  // the test process never presses the button, which is exactly that case.
  let focus_transform = @transform.Transform::from_xyz(-2.0F, 1.0F, 0.0F)
  set_gizmo_state(world, {
    ..transform_gizmo_state_of(world),
    active: true,
    axis: Some(X),
    start_transform: focus_transform,
    entity: Some(scene.focus),
    drag_start_world: focus_transform.translation,
    gizmo_origin: focus_transform.translation,
  })
  ignore(scene.app.update())
  let state = transform_gizmo_state_of(world)
  debug_inspect(state.active, content="false")
  debug_inspect(state.axis is None, content="true")
  debug_inspect(state.entity is None, content="true")
}

///|
test "transform_gizmo: hover does not retarget during an active drag" {
  let scene = gizmo_systems_test_scene()
  defer scene.app.world().close()
  let world = scene.app.world()
  // Cursor parked on the X handle, but the state says a drag is active. The
  // hover system must leave `hovered_axis` cleared instead of retargeting;
  // since the button is not held the drag system deactivates in the same
  // frame, and hover ran with the pre-deactivation state.
  gizmo_systems_test_place_cursor(scene, gizmo_systems_test_x_handle_screen(scene))
  let focus_transform = @transform.Transform::from_xyz(-2.0F, 1.0F, 0.0F)
  set_gizmo_state(world, {
    ..transform_gizmo_state_of(world),
    active: true,
    axis: Some(X),
    start_transform: focus_transform,
    entity: Some(scene.focus),
    drag_start_world: focus_transform.translation,
    gizmo_origin: focus_transform.translation,
  })
  ignore(scene.app.update())
  let state = transform_gizmo_state_of(world)
  debug_inspect(state.active, content="false")
}
