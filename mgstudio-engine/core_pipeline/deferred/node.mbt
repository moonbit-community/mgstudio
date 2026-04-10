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
  occlusion_culling_enabled : Bool
  no_indirect_drawing : Bool
}

///|
pub fn DeferredPrepassViewState::new(
  has_opaque_deferred_phase? : Bool = false,
  has_alpha_mask_deferred_phase? : Bool = false,
  occlusion_culling_enabled? : Bool = false,
  no_indirect_drawing? : Bool = false,
) -> DeferredPrepassViewState {
  DeferredPrepassViewState::{
    has_opaque_deferred_phase,
    has_alpha_mask_deferred_phase,
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
