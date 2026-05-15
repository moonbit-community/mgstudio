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
  mut last_operation_count : Int
  mut first_pass_draw_count : Int
  mut second_pass_draw_count : Int
  mut resolve_depth_count : Int
  mut resolve_material_depth_count : Int
  mut last_draw_count : Int
  mut clear_raster_cluster_prev_counts_count : Int
  mut clear_visibility_buffer_count : Int
  mut first_instance_cull_dispatch_count : Int
  mut first_bvh_cull_dispatch_count : Int
  mut first_bvh_cull_count_clear_count : Int
  mut first_bvh_cull_dispatch_clear_count : Int
  mut first_meshlet_cull_dispatch_count : Int
  mut remap_1d_to_2d_dispatch_count : Int
  mut second_instance_cull_dispatch_count : Int
  mut second_bvh_cull_dispatch_count : Int
  mut second_meshlet_cull_dispatch_count : Int
  mut software_raster_pass_count : Int
  mut hardware_raster_pass_count : Int
  mut fill_counts_pass_count : Int
  mut downsample_depth_count : Int
  mut last_max_bvh_depth : Int
  mut last_rightmost_slot : Int
}

///|
pub fn MeshletVisibilityBufferRasterState::default() -> MeshletVisibilityBufferRasterState {
  MeshletVisibilityBufferRasterState::{
    enabled: meshlet_runtime_available(),
    last_view_count: 0,
    last_shadow_view_count: 0,
    last_pipeline_ready: false,
    last_operation_count: 0,
    first_pass_draw_count: 0,
    second_pass_draw_count: 0,
    resolve_depth_count: 0,
    resolve_material_depth_count: 0,
    last_draw_count: 0,
    clear_raster_cluster_prev_counts_count: 0,
    clear_visibility_buffer_count: 0,
    first_instance_cull_dispatch_count: 0,
    first_bvh_cull_dispatch_count: 0,
    first_bvh_cull_count_clear_count: 0,
    first_bvh_cull_dispatch_clear_count: 0,
    first_meshlet_cull_dispatch_count: 0,
    remap_1d_to_2d_dispatch_count: 0,
    second_instance_cull_dispatch_count: 0,
    second_bvh_cull_dispatch_count: 0,
    second_meshlet_cull_dispatch_count: 0,
    software_raster_pass_count: 0,
    hardware_raster_pass_count: 0,
    fill_counts_pass_count: 0,
    downsample_depth_count: 0,
    last_max_bvh_depth: 0,
    last_rightmost_slot: 0,
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
pub(all) enum MeshletVisibilityBufferRasterOp {
  ClearRasterClusterPrevCounts
  ClearVisibilityBuffer(Bool)
  FirstInstanceCull(Bool)
  FirstBvhCull(Bool, Bool)
  FirstBvhCullClearCount(Bool, Bool)
  FirstBvhCullClearDispatch(Bool, Bool)
  FirstMeshletCull(Bool)
  FirstRemap1dTo2d(Bool)
  SoftwareRaster(Bool, Bool)
  HardwareRaster(Bool, Bool)
  FillCounts(Bool, Bool)
  DownsampleDepth(Bool, Bool)
  SecondInstanceCull(Bool)
  SecondBvhCull(Bool, Bool)
  SecondMeshletCull(Bool)
  SecondRemap1dTo2d(Bool)
  ResolveDepth(Bool)
  ResolveMaterialDepth
}

///|
fn meshlet_visibility_buffer_raster_ping_label(ping : Bool) -> String {
  if ping {
    "ping"
  } else {
    "pong"
  }
}

///|
pub fn meshlet_visibility_buffer_raster_op_label(
  op : MeshletVisibilityBufferRasterOp,
) -> String {
  match op {
    ClearRasterClusterPrevCounts => "clear_raster_cluster_prev_counts"
    ClearVisibilityBuffer(shadow_view) =>
      if shadow_view {
        "clear_visibility_buffer_shadow_view"
      } else {
        "clear_visibility_buffer"
      }
    FirstInstanceCull(_) => "meshlet_first_instance_cull"
    FirstBvhCull(_, ping) =>
      "meshlet_first_bvh_cull_\{meshlet_visibility_buffer_raster_ping_label(ping)}"
    FirstBvhCullClearCount(_, ping) =>
      "meshlet_first_bvh_cull_count_clear_\{meshlet_visibility_buffer_raster_ping_label(ping)}"
    FirstBvhCullClearDispatch(_, ping) =>
      "meshlet_first_bvh_cull_dispatch_clear_\{meshlet_visibility_buffer_raster_ping_label(ping)}"
    FirstMeshletCull(_) => "meshlet_first_meshlet_cull"
    FirstRemap1dTo2d(_) => "meshlet_first_remap_1d_to_2d_dispatch"
    SoftwareRaster(first_pass, shadow_view) =>
      if first_pass {
        if shadow_view {
          "raster_software_first_shadow_view"
        } else {
          "raster_software_first"
        }
      } else if shadow_view {
        "raster_software_second_shadow_view"
      } else {
        "raster_software_second"
      }
    HardwareRaster(first_pass, shadow_view) =>
      if first_pass {
        if shadow_view {
          "raster_hardware_first_shadow_view"
        } else {
          "raster_hardware_first"
        }
      } else if shadow_view {
        "raster_hardware_second_shadow_view"
      } else {
        "raster_hardware_second"
      }
    FillCounts(first_pass, shadow_view) =>
      if first_pass {
        if shadow_view {
          "fill_counts_first_shadow_view"
        } else {
          "fill_counts_first"
        }
      } else if shadow_view {
        "fill_counts_second_shadow_view"
      } else {
        "fill_counts_second"
      }
    DownsampleDepth(first_pass, shadow_view) =>
      if first_pass {
        if shadow_view {
          "downsample_depth_first_shadow_view"
        } else {
          "downsample_depth_first"
        }
      } else if shadow_view {
        "downsample_depth_second_shadow_view"
      } else {
        "downsample_depth_second"
      }
    SecondInstanceCull(_) => "meshlet_second_instance_cull"
    SecondBvhCull(_, ping) =>
      "meshlet_second_bvh_cull_\{meshlet_visibility_buffer_raster_ping_label(ping)}"
    SecondMeshletCull(_) => "meshlet_second_meshlet_cull"
    SecondRemap1dTo2d(_) => "meshlet_second_remap_1d_to_2d_dispatch"
    ResolveDepth(shadow_view) =>
      if shadow_view {
        "resolve_depth_shadow_view"
      } else {
        "resolve_depth"
      }
    ResolveMaterialDepth => "resolve_material_depth"
  }
}

///|
pub struct MeshletVisibilityBufferRasterPlan {
  operations : Array[MeshletVisibilityBufferRasterOp]
  view_count : Int
  shadow_view_count : Int
  max_bvh_depth : Int
  rightmost_slot : Int
}

///|
fn meshlet_raster_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
fn meshlet_push_first_pass_ops(
  operations : Array[MeshletVisibilityBufferRasterOp],
  shadow_view : Bool,
  max_bvh_depth : Int,
  remap_dispatch_enabled : Bool,
) -> Unit {
  operations.push(
    MeshletVisibilityBufferRasterOp::FirstInstanceCull(shadow_view),
  )
  let mut ping = true
  for _ in 0..<max_bvh_depth {
    operations.push(
      MeshletVisibilityBufferRasterOp::FirstBvhCull(shadow_view, ping),
    )
    operations.push(
      MeshletVisibilityBufferRasterOp::FirstBvhCullClearCount(shadow_view, ping),
    )
    operations.push(
      MeshletVisibilityBufferRasterOp::FirstBvhCullClearDispatch(
        shadow_view, ping,
      ),
    )
    ping = !ping
  }
  operations.push(
    MeshletVisibilityBufferRasterOp::FirstMeshletCull(shadow_view),
  )
  if remap_dispatch_enabled {
    operations.push(
      MeshletVisibilityBufferRasterOp::FirstRemap1dTo2d(shadow_view),
    )
  }
  operations.push(
    MeshletVisibilityBufferRasterOp::SoftwareRaster(true, shadow_view),
  )
  operations.push(
    MeshletVisibilityBufferRasterOp::HardwareRaster(true, shadow_view),
  )
  operations.push(
    MeshletVisibilityBufferRasterOp::FillCounts(true, shadow_view),
  )
}

///|
fn meshlet_push_second_pass_ops(
  operations : Array[MeshletVisibilityBufferRasterOp],
  shadow_view : Bool,
  max_bvh_depth : Int,
  remap_dispatch_enabled : Bool,
) -> Unit {
  operations.push(
    MeshletVisibilityBufferRasterOp::SecondInstanceCull(shadow_view),
  )
  let mut ping = true
  for _ in 0..<max_bvh_depth {
    operations.push(
      MeshletVisibilityBufferRasterOp::SecondBvhCull(shadow_view, ping),
    )
    ping = !ping
  }
  operations.push(
    MeshletVisibilityBufferRasterOp::SecondMeshletCull(shadow_view),
  )
  if remap_dispatch_enabled {
    operations.push(
      MeshletVisibilityBufferRasterOp::SecondRemap1dTo2d(shadow_view),
    )
  }
  operations.push(
    MeshletVisibilityBufferRasterOp::SoftwareRaster(false, shadow_view),
  )
  operations.push(
    MeshletVisibilityBufferRasterOp::HardwareRaster(false, shadow_view),
  )
  operations.push(
    MeshletVisibilityBufferRasterOp::FillCounts(false, shadow_view),
  )
}

///|
fn meshlet_push_visibility_buffer_raster_view_ops(
  operations : Array[MeshletVisibilityBufferRasterOp],
  shadow_view : Bool,
  max_bvh_depth : Int,
  has_material_depth : Bool,
  remap_dispatch_enabled : Bool,
) -> Unit {
  operations.push(
    MeshletVisibilityBufferRasterOp::ClearVisibilityBuffer(shadow_view),
  )
  meshlet_push_first_pass_ops(
    operations, shadow_view, max_bvh_depth, remap_dispatch_enabled,
  )
  operations.push(
    MeshletVisibilityBufferRasterOp::DownsampleDepth(true, shadow_view),
  )
  meshlet_push_second_pass_ops(
    operations, shadow_view, max_bvh_depth, remap_dispatch_enabled,
  )
  operations.push(MeshletVisibilityBufferRasterOp::ResolveDepth(shadow_view))
  if !shadow_view && has_material_depth {
    operations.push(MeshletVisibilityBufferRasterOp::ResolveMaterialDepth)
  }
  operations.push(
    MeshletVisibilityBufferRasterOp::DownsampleDepth(false, shadow_view),
  )
}

///|
pub fn meshlet_visibility_buffer_raster_plan(
  view_count : Int,
  shadow_view_count? : Int = 0,
  max_bvh_depth? : Int = 0,
  rightmost_slot? : Int = 0,
  material_depth_view_count? : Int = view_count,
  remap_dispatch_enabled? : Bool = false,
  enabled? : Bool = true,
  pipelines_ready? : Bool = true,
) -> MeshletVisibilityBufferRasterPlan {
  let safe_view_count = meshlet_raster_non_negative(view_count)
  let safe_shadow_view_count = meshlet_raster_non_negative(shadow_view_count)
  let safe_max_bvh_depth = meshlet_raster_non_negative(max_bvh_depth)
  let safe_rightmost_slot = meshlet_raster_non_negative(rightmost_slot)
  let safe_material_depth_view_count = meshlet_raster_non_negative(
    material_depth_view_count,
  ).min(safe_view_count)
  let operations : Array[MeshletVisibilityBufferRasterOp] = []
  if enabled && pipelines_ready {
    operations.push(
      MeshletVisibilityBufferRasterOp::ClearRasterClusterPrevCounts,
    )
    for index in 0..<safe_view_count {
      meshlet_push_visibility_buffer_raster_view_ops(
        operations,
        false,
        safe_max_bvh_depth,
        index < safe_material_depth_view_count,
        remap_dispatch_enabled,
      )
    }
    for _ in 0..<safe_shadow_view_count {
      meshlet_push_visibility_buffer_raster_view_ops(
        operations, true, safe_max_bvh_depth, false, remap_dispatch_enabled,
      )
    }
  }
  MeshletVisibilityBufferRasterPlan::{
    operations,
    view_count: safe_view_count,
    shadow_view_count: safe_shadow_view_count,
    max_bvh_depth: safe_max_bvh_depth,
    rightmost_slot: safe_rightmost_slot,
  }
}

///|
pub fn MeshletVisibilityBufferRasterPlan::operation_count(
  self : MeshletVisibilityBufferRasterPlan,
) -> Int {
  self.operations.length()
}

///|
pub fn MeshletVisibilityBufferRasterPlan::view_count(
  self : MeshletVisibilityBufferRasterPlan,
) -> Int {
  self.view_count
}

///|
pub fn MeshletVisibilityBufferRasterPlan::shadow_view_count(
  self : MeshletVisibilityBufferRasterPlan,
) -> Int {
  self.shadow_view_count
}

///|
pub fn MeshletVisibilityBufferRasterPlan::max_bvh_depth(
  self : MeshletVisibilityBufferRasterPlan,
) -> Int {
  self.max_bvh_depth
}

///|
pub fn MeshletVisibilityBufferRasterPlan::rightmost_slot(
  self : MeshletVisibilityBufferRasterPlan,
) -> Int {
  self.rightmost_slot
}

///|
pub fn MeshletVisibilityBufferRasterPlan::operations(
  self : MeshletVisibilityBufferRasterPlan,
) -> Array[MeshletVisibilityBufferRasterOp] {
  self.operations
}

///|
fn meshlet_raster_state_reset_counts(
  state : MeshletVisibilityBufferRasterState,
) -> Unit {
  state.last_draw_count = 0
  state.last_operation_count = 0
  state.first_pass_draw_count = 0
  state.second_pass_draw_count = 0
  state.resolve_depth_count = 0
  state.resolve_material_depth_count = 0
  state.clear_raster_cluster_prev_counts_count = 0
  state.clear_visibility_buffer_count = 0
  state.first_instance_cull_dispatch_count = 0
  state.first_bvh_cull_dispatch_count = 0
  state.first_bvh_cull_count_clear_count = 0
  state.first_bvh_cull_dispatch_clear_count = 0
  state.first_meshlet_cull_dispatch_count = 0
  state.remap_1d_to_2d_dispatch_count = 0
  state.second_instance_cull_dispatch_count = 0
  state.second_bvh_cull_dispatch_count = 0
  state.second_meshlet_cull_dispatch_count = 0
  state.software_raster_pass_count = 0
  state.hardware_raster_pass_count = 0
  state.fill_counts_pass_count = 0
  state.downsample_depth_count = 0
}

///|
fn meshlet_raster_state_apply_plan(
  state : MeshletVisibilityBufferRasterState,
  plan : MeshletVisibilityBufferRasterPlan,
  draw_count : Int,
) -> Unit {
  state.last_operation_count = plan.operation_count()
  for operation in plan.operations() {
    match operation {
      ClearRasterClusterPrevCounts =>
        state.clear_raster_cluster_prev_counts_count = state.clear_raster_cluster_prev_counts_count +
          1
      ClearVisibilityBuffer(_) =>
        state.clear_visibility_buffer_count = state.clear_visibility_buffer_count +
          1
      FirstInstanceCull(_) =>
        state.first_instance_cull_dispatch_count = state.first_instance_cull_dispatch_count +
          1
      FirstBvhCull(_, _) =>
        state.first_bvh_cull_dispatch_count = state.first_bvh_cull_dispatch_count +
          1
      FirstBvhCullClearCount(_, _) =>
        state.first_bvh_cull_count_clear_count = state.first_bvh_cull_count_clear_count +
          1
      FirstBvhCullClearDispatch(_, _) =>
        state.first_bvh_cull_dispatch_clear_count = state.first_bvh_cull_dispatch_clear_count +
          1
      FirstMeshletCull(_) =>
        state.first_meshlet_cull_dispatch_count = state.first_meshlet_cull_dispatch_count +
          1
      FirstRemap1dTo2d(_) =>
        state.remap_1d_to_2d_dispatch_count = state.remap_1d_to_2d_dispatch_count +
          1
      SoftwareRaster(_, _) =>
        state.software_raster_pass_count = state.software_raster_pass_count + 1
      HardwareRaster(_, _) =>
        state.hardware_raster_pass_count = state.hardware_raster_pass_count + 1
      FillCounts(_, _) =>
        state.fill_counts_pass_count = state.fill_counts_pass_count + 1
      DownsampleDepth(_, _) =>
        state.downsample_depth_count = state.downsample_depth_count + 1
      SecondInstanceCull(_) =>
        state.second_instance_cull_dispatch_count = state.second_instance_cull_dispatch_count +
          1
      SecondBvhCull(_, _) =>
        state.second_bvh_cull_dispatch_count = state.second_bvh_cull_dispatch_count +
          1
      SecondMeshletCull(_) =>
        state.second_meshlet_cull_dispatch_count = state.second_meshlet_cull_dispatch_count +
          1
      SecondRemap1dTo2d(_) =>
        state.remap_1d_to_2d_dispatch_count = state.remap_1d_to_2d_dispatch_count +
          1
      ResolveDepth(_) =>
        state.resolve_depth_count = state.resolve_depth_count + 1
      ResolveMaterialDepth =>
        state.resolve_material_depth_count = state.resolve_material_depth_count +
          1
    }
  }
  if plan.operation_count() > 0 {
    state.last_draw_count = draw_count
    state.first_pass_draw_count = draw_count
    state.second_pass_draw_count = draw_count
  }
}

///|
pub fn meshlet_visibility_buffer_raster(
  state : MeshletVisibilityBufferRasterState,
  draw_count : Int,
  view_count? : Int = 0,
  shadow_view_count? : Int = 0,
  max_bvh_depth? : Int = 0,
  rightmost_slot? : Int = 0,
  material_depth_view_count? : Int = view_count,
  remap_dispatch_enabled? : Bool = false,
  pipelines_ready? : Bool = false,
) -> Unit {
  let safe_draw_count = if draw_count < 0 { 0 } else { draw_count }
  let safe_view_count = if view_count < 0 { 0 } else { view_count }
  let safe_shadow_view_count = if shadow_view_count < 0 {
    0
  } else {
    shadow_view_count
  }
  let safe_max_bvh_depth = if max_bvh_depth < 0 { 0 } else { max_bvh_depth }
  let safe_rightmost_slot = if rightmost_slot < 0 { 0 } else { rightmost_slot }
  let safe_material_depth_view_count = (if material_depth_view_count < 0 {
    0
  } else {
    material_depth_view_count
  }).min(safe_view_count)
  let pass_view_count = safe_view_count + safe_shadow_view_count
  state.last_view_count = safe_view_count
  state.last_shadow_view_count = safe_shadow_view_count
  state.last_max_bvh_depth = safe_max_bvh_depth
  state.last_rightmost_slot = safe_rightmost_slot
  state.last_pipeline_ready = pipelines_ready
  ignore(pass_view_count)
  meshlet_raster_state_reset_counts(state)
  meshlet_raster_state_apply_plan(
    state,
    meshlet_visibility_buffer_raster_plan(
      safe_view_count,
      shadow_view_count=safe_shadow_view_count,
      max_bvh_depth=safe_max_bvh_depth,
      rightmost_slot=safe_rightmost_slot,
      material_depth_view_count=safe_material_depth_view_count,
      remap_dispatch_enabled~,
      enabled=state.enabled,
      pipelines_ready~,
    ),
    safe_draw_count,
  )
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
pub fn MeshletVisibilityBufferRasterState::last_operation_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.last_operation_count
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

///|
pub fn MeshletVisibilityBufferRasterState::clear_visibility_buffer_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.clear_visibility_buffer_count
}

///|
pub fn MeshletVisibilityBufferRasterState::clear_raster_cluster_prev_counts_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.clear_raster_cluster_prev_counts_count
}

///|
pub fn MeshletVisibilityBufferRasterState::first_bvh_cull_dispatch_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.first_bvh_cull_dispatch_count
}

