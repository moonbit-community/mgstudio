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
/// Port of `bevy/examples/input/touch_input.rs`.
///
/// Baseline parity:
/// - Uses `Res<Touches>` and follows Bevy's iteration flow.
/// - Runtime touch host events are not wired yet, so no touch events are emitted.

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(@app.system_param(touch_system))
  .run()
}

///|
fn touch_system(touches_res : @app.Res[@input.Touches]) -> Unit {
  let touches = touches_res.get()
  for touch in touches.iter_just_pressed() {
    log_line(
      "just pressed touch with id: \{touch.id()}, at: \{format_vec2(touch.position())}",
    )
  }
  for touch in touches.iter_just_released() {
    log_line(
      "just released touch with id: \{touch.id()}, at: \{format_vec2(touch.position())}",
    )
  }
  for touch in touches.iter_just_canceled() {
    log_line("canceled touch with id: \{touch.id()}")
  }
  for touch in touches.iter() {
    log_line(
      "active touch: Touch { id: \{touch.id()}, position: \{format_vec2(touch.position())} }",
    )
    log_line("  just_pressed: \{touches.just_pressed(touch.id())}")
  }
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[touch_input] " + text)
}
