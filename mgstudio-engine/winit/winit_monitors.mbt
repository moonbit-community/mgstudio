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
pub struct WinitMonitorEntry {
  monitor : @window_core.MonitorHandle
  entity : @core.Entity
} derive(Eq)

///|
pub fn WinitMonitorEntry::new(
  monitor : @window_core.MonitorHandle,
  entity : @core.Entity,
) -> WinitMonitorEntry {
  WinitMonitorEntry::{ monitor, entity }
}

///|
pub struct WinitMonitors {
  monitors : Array[WinitMonitorEntry]
} derive(Eq)

///|
pub fn WinitMonitors::new() -> WinitMonitors {
  WinitMonitors::{ monitors: [] }
}

///|
pub fn WinitMonitors::nth(
  self : WinitMonitors,
  n : Int,
) -> @window_core.MonitorHandle? {
  if n < 0 || n >= self.monitors.length() {
    None
  } else {
    Some(self.monitors[n].monitor)
  }
}

///|
pub fn WinitMonitors::find_entity(
  self : WinitMonitors,
  entity : @core.Entity,
) -> @window_core.MonitorHandle? {
  for entry in self.monitors {
    if entry.entity == entity {
      return Some(entry.monitor)
    }
  }
  None
}

///|
pub impl Default for WinitMonitors with default() {
  WinitMonitors::new()
}

///|
let ecs_key_winit_monitors : @ecs.ResourceKey[WinitMonitors] = @ecs.register_resource(
  debug_name="bevy_winit::WinitMonitors",
)

///|
pub impl @app.Resource for WinitMonitors with resource() {
  ecs_key_winit_monitors
}
