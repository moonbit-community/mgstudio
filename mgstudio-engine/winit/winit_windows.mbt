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
pub struct WinitWindowEntry {
  entity : @core.Entity
  window : @window.HostWindow
} derive(Eq)

///|
pub fn WinitWindowEntry::new(
  entity : @core.Entity,
  window : @window.HostWindow,
) -> WinitWindowEntry {
  WinitWindowEntry::{ entity, window }
}

///|
pub struct WinitWindows {
  windows : Array[WinitWindowEntry]
} derive(Eq)

///|
pub fn WinitWindows::new() -> WinitWindows {
  WinitWindows::{ windows: [] }
}

///|
pub fn WinitWindows::sync_windows(
  self : WinitWindows,
  world : @ecs.World,
) -> Unit {
  self.windows.clear()
  for entry in @window.window_host_entries(world) {
    self.windows.push(WinitWindowEntry::new(entry.entity, entry.host_window))
  }
}

///|
pub fn WinitWindows::get_window(
  self : WinitWindows,
  entity : @core.Entity,
) -> @window.HostWindow? {
  for entry in self.windows {
    if entry.entity == entity {
      return Some(entry.window)
    }
  }
  None
}

///|
pub fn WinitWindows::get_window_entity(
  self : WinitWindows,
  window : @window.HostWindow,
) -> @core.Entity? {
  for entry in self.windows {
    if entry.window == window {
      return Some(entry.entity)
    }
  }
  None
}

///|
pub fn WinitWindows::remove_window(
  self : WinitWindows,
  entity : @core.Entity,
) -> @window.HostWindow? {
  for i, entry in self.windows {
    if entry.entity == entity {
      return Some(self.windows.remove(i).window)
    }
  }
  None
}

///|
pub impl Default for WinitWindows with default() {
  WinitWindows::new()
}

///|
let ecs_key_winit_windows : @ecs.ResourceKey[WinitWindows] = @ecs.register_resource(
  debug_name="bevy_winit::WinitWindows",
)

///|
pub impl @app.Resource for WinitWindows with resource() {
  ecs_key_winit_windows
}

///|
pub fn winit_sync_windows_resource_system(world : @ecs.World) -> Unit {
  let windows = match (try! world.get_resource(WinitWindows::resource())) {
    Some(windows) => windows
    None => WinitWindows::default()
  }
  windows.sync_windows(world)
  world.insert_resource(WinitWindows::resource(), windows)
}
