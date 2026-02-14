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
/// - Bevy `CursorOptions` / `CursorGrabMode` are not exposed in mgstudio yet.
/// - This port logs and tracks intended grab/visibility state only.
let cursor_grabbed_ref : Ref[Bool] = Ref::new(false)

///|
let cursor_visible_ref : Ref[Bool] = Ref::new(true)

///|
let capability_logged_ref : Ref[Bool] = Ref::new(false)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(grab_mouse_system)
  .run()
}

///|
fn grab_mouse_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  if !capability_logged_ref.val {
    capability_logged_ref.val = true
    log_line(
      "Host cursor visibility/grab control is not exposed; using simulated state.",
    )
  }
  if @input.mouse_button_just_pressed(Left) {
    cursor_visible_ref.val = false
    cursor_grabbed_ref.val = true
    log_state("Locked")
  }
  if @input.key_just_pressed(Escape) {
    cursor_visible_ref.val = true
    cursor_grabbed_ref.val = false
    log_state("None")
  }
}

///|
fn log_state(grab_mode : String) -> Unit {
  log_line(
    "cursor_options { visible: \{cursor_visible_ref.val}, grab_mode: \{grab_mode}, grabbed: \{cursor_grabbed_ref.val} }",
  )
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[mouse_grab] " + text)
}
