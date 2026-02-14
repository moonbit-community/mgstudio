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
/// Port of `bevy/examples/input/touch_input_events.rs`.
///
/// Baseline parity:
/// - Touch input events are logged in an event-like stream.
/// - Bevy `MessageReader<TouchInput>` is not available in mgstudio.
/// - Left mouse is mapped to a synthetic single touch id (`0`).
let touch_active_ref : Ref[Bool] = Ref::new(false)

///|
let last_touch_position_ref : Ref[@math.Vec2?] = Ref::new(None)

///|
let capability_logged_ref : Ref[Bool] = Ref::new(false)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(touch_event_system)
  .run()
}

///|
fn touch_event_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  if !capability_logged_ref.val {
    capability_logged_ref.val = true
    log_line(
      "Native touch message stream is unavailable; using left mouse as touch id 0.",
    )
  }

  let position_opt = @input.mouse_position()
  if @input.mouse_button_just_pressed(Left) {
    touch_active_ref.val = true
    if position_opt is Some(position) {
      last_touch_position_ref.val = Some(position)
      log_touch_input("Started", position)
    }
  }

  if touch_active_ref.val &&
    @input.mouse_button_pressed(Left) &&
    position_opt is Some(position) {
    if should_emit_move(position) {
      last_touch_position_ref.val = Some(position)
      log_touch_input("Moved", position)
    }
  }

  if @input.mouse_button_just_released(Left) {
    touch_active_ref.val = false
    if position_opt is Some(position) {
      last_touch_position_ref.val = Some(position)
      log_touch_input("Ended", position)
    } else if last_touch_position_ref.val is Some(last_position) {
      log_touch_input("Ended", last_position)
    }
  }
}

///|
fn should_emit_move(position : @math.Vec2) -> Bool {
  match last_touch_position_ref.val {
    Some(last_position) =>
      position.x != last_position.x || position.y != last_position.y
    None => true
  }
}

///|
fn log_touch_input(phase : String, position : @math.Vec2) -> Unit {
  log_line(
    "TouchInput { id: 0, phase: \{phase}, position: \{format_vec2(position)} }",
  )
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[touch_input_events] " + text)
}
