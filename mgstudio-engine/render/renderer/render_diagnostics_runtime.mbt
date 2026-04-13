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
/// Runtime diagnostics counters and per-pass CPU timing.
pub struct RenderDiagnosticsSnapshot {
  mesh2d_draw_calls : Int
  mesh2d_executed_draw_calls : Int
  mesh3d_draw_calls : Int
  mesh3d_executed_draw_calls : Int
  pass_total_count : Int
  pass_2d_count : Int
  pass_3d_main_count : Int
  pass_3d_motion_vector_count : Int
  pass_3d_point_shadow_count : Int
  pass_total_cpu_ms : Float
  pass_2d_cpu_ms : Float
  pass_3d_main_cpu_ms : Float
  pass_3d_motion_vector_cpu_ms : Float
  pass_3d_point_shadow_cpu_ms : Float
}

///|
pub fn RenderDiagnosticsSnapshot::default() -> RenderDiagnosticsSnapshot {
  RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: 0,
    mesh2d_executed_draw_calls: 0,
    mesh3d_draw_calls: 0,
    mesh3d_executed_draw_calls: 0,
    pass_total_count: 0,
    pass_2d_count: 0,
    pass_3d_main_count: 0,
    pass_3d_motion_vector_count: 0,
    pass_3d_point_shadow_count: 0,
    pass_total_cpu_ms: 0.0F,
    pass_2d_cpu_ms: 0.0F,
    pass_3d_main_cpu_ms: 0.0F,
    pass_3d_motion_vector_cpu_ms: 0.0F,
    pass_3d_point_shadow_cpu_ms: 0.0F,
  }
}

///|
pub fn RenderDiagnosticsSnapshot::new(
  mesh2d_draw_calls : Int,
  mesh2d_executed_draw_calls : Int,
  mesh3d_draw_calls : Int,
  mesh3d_executed_draw_calls : Int,
) -> RenderDiagnosticsSnapshot {
  RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls,
    mesh2d_executed_draw_calls,
    mesh3d_draw_calls,
    mesh3d_executed_draw_calls,
    pass_total_count: 0,
    pass_2d_count: 0,
    pass_3d_main_count: 0,
    pass_3d_motion_vector_count: 0,
    pass_3d_point_shadow_count: 0,
    pass_total_cpu_ms: 0.0F,
    pass_2d_cpu_ms: 0.0F,
    pass_3d_main_cpu_ms: 0.0F,
    pass_3d_motion_vector_cpu_ms: 0.0F,
    pass_3d_point_shadow_cpu_ms: 0.0F,
  }
}

///|
const RENDER_PASS_PHASE_NONE : Int = 0

///|
const RENDER_PASS_PHASE_2D : Int = 1

///|
const RENDER_PASS_PHASE_3D_MAIN : Int = 2

///|
const RENDER_PASS_PHASE_3D_MOTION_VECTOR : Int = 3

///|
const RENDER_PASS_PHASE_3D_POINT_SHADOW : Int = 4

///|
let debug_frame_counter_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_invalid_id_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_invalid_id_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh2d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh2d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh3d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh3d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
priv struct RenderPassTimingRuntimeState {
  mut pass_total_count : Int
  mut pass_2d_count : Int
  mut pass_3d_main_count : Int
  mut pass_3d_motion_vector_count : Int
  mut pass_3d_point_shadow_count : Int
  mut pass_total_cpu_ms : Float
  mut pass_2d_cpu_ms : Float
  mut pass_3d_main_cpu_ms : Float
  mut pass_3d_motion_vector_cpu_ms : Float
  mut pass_3d_point_shadow_cpu_ms : Float
  mut active_pass_phase : Int
  mut active_pass_start_time : Float?
}

///|
fn render_pass_timing_runtime_state_default() -> RenderPassTimingRuntimeState {
  RenderPassTimingRuntimeState::{
    pass_total_count: 0,
    pass_2d_count: 0,
    pass_3d_main_count: 0,
    pass_3d_motion_vector_count: 0,
    pass_3d_point_shadow_count: 0,
    pass_total_cpu_ms: 0.0F,
    pass_2d_cpu_ms: 0.0F,
    pass_3d_main_cpu_ms: 0.0F,
    pass_3d_motion_vector_cpu_ms: 0.0F,
    pass_3d_point_shadow_cpu_ms: 0.0F,
    active_pass_phase: RENDER_PASS_PHASE_NONE,
    active_pass_start_time: None,
  }
}

///|
let render_pass_timing_runtime_state_ref : Ref[RenderPassTimingRuntimeState] = Ref::new(
  render_pass_timing_runtime_state_default(),
)

///|
let last_frame_render_diagnostics_snapshot_ref : Ref[RenderDiagnosticsSnapshot] = Ref::new(
  RenderDiagnosticsSnapshot::default(),
)

///|
let debug_mesh2d_drop_no_frame_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pass_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pass_state_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_missing_mesh_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_bad_stride_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pipeline_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_uniform_buf_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_uniform_bg_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_texture_ref : Ref[Int] = Ref::new(0)

