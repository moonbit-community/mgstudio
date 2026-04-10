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
// Bevy source: `bevy/crates/bevy_state/src/state/freely_mutable_state.rs`.
// Bridge aliases for freely-mutable next-state resources.

///|
pub type FreelyMutableNextState[S] = @state_root.NextState[S]

///|
pub const FREELY_MUTABLE_STATE_MODULE_TAG : String = "bevy_state::state::freely_mutable_state"

///|
pub struct FreelyMutableStateBridge {
  module_tag : String
}

///|
pub fn FreelyMutableStateBridge::default() -> FreelyMutableStateBridge {
  FreelyMutableStateBridge::{ module_tag: FREELY_MUTABLE_STATE_MODULE_TAG }
}

///|
pub fn freely_mutable_state_bridge_enabled(
  bridge : FreelyMutableStateBridge,
) -> Bool {
  bridge.module_tag == FREELY_MUTABLE_STATE_MODULE_TAG
}

///|
pub fn freely_mutable_state_bridge_module_tag(
  bridge : FreelyMutableStateBridge,
) -> String {
  bridge.module_tag
}
