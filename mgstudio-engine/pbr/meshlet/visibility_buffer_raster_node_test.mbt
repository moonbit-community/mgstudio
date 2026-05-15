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
    max_bvh_depth=5,
    rightmost_slot=9,
    pipelines_ready=true,
  )
  inspect(state.last_draw_count(), content="12")
  inspect(state.last_operation_count(), content="242")
  inspect(state.first_pass_draw_count(), content="12")
  inspect(state.second_pass_draw_count(), content="12")
  inspect(state.resolve_depth_count(), content="7")
  inspect(state.resolve_material_depth_count(), content="3")
  inspect(state.clear_raster_cluster_prev_counts_count(), content="1")
  inspect(state.clear_visibility_buffer_count(), content="7")
  inspect(state.first_bvh_cull_dispatch_count(), content="35")
  inspect(state.first_bvh_cull_count_clear_count(), content="35")
  inspect(state.first_bvh_cull_dispatch_clear_count(), content="35")
  inspect(state.second_bvh_cull_dispatch_count(), content="35")
  inspect(state.remap_1d_to_2d_dispatch_count(), content="0")
  inspect(state.software_raster_pass_count(), content="14")
  inspect(state.hardware_raster_pass_count(), content="14")
  inspect(state.fill_counts_pass_count(), content="14")
  inspect(state.downsample_depth_count(), content="14")
  inspect(state.last_max_bvh_depth(), content="5")
  inspect(state.last_rightmost_slot(), content="9")
}

///|
test "pbr meshlet: visibility raster plan follows bevy pass order" {
  let plan = meshlet_visibility_buffer_raster_plan(
    1,
    max_bvh_depth=2,
    rightmost_slot=4,
  )
  let ops = plan.operations()
  inspect(plan.operation_count(), content="24")
  inspect(plan.view_count(), content="1")
  inspect(plan.shadow_view_count(), content="0")
  inspect(plan.max_bvh_depth(), content="2")
  inspect(plan.rightmost_slot(), content="4")
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[0]),
    content="clear_raster_cluster_prev_counts",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[1]),
    content="clear_visibility_buffer",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[2]),
    content="meshlet_first_instance_cull",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[3]),
    content="meshlet_first_bvh_cull_ping",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[6]),
    content="meshlet_first_bvh_cull_pong",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[12]),
    content="downsample_depth_first",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[13]),
    content="meshlet_second_instance_cull",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[21]),
    content="resolve_depth",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[22]),
    content="resolve_material_depth",
  )
  inspect(
    meshlet_visibility_buffer_raster_op_label(ops[23]),
    content="downsample_depth_second",
  )
}
