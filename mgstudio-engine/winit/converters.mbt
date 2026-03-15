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
pub fn convert_winit_video_mode(
  mode : @window_core.VideoMode,
) -> @window.VideoMode {
  let size = mode.surface_size()
  @window.VideoMode::new(
    @math.UVec2::new(size.width(), size.height()),
    match mode.bit_depth() {
      Some(bit_depth) => bit_depth
      None => 0
    },
    match mode.refresh_rate_millihertz() {
      Some(refresh_rate) => refresh_rate
      None => 0
    },
  )
}

///|
pub fn convert_winit_monitor(
  monitor : @window_core.MonitorHandle,
) -> @window.Monitor {
  let size = monitor.surface_size()
  let position = monitor.position()
  let video_modes : Array[@window.VideoMode] = []
  for mode in monitor.video_modes() {
    video_modes.push(convert_winit_video_mode(mode))
  }
  @window.Monitor::{
    name: monitor.name(),
    physical_height: size.height(),
    physical_width: size.width(),
    physical_position: @math.IVec2::new(position.x(), position.y()),
    refresh_rate_millihertz: match monitor.current_video_mode() {
      Some(mode) => mode.refresh_rate_millihertz()
      None => None
    },
    scale_factor: monitor.scale_factor(),
    video_modes,
  }
}
