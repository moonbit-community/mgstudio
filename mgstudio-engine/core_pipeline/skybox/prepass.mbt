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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/skybox/prepass.rs`.
// Skybox prepass node descriptor.

///|
pub const SKYBOX_PREPASS_LABEL : String = "skybox_prepass"

///|
pub struct SkyboxPrepassNode {
  label : String
}

///|
pub fn SkyboxPrepassNode::default() -> SkyboxPrepassNode {
  SkyboxPrepassNode::{ label: SKYBOX_PREPASS_LABEL }
}

///|
pub fn SkyboxPrepassNode::label(self : SkyboxPrepassNode) -> String {
  self.label
}

///|
pub const SKYBOX_PREPASS_PIPELINE_LABEL : String = "skybox_prepass_pipeline"

///|
pub const SKYBOX_PREPASS_BIND_GROUP_LABEL : String = "skybox_prepass_bind_group"

///|
pub struct SkyboxPrepassPipelineKey {
  samples : Int
  normal_prepass : Bool
} derive(Eq, Debug)

///|
pub fn SkyboxPrepassPipelineKey::new(
  samples~ : Int,
  normal_prepass~ : Bool,
) -> SkyboxPrepassPipelineKey {
  let samples = if samples <= 0 { 1 } else { samples }
  SkyboxPrepassPipelineKey::{ samples, normal_prepass }
}

///|
pub struct RenderSkyboxPrepassPipeline {
  pipeline_id : Int
}

///|
pub fn RenderSkyboxPrepassPipeline::new(
  pipeline_id~ : Int,
) -> RenderSkyboxPrepassPipeline {
  RenderSkyboxPrepassPipeline::{ pipeline_id, }
}

///|
pub struct SkyboxPrepassBindGroup {
  bind_group_id : Int
}

///|
pub fn SkyboxPrepassBindGroup::new(
  bind_group_id~ : Int,
) -> SkyboxPrepassBindGroup {
  SkyboxPrepassBindGroup::{ bind_group_id, }
}

///|
pub struct SkyboxPrepassViewState {
  has_skybox : Bool
  has_motion_vector_prepass : Bool
  has_normal_prepass : Bool
  msaa_samples : Int
  has_view_uniform_binding : Bool
  has_previous_view_uniform_binding : Bool
}

///|
pub fn SkyboxPrepassViewState::new(
  has_skybox? : Bool = false,
  has_motion_vector_prepass? : Bool = false,
  has_normal_prepass? : Bool = false,
  msaa_samples? : Int = 1,
  has_view_uniform_binding? : Bool = false,
  has_previous_view_uniform_binding? : Bool = false,
) -> SkyboxPrepassViewState {
  SkyboxPrepassViewState::{
    has_skybox,
    has_motion_vector_prepass,
    has_normal_prepass,
    msaa_samples,
    has_view_uniform_binding,
    has_previous_view_uniform_binding,
  }
}

///|
pub fn skybox_prepass_should_prepare_pipeline(
  state : SkyboxPrepassViewState,
) -> Bool {
  state.has_skybox && state.has_motion_vector_prepass
}

///|
pub fn skybox_prepass_pipeline_key(
  state : SkyboxPrepassViewState,
) -> SkyboxPrepassPipelineKey {
  SkyboxPrepassPipelineKey::new(
    samples=state.msaa_samples,
    normal_prepass=state.has_normal_prepass,
  )
}

///|
pub fn skybox_prepass_should_prepare_bind_group(
  state : SkyboxPrepassViewState,
) -> Bool {
  skybox_prepass_should_prepare_pipeline(state) &&
  state.has_view_uniform_binding &&
  state.has_previous_view_uniform_binding
}