///|
fn render_pass_timing_reset_counters() -> Unit {
  let state = render_pass_timing_runtime_state_ref.val
  state.pass_total_count = 0
  state.pass_2d_count = 0
  state.pass_3d_main_count = 0
  state.pass_3d_motion_vector_count = 0
  state.pass_3d_point_shadow_count = 0
  state.pass_total_cpu_ms = 0.0F
  state.pass_2d_cpu_ms = 0.0F
  state.pass_3d_main_cpu_ms = 0.0F
  state.pass_3d_motion_vector_cpu_ms = 0.0F
  state.pass_3d_point_shadow_cpu_ms = 0.0F
}

///|
fn render_pass_timing_phase_from_3d_pass_kind(pass_kind : Int) -> Int {
  match pass_kind_base_kind(pass_kind) {
    PASS_KIND_BASE_MOTION_VECTOR => RENDER_PASS_PHASE_3D_MOTION_VECTOR
    PASS_KIND_BASE_POINT_SHADOW => RENDER_PASS_PHASE_3D_POINT_SHADOW
    _ => RENDER_PASS_PHASE_3D_MAIN
  }
}

///|
fn render_pass_timing_end_active_pass() -> Unit {
  let state = render_pass_timing_runtime_state_ref.val
  if state.active_pass_start_time is Some(start_time) {
    let elapsed_ms = (@time.host_time_now() - start_time) * 1000.0F
    state.pass_total_count = state.pass_total_count + 1
    state.pass_total_cpu_ms = state.pass_total_cpu_ms + elapsed_ms
    match state.active_pass_phase {
      RENDER_PASS_PHASE_2D => {
        state.pass_2d_count = state.pass_2d_count + 1
        state.pass_2d_cpu_ms = state.pass_2d_cpu_ms + elapsed_ms
      }
      RENDER_PASS_PHASE_3D_MOTION_VECTOR => {
        state.pass_3d_motion_vector_count = state.pass_3d_motion_vector_count +
          1
        state.pass_3d_motion_vector_cpu_ms = state.pass_3d_motion_vector_cpu_ms +
          elapsed_ms
      }
      RENDER_PASS_PHASE_3D_POINT_SHADOW => {
        state.pass_3d_point_shadow_count = state.pass_3d_point_shadow_count + 1
        state.pass_3d_point_shadow_cpu_ms = state.pass_3d_point_shadow_cpu_ms +
          elapsed_ms
      }
      RENDER_PASS_PHASE_3D_MAIN => {
        state.pass_3d_main_count = state.pass_3d_main_count + 1
        state.pass_3d_main_cpu_ms = state.pass_3d_main_cpu_ms + elapsed_ms
      }
      _ => ()
    }
  }
  state.active_pass_start_time = None
  state.active_pass_phase = RENDER_PASS_PHASE_NONE
}

///|
fn render_pass_timing_begin_active_pass(phase : Int) -> Unit {
  let state = render_pass_timing_runtime_state_ref.val
  state.active_pass_phase = phase
  state.active_pass_start_time = Some(@time.host_time_now())
}

///|
fn render_diagnostics_reset_debug_counters_if_needed() -> Unit {
  debug_frame_counter_ref.val = debug_frame_counter_ref.val + 1
  if debug_frame_counter_ref.val % 60 == 0 {
    debug_mesh2d_draw_calls_ref.val = 0
    debug_mesh3d_draw_calls_ref.val = 0
    debug_mesh2d_invalid_id_calls_ref.val = 0
    debug_mesh3d_invalid_id_calls_ref.val = 0
    debug_mesh2d_executed_draw_calls_ref.val = 0
    debug_mesh3d_executed_draw_calls_ref.val = 0
    debug_mesh2d_drop_no_frame_ref.val = 0
    debug_mesh2d_drop_no_pass_ref.val = 0
    debug_mesh2d_drop_no_pass_state_ref.val = 0
    debug_mesh2d_drop_missing_mesh_ref.val = 0
    debug_mesh2d_drop_bad_stride_ref.val = 0
    debug_mesh2d_drop_no_pipeline_ref.val = 0
    debug_mesh2d_drop_no_uniform_buf_ref.val = 0
    debug_mesh2d_drop_no_uniform_bg_ref.val = 0
    debug_mesh2d_drop_no_texture_ref.val = 0
  }
}

///|
pub fn render_diagnostics_begin_frame() -> Unit {
  let state = render_pass_timing_runtime_state_ref.val
  state.active_pass_phase = RENDER_PASS_PHASE_NONE
  state.active_pass_start_time = None
  current_frame_mesh2d_draw_calls_ref.val = 0
  current_frame_mesh2d_executed_draw_calls_ref.val = 0
  current_frame_mesh3d_draw_calls_ref.val = 0
  current_frame_mesh3d_executed_draw_calls_ref.val = 0
  render_pass_timing_reset_counters()
}

///|
pub fn render_diagnostics_end_frame() -> Unit {
  render_diagnostics_commit_current_frame_snapshot()
  render_diagnostics_reset_debug_counters_if_needed()
}

