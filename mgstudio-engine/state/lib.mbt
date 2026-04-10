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
// Bevy source: `bevy/crates/bevy_state/src/lib.rs`.
// Root `Milky2018/mgstudio/state` is the runtime owner.

///|
pub const STATE_RUNTIME_OWNER : String = "Milky2018/mgstudio/state"

///|
pub const STATE_MODULE_TAG : String = "bevy_state::lib"

///|
pub fn state_runtime_owner() -> String {
  STATE_RUNTIME_OWNER
}

///|
pub fn state_runtime_available() -> Bool {
  true
}

///|
pub fn state_module_tag() -> String {
  STATE_MODULE_TAG
}
