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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/main_opaque_pass_3d_node.rs`.
// 3D opaque pass node descriptor.

///|
pub const MAIN_OPAQUE_PASS_3D_LABEL : String = "main_opaque_pass_3d"

///|
pub struct MainOpaquePass3dNode {
  label : String
}

///|
pub fn MainOpaquePass3dNode::default() -> MainOpaquePass3dNode {
  MainOpaquePass3dNode::{ label: MAIN_OPAQUE_PASS_3D_LABEL }
}

///|
pub fn MainOpaquePass3dNode::label(self : MainOpaquePass3dNode) -> String {
  self.label
}

///|
pub struct MainOpaquePass3dState {
  has_opaque_phase : Bool
  has_alpha_mask_phase : Bool
  has_skybox_pipeline : Bool
  has_skybox_bind_group : Bool
}

///|
pub fn MainOpaquePass3dState::new(
  has_opaque_phase? : Bool = false,
  has_alpha_mask_phase? : Bool = false,
  has_skybox_pipeline? : Bool = false,
  has_skybox_bind_group? : Bool = false,
) -> MainOpaquePass3dState {
  MainOpaquePass3dState::{
    has_opaque_phase,
    has_alpha_mask_phase,
    has_skybox_pipeline,
    has_skybox_bind_group,
  }
}

///|
pub fn main_opaque_pass_3d_should_run(state : MainOpaquePass3dState) -> Bool {
  state.has_opaque_phase ||
  state.has_alpha_mask_phase ||
  main_opaque_pass_3d_should_draw_skybox(state)
}

///|
pub fn main_opaque_pass_3d_should_draw_opaque(
  state : MainOpaquePass3dState,
) -> Bool {
  state.has_opaque_phase
}

///|
pub fn main_opaque_pass_3d_should_draw_alpha_mask(
  state : MainOpaquePass3dState,
) -> Bool {
  state.has_alpha_mask_phase
}

///|
pub fn main_opaque_pass_3d_should_draw_skybox(
  state : MainOpaquePass3dState,
) -> Bool {
  state.has_skybox_pipeline && state.has_skybox_bind_group
}
