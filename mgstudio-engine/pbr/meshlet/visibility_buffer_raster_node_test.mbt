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
test "pbr meshlet: visibility node keeps zero draw count when runtime unavailable" {
  let state = MeshletVisibilityBufferRasterState::default()
  meshlet_visibility_buffer_raster(state, 20)
  inspect(state.enabled(), content="false")
  inspect(state.last_draw_count(), content="0")
}

///|
test "pbr meshlet: visibility node tracks first/second pass and resolve counters" {
  let state = meshlet_visibility_buffer_raster_state_with_enabled(true)
  meshlet_visibility_buffer_raster(
    state,
    12,
    view_count=3,
    shadow_view_count=4,
    pipelines_ready=true,
  )
  inspect(state.last_draw_count(), content="12")
  inspect(state.first_pass_draw_count(), content="12")
  inspect(state.second_pass_draw_count(), content="12")
  inspect(state.resolve_depth_count(), content="7")
  inspect(state.resolve_material_depth_count(), content="3")
}
