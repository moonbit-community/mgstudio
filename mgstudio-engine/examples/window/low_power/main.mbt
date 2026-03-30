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
///
/// Baseline parity:
/// - Demonstrates low-power/window-update strategy intent.
/// - Bevy present-mode and wakeup tuning surface is not available in this path.
let logged_ref : Ref[Bool] = Ref::new(false)

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup_visual))
  .add_systems(@app.Update, @app.system(low_power_system))
  .run()
}

///|
fn setup_visual(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_clear_color(
      @sprite.Color::srgb(0.14F, 0.18F, 0.24F),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn low_power_system(world : @ecs.World) -> Unit {
  world |> ignore
  if logged_ref.val {
    return
  }
  logged_ref.val = true
  log_line(
    "low-power scheduling knobs are not exposed; runtime uses default loop behavior",
  )
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[low_power] " + text)
}
