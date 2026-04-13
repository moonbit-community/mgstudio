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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/skybox/mod.rs`.
// Skybox plugin owner surface.

///|
const SKYBOX_PLUGIN_NAME : String = "mgstudio.core_pipeline.skybox.SkyboxPlugin"

///|
pub struct SkyboxPlugin {}

///|
pub fn SkyboxPlugin::default() -> SkyboxPlugin {
  SkyboxPlugin::{  }
}

///|
pub struct Skybox {} derive(ToJson, FromJson)

///|
pub fn Skybox::default() -> Skybox {
  Skybox::{  }
}

///|
pub const SKYBOX_PIPELINE_LABEL : String = "skybox_pipeline"

///|
pub struct SkyboxPipelineKey {
  hdr : Bool
  samples : Int
  depth_format : String
} derive(Eq, Debug)

///|
pub fn SkyboxPipelineKey::new(
  hdr? : Bool = true,
  samples? : Int = 1,
  depth_format? : String = "depth32float",
) -> SkyboxPipelineKey {
  let samples = if samples <= 0 { 1 } else { samples }
  SkyboxPipelineKey::{ hdr, samples, depth_format }
}

///|
pub struct SkyboxPipelineId {
  pipeline_id : Int
}

///|
pub fn SkyboxPipelineId::new(pipeline_id~ : Int) -> SkyboxPipelineId {
  SkyboxPipelineId::{ pipeline_id, }
}

///|
pub struct SkyboxBindGroup {
  bind_group_id : Int
  skybox_uniform_index : Int
}

///|
pub fn SkyboxBindGroup::new(
  bind_group_id~ : Int,
  skybox_uniform_index~ : Int,
) -> SkyboxBindGroup {
  SkyboxBindGroup::{ bind_group_id, skybox_uniform_index }
}

///|
pub struct SkyboxPrepareViewState {
  has_skybox : Bool
  hdr : Bool
  msaa_samples : Int
  has_view_uniform_binding : Bool
  has_skybox_uniform_binding : Bool
  has_skybox_gpu_image : Bool
}

///|
pub fn SkyboxPrepareViewState::new(
  has_skybox? : Bool = false,
  hdr? : Bool = true,
  msaa_samples? : Int = 1,
  has_view_uniform_binding? : Bool = false,
  has_skybox_uniform_binding? : Bool = false,
  has_skybox_gpu_image? : Bool = false,
) -> SkyboxPrepareViewState {
  SkyboxPrepareViewState::{
    has_skybox,
    hdr,
    msaa_samples,
    has_view_uniform_binding,
    has_skybox_uniform_binding,
    has_skybox_gpu_image,
  }
}

///|
pub fn skybox_should_prepare_pipeline(state : SkyboxPrepareViewState) -> Bool {
  state.has_skybox
}

///|
pub fn skybox_pipeline_key(
  state : SkyboxPrepareViewState,
  depth_format? : String = "depth32float",
) -> SkyboxPipelineKey {
  SkyboxPipelineKey::new(
    hdr=state.hdr,
    samples=state.msaa_samples,
    depth_format~,
  )
}

///|
pub fn skybox_should_prepare_bind_group(state : SkyboxPrepareViewState) -> Bool {
  state.has_skybox &&
  state.has_view_uniform_binding &&
  state.has_skybox_uniform_binding &&
  state.has_skybox_gpu_image
}

///|
pub let ecs_key_skybox : @ecs.ComponentKey[Skybox] = @ecs.register_component(
  debug_name="core_pipeline.skybox",
)

///|
pub impl @ecs.Component for Skybox with component() {
  ecs_key_skybox
}

///|
pub fn skybox_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  skybox_plugin_with(app, SkyboxPlugin::default())
}

///|
pub impl @app.PluginReplacement for SkyboxPlugin with plugin_name(_self) {
  SKYBOX_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for SkyboxPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    skybox_plugin_with(app, self)
  }
}

///|
pub fn skybox_plugin_with(
  app : @app.App[@ecs.World],
  plugin : SkyboxPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { SkyboxPipelineState::default() })
}

///|
pub struct SkyboxPipelineState {
  mut pipeline_count : Int
  mut bind_group_count : Int
}

///|
pub fn SkyboxPipelineState::default() -> SkyboxPipelineState {
  SkyboxPipelineState::{ pipeline_count: 0, bind_group_count: 0 }
}

///|
pub fn SkyboxPipelineState::record_pipeline(self : SkyboxPipelineState) -> Unit {
  self.pipeline_count = self.pipeline_count + 1
}

///|
pub fn SkyboxPipelineState::record_bind_group(
  self : SkyboxPipelineState,
) -> Unit {
  self.bind_group_count = self.bind_group_count + 1
}

///|
pub let ecs_key_skybox_pipeline_state : @ecs.ResourceKey[SkyboxPipelineState] = @ecs.register_resource(
  debug_name="core_pipeline.skybox.pipeline_state",
)

///|
pub impl @app.Resource for SkyboxPipelineState with resource() {
  ecs_key_skybox_pipeline_state
}
