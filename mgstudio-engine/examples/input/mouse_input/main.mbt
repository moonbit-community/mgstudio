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
/// Port of `bevy/examples/input/mouse_input.rs`.
///
/// Baseline parity:
/// - Left mouse button pressed/just-pressed/just-released semantics are preserved.
/// - Mouse motion and wheel deltas are read from accumulated per-frame resources.

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Update, @app.system(@app.system_param(mouse_click_system)))
  .add_systems(@app.Update, @app.system(@app.system_param2(mouse_move_system)))
  .run()
}

///|
fn mouse_click_system(mouse : @input.ButtonInput[@window.MouseButton]) -> Unit {
  if mouse.pressed(Left) {
    log_line("left mouse currently pressed")
  }
  if mouse.just_pressed(Left) {
    log_line("left mouse just pressed")
  }
  if mouse.just_released(Left) {
    log_line("left mouse just released")
  }
}

///|
fn mouse_move_system(
  accumulated_mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  accumulated_mouse_scroll : @app.Res[@input.AccumulatedMouseScroll],
) -> Unit {
  let motion = accumulated_mouse_motion.get().delta
  if !is_zero_vec2(motion) {
    log_line("mouse moved \{format_vec2(motion)}")
  }
  let scroll = accumulated_mouse_scroll.get().delta
  if !is_zero_vec2(scroll) {
    log_line("mouse scrolled \{format_vec2(scroll)}")
  }
}

///|
fn is_zero_vec2(v : @math.Vec2) -> Bool {
  v.x == 0.0F && v.y == 0.0F
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[mouse_input] " + text)
}
