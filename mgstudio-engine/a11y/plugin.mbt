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
fn ensure_requested_binding_system(world : @ecs.World) -> Unit {
  guard get_accessibility_requested_resource(world).get() is Some(requested) else {
    return
  }
  @windowing.bind_accessibility_requested(
    AccessibilityRequested::handle(requested),
  )
}

///|
pub fn a11y_poll_actions_system(world : @ecs.World) -> Unit {
  let actions = @windowing.take_accessibility_actions()
  if actions.length() == 0 {
    return
  }

  let tick = world.read_change_tick()
  let writer = world.message_writer(ecs_msg_key_action_request)
  let state = Ref::new(
    match get_a11y_state_resource(world).get() {
      Some(existing) => existing
      None => A11yState::default()
    },
  )

  for action in actions {
    ignore(writer.write(ActionRequest::new(action)))
    if action.action() == @moon_accesskit.Action::Focus ||
      action.action() == @moon_accesskit.Action::SetValue {
      A11yState::set_focused_node(state, action.target_node())
    }
    A11yState::push_action(state, action)
  }

  get_a11y_state_resource(world).insert(state.val, tick)
}

///|
pub fn a11y_commit_pending_update_system(world : @ecs.World) -> Unit {
  let manage_updates = match
    get_manage_accessibility_updates_resource(world).get() {
    Some(manage_updates) => manage_updates.get()
    None => false
  }
  if !manage_updates {
    return
  }
  @windowing.commit_pending_accessibility_update() |> ignore
}

///|
pub fn accessibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .init_resource(AccessibilityRequested::default)
  .init_resource(ManageAccessibilityUpdates::default)
  .init_resource(A11yState::default)
  .add_message(ecs_msg_key_action_request)
  .add_pre_update_system_config(
    @app.system(ensure_requested_binding_system).in_set(a11y_set),
  )
  .add_pre_update_system_config(
    @app.system(a11y_poll_actions_system).in_set(a11y_set),
  )
  .add_last_system_config(
    @app.system(a11y_commit_pending_update_system).in_set(a11y_set),
  )
}

///|
pub fn a11y_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  accessibility_plugin(app)
}
