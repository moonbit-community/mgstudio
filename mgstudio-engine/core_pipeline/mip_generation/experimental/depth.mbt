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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/mip_generation/experimental/depth.rs`.
// Experimental depth mip-generation node descriptor.

///|
pub const EXPERIMENTAL_DEPTH_MIP_GENERATION_LABEL : String = "mip_generation.experimental.depth"

///|
pub struct ExperimentalDepthMipGenerationNode {
  label : String
}

///|
pub fn ExperimentalDepthMipGenerationNode::default() -> ExperimentalDepthMipGenerationNode {
  ExperimentalDepthMipGenerationNode::{
    label: EXPERIMENTAL_DEPTH_MIP_GENERATION_LABEL,
  }
}

///|
pub fn ExperimentalDepthMipGenerationNode::label(
  self : ExperimentalDepthMipGenerationNode,
) -> String {
  self.label
}

///|
pub const DEPTH_PYRAMID_MIP_COUNT : Int = 12

///|
pub(all) enum DownsampleDepthPassKind {
  Early
  Late
} derive(Eq, Debug)

///|
pub fn downsample_depth_pass_label(kind : DownsampleDepthPassKind) -> String {
  match kind {
    Early => "early_downsample_depth"
    Late => "late_downsample_depth"
  }
}

///|
pub struct DownsampleDepthPipelinePairState {
  first_pipeline_ready : Bool
  second_pipeline_ready : Bool
  first_multisample_pipeline_ready : Bool
  second_multisample_pipeline_ready : Bool
}

///|
pub fn DownsampleDepthPipelinePairState::default() -> DownsampleDepthPipelinePairState {
  DownsampleDepthPipelinePairState::new()
}

///|
pub fn DownsampleDepthPipelinePairState::new(
  first_pipeline_ready? : Bool = false,
  second_pipeline_ready? : Bool = false,
  first_multisample_pipeline_ready? : Bool = false,
  second_multisample_pipeline_ready? : Bool = false,
) -> DownsampleDepthPipelinePairState {
  DownsampleDepthPipelinePairState::{
    first_pipeline_ready,
    second_pipeline_ready,
    first_multisample_pipeline_ready,
    second_multisample_pipeline_ready,
  }
}

///|
pub fn downsample_depth_pipeline_pair_ready(
  pipelines : DownsampleDepthPipelinePairState,
  multisampled~ : Bool,
) -> Bool {
  if multisampled {
    pipelines.first_multisample_pipeline_ready &&
    pipelines.second_multisample_pipeline_ready
  } else {
    pipelines.first_pipeline_ready && pipelines.second_pipeline_ready
  }
}

///|
pub struct DownsampleDepthViewState {
  has_depth_pyramid : Bool
  has_downsample_bind_group : Bool
  depth_texture_width : Int
  depth_texture_height : Int
  depth_texture_sample_count : Int
}

///|
pub fn DownsampleDepthViewState::new(
  has_depth_pyramid? : Bool = false,
  has_downsample_bind_group? : Bool = false,
  depth_texture_width? : Int = 0,
  depth_texture_height? : Int = 0,
  depth_texture_sample_count? : Int = 1,
) -> DownsampleDepthViewState {
  DownsampleDepthViewState::{
    has_depth_pyramid,
    has_downsample_bind_group,
    depth_texture_width,
    depth_texture_height,
    depth_texture_sample_count,
  }
}

///|
pub fn downsample_depth_view_has_valid_size(
  state : DownsampleDepthViewState,
) -> Bool {
  state.depth_texture_width > 0 && state.depth_texture_height > 0
}

///|
pub fn downsample_depth_view_is_multisampled(
  state : DownsampleDepthViewState,
) -> Bool {
  state.depth_texture_sample_count > 1
}

///|
pub fn downsample_depth_should_run(
  state : DownsampleDepthViewState,
  pipelines : DownsampleDepthPipelinePairState,
) -> Bool {
  state.has_depth_pyramid &&
  state.has_downsample_bind_group &&
  downsample_depth_view_has_valid_size(state) &&
  downsample_depth_pipeline_pair_ready(
    pipelines,
    multisampled=downsample_depth_view_is_multisampled(state),
  )
}

///|
pub let ecs_key_downsample_depth_pipeline_pair_state : @ecs.ResourceKey[
  DownsampleDepthPipelinePairState,
] = @ecs.register_resource(
  debug_name="core_pipeline.mip_generation.experimental.depth.pipeline_pair_state",
)

///|
pub impl @app.Resource for DownsampleDepthPipelinePairState with resource() {
  ecs_key_downsample_depth_pipeline_pair_state
}
