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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs`.
const PREPASS_PLUGIN_NAME : String = "mgstudio.core_pipeline.prepass.PrepassPlugin"

///|
pub const EARLY_PREPASS_LABEL : String = "early prepass"

///|
pub const LATE_PREPASS_LABEL : String = "late prepass"

///|
pub struct PrepassPlugin {}

///|
pub fn PrepassPlugin::default() -> PrepassPlugin {
  PrepassPlugin::{  }
}

///|
pub fn prepass_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  prepass_plugin_with(app, PrepassPlugin::default())
}

///|
pub impl @app.Plugin for PrepassPlugin with name(_self) {
  PREPASS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for PrepassPlugin with build(self, app) {
  prepass_plugin_with(app, self)
}

///|
pub fn prepass_plugin_with(
  app : @app.App[@ecs.World],
  plugin : PrepassPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { PrepassViewState::default() })
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs`.
pub struct DepthPrepass {} derive(ToJson, FromJson)

///|
pub fn DepthPrepass::default() -> DepthPrepass {
  DepthPrepass::{  }
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs`.
pub struct NormalPrepass {} derive(ToJson, FromJson)

///|
pub fn NormalPrepass::default() -> NormalPrepass {
  NormalPrepass::{  }
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/prepass/mod.rs`.
pub struct MotionVectorPrepass {} derive(ToJson, FromJson)

///|
pub fn MotionVectorPrepass::default() -> MotionVectorPrepass {
  MotionVectorPrepass::{  }
}

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @ecs.register_component(
  debug_name="render3d.depth_prepass",
)

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @ecs.register_component(
  debug_name="render3d.normal_prepass",
)

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @ecs.register_component(
  debug_name="render3d.motion_vector_prepass",
)

///|
pub impl @ecs.Component for DepthPrepass with component() {
  ecs_key_depth_prepass
}

///|
pub impl @ecs.Component for NormalPrepass with component() {
  ecs_key_normal_prepass
}

///|
pub impl @ecs.Component for MotionVectorPrepass with component() {
  ecs_key_motion_vector_prepass
}

///|
pub let ecs_key_prepass_view_state : @ecs.ResourceKey[PrepassViewState] = @ecs.register_resource(
  debug_name="core_pipeline.prepass.view_state",
)

///|
pub impl @app.Resource for PrepassViewState with resource() {
  ecs_key_prepass_view_state
}
