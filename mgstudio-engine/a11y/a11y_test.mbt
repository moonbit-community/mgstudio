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
test "a11y: accessibility plugin initializes bevy-aligned resources" {
  let app = accessibility_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()

  let requested = get_accessibility_requested_resource(world).get().unwrap()
  let manage_updates = get_manage_accessibility_updates_resource(world)
    .get()
    .unwrap()
  let state = get_a11y_state_resource(world).get().unwrap()

  assert_true(!requested.get())
  assert_true(manage_updates.get())
  assert_eq(state.focused_node(), @moon_accesskit.NodeId::root())
  assert_true(world.contains_message(ecs_msg_key_action_request))
}

///|
test "a11y: plugin forwards backend actions to world messages and compatibility state" {
  @windowing.set_accessibility_requested(false)
  ignore(@windowing.take_accessibility_actions())

  let target = @moon_accesskit.NodeId::from_u64(42UL)
  let request = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    target,
  )

  let mut app = accessibility_plugin(@app.App::new(@ecs.World::new()))
  app = app.run_once()

  @windowing.enqueue_accessibility_action(request)
  app = app.run_once()

  let world = app.world()
  let cursor = Ref::new(0)
  let reader = world.message_reader(ecs_msg_key_action_request, cursor)
  let messages = try! reader.read()
  let state = Ref::new(get_a11y_state_resource(world).get().unwrap())
  let drained = A11yState::drain_actions(state)

  assert_eq(messages.length(), 1)
  assert_eq(messages[0].action(), @moon_accesskit.Action::Focus)
  assert_eq(messages[0].target_node(), target)
  assert_eq(state.val.focused_node(), target)
  assert_eq(drained.length(), 1)
  assert_eq(drained[0].target_node(), target)
  assert_true(get_accessibility_requested_resource(world).get().unwrap().get())
}
