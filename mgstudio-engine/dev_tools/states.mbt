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
// Bevy source: `bevy/crates/bevy_dev_tools/src/states.rs`.
// The current runtime does not expose Bevy's state-debug helper surface.

///|
pub const STATES_DEBUG_MODULE_TAG : String = "bevy_dev_tools::states"

///|
pub struct StatesDebugConfig {
  enabled : Bool
}

///|
pub fn StatesDebugConfig::default() -> StatesDebugConfig {
  StatesDebugConfig::{ enabled: false }
}

///|
pub fn dev_tools_states_debug_available() -> Bool {
  true
}

///|
pub fn dev_tools_states_debug_enabled(config : StatesDebugConfig) -> Bool {
  config.enabled
}

///|
pub fn dev_tools_states_debug_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
}
