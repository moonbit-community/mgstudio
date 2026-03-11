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
/// Wrapper used to expose `moon_accesskit.ActionRequest` as an ECS message.
pub(all) struct ActionRequest {
  request : @moon_accesskit.ActionRequest
}

///|
pub fn ActionRequest::new(
  request : @moon_accesskit.ActionRequest,
) -> ActionRequest {
  { request, }
}

///|
pub fn ActionRequest::accesskit_request(
  self : ActionRequest,
) -> @moon_accesskit.ActionRequest {
  self.request
}

///|
pub fn ActionRequest::action(self : ActionRequest) -> @moon_accesskit.Action {
  self.request.action()
}

///|
pub fn ActionRequest::target_tree(
  self : ActionRequest,
) -> @moon_accesskit.TreeId {
  self.request.target_tree()
}

///|
pub fn ActionRequest::target_node(
  self : ActionRequest,
) -> @moon_accesskit.NodeId {
  self.request.target_node()
}

///|
pub fn ActionRequest::data(self : ActionRequest) -> @moon_accesskit.ActionData? {
  self.request.data()
}

///|
pub struct AccessibilityRequested {
  requested : Ref[Bool]
}

///|
pub fn AccessibilityRequested::default() -> AccessibilityRequested {
  { requested: Ref::new(false) }
}

///|
pub fn AccessibilityRequested::get(self : AccessibilityRequested) -> Bool {
  self.requested.val
}

///|
pub fn AccessibilityRequested::set(
  self : AccessibilityRequested,
  value : Bool,
) -> Unit {
  self.requested.val = value
}

///|
pub fn AccessibilityRequested::handle(
  self : AccessibilityRequested,
) -> Ref[Bool] {
  self.requested
}

///|
pub struct ManageAccessibilityUpdates {
  mut value : Bool
}

///|
pub fn ManageAccessibilityUpdates::default() -> ManageAccessibilityUpdates {
  { value: true }
}

///|
pub fn ManageAccessibilityUpdates::get(
  self : ManageAccessibilityUpdates,
) -> Bool {
  self.value
}

///|
pub fn ManageAccessibilityUpdates::set(
  self : ManageAccessibilityUpdates,
  value : Bool,
) -> Unit {
  self.value = value
}

///|
/// Represents an entity in the AccessKit tree.
pub(all) struct AccessibilityNode {
  mut node : @moon_accesskit.Node
}

///|
pub fn AccessibilityNode::new(node : @moon_accesskit.Node) -> AccessibilityNode {
  { node, }
}

///|
pub fn AccessibilityNode::node(
  self : AccessibilityNode,
) -> @moon_accesskit.Node {
  self.node
}

///|
pub fn AccessibilityNode::set_node(
  self : AccessibilityNode,
  node : @moon_accesskit.Node,
) -> Unit {
  self.node = node
}

///|
pub fn AccessibilityNode::role(
  self : AccessibilityNode,
) -> @moon_accesskit.Role {
  self.node.role()
}

///|
pub fn AccessibilityNode::set_role(
  self : AccessibilityNode,
  role : @moon_accesskit.Role,
) -> Unit {
  self.node.set_role(role)
}

///|
pub fn AccessibilityNode::bounds(
  self : AccessibilityNode,
) -> @moon_accesskit.Rect? {
  self.node.bounds()
}

///|
pub fn AccessibilityNode::set_bounds(
  self : AccessibilityNode,
  bounds : @moon_accesskit.Rect,
) -> Unit {
  self.node.set_bounds(bounds)
}

///|
pub fn AccessibilityNode::children(
  self : AccessibilityNode,
) -> Array[@moon_accesskit.NodeId] {
  self.node.children()
}

///|
pub fn AccessibilityNode::set_children(
  self : AccessibilityNode,
  children : Array[@moon_accesskit.NodeId],
) -> Unit {
  self.node.set_children(children)
}

///|
pub fn AccessibilityNode::push_child(
  self : AccessibilityNode,
  child : @moon_accesskit.NodeId,
) -> Unit {
  self.node.push_child(child)
}

///|
pub fn AccessibilityNode::supports_action(
  self : AccessibilityNode,
  action : @moon_accesskit.Action,
) -> Bool {
  self.node.supports_action(action)
}

///|
pub fn AccessibilityNode::add_action(
  self : AccessibilityNode,
  action : @moon_accesskit.Action,
) -> Unit {
  self.node.add_action(action)
}

///|
pub fn AccessibilityNode::clear_actions(self : AccessibilityNode) -> Unit {
  self.node.clear_actions()
}

///|
pub fn AccessibilityNode::label(self : AccessibilityNode) -> String? {
  self.node.label()
}

///|
pub fn AccessibilityNode::set_label(
  self : AccessibilityNode,
  label : String,
) -> Unit {
  self.node.set_label(label)
}

///|
pub fn AccessibilityNode::clear_label(self : AccessibilityNode) -> Unit {
  self.node.clear_label()
}

///|
pub fn AccessibilityNode::value(self : AccessibilityNode) -> String? {
  self.node.value()
}

///|
pub fn AccessibilityNode::set_value(
  self : AccessibilityNode,
  value : String,
) -> Unit {
  self.node.set_value(value)
}

///|
pub fn AccessibilityNode::clear_value(self : AccessibilityNode) -> Unit {
  self.node.clear_value()
}

///|
pub fn AccessibilityNode::is_hidden(self : AccessibilityNode) -> Bool {
  self.node.is_hidden()
}

///|
pub fn AccessibilityNode::set_hidden(self : AccessibilityNode) -> Unit {
  self.node.set_hidden()
}

///|
pub fn AccessibilityNode::clear_hidden(self : AccessibilityNode) -> Unit {
  self.node.clear_hidden()
}

///|
/// Compatibility resource used by existing engine integrations while the rest of
/// the engine migrates to message-driven `ActionRequest` consumption.
pub struct A11yState {
  mut pending_actions : Array[@moon_accesskit.ActionRequest]
  mut focused_node : @moon_accesskit.NodeId
}

///|
pub fn A11yState::default() -> A11yState {
  { pending_actions: [], focused_node: @moon_accesskit.NodeId::root() }
}

///|
pub fn A11yState::push_action(
  self : Ref[A11yState],
  action : @moon_accesskit.ActionRequest,
) -> Unit {
  self.val.pending_actions.push(action)
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

///|
/// Convert an entity into a stable `NodeId`.
pub fn node_id_for_entity(entity : @core.Entity) -> @moon_accesskit.NodeId {
  let packed = entity.id * 65536 + entity.generation + 1
  @moon_accesskit.NodeId::from_u64(packed.to_uint64())
}

///|
/// Queue a host update payload for the native accessibility backend.
pub fn a11y_host_apply_update_payload(payload : String) -> Unit {
  @windowing.queue_accessibility_update_payload(payload~)
}

///|
/// Queue an AccessKit `TreeUpdate` for the native accessibility backend.
pub fn a11y_host_apply_update(update : @moon_accesskit.TreeUpdate) -> Unit {
  @windowing.queue_accessibility_update(update)
}

///|
pub(all) enum AccessibilitySystems {
  Update
} derive(Eq, Show)

///|
pub fn accessibility_system_set_name(
  stage_set : AccessibilitySystems,
) -> @app.SystemSet {
  match stage_set {
    Update => @app.system_set("bevy_a11y::AccessibilitySystems::Update")
  }
}

///|
pub let a11y_set : @app.SystemSet = accessibility_system_set_name(
  AccessibilitySystems::Update,
)
