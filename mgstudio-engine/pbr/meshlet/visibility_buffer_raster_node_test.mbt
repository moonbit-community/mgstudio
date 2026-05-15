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

///|
test "pbr meshlet: visibility raster command descriptors mirror bevy dispatch modes" {
  let first_instance = meshlet_visibility_buffer_raster_op_command_descriptor(
    MeshletVisibilityBufferRasterOp::FirstInstanceCull(false),
  )
  inspect(
    first_instance.command_kind()
    is MeshletVisibilityBufferRasterCommandKind::ComputePass,
    content="true",
  )
  inspect(
    first_instance.dispatch_kind()
    is MeshletVisibilityBufferRasterDispatchKind::DirectWorkgroups,
    content="true",
  )
  inspect(first_instance.pipeline_slot(), content="first_instance_cull")
  inspect(first_instance.bind_group(), content="first_instance_cull")
  inspect(first_instance.immediate_size(), content="4")
  inspect(first_instance.dynamic_offset_count(), content="2")
  let first_bvh_pong = meshlet_visibility_buffer_raster_op_command_descriptor(
    MeshletVisibilityBufferRasterOp::FirstBvhCull(false, false),
  )
  inspect(
    first_bvh_pong.dispatch_kind()
    is MeshletVisibilityBufferRasterDispatchKind::IndirectWorkgroups,
    content="true",
  )
  inspect(first_bvh_pong.pipeline_slot(), content="first_bvh_cull")
  inspect(first_bvh_pong.bind_group(), content="first_bvh_cull_pong")
  inspect(first_bvh_pong.immediate_size(), content="8")
  inspect(first_bvh_pong.dynamic_offset_count(), content="2")
  let clear_count = meshlet_visibility_buffer_raster_op_command_descriptor(
    MeshletVisibilityBufferRasterOp::FirstBvhCullClearCount(false, true),
  )
  inspect(
    clear_count.command_kind()
    is MeshletVisibilityBufferRasterCommandKind::ClearBuffer,
    content="true",
  )
  inspect(clear_count.clear_buffer_count(), content="1")
}

///|
test "pbr meshlet: visibility raster command descriptors preserve render and shadow variants" {
  let hardware_camera = meshlet_visibility_buffer_raster_op_command_descriptor(
    MeshletVisibilityBufferRasterOp::HardwareRaster(true, false),
  )
  inspect(
    hardware_camera.command_kind()
    is MeshletVisibilityBufferRasterCommandKind::RenderPass,
    content="true",
  )
  inspect(
    hardware_camera.dispatch_kind()
    is MeshletVisibilityBufferRasterDispatchKind::IndirectDraw,
    content="true",
  )
  inspect(
    hardware_camera.pipeline_slot(),
    content="visibility_buffer_hardware_raster",
  )
  inspect(hardware_camera.bind_group(), content="visibility_buffer_raster")
  inspect(hardware_camera.immediate_size(), content="4")
  inspect(hardware_camera.dynamic_offset_count(), content="1")
  inspect(hardware_camera.uses_camera_viewport(), content="true")
  let hardware_directional_shadow = meshlet_visibility_buffer_raster_op_command_descriptor(
    MeshletVisibilityBufferRasterOp::HardwareRaster(true, true),
    directional_shadow_view=true,
  )
  inspect(
    hardware_directional_shadow.pipeline_slot(),
    content="visibility_buffer_hardware_raster_shadow_view_unclipped",
  )
  inspect(
    hardware_directional_shadow.uses_shadow_unclipped_pipeline(),
    content="true",
  )
  inspect(hardware_directional_shadow.uses_camera_viewport(), content="false")
  let resolve_material_depth = meshlet_visibility_buffer_raster_op_command_descriptor(
    MeshletVisibilityBufferRasterOp::ResolveMaterialDepth,
  )
  inspect(
    resolve_material_depth.command_kind()
    is MeshletVisibilityBufferRasterCommandKind::DepthResolvePass,
    content="true",
  )
  inspect(
    resolve_material_depth.dispatch_kind()
    is MeshletVisibilityBufferRasterDispatchKind::DirectDraw,
    content="true",
  )
  inspect(
    resolve_material_depth.pipeline_slot(),
    content="resolve_material_depth",
  )
  inspect(resolve_material_depth.bind_group(), content="resolve_material_depth")
  inspect(resolve_material_depth.uses_camera_viewport(), content="true")
}
