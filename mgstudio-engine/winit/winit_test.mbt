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
fn read_window_created(world : @ecs.World) -> Array[@window.WindowCreated] {
  let reader = world.message_reader(@window.ecs_key_window_created, Ref::new(0))
  try! reader.read()
}

///|
test "winit: plugin replacement id aligns with bevy_winit" {
  let plugin = WinitPlugin::default()
  inspect(plugin.replacement_id(), content=WINIT_PLUGIN_ID)
}

///|
test "winit: backend sync is owned by winit plugin" {
  let app_without_winit = @window.window_plugin(
    @app.App::new(@ecs.World::new()),
  ).run_once()
  inspect(read_window_created(app_without_winit.world()).length(), content="0")

  let app_with_winit = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  inspect(read_window_created(app_with_winit.world()).length(), content="1")
}
