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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/deferred/copy_lighting_id.rs`.
// Deferred lighting-id copy node/plugin surface.

///|
const COPY_DEFERRED_LIGHTING_ID_PLUGIN_NAME : String = "mgstudio.core_pipeline.deferred.copy_lighting_id.CopyDeferredLightingIdPlugin"

///|
pub const COPY_DEFERRED_LIGHTING_ID_PASS_LABEL : String = "copy_deferred_lighting_id"

///|
pub struct CopyDeferredLightingIdPlugin {}

///|
pub fn CopyDeferredLightingIdPlugin::default() -> CopyDeferredLightingIdPlugin {
  CopyDeferredLightingIdPlugin::{  }
}

///|
pub struct DeferredLightingIdDepthTexture {
  texture_id : Int
}

///|
pub fn DeferredLightingIdDepthTexture::new(
  texture_id~ : Int,
) -> DeferredLightingIdDepthTexture {
  DeferredLightingIdDepthTexture::{ texture_id, }
}

///|
pub fn copy_deferred_lighting_id_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  copy_deferred_lighting_id_plugin_with(
    app,
    CopyDeferredLightingIdPlugin::default(),
  )
}

///|
pub impl @app.Plugin for CopyDeferredLightingIdPlugin with name(_self) {
  COPY_DEFERRED_LIGHTING_ID_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CopyDeferredLightingIdPlugin with build(self, app) {
  copy_deferred_lighting_id_plugin_with(app, self)
}

///|
pub fn copy_deferred_lighting_id_plugin_with(
  app : @app.App[@ecs.World],
  plugin : CopyDeferredLightingIdPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { CopyDeferredLightingIdState::default() })
}

///|
pub fn deferred_lighting_id_depth_texture_id(
  texture : DeferredLightingIdDepthTexture,
) -> Int {
  texture.texture_id
}

///|
pub struct CopyDeferredLightingIdState {
  has_copy_pipeline : Bool
  has_deferred_lighting_pass_id_texture : Bool
}

///|
pub fn CopyDeferredLightingIdState::default() -> CopyDeferredLightingIdState {
  CopyDeferredLightingIdState::new()
}

///|
pub fn CopyDeferredLightingIdState::new(
  has_copy_pipeline? : Bool = false,
  has_deferred_lighting_pass_id_texture? : Bool = false,
) -> CopyDeferredLightingIdState {
  CopyDeferredLightingIdState::{
    has_copy_pipeline,
    has_deferred_lighting_pass_id_texture,
  }
}

///|
pub fn copy_deferred_lighting_id_should_run(
  state : CopyDeferredLightingIdState,
) -> Bool {
  state.has_copy_pipeline && state.has_deferred_lighting_pass_id_texture
}

///|
pub fn deferred_lighting_id_depth_texture_should_prepare(
  physical_target_width : Int,
  physical_target_height : Int,
) -> Bool {
  physical_target_width > 0 && physical_target_height > 0
}

///|
pub let ecs_key_copy_deferred_lighting_id_state : @ecs.ResourceKey[
  CopyDeferredLightingIdState,
] = @ecs.register_resource(
  debug_name="core_pipeline.deferred.copy_lighting_id.state",
)

///|
pub impl @app.Resource for CopyDeferredLightingIdState with resource() {
  ecs_key_copy_deferred_lighting_id_state
}