///|
pub fn MeshletVisibilityBufferRasterState::first_bvh_cull_count_clear_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.first_bvh_cull_count_clear_count
}

///|
pub fn MeshletVisibilityBufferRasterState::first_bvh_cull_dispatch_clear_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.first_bvh_cull_dispatch_clear_count
}

///|
pub fn MeshletVisibilityBufferRasterState::second_bvh_cull_dispatch_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.second_bvh_cull_dispatch_count
}

///|
pub fn MeshletVisibilityBufferRasterState::remap_1d_to_2d_dispatch_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.remap_1d_to_2d_dispatch_count
}

///|
pub fn MeshletVisibilityBufferRasterState::software_raster_pass_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.software_raster_pass_count
}

///|
pub fn MeshletVisibilityBufferRasterState::hardware_raster_pass_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.hardware_raster_pass_count
}

///|
pub fn MeshletVisibilityBufferRasterState::fill_counts_pass_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.fill_counts_pass_count
}

///|
pub fn MeshletVisibilityBufferRasterState::downsample_depth_count(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.downsample_depth_count
}

///|
pub fn MeshletVisibilityBufferRasterState::last_max_bvh_depth(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.last_max_bvh_depth
}

///|
pub fn MeshletVisibilityBufferRasterState::last_rightmost_slot(
  self : MeshletVisibilityBufferRasterState,
) -> Int {
  self.last_rightmost_slot
}
