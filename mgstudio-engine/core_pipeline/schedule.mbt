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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/schedule.rs`.
// Core pipeline schedule labels and system-set stages.

///|
pub const CORE_3D_SCHEDULE_LABEL : String = "mgstudio.core_pipeline.core_3d"

///|
pub const CORE_2D_SCHEDULE_LABEL : String = "mgstudio.core_pipeline.core_2d"

///|
pub struct Core3d {}

///|
pub struct Core2d {}

///|
pub fn Core3d::default() -> Core3d {
  Core3d::{  }
}

///|
pub fn Core2d::default() -> Core2d {
  Core2d::{  }
}

///|
pub(all) enum Core3dSystems {
  Prepass
  MainPass
  PostProcess
} derive(Eq, Debug)

///|
pub(all) enum Core2dSystems {
  MainPass
  PostProcess
} derive(Eq, Debug)

///|
pub fn core3d_system_set_prepass() -> @app.SystemSet {
  @app.system_set("mgstudio.core_pipeline.core3d.prepass")
}

///|
pub fn core3d_system_set_main_pass() -> @app.SystemSet {
  @app.system_set("mgstudio.core_pipeline.core3d.main_pass")
}

///|
pub fn core3d_system_set_post_process() -> @app.SystemSet {
  @app.system_set("mgstudio.core_pipeline.core3d.post_process")
}

///|
pub fn core2d_system_set_main_pass() -> @app.SystemSet {
  @app.system_set("mgstudio.core_pipeline.core2d.main_pass")
}

///|
pub fn core2d_system_set_post_process() -> @app.SystemSet {
  @app.system_set("mgstudio.core_pipeline.core2d.post_process")
}

///|
pub fn core3d_base_schedule() -> @app.Schedule {
  @app.Schedule::new(@app.ScheduleStage::Custom(CORE_3D_SCHEDULE_LABEL))
}

///|
pub fn core2d_base_schedule() -> @app.Schedule {
  @app.Schedule::new(@app.ScheduleStage::Custom(CORE_2D_SCHEDULE_LABEL))
}

///|
pub fn core_pipeline_schedule_enabled() -> Bool {
  true
}

///|
pub struct CameraDriverSortedCamera {
  entity_id : Int
  order : Int
  schedule_label : String
  target_window_id : Int?
} derive(Eq, Debug)

///|
pub fn CameraDriverSortedCamera::new(
  entity_id~ : Int,
  order~ : Int,
  schedule_label~ : String,
  target_window_id? : Int? = None,
) -> CameraDriverSortedCamera {
  CameraDriverSortedCamera::{ entity_id, order, schedule_label, target_window_id }
}

///|
pub struct CameraDriverState {
  sorted_cameras : Array[CameraDriverSortedCamera]
  covered_window_ids : Array[Int]
}

///|
pub fn CameraDriverState::default() -> CameraDriverState {
  CameraDriverState::{ sorted_cameras: [], covered_window_ids: [] }
}

///|
pub fn CameraDriverState::clear(self : CameraDriverState) -> Unit {
  self.sorted_cameras.clear()
  self.covered_window_ids.clear()
}

///|
pub fn CameraDriverState::push_sorted_camera(
  self : CameraDriverState,
  sorted_camera : CameraDriverSortedCamera,
) -> Unit {
  self.sorted_cameras.push(sorted_camera)
}

///|
pub fn CameraDriverState::mark_window_covered(
  self : CameraDriverState,
  window_id : Int,
) -> Unit {
  for existing in self.covered_window_ids {
    if existing == window_id {
      return
    }
  }
  self.covered_window_ids.push(window_id)
}

///|
pub fn CameraDriverState::window_is_covered(
  self : CameraDriverState,
  window_id : Int,
) -> Bool {
  for existing in self.covered_window_ids {
    if existing == window_id {
      return true
    }
  }
  false
}

///|
pub let ecs_key_camera_driver_state : @ecs.ResourceKey[
  CameraDriverState
] = @ecs.register_resource(
  debug_name="core_pipeline.schedule.camera_driver_state",
)

///|
pub impl @app.Resource for CameraDriverState with resource() {
  ecs_key_camera_driver_state
}

///|
pub fn camera_driver_prepare_state(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.init_resource(fn() { CameraDriverState::default() })
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/schedule.rs` (`camera_driver` entrypoint).
pub fn camera_driver(world : @ecs.World) -> Unit {
  if world.resource(ecs_key_camera_driver_state).get() is Some(camera_driver_state) {
    camera_driver_state.clear()
  }
}
