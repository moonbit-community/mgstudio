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
test "a11y: accessibility plugin initializes resources and ambiguous allowance" {
  let app = accessibility_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()

  let requested = get_accessibility_requested_resource(world).get().unwrap()
  let manage_updates = get_manage_accessibility_updates_resource(world)
    .get()
    .unwrap()

  assert_true(!requested.get())
  assert_true(manage_updates.get())
  assert_true(!world.contains_message(ecs_msg_key_action_request))
  assert_true(
    app.is_ambiguous_component_allowed(key=ecs_key_accessibility_node),
  )
}

///|
test "a11y: AccessibilityRequested clone shares underlying request flag" {
  let requested = AccessibilityRequested::default()
  let cloned = requested.clone()
  assert_true(!requested.get())
  assert_true(!cloned.get())
  cloned.set(true)
  assert_true(requested.get())
  assert_true(cloned.get())
  let handle = requested.handle()
  handle.val = false
  assert_true(!requested.get())
  assert_true(!cloned.get())
}

///|
test "a11y: ManageAccessibilityUpdates defaults true and supports mutation" {
  let updates = ManageAccessibilityUpdates::default()
  assert_true(updates.get())
  updates.set(false)
  assert_true(!updates.get())
  updates.set(true)
  assert_true(updates.get())
}

///|
test "a11y: plugin init_resource keeps existing resource values" {
  let requested = AccessibilityRequested::default()
  requested.set(true)
  let updates = ManageAccessibilityUpdates::default()
  updates.set(false)
  let app = @app.App::new(@ecs.World::new())
    .insert_world_resource(ecs_res_key_accessibility_requested, requested)
    .insert_world_resource(ecs_res_key_manage_accessibility_updates, updates)
  let app = accessibility_plugin(app)
  let world = app.world()
  let requested_after = get_accessibility_requested_resource(world).get().unwrap()
  let updates_after = get_manage_accessibility_updates_resource(world).get().unwrap()
  assert_true(requested_after.get())
  assert_true(!updates_after.get())
}

///|
test "a11y: ActionRequest wrapper forwards accesskit payload" {
  let target = @moon_accesskit.NodeId::from_u64(42UL)
  let request = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    target,
  )
  let wrapped = ActionRequest::new(request)
  assert_eq(wrapped.action(), @moon_accesskit.Action::Focus)
  assert_eq(wrapped.target_tree(), @moon_accesskit.TreeId::root())
  assert_eq(wrapped.target_node(), target)
  assert_true(wrapped.data() is None)
  assert_eq(wrapped.accesskit_request().target_node(), target)
}
