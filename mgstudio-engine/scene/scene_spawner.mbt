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
// Bevy source: `bevy/crates/bevy_scene/src/scene_spawner.rs`.

///|
pub fn scene_spawner_run_load_pending_system(world : @ecs.World) -> Unit {
  scene_load_pending_system(world)
}

///|
pub fn scene_spawner_run_spawn_roots_system(world : @ecs.World) -> Unit {
  scene_spawn_roots_system(world)
}

///|
pub fn scene_spawner_run_reload_modified_roots_system(
  world : @ecs.World,
) -> Unit {
  scene_reload_modified_roots_system(world)
}

///|
pub fn scene_spawner_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  scene_plugin(app)
}

///|
pub fn scene_spawner_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ScenePlugin,
) -> @app.App[@ecs.World] {
  scene_plugin_with(app, plugin)
}
