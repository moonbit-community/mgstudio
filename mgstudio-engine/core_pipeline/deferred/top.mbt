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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/deferred/mod.rs`.
pub const DEFERRED_PLUGIN_ID : String = "bevy_core_pipeline::deferred::DeferredPlugin"

///|
pub struct DeferredPlugin {}

///|
pub fn DeferredPlugin::default() -> DeferredPlugin {
  DeferredPlugin::{  }
}

///|
pub fn deferred_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  deferred_plugin_with(app, DeferredPlugin::default())
}

///|
pub impl @app.PluginReplacement for DeferredPlugin with replacement_id(_self) {
  DEFERRED_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for DeferredPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    deferred_plugin_with(app, self)
  }
}

///|
pub fn deferred_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : DeferredPlugin,
) -> @app.App[@ecs.World] {
  app.add_plugin(copy_deferred_lighting_id_plugin)
}

///|
pub const DEFERRED_PREPASS_EARLY_LABEL : String = "early deferred prepass"

///|
pub const DEFERRED_PREPASS_LATE_LABEL : String = "late deferred prepass"

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/deferred/mod.rs`.
pub struct DeferredPrepass {} derive(ToJson, FromJson)

///|
pub fn DeferredPrepass::default() -> DeferredPrepass {
  DeferredPrepass::{  }
}

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @ecs.register_component(
  debug_name="render3d.deferred_prepass",
)

///|
pub impl @ecs.Component for DeferredPrepass with component() {
  ecs_key_deferred_prepass
}
