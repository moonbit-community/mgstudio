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
pub struct CameraDebugConfig {
  interval_seconds : Float
}

///|
pub fn CameraDebugConfig::new(interval_seconds : Float) -> CameraDebugConfig {
  CameraDebugConfig::{ interval_seconds, }
}

///|
pub fn CameraDebugConfig::default() -> CameraDebugConfig {
  CameraDebugConfig::new(1.0F)
}

///|
priv struct CameraDebugState {
  mut timer : Float
  mut config : CameraDebugConfig
}

///|
let camera_debug_state : Ref[CameraDebugState] = Ref::new(CameraDebugState::{
  timer: 0.0F,
  config: CameraDebugConfig::default(),
})

///|
pub fn camera_debug_config() -> CameraDebugConfig {
  camera_debug_state.val.config
}

///|
pub fn camera_debug_set_config(config : CameraDebugConfig) -> Unit {
  camera_debug_state.val.config = config
}

///|
fn camera_debug_system() -> Unit {
  let interval = camera_debug_state.val.config.interval_seconds
  let mut timer = camera_debug_state.val.timer + @time.time_delta_seconds()
  if interval <= 0.0F {
    @render2d.render2d_debug_log_primary_camera()
    camera_debug_state.val.timer = 0.0F
    return
  }
  if timer >= interval {
    timer = timer - interval
    @render2d.render2d_debug_log_primary_camera()
  }
  camera_debug_state.val.timer = timer
}

///|
pub fn camera_debug_plugin(app : @app.App) -> @app.App {
  app.add_system(camera_debug_system)
}

///|
pub fn camera_debug_plugin_with_interval(
  interval_seconds : Float,
) -> @app.Plugin {
  fn(app : @app.App) -> @app.App {
    camera_debug_set_config(CameraDebugConfig::new(interval_seconds))
    camera_debug_plugin(app)
  }
}
