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
priv struct Render3dPendingFrame {
  frame_config : Render3dExecuteFrameConfig
  cameras : Array[ExtractedCamera3d]
  meshes : Array[ExtractedMesh3d]
}

///|
priv struct Render3dPreparedCameraQueue {
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d
  opaque_alpha_draw_item_indices : Array[Int]
  indexed_indirect_parameter_indices : Array[Int]
  non_indexed_indirect_parameter_indices : Array[Int]
  camera_pass_projection : @pbr_render.Render3dPassProjection
  viewport_state : Render3dCameraViewportState
  camera_exposure_value : Float
}

///|
priv struct Render3dQueuedFrame {
  frame_config : Render3dExecuteFrameConfig
  cameras : Array[ExtractedCamera3d]
  meshes : Array[ExtractedMesh3d]
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?]
  camera_execution_plans : Array[Render3dCameraExecutionPlan?]
  queued_shadow_phase_views : Array[Render3dQueuedShadowPhaseView]
  prepared_camera_count : Int
}

///|
priv struct Render3dShadowExecutionData {
  camera_execution_plans : Array[Render3dCameraExecutionPlan?]
  queued_shadow_phase_views : Array[Render3dQueuedShadowPhaseView]
}

///|
priv struct Render3dExecuteQueueState {
  mut pending_frame : Render3dPendingFrame?
  mut shadow_execution_data : Render3dShadowExecutionData?
  mut queued_frame : Render3dQueuedFrame?
}

///|
fn render3d_execute_queue_state_default() -> Render3dExecuteQueueState {
  Render3dExecuteQueueState::{
    pending_frame: None,
    shadow_execution_data: None,
    queued_frame: None,
  }
}

///|
fn render3d_queue_store_pending_frame(
  world : @ecs.World,
  frame_config : Render3dExecuteFrameConfig,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    value.pending_frame = Some(Render3dPendingFrame::{
      frame_config,
      cameras,
      meshes,
    })
    value.shadow_execution_data = None
  })
}

///|
fn render3d_queue_take_pending_frame(
  world : @ecs.World,
) -> Render3dPendingFrame? {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    let pending = value.pending_frame
    value.pending_frame = None
    pending
  })
}

///|
fn render3d_pending_frame_snapshot(world : @ecs.World) -> Render3dPendingFrame? {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.peek().pending_frame
}

///|
let render3d_execute_queue_state_key : @ecs.ResourceKey[
  Render3dExecuteQueueState,
] = @ecs.register_resource(debug_name="mgstudio.render3d.execute_queue_state")

///|
impl @app.Resource for Render3dExecuteQueueState with fn resource() {
  render3d_execute_queue_state_key
}

///|
fn ensure_render3d_execute_queue_state(world : @ecs.World) -> Unit {
  if world.get_resource(Render3dExecuteQueueState::resource()) is None {
    world.insert_resource(
      Render3dExecuteQueueState::resource(),
      render3d_execute_queue_state_default(),
    )
  }
}

///|
fn render3d_execute_queue_state_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dExecuteQueueState] {
  ensure_render3d_execute_queue_state(world)
  match world.get_resource_mut(Render3dExecuteQueueState::resource()) {
    Some(state) => state
    None => abort("Missing Render3dExecuteQueueState resource in render world")
  }
}

///|
fn render3d_queue_store_frame(
  world : @ecs.World,
  frame_config : Render3dExecuteFrameConfig,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
  camera_execution_plans : Array[Render3dCameraExecutionPlan?],
  queued_shadow_phase_views : Array[Render3dQueuedShadowPhaseView],
) -> Unit {
  let mut prepared_camera_count = cameras.length()
  if prepared_camera_queues.length() < prepared_camera_count {
    prepared_camera_count = prepared_camera_queues.length()
  }
  if camera_execution_plans.length() < prepared_camera_count {
    prepared_camera_count = camera_execution_plans.length()
  }
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    value.queued_frame = Some(Render3dQueuedFrame::{
      frame_config,
      cameras,
      meshes,
      prepared_camera_queues,
      camera_execution_plans,
      queued_shadow_phase_views,
      prepared_camera_count,
    })
  })
}

///|
fn render3d_queue_take_frame(world : @ecs.World) -> Render3dQueuedFrame? {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    let queued = value.queued_frame
    value.queued_frame = None
    queued
  })
}

///|
fn render3d_queue_frame_snapshot(world : @ecs.World) -> Render3dQueuedFrame? {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.peek().queued_frame
}

///|
fn render3d_queue_store_shadow_execution_data(
  world : @ecs.World,
  camera_execution_plans : Array[Render3dCameraExecutionPlan?],
  queued_shadow_phase_views : Array[Render3dQueuedShadowPhaseView],
) -> Unit {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    value.shadow_execution_data = Some(Render3dShadowExecutionData::{
      camera_execution_plans,
      queued_shadow_phase_views,
    })
  })
}

///|
fn render3d_queue_take_shadow_execution_data(
  world : @ecs.World,
) -> Render3dShadowExecutionData? {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    let data = value.shadow_execution_data
    value.shadow_execution_data = None
    data
  })
}

///|
fn render3d_queue_clear_frame(world : @ecs.World) -> Unit {
  let state = render3d_execute_queue_state_mut_or_abort(world)
  state.modify(fn(value) {
    value.pending_frame = None
    value.shadow_execution_data = None
    value.queued_frame = None
  })
}

///|
