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
/// A11y runtime bridge: engine produces AccessKit updates; runtimes send actions.
///
/// This package owns the host bridge plumbing (imports + action polling).
/// UI extraction currently lives in `@ui` (so it can access UI-specific ECS).

///|
pub struct A11yState {
  mut last_update : @moon_accesskit.TreeUpdate?
  mut pending_actions : Array[@moon_accesskit.ActionRequest]
  mut focused_node : @moon_accesskit.NodeId
} derive(ToJson, FromJson)

///|
pub fn A11yState::default() -> A11yState {
  A11yState::{
    last_update: None,
    pending_actions: [],
    focused_node: @moon_accesskit.NodeId::root(),
  }
}

///|
pub fn A11yState::push_action(
  self : Ref[A11yState],
  action : @moon_accesskit.ActionRequest,
) -> Unit {
  self.val.pending_actions = self.val.pending_actions + [action]
}

///|
pub fn A11yState::drain_actions(
  self : Ref[A11yState],
) -> Array[@moon_accesskit.ActionRequest] {
  let out = self.val.pending_actions
  self.val.pending_actions = []
  out
}

///|
pub fn A11yState::set_update(
  self : Ref[A11yState],
  update : @moon_accesskit.TreeUpdate,
) -> Unit {
  self.val.last_update = Some(update)
}

///|
pub fn A11yState::focused_node(self : A11yState) -> @moon_accesskit.NodeId {
  self.focused_node
}

///|
pub fn A11yState::set_focused_node(
  self : Ref[A11yState],
  node : @moon_accesskit.NodeId,
) -> Unit {
  self.val.focused_node = node
}

// -----------------------------------------------------------------------------
// Host bridge (guest -> host)
// -----------------------------------------------------------------------------

///|
fn host_a11y_begin_update(root_id : Int) -> Unit {
  @native_a11y.begin_update(root_id)
}

///|
fn host_a11y_push_node(
  node_id~ : Int,
  parent_id~ : Int,
  role_id~ : Int,
  x~ : Float,
  y~ : Float,
  width~ : Float,
  height~ : Float,
  name~ : String,
  actions_mask~ : Int,
) -> Unit {
  @native_a11y.push_node(
    node_id~,
    parent_id~,
    role_id~,
    x~,
    y~,
    width~,
    height~,
    name~,
    actions_mask~,
  )
}

///|
fn host_a11y_end_update() -> Unit {
  @native_a11y.end_update()
}

///|
fn host_a11y_actions_len() -> Int {
  @native_a11y.actions_len()
}

///|
fn host_a11y_action_target(index : Int) -> Int {
  @native_a11y.action_target(index)
}

///|
fn host_a11y_action_kind(index : Int) -> Int {
  @native_a11y.action_kind(index)
}

///|
fn host_a11y_action_value_len(index : Int) -> Int {
  @native_a11y.action_value_len(index)
}

///|
fn host_a11y_action_value_code_unit(index~ : Int, offset~ : Int) -> Int {
  @native_a11y.action_value_code_unit(index~, offset~)
}

///|
fn host_a11y_actions_clear() -> Unit {
  @native_a11y.actions_clear()
}

///|
/// Role ids shared with runtimes.
pub let host_role_window : Int = 1

///|
pub let host_role_container : Int = 2

///|
pub let host_role_button : Int = 3

///|
pub let host_role_label : Int = 4

///|
pub let host_role_image : Int = 5

///|
/// Action mask bits shared with runtimes.
pub let host_action_focus_bit : Int = 1

///|
pub let host_action_default_bit : Int = 2

///|
pub let host_action_scroll_bit : Int = 4

///|
pub let host_action_set_value_bit : Int = 8

