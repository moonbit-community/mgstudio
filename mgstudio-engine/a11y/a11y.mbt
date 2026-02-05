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
#ecs.resource
pub struct A11yState {
  mut last_update : @accesskit.TreeUpdate?
  mut pending_actions : Array[@accesskit.ActionRequest]
}

///|
pub fn A11yState::default() -> A11yState {
  A11yState::{ last_update: None, pending_actions: [] }
}

///|
pub fn A11yState::push_action(
  self : Ref[A11yState],
  action : @accesskit.ActionRequest,
) -> Unit {
  self.val.pending_actions = self.val.pending_actions + [action]
}

///|
pub fn A11yState::drain_actions(
  self : Ref[A11yState],
) -> Array[@accesskit.ActionRequest] {
  let out = self.val.pending_actions
  self.val.pending_actions = []
  out
}

///|
pub fn A11yState::set_update(
  self : Ref[A11yState],
  update : @accesskit.TreeUpdate,
) -> Unit {
  self.val.last_update = Some(update)
}

// -----------------------------------------------------------------------------
// Host bridge (guest -> host)
// -----------------------------------------------------------------------------

///|
fn host_a11y_begin_update(root_id : Int) -> Unit = "mgstudio_host" "a11y_begin_update"

///|
fn host_a11y_push_node(
  node_id : Int,
  parent_id : Int,
  role_id : Int,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
  name_id : Int,
  actions_mask : Int,
) -> Unit = "mgstudio_host" "a11y_push_node"

///|
fn host_a11y_end_update() -> Unit = "mgstudio_host" "a11y_end_update"

///|
fn host_a11y_actions_len() -> Int = "mgstudio_host" "a11y_actions_len"

///|
fn host_a11y_action_target(index : Int) -> Int = "mgstudio_host" "a11y_action_target"

///|
fn host_a11y_action_kind(index : Int) -> Int = "mgstudio_host" "a11y_action_kind"

///|
fn host_a11y_actions_clear() -> Unit = "mgstudio_host" "a11y_actions_clear"

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
/// Action mask bits shared with runtimes.
pub let host_action_focus_bit : Int = 1

///|
pub let host_action_default_bit : Int = 2

///|
/// Convert an entity into a stable `NodeId` for the host bridge.
pub fn node_id_for_entity(entity : @core.Entity) -> Int {
  // Pack (id, generation) into a 32-bit-ish integer. This is stable for a
  // single session and good enough for the initial bridge.
  entity.id * 65536 + entity.generation
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
  host_a11y_push_node(
    node_id, parent_id, role_id, x, y, width, height, name_id, actions_mask,
  )
}

///|
/// End a full-tree update on the host.
pub fn a11y_host_end_update() -> Unit {
  host_a11y_end_update()
}

///|
pub let a11y_set : @app.SystemSet = @app.system_set("mgstudio.a11y")

///|
pub fn[W : HasRes_A11yState + @core.ChangeTickWorld] ensure_a11y_state(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_A11yState::get_a11y_state_resource(world)
  if res.get() is None {
    res.insert(A11yState::default(), tick)
  }
}

///|
/// Poll host-side accessibility actions into `A11yState.pending_actions`.
pub fn[W : HasRes_A11yState + @core.ChangeTickWorld] a11y_poll_actions_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  guard HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(tick)
    is Some(state) else {
    return
  }
  let n = host_a11y_actions_len()
  if n <= 0 {
    return
  }
  for i in 0..<n {
    let target = host_a11y_action_target(i)
    let kind = host_a11y_action_kind(i)
    let action = match kind {
      1 => @accesskit.Action::Focus
      _ => @accesskit.Action::Default
    }
    A11yState::push_action(state, @accesskit.ActionRequest::new(target, action))
  }
  host_a11y_actions_clear()
}

///|
pub fn[W : HasRes_A11yState + @core.ChangeTickWorld] a11y_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_pre_update_system_config(@app.system(ensure_a11y_state).in_set(a11y_set))
  .add_pre_update_system_config(
    @app.system(a11y_poll_actions_system).in_set(a11y_set),
  )
}
