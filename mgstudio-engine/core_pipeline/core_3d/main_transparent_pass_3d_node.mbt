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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/core_3d/main_transparent_pass_3d_node.rs`.
// 3D transparent pass node descriptor.

///|
pub const MAIN_TRANSPARENT_PASS_3D_LABEL : String = "main_transparent_pass_3d"

///|
pub struct MainTransparentPass3dNode {
  label : String
}

///|
pub fn MainTransparentPass3dNode::default() -> MainTransparentPass3dNode {
  MainTransparentPass3dNode::{ label: MAIN_TRANSPARENT_PASS_3D_LABEL }
}

///|
pub fn MainTransparentPass3dNode::label(
  self : MainTransparentPass3dNode,
) -> String {
  self.label
}

///|
pub const RESET_VIEWPORT_PASS_3D_LABEL : String = "reset_viewport_pass_3d"

///|
pub struct MainTransparentPass3dState {
  has_transparent_phase : Bool
  has_oit : Bool
  has_oit_resolve_pipeline : Bool
  has_custom_viewport : Bool
  webgl_requires_viewport_reset : Bool
}

///|
pub fn MainTransparentPass3dState::new(
  has_transparent_phase? : Bool = false,
  has_oit? : Bool = false,
  has_oit_resolve_pipeline? : Bool = false,
  has_custom_viewport? : Bool = false,
  webgl_requires_viewport_reset? : Bool = false,
) -> MainTransparentPass3dState {
  MainTransparentPass3dState::{
    has_transparent_phase,
    has_oit,
    has_oit_resolve_pipeline,
    has_custom_viewport,
    webgl_requires_viewport_reset,
  }
}

///|
pub fn main_transparent_pass_3d_should_run(
  state : MainTransparentPass3dState,
) -> Bool {
  state.has_transparent_phase
}

///|
pub fn main_transparent_pass_3d_is_oit_ready(
  state : MainTransparentPass3dState,
) -> Bool {
  !state.has_oit || state.has_oit_resolve_pipeline
}

///|
pub fn main_transparent_pass_3d_should_render(
  state : MainTransparentPass3dState,
) -> Bool {
  main_transparent_pass_3d_should_run(state) &&
  main_transparent_pass_3d_is_oit_ready(state)
}

///|
pub fn main_transparent_pass_3d_requires_reset_viewport_pass(
  state : MainTransparentPass3dState,
) -> Bool {
  state.has_custom_viewport && state.webgl_requires_viewport_reset
}