///|
pub fn render_diagnostics_record_mesh2d_draw(mesh_id : Int) -> Unit {
  debug_mesh2d_draw_calls_ref.val = debug_mesh2d_draw_calls_ref.val + 1
  current_frame_mesh2d_draw_calls_ref.val = current_frame_mesh2d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh2d_invalid_id_calls_ref.val = debug_mesh2d_invalid_id_calls_ref.val +
      1
  }
}

///|
pub fn render_diagnostics_record_mesh3d_draw(mesh_id : Int) -> Unit {
  debug_mesh3d_draw_calls_ref.val = debug_mesh3d_draw_calls_ref.val + 1
  current_frame_mesh3d_draw_calls_ref.val = current_frame_mesh3d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh3d_invalid_id_calls_ref.val = debug_mesh3d_invalid_id_calls_ref.val +
      1
  }
}

///|
pub fn render_diagnostics_record_mesh2d_executed_draw() -> Unit {
  debug_mesh2d_executed_draw_calls_ref.val = debug_mesh2d_executed_draw_calls_ref.val +
    1
  current_frame_mesh2d_executed_draw_calls_ref.val = current_frame_mesh2d_executed_draw_calls_ref.val +
    1
}

///|
pub fn render_diagnostics_record_mesh3d_executed_draw() -> Unit {
  debug_mesh3d_executed_draw_calls_ref.val = debug_mesh3d_executed_draw_calls_ref.val +
    1
  current_frame_mesh3d_executed_draw_calls_ref.val = current_frame_mesh3d_executed_draw_calls_ref.val +
    1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_no_frame() -> Unit {
  debug_mesh2d_drop_no_frame_ref.val = debug_mesh2d_drop_no_frame_ref.val + 1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_no_pass() -> Unit {
  debug_mesh2d_drop_no_pass_ref.val = debug_mesh2d_drop_no_pass_ref.val + 1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_no_pass_state() -> Unit {
  debug_mesh2d_drop_no_pass_state_ref.val = debug_mesh2d_drop_no_pass_state_ref.val +
    1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_missing_mesh() -> Unit {
  debug_mesh2d_drop_missing_mesh_ref.val = debug_mesh2d_drop_missing_mesh_ref.val +
    1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_bad_stride() -> Unit {
  debug_mesh2d_drop_bad_stride_ref.val = debug_mesh2d_drop_bad_stride_ref.val +
    1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_no_pipeline() -> Unit {
  debug_mesh2d_drop_no_pipeline_ref.val = debug_mesh2d_drop_no_pipeline_ref.val +
    1
}

///|
pub fn render_diagnostics_record_mesh2d_drop_no_uniform_buf() -> Unit {
  debug_mesh2d_drop_no_uniform_buf_ref.val = debug_mesh2d_drop_no_uniform_buf_ref.val +
    1
}

///|
pub fn render_diagnostics_snapshot() -> RenderDiagnosticsSnapshot {
  last_frame_render_diagnostics_snapshot_ref.val
}

///|
pub fn render_diagnostics_commit_current_frame_snapshot() -> Unit {
  render_pass_timing_end_active_pass()
  let timing_state = render_pass_timing_runtime_state_ref.val
  last_frame_render_diagnostics_snapshot_ref.val = RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: current_frame_mesh2d_draw_calls_ref.val,
    mesh2d_executed_draw_calls: current_frame_mesh2d_executed_draw_calls_ref.val,
    mesh3d_draw_calls: current_frame_mesh3d_draw_calls_ref.val,
    mesh3d_executed_draw_calls: current_frame_mesh3d_executed_draw_calls_ref.val,
    pass_total_count: timing_state.pass_total_count,
    pass_2d_count: timing_state.pass_2d_count,
    pass_3d_main_count: timing_state.pass_3d_main_count,
    pass_3d_motion_vector_count: timing_state.pass_3d_motion_vector_count,
    pass_3d_point_shadow_count: timing_state.pass_3d_point_shadow_count,
    pass_total_cpu_ms: timing_state.pass_total_cpu_ms,
    pass_2d_cpu_ms: timing_state.pass_2d_cpu_ms,
    pass_3d_main_cpu_ms: timing_state.pass_3d_main_cpu_ms,
    pass_3d_motion_vector_cpu_ms: timing_state.pass_3d_motion_vector_cpu_ms,
    pass_3d_point_shadow_cpu_ms: timing_state.pass_3d_point_shadow_cpu_ms,
  }
}

///|
pub fn render_diagnostics_reset_current_frame_counters() -> Unit {
  let state = render_pass_timing_runtime_state_ref.val
  state.active_pass_phase = RENDER_PASS_PHASE_NONE
  state.active_pass_start_time = None
  current_frame_mesh2d_draw_calls_ref.val = 0
  current_frame_mesh2d_executed_draw_calls_ref.val = 0
  current_frame_mesh3d_draw_calls_ref.val = 0
  current_frame_mesh3d_executed_draw_calls_ref.val = 0
  render_pass_timing_reset_counters()
  last_frame_render_diagnostics_snapshot_ref.val = RenderDiagnosticsSnapshot::default()
}
