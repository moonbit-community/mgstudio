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
pub(all) enum PrepassRunKind {
  Early
  Late
}

///|
pub struct PrepassColorAttachmentPlan {
  normal : Bool
  motion_vectors : Bool
  deferred : Bool
  deferred_lighting_pass_id : Bool
  slot_count : Int
}

///|
pub struct PrepassRunPlan {
  label : String
  should_run : Bool
  skip_due_to_deferred : Bool
  color_attachments : PrepassColorAttachmentPlan
  has_depth_stencil_attachment : Bool
  draw_opaque_phase : Bool
  draw_alpha_mask_phase : Bool
  draw_skybox : Bool
  skybox_dynamic_offset_count : Int
  copy_depth_to_prepass_depth : Bool
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
pub fn PrepassViewState::PrepassViewState() -> PrepassViewState {
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

///|
pub fn prepass_color_attachment_plan(
  state : PrepassViewState,
) -> PrepassColorAttachmentPlan {
  let any = prepass_has_any_color_attachment(state)
  PrepassColorAttachmentPlan::{
    normal: state.has_normal_attachment,
    motion_vectors: state.has_motion_vectors_attachment,
    deferred: state.has_deferred_attachment,
    deferred_lighting_pass_id: state.has_deferred_lighting_pass_id_attachment,
    slot_count: if any {
      4
    } else {
      0
    },
  }
}

///|
pub fn prepass_run_kind_label(kind : PrepassRunKind) -> String {
  match kind {
    Early => EARLY_PREPASS_LABEL
    Late => LATE_PREPASS_LABEL
  }
}

///|
pub fn prepass_run_kind_should_run(
  kind : PrepassRunKind,
  state : PrepassViewState,
) -> Bool {
  match kind {
    Early => early_prepass_should_run(state)
    Late => late_prepass_should_run(state)
  }
}

///|
pub fn prepass_run_plan(
  kind : PrepassRunKind,
  state : PrepassViewState,
  has_skybox_prepass_pipeline? : Bool = false,
  has_skybox_prepass_bind_group? : Bool = false,
  has_previous_view_uniform_offset? : Bool = false,
  skybox_pipeline_ready? : Bool = false,
) -> PrepassRunPlan {
  let should_run = prepass_run_kind_should_run(kind, state)
  let draw_skybox = should_run &&
    has_skybox_prepass_pipeline &&
    has_skybox_prepass_bind_group &&
    has_previous_view_uniform_offset &&
    skybox_pipeline_ready
  PrepassRunPlan::{
    label: prepass_run_kind_label(kind),
    should_run,
    skip_due_to_deferred: prepass_should_skip_due_to_deferred(state),
    color_attachments: prepass_color_attachment_plan(state),
    has_depth_stencil_attachment: should_run,
    draw_opaque_phase: should_run && state.has_opaque_prepass_phase,
    draw_alpha_mask_phase: should_run && state.has_alpha_mask_prepass_phase,
    draw_skybox,
    skybox_dynamic_offset_count: if draw_skybox {
      2
    } else {
      0
    },
    copy_depth_to_prepass_depth: should_run &&
    prepass_should_copy_depth_to_prepass_depth(state),
  }
}
