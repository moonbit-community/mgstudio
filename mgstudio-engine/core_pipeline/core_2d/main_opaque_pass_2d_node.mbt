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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_2d/main_opaque_pass_2d_node.rs`.
// 2D opaque pass node descriptor.

///|
pub const MAIN_OPAQUE_PASS_2D_LABEL : String = "main_opaque_pass_2d"

///|
pub struct MainOpaquePass2dNode {
  label : String
}

///|
pub fn MainOpaquePass2dNode::default() -> MainOpaquePass2dNode {
  MainOpaquePass2dNode::{ label: MAIN_OPAQUE_PASS_2D_LABEL }
}

///|
pub fn MainOpaquePass2dNode::label(self : MainOpaquePass2dNode) -> String {
  self.label
}

///|
pub struct MainOpaquePass2dState {
  has_opaque_phase : Bool
  has_alpha_mask_phase : Bool
}

///|
pub fn MainOpaquePass2dState::new(
  has_opaque_phase? : Bool = false,
  has_alpha_mask_phase? : Bool = false,
) -> MainOpaquePass2dState {
  MainOpaquePass2dState::{ has_opaque_phase, has_alpha_mask_phase }
}

///|
pub fn main_opaque_pass_2d_should_run(state : MainOpaquePass2dState) -> Bool {
  state.has_opaque_phase || state.has_alpha_mask_phase
}

///|
pub fn main_opaque_pass_2d_should_draw_opaque(
  state : MainOpaquePass2dState,
) -> Bool {
  state.has_opaque_phase
}

///|
pub fn main_opaque_pass_2d_should_draw_alpha_mask(
  state : MainOpaquePass2dState,
) -> Bool {
  state.has_alpha_mask_phase
}
