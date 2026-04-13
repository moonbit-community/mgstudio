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
priv struct MotionBlurHistoryDenseCache {
  mut frame_stamp : Int
  transforms : Array[@transform.Transform?]
  generations : Array[Int]
  stamps : Array[Int]
}

///|
priv struct CameraMotionBlurHistoryEntry {
  entity : @core.Entity
  transform : @transform.Transform
  clip_from_world : ProjectionMatrix3d
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
  mut prepared_camera_queues : Array[Render3dPreparedCameraQueue?]
}

///|
priv struct Render3dExecuteQueueState {
  mut queued_frame : Render3dQueuedFrame?
  motion_blur_history : MotionBlurHistoryDenseCache
  mut camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry]
}

///|
fn render3d_execute_queue_state_default() -> Render3dExecuteQueueState {
  Render3dExecuteQueueState::{
    queued_frame: None,
    motion_blur_history: {
      frame_stamp: 0,
      transforms: [],
      generations: [],
      stamps: [],
    },
    camera_motion_blur_history: [],
  }
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
fn render3d_motion_blur_history_ensure_slot(
  state_ref : Ref[Render3dExecuteQueueState],
  entity_id : Int,
) -> Unit {
  if entity_id < 0 {
    return
  }
  while state_ref.val.motion_blur_history.transforms.length() <= entity_id {
    state_ref.val.motion_blur_history.transforms.push(None)
    state_ref.val.motion_blur_history.generations.push(0)
    state_ref.val.motion_blur_history.stamps.push(0)
  }
}

///|
fn motion_blur_history_begin_frame(world : @ecs.World) -> Int {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  state_ref.val.motion_blur_history.frame_stamp = state_ref.val.motion_blur_history.frame_stamp +
    1
  if state_ref.val.motion_blur_history.frame_stamp <= 0 {
    state_ref.val.motion_blur_history.frame_stamp = 1
    for i in 0..<state_ref.val.motion_blur_history.stamps.length() {
      state_ref.val.motion_blur_history.stamps[i] = 0
    }
  }
  state_ref.val.motion_blur_history.frame_stamp
}

///|
fn motion_blur_history_get(
  world : @ecs.World,
  entity : @core.Entity,
  previous_frame_stamp : Int,
) -> @transform.Transform? {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  let history = state_ref.val.motion_blur_history
  if entity.id < 0 || entity.id >= history.transforms.length() {
    return None
  }
  if history.stamps[entity.id] != previous_frame_stamp {
    return None
  }
  if history.generations[entity.id] != entity.generation {
    return None
  }
  history.transforms[entity.id]
}

///|
fn motion_blur_history_sync(
  world : @ecs.World,
  meshes : Array[ExtractedMesh3d],
  frame_stamp : Int,
) -> Unit {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  for mesh in meshes {
    let entity = mesh.entity.main_entity
    if entity.id < 0 {
      continue
    }
    render3d_motion_blur_history_ensure_slot(state_ref, entity.id)
    state_ref.val.motion_blur_history.transforms[entity.id] = Some(
      mesh.payload.transform,
    )
    state_ref.val.motion_blur_history.generations[entity.id] = entity.generation
    state_ref.val.motion_blur_history.stamps[entity.id] = frame_stamp
  }
}

///|
fn camera_motion_blur_history_get(
  world : @ecs.World,
  entity : @core.Entity,
) -> CameraMotionBlurHistoryEntry? {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  for item in state_ref.val.camera_motion_blur_history {
    if item.entity.id == entity.id &&
      item.entity.generation == entity.generation {
      return Some(item)
    }
  }
  None
}

///|
fn camera_motion_blur_history_sync(
  world : @ecs.World,
  history : Array[CameraMotionBlurHistoryEntry],
) -> Unit {
  let state_ref = render3d_execute_queue_state_ref_or_abort(world)
  state_ref.val.camera_motion_blur_history = history
}
