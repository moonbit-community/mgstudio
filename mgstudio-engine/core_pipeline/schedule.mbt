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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/schedule.rs` (`camera_driver` entrypoint).
pub fn camera_driver(world : @ecs.World) -> Unit {
  @app.run_current_schedule_stage(
    world,
    @app.schedule_label(CORE_3D_SCHEDULE_LABEL),
  )
  @app.run_current_schedule_stage(
    world,
    @app.schedule_label(CORE_2D_SCHEDULE_LABEL),
  )
}
