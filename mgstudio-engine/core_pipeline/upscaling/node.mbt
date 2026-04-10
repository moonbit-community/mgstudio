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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/upscaling/node.rs`.
// Upscaling node descriptor.

///|
pub const UPSCALING_PASS_LABEL : String = "upscaling"

///|
pub struct UpscalingNode {
  label : String
}

///|
pub fn UpscalingNode::default() -> UpscalingNode {
  UpscalingNode::{ label: UPSCALING_PASS_LABEL }
}

///|
pub fn UpscalingNode::label(self : UpscalingNode) -> String {
  self.label
}

///|
pub struct UpscalingNodeState {
  camera_output_mode_skip : Bool
  has_specialized_pipeline : Bool
  has_camera_viewport : Bool
}

///|
pub fn UpscalingNodeState::new(
  camera_output_mode_skip? : Bool = false,
  has_specialized_pipeline? : Bool = false,
  has_camera_viewport? : Bool = false,
) -> UpscalingNodeState {
  UpscalingNodeState::{
    camera_output_mode_skip,
    has_specialized_pipeline,
    has_camera_viewport,
  }
}

///|
pub fn upscaling_should_prepare_target(state : UpscalingNodeState) -> Bool {
  !state.camera_output_mode_skip
}

///|
pub fn upscaling_should_run(state : UpscalingNodeState) -> Bool {
  upscaling_should_prepare_target(state) && state.has_specialized_pipeline
}

///|
pub fn upscaling_should_apply_viewport_scissor(
  state : UpscalingNodeState,
) -> Bool {
  upscaling_should_run(state) && state.has_camera_viewport
}

///|
pub struct UpscalingBindGroupCacheState {
  has_cached_bind_group : Bool
  cached_main_texture_view_id : Int
}

///|
pub fn UpscalingBindGroupCacheState::new(
  has_cached_bind_group? : Bool = false,
  cached_main_texture_view_id? : Int = -1,
) -> UpscalingBindGroupCacheState {
  UpscalingBindGroupCacheState::{
    has_cached_bind_group,
    cached_main_texture_view_id,
  }
}

///|
pub fn upscaling_bind_group_cache_hit(
  cache : UpscalingBindGroupCacheState,
  main_texture_view_id~ : Int,
) -> Bool {
  cache.has_cached_bind_group &&
  cache.cached_main_texture_view_id == main_texture_view_id
}

///|
pub fn upscaling_bind_group_cache_record(
  _cache : UpscalingBindGroupCacheState,
  main_texture_view_id~ : Int,
) -> UpscalingBindGroupCacheState {
  UpscalingBindGroupCacheState::{
    has_cached_bind_group: true,
    cached_main_texture_view_id: main_texture_view_id,
  }
}
