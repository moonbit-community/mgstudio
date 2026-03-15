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
fn winit_monitor_entry_index(
  entries : Array[WinitMonitorEntry],
  monitor : @window_core.MonitorHandle,
) -> Int? {
  for i, entry in entries {
    if entry.monitor == monitor {
      return Some(i)
    }
  }
  None
}

///|
fn winit_has_primary_monitor(world : @ecs.World, entity : @core.Entity) -> Bool {
  match (try! world.get_component(entity) : @window.PrimaryMonitor?) {
    Some(_) => true
    None => false
  }
}

///|
fn winit_sync_primary_monitor_marker(
  world : @ecs.World,
  entity : @core.Entity,
  monitor : @window_core.MonitorHandle,
  primary_monitor : @window_core.MonitorHandle?,
) -> Unit {
  let is_primary = match primary_monitor {
    Some(primary) => primary == monitor
    None => false
  }
  if is_primary {
    if !winit_has_primary_monitor(world, entity) {
      try! world.set_component(entity, @window.PrimaryMonitor::{  })
    }
  } else if winit_has_primary_monitor(world, entity) {
    try! (world.remove(entity, @window.ecs_key_primary_monitor) |> ignore)
  }
}

///|
fn winit_sync_monitor_entity(
  world : @ecs.World,
  entity : @core.Entity,
  monitor : @window_core.MonitorHandle,
  primary_monitor : @window_core.MonitorHandle?,
) -> Unit {
  try! world.set_component(entity, convert_winit_monitor(monitor))
  winit_sync_primary_monitor_marker(world, entity, monitor, primary_monitor)
}

///|
pub fn winit_create_monitors_system(world : @ecs.World) -> Unit {
  let monitor_handles = @windowing.available_monitors()
  let primary_monitor = @windowing.primary_monitor()
  let monitors = match (try! world.get_resource(WinitMonitors::resource())) {
    Some(monitors) => monitors
    None => WinitMonitors::default()
  }

  let seen_entries : Array[Bool] = []
  for _ in 0..<monitors.monitors.length() {
    seen_entries.push(false)
  }

  for monitor in monitor_handles {
    match winit_monitor_entry_index(monitors.monitors, monitor) {
      Some(index) => {
        seen_entries[index] = true
        let existing_entry = monitors.monitors[index]
        if world.is_alive(existing_entry.entity) {
          winit_sync_monitor_entity(
            world,
            existing_entry.entity,
            monitor,
            primary_monitor,
          )
        } else {
          let entity = world.spawn()
          winit_sync_monitor_entity(world, entity, monitor, primary_monitor)
          monitors.monitors[index] = WinitMonitorEntry::new(monitor, entity)
        }
      }
      None => {
        let entity = world.spawn()
        winit_sync_monitor_entity(world, entity, monitor, primary_monitor)
        monitors.monitors.push(WinitMonitorEntry::new(monitor, entity))
        seen_entries.push(true)
      }
    }
  }

  let next_entries : Array[WinitMonitorEntry] = []
  for i, entry in monitors.monitors {
    if i < seen_entries.length() && seen_entries[i] {
      next_entries.push(entry)
    } else if world.is_alive(entry.entity) {
      try! world.despawn(entry.entity)
    }
  }
  monitors.monitors.clear()
  for entry in next_entries {
    monitors.monitors.push(entry)
  }

  world.insert_resource(WinitMonitors::resource(), monitors)
}

///|
fn winit_write_raw_winit_window_events(
  world : @ecs.World,
  events : Array[@windowing.RawWinitWindowEventSnapshot],
) -> Unit {
  if events.length() == 0 {
    return
  }
  let writer = world.message_writer(ecs_key_raw_winit_window_event)
  for event in events {
    ignore(
      writer.write(RawWinitWindowEvent::{
        window_id: event.window_id,
        event: event.event,
      }),
    )
  }
}

///|
pub fn winit_window_backend_sync_system(world : @ecs.World) -> Unit {
  @window.window_backend_create_windows_system(world)
  @window.window_backend_prepare_system(world)
  winit_sync_windows_resource_system(world)
  winit_create_monitors_system(world)
  winit_write_raw_winit_window_events(
    world,
    @windowing.take_raw_winit_window_events(),
  )
}

///|
fn winit_monitors_resource(world : @ecs.World) -> WinitMonitors {
  match (try! world.get_resource(WinitMonitors::resource())) {
    Some(monitors) => monitors
    None => WinitMonitors::default()
  }
}

///|
fn winit_apply_window_mode_change(
  monitors : WinitMonitors,
  request : @window.WindowModeChangeRequest,
) -> Unit {
  let primary_monitor = @windowing.primary_monitor()
  let current_monitor = @windowing.current_monitor(request.host_window)
  match request.mode {
    Windowed => @windowing.set_fullscreen(request.host_window, fullscreen=None)
    BorderlessFullscreen(monitor_selection) => {
      let monitor = select_monitor(
        monitors, primary_monitor, current_monitor, monitor_selection,
      )
      @windowing.set_fullscreen(
        request.host_window,
        fullscreen=Some(@window_core.Fullscreen::Borderless(monitor)),
      )
    }
    Fullscreen(monitor_selection, video_mode_selection) =>
      match
        select_monitor(
          monitors, primary_monitor, current_monitor, monitor_selection,
        ) {
        Some(monitor) =>
          match get_selected_videomode(monitor, video_mode_selection) {
            Some(video_mode) =>
              @windowing.set_fullscreen(
                request.host_window,
                fullscreen=Some(
                  @window_core.Fullscreen::Exclusive(monitor, video_mode),
                ),
              )
            None =>
              @window.host_debug_string(
                value="bevy_winit: could not find valid fullscreen video mode",
              )
          }
        None =>
          abort("bevy_winit: could not find monitor for fullscreen selection")
      }
  }
}

///|
pub fn winit_changed_windows_system(world : @ecs.World) -> Unit {
  @window.window_backend_apply_changed_windows_system(world)
  let monitors = winit_monitors_resource(world)
  for request in @window.window_take_changed_mode_requests(world) {
    winit_apply_window_mode_change(monitors, request)
  }
}

///|
pub fn winit_changed_cursor_options_system(world : @ecs.World) -> Unit {
  @window.window_backend_apply_changed_cursor_options_system(world)
}

///|
pub fn winit_despawn_windows_system(world : @ecs.World) -> Unit {
  @window.window_despawn_closing_windows_system(world)
}

///|
pub fn winit_check_keyboard_focus_lost_system(world : @ecs.World) -> Unit {
  @input.input_check_keyboard_focus_lost_system(world)
}
