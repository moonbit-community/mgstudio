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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/deferred/node.rs`.
// Deferred prepass node descriptors.

///|
pub struct DeferredPrepassNode {
  label : String
}

///|
pub(all) enum DeferredPrepassRunKind {
  Early
  Late
}

///|
pub struct DeferredPrepassColorAttachmentPlan {
  normal : Bool
  motion_vectors : Bool
  deferred : Bool
  deferred_lighting_pass_id : Bool
  slot_count : Int
  deferred_attachment_loads_existing : Bool
  webgl_manual_deferred_clear : Bool
}

///|
pub struct DeferredPrepassRunPlan {
  label : String
  should_run : Bool
  is_late : Bool
  color_attachments : DeferredPrepassColorAttachmentPlan
  has_depth_stencil_attachment : Bool
  draw_opaque_phase : Bool
  draw_alpha_mask_phase : Bool
  copy_depth_to_prepass_depth : Bool
}

///|
pub fn DeferredPrepassNode::early() -> DeferredPrepassNode {
  DeferredPrepassNode::{ label: DEFERRED_PREPASS_EARLY_LABEL }
}

///|
pub fn DeferredPrepassNode::late() -> DeferredPrepassNode {
  DeferredPrepassNode::{ label: DEFERRED_PREPASS_LATE_LABEL }
}

///|
pub fn DeferredPrepassNode::label(self : DeferredPrepassNode) -> String {
  self.label
}

///|
pub fn deferred_prepass_any_phase_non_empty(
  has_opaque_phase~ : Bool,
  has_alpha_mask_phase~ : Bool,
) -> Bool {
  has_opaque_phase || has_alpha_mask_phase
}

///|
pub struct DeferredPrepassViewState {
  has_opaque_deferred_phase : Bool
  has_alpha_mask_deferred_phase : Bool
  has_normal_attachment : Bool
  has_motion_vectors_attachment : Bool
  has_deferred_attachment : Bool
  has_deferred_lighting_pass_id_attachment : Bool
  has_prepass_depth_attachment : Bool
  occlusion_culling_enabled : Bool
  no_indirect_drawing : Bool
}

///|
pub fn DeferredPrepassViewState::new(
  has_opaque_deferred_phase? : Bool = false,
  has_alpha_mask_deferred_phase? : Bool = false,
  has_normal_attachment? : Bool = false,
  has_motion_vectors_attachment? : Bool = false,
  has_deferred_attachment? : Bool = false,
  has_deferred_lighting_pass_id_attachment? : Bool = false,
  has_prepass_depth_attachment? : Bool = false,
  occlusion_culling_enabled? : Bool = false,
  no_indirect_drawing? : Bool = false,
) -> DeferredPrepassViewState {
  DeferredPrepassViewState::{
    has_opaque_deferred_phase,
    has_alpha_mask_deferred_phase,
    has_normal_attachment,
    has_motion_vectors_attachment,
    has_deferred_attachment,
    has_deferred_lighting_pass_id_attachment,
    has_prepass_depth_attachment,
    occlusion_culling_enabled,
    no_indirect_drawing,
  }
}

///|
pub fn deferred_prepass_has_any_phase(state : DeferredPrepassViewState) -> Bool {
  deferred_prepass_any_phase_non_empty(
    has_opaque_phase=state.has_opaque_deferred_phase,
    has_alpha_mask_phase=state.has_alpha_mask_deferred_phase,
  )
}

///|
pub fn early_deferred_prepass_should_run(
  state : DeferredPrepassViewState,
) -> Bool {
  deferred_prepass_has_any_phase(state)
}

///|
pub fn late_deferred_prepass_should_run(
  state : DeferredPrepassViewState,
) -> Bool {
  state.occlusion_culling_enabled &&
  !state.no_indirect_drawing &&
  deferred_prepass_has_any_phase(state)
}

///|
pub fn deferred_prepass_run_kind_label(kind : DeferredPrepassRunKind) -> String {
  match kind {
    Early => DEFERRED_PREPASS_EARLY_LABEL
    Late => DEFERRED_PREPASS_LATE_LABEL
  }
}

///|
pub fn deferred_prepass_run_kind_is_late(kind : DeferredPrepassRunKind) -> Bool {
  kind is Late
}

///|
pub fn deferred_prepass_run_kind_should_run(
  kind : DeferredPrepassRunKind,
  state : DeferredPrepassViewState,
) -> Bool {
  match kind {
    Early => early_deferred_prepass_should_run(state)
    Late => late_deferred_prepass_should_run(state)
  }
}

///|
pub fn deferred_prepass_color_attachment_plan(
  kind : DeferredPrepassRunKind,
  state : DeferredPrepassViewState,
  webgl_manual_clear_supported? : Bool = false,
) -> DeferredPrepassColorAttachmentPlan {
  let any = state.has_normal_attachment ||
    state.has_motion_vectors_attachment ||
    state.has_deferred_attachment ||
    state.has_deferred_lighting_pass_id_attachment
  let is_late = deferred_prepass_run_kind_is_late(kind)
  DeferredPrepassColorAttachmentPlan::{
    normal: state.has_normal_attachment,
    motion_vectors: state.has_motion_vectors_attachment,
    deferred: state.has_deferred_attachment,
    deferred_lighting_pass_id: state.has_deferred_lighting_pass_id_attachment,
    slot_count: if any {
      4
    } else {
      0
    },
    deferred_attachment_loads_existing: state.has_deferred_attachment && is_late,
    webgl_manual_deferred_clear: state.has_deferred_attachment &&
    !is_late &&
    webgl_manual_clear_supported,
  }
}

///|
pub fn deferred_prepass_run_plan(
  kind : DeferredPrepassRunKind,
  state : DeferredPrepassViewState,
  webgl_manual_clear_supported? : Bool = false,
) -> DeferredPrepassRunPlan {
  let should_run = deferred_prepass_run_kind_should_run(kind, state)
  let is_late = deferred_prepass_run_kind_is_late(kind)
  DeferredPrepassRunPlan::{
    label: deferred_prepass_run_kind_label(kind),
    should_run,
    is_late,
    color_attachments: deferred_prepass_color_attachment_plan(
      kind,
      state,
      webgl_manual_clear_supported~,
    ),
    has_depth_stencil_attachment: should_run,
    draw_opaque_phase: should_run && state.has_opaque_deferred_phase,
    draw_alpha_mask_phase: should_run && state.has_alpha_mask_deferred_phase,
    copy_depth_to_prepass_depth: should_run &&
    state.has_prepass_depth_attachment,
  }
}
