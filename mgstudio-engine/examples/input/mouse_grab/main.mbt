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
/// Port of `bevy/examples/input/mouse_grab.rs`.
///
/// Baseline parity:
/// - Left click enters grabbed state; Escape exits grabbed state.
/// - Behavior is applied through mgstudio window cursor APIs.
let cursor_grabbed_ref : Ref[Bool] = Ref::new(false)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(@app.system_param2(grab_mouse_system))
  .run()
}

///|
fn grab_mouse_system(
  mouse : @input.ButtonInput[@window.MouseButton],
  key : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if mouse.just_pressed(Left) {
    @window.window_set_cursor_visible(visible=false)
    @window.window_set_cursor_grab_mode(mode=GrabLocked)
    cursor_grabbed_ref.val = true
    log_state("Locked")
  }
  if key.just_pressed(Escape) {
    @window.window_set_cursor_visible(visible=true)
    @window.window_set_cursor_grab_mode(mode=GrabNone)
    cursor_grabbed_ref.val = false
    log_state("None")
  }
}

///|
fn log_state(grab_mode : String) -> Unit {
  let visible = !cursor_grabbed_ref.val
  log_line("cursor_options { visible: \{visible}, grab_mode: \{grab_mode} }")
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[mouse_grab] " + text)
}
