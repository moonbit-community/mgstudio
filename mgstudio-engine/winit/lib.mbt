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
pub(all) struct WinitPlugin {
  run_on_any_thread : Bool
}

///|
pub const WINIT_PLUGIN_ID : String = "bevy_winit::WinitPlugin"

///|
pub type RawWinitWindowEventData = @windowing.RawWinitWindowEventData

///|
pub(all) struct RawWinitWindowEvent {
  window_id : Int
  event : RawWinitWindowEventData
} derive(Eq, Show)

///|
pub let ecs_key_raw_winit_window_event : @ecs.MessageKey[RawWinitWindowEvent] = @ecs.register_message(
  debug_name="bevy_winit::RawWinitWindowEvent",
)

///|
pub impl @ecs.Message for RawWinitWindowEvent with message() {
  ecs_key_raw_winit_window_event
}

///|
pub fn WinitPlugin::default() -> WinitPlugin {
  WinitPlugin::{ run_on_any_thread: false }
}

///|
priv struct WinitPluginMarker {}

///|
let ecs_key_winit_plugin_marker : @ecs.ResourceKey[WinitPluginMarker] = @ecs.register_resource(
  debug_name="bevy_winit::WinitPluginMarker",
)

///|
pub fn winit_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  winit_plugin_with(app, WinitPlugin::default())
}

///|
pub impl @app.PluginReplacement for WinitPlugin with replacement_id(_self) {
  WINIT_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for WinitPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    winit_plugin_with(app, self)
  }
}

///|
pub fn winit_plugin_with(
  app : @app.App[@ecs.World],
  plugin : WinitPlugin,
) -> @app.App[@ecs.World] {
  plugin.run_on_any_thread |> ignore
  let mut next = app
  if !next.contains_resource(ecs_key_winit_plugin_marker) {
    next = next
      .insert_world_resource(ecs_key_winit_plugin_marker, WinitPluginMarker::{

      })
      .init_resource(WinitSettings::default)
      .add_message(ecs_key_raw_winit_window_event)
      .add_message(@a11y.ecs_msg_key_action_request)
      .add_pre_update_system_config(
        @app.system(winit_bind_accessibility_requested_system).in_set(
          @a11y.a11y_set,
        ),
      )
      .add_pre_update_system_config(
        @app.system(winit_poll_accessibility_actions_system).in_set(
          @a11y.a11y_set,
        ),
      )
      .add_last_system_config(
        @app.system(winit_commit_pending_accessibility_update_system).in_set(
          @a11y.a11y_set,
        ),
      )
      .add_last_system_config(@app.system(winit_changed_windows_system))
      .add_last_system_config(@app.system(winit_changed_cursor_options_system))
      .add_last_system_config(
        @app.system(winit_check_keyboard_focus_lost_system),
      )
      .add_systems(
        @app.PreUpdate,
        @app.system(winit_window_backend_sync_system),
      )
      .set_runner(winit_runner_builder)
  }
  next
}
