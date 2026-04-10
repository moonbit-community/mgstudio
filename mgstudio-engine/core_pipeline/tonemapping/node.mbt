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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/tonemapping/node.rs`.
// Tonemapping pass node descriptors.

///|
pub const TONEMAPPING_PASS_2D_LABEL : String = "tonemapping_pass_2d"

///|
pub const TONEMAPPING_PASS_3D_LABEL : String = "tonemapping_pass_3d"

///|
pub struct TonemappingNode {
  label : String
}

///|
pub fn TonemappingNode::new(label~ : String) -> TonemappingNode {
  TonemappingNode::{ label, }
}

///|
pub fn TonemappingNode::pass_2d() -> TonemappingNode {
  TonemappingNode::{ label: TONEMAPPING_PASS_2D_LABEL }
}

///|
pub fn TonemappingNode::pass_3d() -> TonemappingNode {
  TonemappingNode::{ label: TONEMAPPING_PASS_3D_LABEL }
}

///|
pub fn TonemappingNode::label(self : TonemappingNode) -> String {
  self.label
}

///|
pub struct TonemappingNodeState {
  tonemapping_enabled : Bool
  view_target_is_hdr : Bool
  has_specialized_pipeline : Bool
}

///|
pub fn TonemappingNodeState::new(
  tonemapping_enabled? : Bool = false,
  view_target_is_hdr? : Bool = false,
  has_specialized_pipeline? : Bool = false,
) -> TonemappingNodeState {
  TonemappingNodeState::{
    tonemapping_enabled,
    view_target_is_hdr,
    has_specialized_pipeline,
  }
}

///|
pub fn tonemapping_should_run(state : TonemappingNodeState) -> Bool {
  state.tonemapping_enabled &&
  state.view_target_is_hdr &&
  state.has_specialized_pipeline
}

///|
pub struct TonemappingBindGroupCacheState {
  has_cached_bind_group : Bool
  cached_view_uniform_buffer_id : Int
  cached_source_texture_view_id : Int
  cached_lut_texture_view_id : Int
  has_last_tonemapping_method : Bool
  last_tonemapping_method : String
}

///|
pub fn TonemappingBindGroupCacheState::new(
  has_cached_bind_group? : Bool = false,
  cached_view_uniform_buffer_id? : Int = -1,
  cached_source_texture_view_id? : Int = -1,
  cached_lut_texture_view_id? : Int = -1,
  has_last_tonemapping_method? : Bool = false,
  last_tonemapping_method? : String = "",
) -> TonemappingBindGroupCacheState {
  TonemappingBindGroupCacheState::{
    has_cached_bind_group,
    cached_view_uniform_buffer_id,
    cached_source_texture_view_id,
    cached_lut_texture_view_id,
    has_last_tonemapping_method,
    last_tonemapping_method,
  }
}

///|
pub fn tonemapping_bind_group_cache_tonemapping_changed(
  cache : TonemappingBindGroupCacheState,
  tonemapping_method : String,
) -> Bool {
  !cache.has_last_tonemapping_method ||
  cache.last_tonemapping_method != tonemapping_method
}

///|
pub fn tonemapping_bind_group_cache_hit(
  cache : TonemappingBindGroupCacheState,
  view_uniform_buffer_id~ : Int,
  source_texture_view_id~ : Int,
  lut_texture_view_id~ : Int,
  fallback_lut_texture_view_id~ : Int,
  tonemapping_method : String,
) -> Bool {
  cache.has_cached_bind_group &&
  cache.cached_view_uniform_buffer_id == view_uniform_buffer_id &&
  cache.cached_source_texture_view_id == source_texture_view_id &&
  cache.cached_lut_texture_view_id == lut_texture_view_id &&
  cache.cached_lut_texture_view_id != fallback_lut_texture_view_id &&
  !tonemapping_bind_group_cache_tonemapping_changed(cache, tonemapping_method)
}

///|
pub fn tonemapping_bind_group_cache_record(
  _cache : TonemappingBindGroupCacheState,
  view_uniform_buffer_id~ : Int,
  source_texture_view_id~ : Int,
  lut_texture_view_id~ : Int,
  tonemapping_method : String,
) -> TonemappingBindGroupCacheState {
  TonemappingBindGroupCacheState::{
    has_cached_bind_group: true,
    cached_view_uniform_buffer_id: view_uniform_buffer_id,
    cached_source_texture_view_id: source_texture_view_id,
    cached_lut_texture_view_id: lut_texture_view_id,
    has_last_tonemapping_method: true,
    last_tonemapping_method: tonemapping_method,
  }
}
