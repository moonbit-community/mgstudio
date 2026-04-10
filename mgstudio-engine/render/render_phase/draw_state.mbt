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
// Bevy source: `bevy/crates/bevy_render/src/render_phase/draw_state.rs`.

///|
pub type DrawState = @renderer.GpuPassState

///|
///|
pub fn draw_state_runtime_available(_state : DrawState) -> Bool {
  true
}

///|
pub fn draw_state_target_id(state : DrawState) -> Int {
  state.target_id
}

///|
pub fn draw_state_is_3d(state : DrawState) -> Bool {
  state.is_3d
}

///|
pub fn draw_state_viewport(state : DrawState) -> (UInt, UInt, UInt, UInt) {
  (state.viewport_x, state.viewport_y, state.viewport_w, state.viewport_h)
}
