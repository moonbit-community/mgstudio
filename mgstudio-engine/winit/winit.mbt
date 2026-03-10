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
/// Winit-facing API boundary aligned with Bevy-style window backend responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/window`.

///|
pub type WindowPlugin = @window.WindowPlugin

///|
pub fn window_backend_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @window.window_plugin(app)
}

///|
pub fn window_backend_plugin_with(
  app : @app.App[@ecs.World],
  plugin : WindowPlugin,
) -> @app.App[@ecs.World] {
  @window.window_plugin_with(app, plugin)
}

///|
pub fn window_backend_runner_builder(app : @app.App[@ecs.World]) -> () -> Unit {
  @window.window_runner_builder(app)
}

///|
pub fn poll_backend_events(world : @ecs.World) -> Unit {
  @window.window_poll_host_events(world)
}
