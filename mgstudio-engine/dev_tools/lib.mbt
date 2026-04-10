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
// Bevy source: `bevy/crates/bevy_dev_tools/src/lib.rs`.
// Runtime wrappers live in this file while the broader dev-tools implementation stays split across the package.

///|
pub const HAS_DEV_TOOLS_RUNTIME : Bool = true

///|
pub const DEV_TOOLS_PLUGIN_ID : String = "bevy_dev_tools::DevToolsPlugin"

///|
pub fn dev_tools_default_fps_overlay_config() -> FpsOverlayConfig {
  FpsOverlayConfig::default()
}

///|
pub fn dev_tools_runtime_available() -> Bool {
  HAS_DEV_TOOLS_RUNTIME
}

///|
pub fn dev_tools_plugin_id() -> String {
  DEV_TOOLS_PLUGIN_ID
}
