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
// Bevy source: `bevy/crates/bevy_dev_tools/src/picking_debug.rs`.

///|
pub enum DebugPickingMode {
  Normal
  Noisy
  Disabled
} derive(Eq, Debug)

///|
pub fn DebugPickingMode::default() -> DebugPickingMode {
  DebugPickingMode::Disabled
}

///|
pub fn dev_tools_picking_debug_enabled(mode : DebugPickingMode) -> Bool {
  mode == DebugPickingMode::Normal || mode == DebugPickingMode::Noisy
}

///|
pub fn dev_tools_picking_debug_is_noisy(mode : DebugPickingMode) -> Bool {
  mode == DebugPickingMode::Noisy
}

///|
pub impl @app.Resource for DebugPickingMode with resource() {
  ecs_res_key_debug_picking_mode
}

///|
priv struct PickingDebugPluginMarker {}

///|
let ecs_res_key_debug_picking_mode : @ecs.ResourceKey[DebugPickingMode] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::DebugPickingMode",
)

///|
let ecs_res_key_picking_debug_plugin_marker : @ecs.ResourceKey[
  PickingDebugPluginMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::PickingDebugPluginMarker",
)

///|
fn picking_debug_should_log(
  mode : DebugPickingMode,
  event : @pointer_events.PointerEvent,
) -> Bool {
  match mode {
    DebugPickingMode::Noisy => true
    DebugPickingMode::Normal =>
      event.kind != @pointer_events.PointerEventKind::Move
    DebugPickingMode::Disabled => false
  }
}

///|
fn picking_debug_log_system(
  mode : @app.Res[DebugPickingMode],
  events : @app.ResMut[@app.PickingEvents],
) -> Unit {
  let debug_mode = mode.get()
  if !dev_tools_picking_debug_enabled(debug_mode) {
    return
  }
  let events_ref = events.get_ref()
  let captured_events = @app.PickingEvents::drain(events_ref)
  for event in captured_events {
    if picking_debug_should_log(debug_mode, event) {
      let target_label = match event.target {
        Some(entity) =>
          "Some(\{entity.id.to_string()}/\{entity.generation.to_string()})"
        None => "None"
      }
      let position_label = "(\{event.position.x.to_string()}, \{event.position.y.to_string()})"
      println(
        "[picking_debug] pointer=\{event.pointer.to_string()} kind=\{to_repr(event.kind).to_string()} target=\{target_label} position=\{position_label}",
      )
    }
    @app.PickingEvents::push(events_ref, event)
  }
}

///|
pub fn dev_tools_picking_debug_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_res_key_picking_debug_plugin_marker) {
    return app
  }
  let mut next = app.insert_world_resource(
    ecs_res_key_picking_debug_plugin_marker,
    PickingDebugPluginMarker::{  },
  )
  if !next.contains_resource(ecs_res_key_debug_picking_mode) {
    next = next.insert_world_resource(
      ecs_res_key_debug_picking_mode,
      DebugPickingMode::default(),
    )
  }
  next.add_pre_update_system_config(
    @app.system(@app.system_param2(picking_debug_log_system)).after(
      @picking.picking_set_events,
    ),
  )
}
