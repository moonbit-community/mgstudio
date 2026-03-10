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
fn reset_accessibility_backend_state() -> Unit {
  detached_accessibility_requested_ref.val = false
  bound_accessibility_requested_ref.val = None
  pending_update_payload_ref.val = None
  last_update_payload_ref.val = ""
  pending_actions_ref.val.clear()
}

///|
test "windowing accessibility: queued tree updates commit only when accessibility is requested" {
  reset_accessibility_backend_state()

  let node_id = @moon_accesskit.NodeId::from_u64(7UL)
  let update = @moon_accesskit.TreeUpdate::new(
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  let node = @moon_accesskit.Node::new(@moon_accesskit.Role::Button)
  update.push_node(node_id, node)
  update.set_tree(@moon_accesskit.Tree::new(node_id))

  queue_accessibility_update(update)
  assert_true(!commit_pending_accessibility_update())
  assert_eq(last_accessibility_update_payload(), "")

  set_accessibility_requested(true)
  assert_true(commit_pending_accessibility_update())
  assert_eq(last_accessibility_update_payload(), update.to_json().stringify())
}

///|
test "windowing accessibility: binding requested state shares host activation and action queue" {
  reset_accessibility_backend_state()

  let requested = Ref::new(false)
  bind_accessibility_requested(requested)
  assert_true(!requested.val)

  set_accessibility_requested(true)
  assert_true(requested.val)

  let node_id = @moon_accesskit.NodeId::from_u64(13UL)
  let request = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::SetValue,
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  request.set_data(@moon_accesskit.ActionData::Value("hello"))
  enqueue_accessibility_action(request)
  let actions = take_accessibility_actions()

  assert_eq(actions.length(), 1)
  assert_eq(actions[0].target_node(), node_id)
  assert_eq(actions[0].data(), Some(@moon_accesskit.ActionData::Value("hello")))
  assert_true(requested.val)
}
