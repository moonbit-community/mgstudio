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
fn pan_camera_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn pan_camera_approx_eq(a : Float, b : Float) -> Bool {
  pan_camera_abs_float(a - b) < 0.001F
}

///|
test "render2d: pan camera default text matches bevy controls" {
  let text = PanCamera::default().to_string()
  inspect(text.contains("PanCamera Controls:"), content="true")
  inspect(text.contains("KeyW / KeyS"), content="true")
  inspect(text.contains("Mouse Scroll + Equal / Minus"), content="true")
}

///|
test "render2d: pan camera movement normalizes diagonal input" {
  let key_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  key_input.press(@window.KeyCode::KeyW)
  key_input.press(@window.KeyCode::KeyD)
  let scroll = @input.AccumulatedMouseScroll::new()
  let (transform, _controller) = pan_camera_step(
    @math.Transform::identity(),
    PanCamera::default(),
    0.5F,
    key_input,
    scroll,
  )
  inspect(transform.translation.x > 176.7F, content="true")
  inspect(transform.translation.x < 176.8F, content="true")
  inspect(transform.translation.y > 176.7F, content="true")
  inspect(transform.translation.y < 176.8F, content="true")
}

///|
test "render2d: pan camera rotation and zoom follow controller settings" {
  let key_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  key_input.press(@window.KeyCode::KeyQ)
  key_input.press(@window.KeyCode::Equal)
  let scroll = @input.AccumulatedMouseScroll::new_with_unit(
    @input.MouseScrollUnit::Line,
    @math.Vec2::new(0.0F, 1.0F),
  )
  let (transform, controller) = pan_camera_step(
    @math.Transform::identity(),
    PanCamera::default(),
    0.5F,
    key_input,
    scroll,
  )
  inspect(
    pan_camera_approx_eq(transform.rotation_z(), 1.5707963267948966F),
    content="true",
  )
  inspect(pan_camera_approx_eq(controller.zoom_factor, 1.0F), content="true")
  inspect(pan_camera_approx_eq(transform.scale.x, 1.0F), content="true")
  inspect(pan_camera_approx_eq(transform.scale.y, 1.0F), content="true")
}

///|
test "render2d: pan camera zoom clamps to configured bounds" {
  let key_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  let scroll = @input.AccumulatedMouseScroll::new_with_unit(
    @input.MouseScrollUnit::Line,
    @math.Vec2::new(0.0F, 200.0F),
  )
  let controller = PanCamera::{
    ..PanCamera::default(),
    min_zoom: 0.5F,
    max_zoom: 2.0F,
  }
  let (transform, updated) = pan_camera_step(
    @math.Transform::identity(),
    controller,
    0.0F,
    key_input,
    scroll,
  )
  inspect(pan_camera_approx_eq(updated.zoom_factor, 0.5F), content="true")
  inspect(pan_camera_approx_eq(transform.scale.x, 0.5F), content="true")
  inspect(pan_camera_approx_eq(transform.scale.y, 0.5F), content="true")
}
