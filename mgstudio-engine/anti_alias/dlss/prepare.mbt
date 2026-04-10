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
// Bevy source: `bevy/crates/bevy_anti_alias/src/dlss/prepare.rs`.
// Bridge preparation gate for optional DLSS runtime path.

///|
pub const DLSS_PREPARE_MODULE_TAG : String = "bevy_anti_alias::dlss::prepare"

///|
pub struct DlssPrepareBridge {
  prepare_label : String
}

///|
pub fn DlssPrepareBridge::default() -> DlssPrepareBridge {
  DlssPrepareBridge::{ prepare_label: DLSS_PREPARE_MODULE_TAG }
}

///|
pub fn dlss_prepare_enabled() -> Bool {
  DLSS_RUNTIME_SUPPORTED
}

///|
pub fn dlss_prepare_bridge_enabled(bridge : DlssPrepareBridge) -> Bool {
  bridge.prepare_label == DLSS_PREPARE_MODULE_TAG && dlss_prepare_enabled()
}

///|
pub fn dlss_prepare_bridge_label(bridge : DlssPrepareBridge) -> String {
  bridge.prepare_label
}
