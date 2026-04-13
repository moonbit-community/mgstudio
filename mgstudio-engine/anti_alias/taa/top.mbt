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
// Bevy source: `bevy/crates/bevy_anti_alias/src/taa/mod.rs`.

///|
pub type TemporalAntiAliasing = @post_process.TemporalAntiAliasing

///|
pub type TemporalJitter = @post_process.TemporalJitter

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @post_process.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @post_process.ecs_key_temporal_jitter

///|
const TEMPORAL_ANTI_ALIAS_PLUGIN_NAME : String = "mgstudio.anti_alias.taa.TemporalAntiAliasPlugin"

///|
pub struct TemporalAntiAliasPlugin {}

///|
pub fn TemporalAntiAliasPlugin::default() -> TemporalAntiAliasPlugin {
  TemporalAntiAliasPlugin::{  }
}

///|
pub struct TemporalAntiAliasRuntimeState {
  enabled_camera_count : Int
  reset_requested_count : Int
} derive(Eq, Debug)

///|
pub fn TemporalAntiAliasRuntimeState::default() -> TemporalAntiAliasRuntimeState {
  TemporalAntiAliasRuntimeState::{
    enabled_camera_count: 0,
    reset_requested_count: 0,
  }
}

///|
pub let ecs_key_temporal_anti_alias_runtime_state : @ecs.ResourceKey[
  TemporalAntiAliasRuntimeState,
] = @ecs.register_resource(debug_name="anti_alias.taa.runtime_state")

///|
pub impl @app.Resource for TemporalAntiAliasRuntimeState with resource() {
  ecs_key_temporal_anti_alias_runtime_state
}

///|
pub impl @app.PluginReplacement for TemporalAntiAliasPlugin with plugin_name(
  _self,
) {
  TEMPORAL_ANTI_ALIAS_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for TemporalAntiAliasPlugin with world_plugin(
  self,
) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    temporal_anti_alias_plugin_with(app, self)
  }
}

///|
pub fn temporal_anti_alias_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  temporal_anti_alias_plugin_with(app, TemporalAntiAliasPlugin::default())
}

///|
pub fn temporal_anti_alias_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : TemporalAntiAliasPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { TemporalAntiAliasRuntimeState::default() })
  .add_system(temporal_anti_alias_update_runtime_state)
}

///|
fn temporal_anti_alias_camera_component_present(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, @sprite.ecs_key_camera)
}

///|
pub fn temporal_anti_alias_update_runtime_state(world : @ecs.World) -> Unit {
  let mut enabled_camera_count = 0
  let mut reset_requested_count = 0
  world.for_each_component(ecs_key_temporal_anti_aliasing, fn(
    entity,
    taa : TemporalAntiAliasing,
  ) {
    if temporal_anti_alias_camera_component_present(world, entity) {
      enabled_camera_count = enabled_camera_count + 1
      if taa.reset {
        reset_requested_count = reset_requested_count + 1
      }
    }
  })
  let next = TemporalAntiAliasRuntimeState::{
    enabled_camera_count,
    reset_requested_count,
  }
  let current : TemporalAntiAliasRuntimeState? = try! world.get_resource(
    ecs_key_temporal_anti_alias_runtime_state,
  )
  match current {
    Some(state) =>
      if state != next {
        world.insert_resource(ecs_key_temporal_anti_alias_runtime_state, next)
      }
    None =>
      world.insert_resource(ecs_key_temporal_anti_alias_runtime_state, next)
  }
}
