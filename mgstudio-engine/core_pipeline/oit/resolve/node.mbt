// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/oit/resolve/node.rs`.
// OIT resolve node descriptor.

///|
pub struct OitResolveNode {
  label : String
}

///|
pub fn OitResolveNode::default() -> OitResolveNode {
  OitResolveNode::{ label: OIT_RESOLVE_PASS_LABEL }
}

///|
pub fn OitResolveNode::label(self : OitResolveNode) -> String {
  self.label
}

///|
pub struct OitResolveNodeState {
  has_oit_resolve_pipeline_resource : Bool
  has_oit_resolve_bind_group_resource : Bool
  has_specialized_resolve_pipeline : Bool
  has_view_depth_texture : Bool
  has_depth_prepass : Bool
  has_camera_viewport_override : Bool
}

///|
pub fn OitResolveNodeState::new(
  has_oit_resolve_pipeline_resource? : Bool = false,
  has_oit_resolve_bind_group_resource? : Bool = false,
  has_specialized_resolve_pipeline? : Bool = false,
  has_view_depth_texture? : Bool = false,
  has_depth_prepass? : Bool = false,
  has_camera_viewport_override? : Bool = false,
) -> OitResolveNodeState {
  OitResolveNodeState::{
    has_oit_resolve_pipeline_resource,
    has_oit_resolve_bind_group_resource,
    has_specialized_resolve_pipeline,
    has_view_depth_texture,
    has_depth_prepass,
    has_camera_viewport_override,
  }
}

///|
pub fn oit_resolve_should_run(state : OitResolveNodeState) -> Bool {
  state.has_oit_resolve_pipeline_resource &&
  state.has_oit_resolve_bind_group_resource &&
  state.has_specialized_resolve_pipeline &&
  state.has_view_depth_texture
}

///|
pub fn oit_resolve_requires_depth_bind_group(
  state : OitResolveNodeState,
) -> Bool {
  oit_resolve_should_run(state) && !state.has_depth_prepass
}

///|
pub fn oit_resolve_should_set_camera_viewport(
  state : OitResolveNodeState,
) -> Bool {
  oit_resolve_should_run(state) && state.has_camera_viewport_override
}
