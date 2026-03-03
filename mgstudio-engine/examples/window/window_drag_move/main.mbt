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
/// Port of `bevy/examples/window/window_drag_move.rs`.
///
/// Baseline parity:
/// - Captures drag-move intent in runtime logs.
/// - Host window drag API is not exposed in current mgstudio path.
let logged_ref : Ref[Bool] = Ref::new(false)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(window_drag_move_system)
  .run()
}

///|
fn window_drag_move_system(world : @ecs.World) -> Unit {
  world |> ignore
  if logged_ref.val {
    return
  }
  logged_ref.val = true
  log_line("window drag-move is not available in current runtime API")
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[window_drag_move] " + text)
}
