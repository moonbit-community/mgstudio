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
fn read_window_created(world : @ecs.World) -> Array[@window.WindowCreated] {
  let reader = world.message_reader(@window.ecs_key_window_created, Ref::new(0))
  try! reader.read()
}

///|
fn read_action_requests(world : @ecs.World) -> Array[@a11y.ActionRequest] {
  let reader = world.message_reader(
    @a11y.ecs_msg_key_action_request,
    Ref::new(0),
  )
  try! reader.read()
}

///|
test "winit: plugin replacement id aligns with bevy_winit" {
  let plugin = WinitPlugin::default()
  inspect(plugin.replacement_id(), content=WINIT_PLUGIN_ID)
}

///|
test "winit: backend sync is owned by winit plugin" {
  let app_without_winit = @window.window_plugin(
    @app.App::new(@ecs.World::new()),
  ).run_once()
  inspect(read_window_created(app_without_winit.world()).length(), content="0")

  let app_with_winit = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  inspect(read_window_created(app_with_winit.world()).length(), content="1")
}

///|
test "winit: plugin owns accessibility action propagation" {
  @windowing.set_accessibility_requested(false)
  ignore(@windowing.take_accessibility_actions())

  let target = @moon_accesskit.NodeId::from_u64(42UL)
  let request = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    target,
  )

  let mut app = winit_plugin(
    @a11y.accessibility_plugin(
      @window.window_plugin(@app.App::new(@ecs.World::new())),
    ),
  )
  app = app.run_once()

  @windowing.enqueue_accessibility_action(request)
  app = app.run_once()

  let world = app.world()
  let actions = read_action_requests(world)
  let state = Ref::new(@a11y.get_a11y_state_resource(world).get().unwrap())
  let drained = @a11y.A11yState::drain_actions(state)

  assert_true(world.contains_message(@a11y.ecs_msg_key_action_request))
  assert_eq(actions.length(), 1)
  assert_eq(actions[0].action(), @moon_accesskit.Action::Focus)
  assert_eq(actions[0].target_node(), target)
  assert_eq(state.val.focused_node(), target)
  assert_eq(drained.length(), 1)
  assert_eq(drained[0].target_node(), target)
  assert_true(
    @a11y.get_accessibility_requested_resource(world).get().unwrap().get(),
  )
}

///|
test "winit: plugin owns accessibility update commit" {
  @windowing.set_accessibility_requested(true)
  ignore(@windowing.take_accessibility_actions())

  let mut app = winit_plugin(
    @a11y.accessibility_plugin(
      @window.window_plugin(@app.App::new(@ecs.World::new())),
    ),
  )
  app = app.run_once()

  let payload = "winit-a11y-commit"
  @a11y.a11y_host_apply_update_payload(payload)
  app = app.run_once()

  inspect(@windowing.last_accessibility_update_payload(), content=payload)
}
