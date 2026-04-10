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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() { @mgstudio.DefaultPlugins::build() })
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(print_mouse_events_system)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(print_mouse_gesture_events_system)),
  )
  .run()
}

///|
fn print_mouse_events_system(
  mouse_button_input_reader : @ecs.MessageReader[@input.MouseButtonInput],
  mouse_motion_reader : @ecs.MessageReader[@input.MouseMotion],
  cursor_moved_reader : @ecs.MessageReader[@window.CursorMoved],
  mouse_wheel_reader : @ecs.MessageReader[@input.MouseWheel],
) -> Unit {
  for event in (try! mouse_button_input_reader.read()) {
    log_line(format_mouse_button_input(event))
  }
  for event in (try! mouse_motion_reader.read()) {
    log_line(format_mouse_motion(event))
  }
  for event in (try! cursor_moved_reader.read()) {
    log_line(format_cursor_moved(event))
  }
  for event in (try! mouse_wheel_reader.read()) {
    log_line(format_mouse_wheel(event))
  }
}

///|
fn print_mouse_gesture_events_system(
  pinch_gesture_reader : @ecs.MessageReader[@input.PinchGesture],
  rotation_gesture_reader : @ecs.MessageReader[@input.RotationGesture],
  double_tap_gesture_reader : @ecs.MessageReader[@input.DoubleTapGesture],
) -> Unit {
  for event in (try! pinch_gesture_reader.read()) {
    log_line("PinchGesture { delta: \{event.delta} }")
  }
  for event in (try! rotation_gesture_reader.read()) {
    log_line("RotationGesture { delta: \{event.delta} }")
  }
  for _event in (try! double_tap_gesture_reader.read()) {
    log_line("DoubleTapGesture")
  }
}

///|
fn format_mouse_button_input(event : @input.MouseButtonInput) -> String {
  "MouseButtonInput { button: \{format_mouse_button(event.button)}, state: \{format_button_state(event.state)} }"
}

///|
fn format_mouse_motion(event : @input.MouseMotion) -> String {
  "MouseMotion { delta: \{format_vec2(event.delta)} }"
}

///|
fn format_cursor_moved(event : @window.CursorMoved) -> String {
  let delta_text = match event.delta {
    Some(delta) => "Some(\{format_vec2(delta)})"
    None => "None"
  }
  "CursorMoved { window: \{event.window.id}, position: \{format_vec2(event.position)}, delta: \{delta_text} }"
}

///|
fn format_mouse_wheel(event : @input.MouseWheel) -> String {
  let unit = match event.unit {
    @input.MouseScrollUnit::Line => "Line"
    @input.MouseScrollUnit::Pixel => "Pixel"
  }
  "MouseWheel { unit: \{unit}, x: \{event.x}, y: \{event.y} }"
}

///|
fn format_mouse_button(button : @window.MouseButton) -> String {
  match button {
    Left => "Left"
    Middle => "Middle"
    Right => "Right"
  }
}

///|
fn format_button_state(state : @input.ButtonState) -> String {
  match state {
    Pressed => "Pressed"
    Released => "Released"
  }
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[mouse_input_events] \{text}")
}
