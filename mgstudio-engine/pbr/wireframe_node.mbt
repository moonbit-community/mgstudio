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
// Bevy source: `bevy/crates/bevy_pbr/src/wireframe.rs::wireframe_3d`.

///|
pub struct Wireframe3dRenderNode {}

///|
pub fn Wireframe3dRenderNode::Wireframe3dRenderNode() -> Wireframe3dRenderNode {
  Wireframe3dRenderNode::{  }
}

///|
pub fn Wireframe3dRenderNode::label(self : Wireframe3dRenderNode) -> String {
  ignore(self)
  "wireframe_3d"
}

///|
pub suberror Wireframe3dRenderNodeSkipReason {
  MissingPhase
  EmptyPhase
}

///|
pub struct Wireframe3dRenderNodePlan {
  label : String
  retained_view_entity : @core.Entity
  item_count : Int
  viewport_enabled : Bool
} derive(Eq, Debug)

///|
pub fn Wireframe3dRenderNodePlan::new(
  retained_view_entity : @core.Entity,
  item_count : Int,
  viewport_enabled : Bool,
) -> Wireframe3dRenderNodePlan {
  Wireframe3dRenderNodePlan::{
    label: "wireframe_3d",
    retained_view_entity,
    item_count,
    viewport_enabled,
  }
}

///|
pub fn Wireframe3dRenderNodePlan::label(
  self : Wireframe3dRenderNodePlan,
) -> String {
  self.label
}

///|
pub fn Wireframe3dRenderNodePlan::retained_view_entity(
  self : Wireframe3dRenderNodePlan,
) -> @core.Entity {
  self.retained_view_entity
}

///|
pub fn Wireframe3dRenderNodePlan::item_count(
  self : Wireframe3dRenderNodePlan,
) -> Int {
  self.item_count
}

///|
pub fn Wireframe3dRenderNodePlan::viewport_enabled(
  self : Wireframe3dRenderNodePlan,
) -> Bool {
  self.viewport_enabled
}

///|
pub fn wireframe_3d_render_node_plan(
  phases : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
  viewport_enabled : Bool,
) -> Wireframe3dRenderNodePlan raise Wireframe3dRenderNodeSkipReason {
  guard phases.phase(retained_view_entity) is Some(phase) else {
    raise Wireframe3dRenderNodeSkipReason::MissingPhase
  }
  if phase.is_empty() {
    raise Wireframe3dRenderNodeSkipReason::EmptyPhase
  }
  Wireframe3dRenderNodePlan::new(
    retained_view_entity,
    phase.len(),
    viewport_enabled,
  )
}
