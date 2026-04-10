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
// Bevy source: `bevy/crates/bevy_anti_alias/src/dlss/extract.rs`.
// Bridge extraction gate for optional DLSS runtime path.

///|
pub const DLSS_EXTRACT_MODULE_TAG : String = "bevy_anti_alias::dlss::extract"

///|
pub struct DlssExtractBridge {
  extract_label : String
}

///|
pub fn DlssExtractBridge::default() -> DlssExtractBridge {
  DlssExtractBridge::{ extract_label: DLSS_EXTRACT_MODULE_TAG }
}

///|
pub fn dlss_extract_enabled() -> Bool {
  DLSS_RUNTIME_SUPPORTED
}

///|
pub fn dlss_extract_bridge_enabled(bridge : DlssExtractBridge) -> Bool {
  bridge.extract_label == DLSS_EXTRACT_MODULE_TAG && dlss_extract_enabled()
}

///|
pub fn dlss_extract_bridge_label(bridge : DlssExtractBridge) -> String {
  bridge.extract_label
}
