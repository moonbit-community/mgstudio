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
/// Port of `bevy/examples/app/return_after_run.rs`.

///|
fn set_title(_world : @ecs_world.World) -> Unit {
  @window.window_set_title(
    title="Close the window to return to the main function",
  )
}

///|
fn system(_world : @ecs_world.World) -> Unit {
  println("Logging from Bevy App")
}

///|
pub fn game_app() -> Unit {
  println("Running Bevy App")
  let plugins = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(set_title)
  .add_system(system)
  .run()
  println("Bevy App has exited. We are back in our main function.")
}
