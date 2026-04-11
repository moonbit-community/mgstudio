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
// Bevy source: `bevy/crates/bevy_anti_alias/src/smaa/mod.rs`.

///|
pub const SMAA_RUNTIME_SUPPORTED : Bool = false

///|
pub const SMAA_PLUGIN_ID : String = "bevy_anti_alias::smaa::SmaaPlugin"

///|
pub struct SmaaPlugin {}

///|
pub fn SmaaPlugin::default() -> SmaaPlugin {
  SmaaPlugin::{  }
}

///|
pub(all) enum SmaaPreset {
  Low
  Medium
  High
  Ultra
} derive(Eq, Debug)

///|
pub fn SmaaPreset::default() -> SmaaPreset {
  High
}

///|
pub struct Smaa {
  preset : SmaaPreset
} derive(Eq, Debug)

///|
pub fn Smaa::default() -> Smaa {
  Smaa::{ preset: SmaaPreset::default() }
}

///|
pub struct SmaaRuntimeState {
  enabled_camera_count : Int
  runtime_supported : Bool
} derive(Eq, Debug)

///|
pub fn SmaaRuntimeState::default() -> SmaaRuntimeState {
  SmaaRuntimeState::{
    enabled_camera_count: 0,
    runtime_supported: SMAA_RUNTIME_SUPPORTED,
  }
}

///|
let ecs_key_smaa : @ecs.ComponentKey[Smaa] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::Smaa",
)

///|
let ecs_key_smaa_runtime_state : @ecs.ResourceKey[SmaaRuntimeState] = @ecs.register_resource(
  debug_name="anti_alias.smaa.runtime_state",
)

///|
pub impl @ecs.Component for Smaa with component() {
  ecs_key_smaa
}

///|
pub impl @app.Resource for SmaaRuntimeState with resource() {
  ecs_key_smaa_runtime_state
}

///|
pub impl @app.PluginReplacement for SmaaPlugin with replacement_id(_self) {
  SMAA_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for SmaaPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    smaa_plugin_with(app, self)
  }
}

///|
pub fn smaa_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  smaa_plugin_with(app, SmaaPlugin::default())
}

///|
pub fn smaa_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : SmaaPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { SmaaRuntimeState::default() })
  .add_system(smaa_update_runtime_state)
}

///|
pub fn smaa_update_runtime_state(world : @ecs.World) -> Unit {
  let enabled_camera_count = world.component_count(ecs_key_smaa)
  let next = SmaaRuntimeState::{
    enabled_camera_count,
    runtime_supported: SMAA_RUNTIME_SUPPORTED,
  }
  let current : SmaaRuntimeState? = try! world.get_resource(ecs_key_smaa_runtime_state)
  match current {
    Some(state) =>
      if state != next {
        world.insert_resource(ecs_key_smaa_runtime_state, next)
      }
    None => world.insert_resource(ecs_key_smaa_runtime_state, next)
  }
}
