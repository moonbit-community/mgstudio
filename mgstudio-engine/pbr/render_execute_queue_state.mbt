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
  mut prepared_camera_queues : Array[Render3dPreparedCameraQueue?]
}

///|
priv struct Render3dExecuteQueueState {
  mut queued_frame : Render3dQueuedFrame?
}

///|
fn render3d_execute_queue_state_default() -> Render3dExecuteQueueState {
  Render3dExecuteQueueState::{ queued_frame: None }
}

///|
let render3d_execute_queue_state_key : @ecs.ResourceKey[
  Render3dExecuteQueueState,
] = @ecs.register_resource(debug_name="mgstudio.render3d.execute_queue_state")

///|
impl @app.Resource for Render3dExecuteQueueState with resource() {
  render3d_execute_queue_state_key
}

///|
fn ensure_render3d_execute_queue_state(world : @ecs.World) -> Unit {
  if (try! world.get_resource(Render3dExecuteQueueState::resource())) is None {
    world.insert_resource(
      Render3dExecuteQueueState::resource(),
      render3d_execute_queue_state_default(),
    )
  }
}

///|
fn render3d_execute_queue_state_ref_or_abort(
  world : @ecs.World,
) -> Ref[Render3dExecuteQueueState] {
  ensure_render3d_execute_queue_state(world)
  match
    (try! world.get_resource_ref_mut(Render3dExecuteQueueState::resource())) {
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
) -> Unit {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  state_ref.val.queued_frame = Some(Render3dQueuedFrame::{
    frame_config,
    cameras,
    meshes,
    prepared_camera_queues: [],
  })
}

///|
fn render3d_queue_take_frame(world : @ecs.World) -> Render3dQueuedFrame? {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  let queued = state_ref.val.queued_frame
  state_ref.val.queued_frame = None
  queued
}

///|
fn render3d_queue_has_frame(world : @ecs.World) -> Bool {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  state_ref.val.queued_frame is Some(_)
}

///|
fn render3d_queue_clear_frame(world : @ecs.World) -> Unit {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  state_ref.val.queued_frame = None
}

///|
fn render3d_queue_update_prepared_camera_queues(
  world : @ecs.World,
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
) -> Unit {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  match state_ref.val.queued_frame {
    Some(frame) => {
      frame.prepared_camera_queues = prepared_camera_queues
      state_ref.val.queued_frame = Some(frame)
    }
    None => ()
  }
}

///|
