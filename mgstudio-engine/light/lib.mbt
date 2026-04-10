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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs`.
//
// File-level bridge capability marker aligned to current mgstudio runtime ownership.

///|
///|
pub struct LightRuntimeBridge {
}

///|
pub fn LightRuntimeBridge::default() -> LightRuntimeBridge {
  LightRuntimeBridge::{  }
}

///|
pub fn light_module_anchor_enabled() -> Bool {
  true
}

///|
pub fn light_runtime_bridge_enabled(_ : LightRuntimeBridge) -> Bool {
  light_module_anchor_enabled()
}