///|
/// Convert an entity into a stable `NodeId` for the host bridge.
pub fn node_id_for_entity(entity : @core.Entity) -> @moon_accesskit.NodeId {
  // Pack (id, generation) into a small `u64` for JSON/JS safety, while
  // reserving 0 for AccessKit's root node.
  let packed = entity.id * 65536 + entity.generation + 1
  @moon_accesskit.NodeId::from_u64(packed.to_uint64())
}

///|
fn host_action_value(index : Int) -> String? {
  let len = host_a11y_action_value_len(index)
  if len <= 0 {
    return None
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let cu = host_a11y_action_value_code_unit(index~, offset=i)
    if cu.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
/// Begin a full-tree update on the host.
pub fn a11y_host_begin_update(root_id : Int) -> Unit {
  host_a11y_begin_update(root_id)
}

///|
/// Push one node to the host (flat list with a parent id).
pub fn a11y_host_push_node(
  node_id : Int,
  parent_id : Int,
  role_id : Int,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
  name_id : Int,
  actions_mask : Int,
) -> Unit {
  let name = if name_id == 0 { "" } else { "#" + name_id.to_string() }
  host_a11y_push_node(
    node_id~,
    parent_id~,
    role_id~,
    x~,
    y~,
    width~,
    height~,
    name~,
    actions_mask~,
  )
}

///|
/// End a full-tree update on the host.
pub fn a11y_host_end_update() -> Unit {
  host_a11y_end_update()
}

///|
fn host_a11y_apply_update(update_json : String) -> Unit {
  @native_a11y.apply_update(update_json~)
}

///|
pub fn a11y_host_apply_update_payload(payload : String) -> Unit {
  host_a11y_apply_update(payload)
}

///|
/// Apply an AccessKit `TreeUpdate` to the host runtime.
pub fn a11y_host_apply_update(update : @moon_accesskit.TreeUpdate) -> Unit {
  a11y_host_apply_update_payload(update.to_json().stringify())
}

///|
pub let a11y_set : @app.SystemSet = @app.system_set("mgstudio.a11y")

///|
pub fn ensure_a11y_state(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let res = get_a11y_state_resource(world)
  if res.get() is None {
    res.insert(A11yState::default(), tick)
  }
}

///|
/// Poll host-side accessibility actions into `A11yState.pending_actions`.
pub fn a11y_poll_actions_system(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let res = get_a11y_state_resource(world)
  guard res.get() is Some(state_value) else { return }
  let n = host_a11y_actions_len()
  if n <= 0 {
    return
  }
  let state = Ref::new(state_value)
  for i in 0..<n {
    let target = host_a11y_action_target(i)
    let kind = host_a11y_action_kind(i)
    let action = match kind {
      1 => @moon_accesskit.Action::Focus
      2 => @moon_accesskit.Action::Click
      3 => @moon_accesskit.Action::ScrollUp
      4 => @moon_accesskit.Action::ScrollDown
      5 => @moon_accesskit.Action::ScrollLeft
      6 => @moon_accesskit.Action::ScrollRight
      7 => @moon_accesskit.Action::SetValue
      _ => @moon_accesskit.Action::Click
    }
    let node_id = @moon_accesskit.NodeId::from_u64(target.to_uint64())
    let req = @moon_accesskit.ActionRequest::new(
      action,
      @moon_accesskit.TreeId::root(),
      node_id,
    )
    if action == @moon_accesskit.Action::SetValue &&
      host_action_value(i) is Some(value) {
      req.set_data(@moon_accesskit.ActionData::Value(value))
    }
    if action == @moon_accesskit.Action::Focus ||
      action == @moon_accesskit.Action::SetValue {
      A11yState::set_focused_node(state, node_id)
    }
    A11yState::push_action(state, req)
  }
  host_a11y_actions_clear()
  res.insert(state.val, tick)
}

///|
pub fn a11y_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system_config(@app.system(ensure_a11y_state).in_set(a11y_set))
  .add_pre_update_system_config(
    @app.system(a11y_poll_actions_system).in_set(a11y_set),
  )
}
