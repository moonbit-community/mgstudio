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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/prepass/node.rs`.
// Prepass node descriptors and attachment predicates.

///|
pub struct PrepassNode {
  label : String
}

///|
pub fn PrepassNode::early() -> PrepassNode {
  PrepassNode::{ label: EARLY_PREPASS_LABEL }
}

///|
pub fn PrepassNode::late() -> PrepassNode {
  PrepassNode::{ label: LATE_PREPASS_LABEL }
}

///|
pub fn PrepassNode::label(self : PrepassNode) -> String {
  self.label
}

///|
pub fn prepass_any_color_attachment_enabled(
  has_normal~ : Bool,
  has_motion_vectors~ : Bool,
  has_deferred~ : Bool,
  has_deferred_lighting_pass_id~ : Bool,
) -> Bool {
  has_normal ||
  has_motion_vectors ||
  has_deferred ||
  has_deferred_lighting_pass_id
}

///|
pub struct PrepassViewState {
  has_deferred_prepass_component : Bool
  has_opaque_prepass_phase : Bool
  has_alpha_mask_prepass_phase : Bool
  has_normal_attachment : Bool
  has_motion_vectors_attachment : Bool
  has_deferred_attachment : Bool
  has_deferred_lighting_pass_id_attachment : Bool
  occlusion_culling_enabled : Bool
  no_indirect_drawing : Bool
  has_prepass_depth_attachment : Bool
}

///|
pub fn PrepassViewState::default() -> PrepassViewState {
  PrepassViewState::new()
}

///|
pub fn PrepassViewState::new(
  has_deferred_prepass_component? : Bool = false,
  has_opaque_prepass_phase? : Bool = false,
  has_alpha_mask_prepass_phase? : Bool = false,
  has_normal_attachment? : Bool = false,
  has_motion_vectors_attachment? : Bool = false,
  has_deferred_attachment? : Bool = false,
  has_deferred_lighting_pass_id_attachment? : Bool = false,
  occlusion_culling_enabled? : Bool = false,
  no_indirect_drawing? : Bool = false,
  has_prepass_depth_attachment? : Bool = false,
) -> PrepassViewState {
  PrepassViewState::{
    has_deferred_prepass_component,
    has_opaque_prepass_phase,
    has_alpha_mask_prepass_phase,
    has_normal_attachment,
    has_motion_vectors_attachment,
    has_deferred_attachment,
    has_deferred_lighting_pass_id_attachment,
    occlusion_culling_enabled,
    no_indirect_drawing,
    has_prepass_depth_attachment,
  }
}

///|
pub fn prepass_has_any_phase(state : PrepassViewState) -> Bool {
  state.has_opaque_prepass_phase || state.has_alpha_mask_prepass_phase
}

///|
pub fn prepass_should_skip_due_to_deferred(state : PrepassViewState) -> Bool {
  state.has_deferred_prepass_component
}

///|
pub fn early_prepass_should_run(state : PrepassViewState) -> Bool {
  !prepass_should_skip_due_to_deferred(state) && prepass_has_any_phase(state)
}

///|
pub fn late_prepass_should_run(state : PrepassViewState) -> Bool {
  state.occlusion_culling_enabled &&
  !state.no_indirect_drawing &&
  early_prepass_should_run(state)
}

///|
pub fn prepass_should_copy_depth_to_prepass_depth(
  state : PrepassViewState,
) -> Bool {
  !state.has_deferred_prepass_component && state.has_prepass_depth_attachment
}

///|
pub fn prepass_has_any_color_attachment(state : PrepassViewState) -> Bool {
  prepass_any_color_attachment_enabled(
    has_normal=state.has_normal_attachment,
    has_motion_vectors=state.has_motion_vectors_attachment,
    has_deferred=state.has_deferred_attachment,
    has_deferred_lighting_pass_id=state.has_deferred_lighting_pass_id_attachment,
  )
}
