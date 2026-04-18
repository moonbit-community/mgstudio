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
const WINIT_PLUGIN_NAME : String = "mgstudio.winit.WinitPlugin"

///|
pub type RawWinitWindowEventData = @windowing.RawWinitWindowEventData

///|
pub(all) struct RawWinitWindowEvent {
  window_id : Int
  event : RawWinitWindowEventData
} derive(Eq)

///|
pub let ecs_key_raw_winit_window_event : @ecs.MessageKey[RawWinitWindowEvent] = @ecs.register_message(
  debug_name="mgstudio_winit::RawWinitWindowEvent",
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
pub fn winit_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  winit_plugin_with(app, WinitPlugin::default())
}

///|
pub impl @app.Plugin for WinitPlugin with name(_self) {
  WINIT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for WinitPlugin with build(self, app) {
  winit_plugin_with(app, self)
}

///|
pub fn winit_plugin_with(
  app : @app.App[@ecs.World],
  plugin : WinitPlugin,
) -> @app.App[@ecs.World] {
  @windowing.set_event_loop_any_thread(plugin.run_on_any_thread)
  app
  .init_resource(WinitWindows::default)
  .init_resource(WinitMonitors::default)
  .init_resource(WinitSettings::default)
  .add_message(ecs_key_raw_winit_window_event)
  .add_message(@a11y.ecs_msg_key_action_request)
  .add_pre_update_system_config(
    @app.system(winit_bind_accessibility_requested_system).in_set(
      @a11y.a11y_set,
    ),
  )
  .add_post_update_system_config(
    @app.system(winit_poll_accessibility_actions_system).in_set(@a11y.a11y_set),
  )
  .add_post_update_system_config(
    @app.system(winit_update_accessibility_nodes_system)
    .in_set(@a11y.a11y_set)
    .run_if(winit_should_update_accessibility_nodes),
  )
  .add_last_system_config(
    @app.system(winit_commit_pending_accessibility_update_system).in_set(
      @a11y.a11y_set,
    ),
  )
  .add_systems(
    @app.Last,
    (
      @app.system(winit_changed_windows_system),
      @app.system(@winit_cursor.winit_changed_cursor_options_system),
      @app.system(winit_despawn_windows_system),
      @app.system(winit_check_keyboard_focus_lost_system),
    )
    |> @app.chain(),
  )
  .add_systems(
    @app.PreUpdate,
    (
      @app.system(winit_create_monitors_system),
      @app.system(winit_create_windows_system),
      @app.system(winit_prepare_windows_system),
      @app.system(winit_sync_windows_resource_system),
      @app.system(winit_write_raw_winit_window_events_system),
    )
    |> @app.chain(),
  )
  .set_runner(winit_runner)
}
