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
pub const MESHLET_VISIBILITY_BUFFER_RASTER_NODE : String = "bevy_pbr::meshlet::visibility_buffer_raster"

///|
pub struct MeshletVisibilityBufferRasterState {
  enabled : Bool
  mut last_draw_count : Int
}

///|
pub fn MeshletVisibilityBufferRasterState::default() -> MeshletVisibilityBufferRasterState {
  MeshletVisibilityBufferRasterState::{
    enabled: meshlet_runtime_available(),
    last_draw_count: 0,
  }
}

///|
pub fn meshlet_visibility_buffer_raster_runtime_available() -> Bool {
  meshlet_runtime_available()
}

///|
pub fn meshlet_visibility_buffer_raster(
  state : MeshletVisibilityBufferRasterState,
  draw_count : Int,
) -> Unit {
  if state.enabled {
    state.last_draw_count = if draw_count < 0 { 0 } else { draw_count }
  }
}
