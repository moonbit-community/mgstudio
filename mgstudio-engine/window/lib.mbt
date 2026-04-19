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
pub fn window_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  window_plugin_with(app, WindowPlugin::default())
}

///|
pub impl @app.Plugin for WindowPlugin with name(_self) {
  WINDOW_PLUGIN_NAME
}

///|
pub impl @app.Plugin for WindowPlugin with build(self, app) {
  window_plugin_with(app, self)
}

///|
pub fn window_plugin_with(
  app : @app.App[@ecs.World],
  plugin : WindowPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  next = next
    .add_message(ecs_key_window_event)
    .add_message(ecs_key_window_resized)
    .add_message(ecs_key_window_created)
    .add_message(ecs_key_cursor_moved)
    .add_message(ecs_key_cursor_entered)
    .add_message(ecs_key_cursor_left)
    .add_message(ecs_key_window_backend_scale_factor_changed)
    .add_message(ecs_key_window_close_requested)
    .add_message(ecs_key_window_closing)
    .add_message(ecs_key_window_closed)
    .add_message(ecs_key_window_destroyed)
    .add_message(ecs_key_window_focused)
    .add_message(ecs_key_window_occluded)
    .add_message(ecs_key_window_scale_factor_changed)
    .add_message(ecs_key_file_drag_and_drop)
    .add_message(ecs_key_window_moved)
    .add_message(ecs_key_window_theme_changed)
    .add_message(ecs_key_app_lifecycle)
    .add_message(ecs_key_request_redraw)
    .add_message(ecs_key_ime)
    .add_systems(@app.First, @app.system(screenshot_clear_system))
  if plugin.primary_window is Some(primary_window) {
    window_spawn_primary_window_entity(
      next.world(),
      primary_window,
      plugin.primary_cursor_options,
    )
  }
  match plugin.exit_condition {
    OnPrimaryClosed =>
      next = next.add_systems(
        @app.PostUpdate,
        @app.system(@app.system_param2(exit_on_primary_closed)),
      )
    OnAllClosed =>
      next = next.add_systems(
        @app.PostUpdate,
        @app.system(@app.system_param2(exit_on_all_closed)),
      )
    DontExit => ()
  }
  if plugin.close_when_requested {
    next = next.add_systems(
      @app.Update,
      @app.system(@app.system_param2(close_when_requested)),
    )
  }
  next
}
