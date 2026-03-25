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
/// Anti-aliasing API boundary aligned with Bevy's `bevy_anti_alias` crate.
/// Surface re-exports are sourced from `core_pipeline` and `post_process`.
/// Current surface maps to available MSAA/FXAA/TAA components.

///|
pub struct AntiAliasPlugin {}

///|
pub fn AntiAliasPlugin::default() -> AntiAliasPlugin {
  AntiAliasPlugin::{  }
}

///|
pub const ANTI_ALIAS_PLUGIN_ID : String = "bevy_anti_alias::AntiAliasPlugin"

///|
pub fn anti_alias_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}

///|
pub type Msaa = @core_pipeline.Msaa

///|
pub type Fxaa = @post_process.Fxaa

///|
pub type FxaaSensitivity = @post_process.FxaaSensitivity

///|
pub type TemporalAntiAliasing = @post_process.TemporalAntiAliasing

///|
pub type TemporalJitter = @post_process.TemporalJitter

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @core_pipeline.ecs_key_msaa

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @post_process.ecs_key_fxaa

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @post_process.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @post_process.ecs_key_temporal_jitter
