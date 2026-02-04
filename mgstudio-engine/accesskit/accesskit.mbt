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
/// A minimal AccessKit v0.17-aligned data model used by mgstudio A11y.
///
/// This package is internal; the engine owns extraction and action dispatch.
///
/// TODO: Extend roles/properties to match AccessKit v0.17.

///|
pub type NodeId = Int

///|
pub(all) enum Role {
  Button
  Label
  Image
  Window
  GenericContainer
} derive(Eq, Show)

///|
pub(all) enum Action {
  Focus
  Default
  Click
  ScrollUp
  ScrollDown
  ScrollLeft
  ScrollRight
} derive(Eq, Show)

///|
pub struct Node {
  id : NodeId
  role : Role
  bounds : @math.Rect
  name : String?
  value : String?
  actions : Array[Action]
}

///|
pub fn Node::new(
  id : NodeId,
  role : Role,
  bounds : @math.Rect,
  actions? : Array[Action] = [],
  name? : String? = None,
  value? : String? = None,
) -> Node {
  Node::{ id, role, bounds, name, value, actions }
}

///|
pub struct TreeUpdate {
  root : NodeId
  nodes : Array[Node]
}

///|
pub fn TreeUpdate::new(root : NodeId, nodes : Array[Node]) -> TreeUpdate {
  TreeUpdate::{ root, nodes }
}

///|
pub struct ActionRequest {
  target : NodeId
  action : Action
}

///|
pub fn ActionRequest::new(target : NodeId, action : Action) -> ActionRequest {
  ActionRequest::{ target, action }
}
