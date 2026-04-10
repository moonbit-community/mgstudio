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
// Bevy source: `bevy/crates/bevy_anti_alias/src/contrast_adaptive_sharpening/node.rs`.
// Bridge node gate for optional CAS runtime path.

///|
pub const CAS_NODE_MODULE_TAG : String = "bevy_anti_alias::contrast_adaptive_sharpening::node"

///|
pub struct CasNodeBridge {
  node_label : String
}

///|
pub fn CasNodeBridge::default() -> CasNodeBridge {
  CasNodeBridge::{ node_label: CAS_NODE_MODULE_TAG }
}

///|
pub fn cas_node_enabled() -> Bool {
  CAS_RUNTIME_SUPPORTED
}

///|
pub fn cas_node_bridge_enabled(bridge : CasNodeBridge) -> Bool {
  bridge.node_label == CAS_NODE_MODULE_TAG && cas_node_enabled()
}

///|
pub fn cas_node_bridge_label(bridge : CasNodeBridge) -> String {
  bridge.node_label
}
