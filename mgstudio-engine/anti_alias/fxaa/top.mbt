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
// Bevy source: `bevy/crates/bevy_anti_alias/src/fxaa/mod.rs`.

///|
pub type Fxaa = @post_process.Fxaa

///|
pub type FxaaSensitivity = @post_process.FxaaSensitivity

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @post_process.ecs_key_fxaa

///|
pub const FXAA_PLUGIN_ID : String = "bevy_anti_alias::fxaa::FxaaPlugin"

///|
pub struct FxaaPlugin {}

///|
pub fn FxaaPlugin::default() -> FxaaPlugin {
  FxaaPlugin::{  }
}

///|
pub struct FxaaRuntimeState {
  enabled_camera_count : Int
} derive(Eq, Debug)

///|
pub fn FxaaRuntimeState::default() -> FxaaRuntimeState {
  FxaaRuntimeState::{ enabled_camera_count: 0 }
}

///|
pub let ecs_key_fxaa_runtime_state : @ecs.ResourceKey[FxaaRuntimeState] = @ecs.register_resource(
  debug_name="anti_alias.fxaa.runtime_state",
)

///|
pub impl @app.Resource for FxaaRuntimeState with resource() {
  ecs_key_fxaa_runtime_state
}

///|
pub impl @app.PluginReplacement for FxaaPlugin with replacement_id(_self) {
  FXAA_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for FxaaPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    fxaa_plugin_with(app, self)
  }
}

///|
pub fn fxaa_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  fxaa_plugin_with(app, FxaaPlugin::default())
}

///|
pub fn fxaa_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : FxaaPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { FxaaRuntimeState::default() })
  .add_system(fxaa_update_runtime_state)
}

///|
pub fn fxaa_update_runtime_state(world : @ecs.World) -> Unit {
  let enabled_camera_count = world.component_count(ecs_key_fxaa)
  let current_state : FxaaRuntimeState? = try! world.get_resource(
    ecs_key_fxaa_runtime_state,
  )
  match current_state {
    Some(state) =>
      if state.enabled_camera_count != enabled_camera_count {
        world.insert_resource(ecs_key_fxaa_runtime_state, FxaaRuntimeState::{
          enabled_camera_count,
        })
      }
    None =>
      world.insert_resource(ecs_key_fxaa_runtime_state, FxaaRuntimeState::{
        enabled_camera_count,
      })
  }
}
