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
fn winit_bind_accessibility_requested_system(world : @ecs.World) -> Unit {
  guard @a11y.get_accessibility_requested_resource(world).get()
    is Some(requested) else {
    return
  }
  @windowing.bind_accessibility_requested(
    @a11y.AccessibilityRequested::handle(requested),
  )
}

///|
fn winit_poll_accessibility_actions_system(world : @ecs.World) -> Unit {
  let actions = @windowing.take_accessibility_actions()
  if actions.length() == 0 {
    return
  }
  let tick = world.read_change_tick()
  let writer = world.message_writer(@a11y.ecs_msg_key_action_request)
  let state = Ref::new(
    match @a11y.get_a11y_state_resource(world).get() {
      Some(existing) => existing
      None => @a11y.A11yState::default()
    },
  )
  for action in actions {
    ignore(writer.write(@a11y.ActionRequest::new(action)))
    if action.action() == @moon_accesskit.Action::Focus ||
      action.action() == @moon_accesskit.Action::SetValue {
      @a11y.A11yState::set_focused_node(state, action.target_node())
    }
    @a11y.A11yState::push_action(state, action)
  }
  @a11y.get_a11y_state_resource(world).insert(state.val, tick)
}

///|
fn winit_commit_pending_accessibility_update_system(world : @ecs.World) -> Unit {
  let manage_updates = match
    @a11y.get_manage_accessibility_updates_resource(world).get() {
    Some(manage_updates) => manage_updates.get()
    None => false
  }
  if !manage_updates {
    return
  }
  @windowing.commit_pending_accessibility_update() |> ignore
}

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
      .add_systems(
        @app.PreUpdate,
        @app.system(@window.window_backend_sync_system),
      )
      .set_runner(@window.window_runner_builder)
  }
  next
}
