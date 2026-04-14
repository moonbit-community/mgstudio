// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/visibility_buffer_raster_node.rs`.

///|
pub const MESHLET_VISIBILITY_BUFFER_RASTER_NODE : String = "mgstudio.pbr.meshlet.visibility_buffer_raster"

///|
pub struct MeshletVisibilityBufferRasterState {
  enabled : Bool
  mut last_view_count : Int
  mut last_shadow_view_count : Int
  mut last_pipeline_ready : Bool
  mut first_pass_draw_count : Int
  mut second_pass_draw_count : Int
  mut resolve_depth_count : Int
  mut resolve_material_depth_count : Int
  mut last_draw_count : Int
}

///|
pub fn MeshletVisibilityBufferRasterState::default() -> MeshletVisibilityBufferRasterState {
  MeshletVisibilityBufferRasterState::{
    enabled: meshlet_runtime_available(),
    last_view_count: 0,
    last_shadow_view_count: 0,
    last_pipeline_ready: false,
    first_pass_draw_count: 0,
    second_pass_draw_count: 0,
    resolve_depth_count: 0,
    resolve_material_depth_count: 0,
    last_draw_count: 0,
  }
}

///|
pub fn meshlet_visibility_buffer_raster_state_with_enabled(
  enabled : Bool,
) -> MeshletVisibilityBufferRasterState {
  MeshletVisibilityBufferRasterState::{
    ..MeshletVisibilityBufferRasterState::default(),
    enabled,
  }
}

///|
pub fn meshlet_visibility_buffer_raster(
  state : MeshletVisibilityBufferRasterState,
  draw_count : Int,
  view_count? : Int = 0,
  shadow_view_count? : Int = 0,
  pipelines_ready? : Bool = false,
) -> Unit {
  let safe_draw_count = if draw_count < 0 { 0 } else { draw_count }
  let safe_view_count = if view_count < 0 { 0 } else { view_count }
  let safe_shadow_view_count = if shadow_view_count < 0 {
    0
  } else {
    shadow_view_count
  }
  state.last_view_count = safe_view_count
  state.last_shadow_view_count = safe_shadow_view_count
  state.last_pipeline_ready = pipelines_ready
  if state.enabled && pipelines_ready {
    state.last_draw_count = safe_draw_count
    state.first_pass_draw_count = safe_draw_count
    state.second_pass_draw_count = safe_draw_count
    state.resolve_depth_count = safe_view_count + safe_shadow_view_count
    state.resolve_material_depth_count = safe_view_count
  } else {
    state.last_draw_count = 0
    state.first_pass_draw_count = 0
    state.second_pass_draw_count = 0
    state.resolve_depth_count = 0
    state.resolve_material_depth_count = 0
  }
}

///|
pub fn MeshletVisibilityBufferRasterState::last_draw_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.last_draw_count
}

///|
pub fn MeshletVisibilityBufferRasterState::enabled(
  self : MeshletVisibilityBufferRasterState,
) -> Bool {
  self.enabled
}

///|
pub fn MeshletVisibilityBufferRasterState::last_view_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.last_view_count
}

///|
pub fn MeshletVisibilityBufferRasterState::last_shadow_view_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.last_shadow_view_count
}

///|
pub fn MeshletVisibilityBufferRasterState::last_pipeline_ready(
  self : MeshletVisibilityBufferRasterState,
) -> Bool {
  self.last_pipeline_ready
}

///|
pub fn MeshletVisibilityBufferRasterState::first_pass_draw_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.first_pass_draw_count
}

///|
pub fn MeshletVisibilityBufferRasterState::second_pass_draw_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.second_pass_draw_count
}

///|
pub fn MeshletVisibilityBufferRasterState::resolve_depth_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.resolve_depth_count
}

///|
pub fn MeshletVisibilityBufferRasterState::resolve_material_depth_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.resolve_material_depth_count
}
