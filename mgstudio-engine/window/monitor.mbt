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
pub(all) struct VideoMode {
  physical_size : @math.UVec2
  bit_depth : Int
  refresh_rate_millihertz : Int
}

///|
pub fn VideoMode::new(
  physical_size : @math.UVec2,
  bit_depth : Int,
  refresh_rate_millihertz : Int,
) -> VideoMode {
  VideoMode::{ physical_size, bit_depth, refresh_rate_millihertz }
}

///|
pub(all) struct Monitor {
  name : String?
  physical_height : Int
  physical_width : Int
  physical_position : @math.IVec2
  refresh_rate_millihertz : Int?
  scale_factor : Double
  video_modes : Array[VideoMode]
}

///|
pub fn Monitor::physical_size(self : Monitor) -> @math.UVec2 {
  let width = if self.physical_width < 0 { 0 } else { self.physical_width }
  let height = if self.physical_height < 0 { 0 } else { self.physical_height }
  @math.UVec2::new(width, height)
}

///|
pub(all) struct PrimaryMonitor {} derive(Eq, Debug)

///|
pub let ecs_key_monitor : @ecs.ComponentKey[Monitor] = @ecs.register_component(
  debug_name="mgstudio_window::Monitor",
)

///|
pub let ecs_key_primary_monitor : @ecs.ComponentKey[PrimaryMonitor] = @ecs.register_component(
  debug_name="mgstudio_window::PrimaryMonitor",
)

///|
pub impl @ecs.Component for Monitor with component() {
  ecs_key_monitor
}

///|
pub impl @ecs.Component for PrimaryMonitor with component() {
  ecs_key_primary_monitor
}
