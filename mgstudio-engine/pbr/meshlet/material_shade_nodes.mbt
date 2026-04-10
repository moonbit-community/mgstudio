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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/material_shade_nodes.rs`.

///|
pub const MESHLET_MAIN_OPAQUE_PASS_NODE : String = "bevy_pbr::meshlet::main_opaque_pass"

///|
pub const MESHLET_PREPASS_NODE : String = "bevy_pbr::meshlet::prepass"

///|
pub const MESHLET_DEFERRED_GBUFFER_PREPASS_NODE : String = "bevy_pbr::meshlet::deferred_gbuffer_prepass"

///|
pub fn meshlet_material_shade_nodes() -> Array[String] {
  [
    MESHLET_MAIN_OPAQUE_PASS_NODE,
    MESHLET_PREPASS_NODE,
    MESHLET_DEFERRED_GBUFFER_PREPASS_NODE,
  ]
}

///|
pub fn meshlet_material_shade_node_count() -> Int {
  meshlet_material_shade_nodes().length()
}

///|
pub fn meshlet_material_shade_nodes_runtime_available() -> Bool {
  meshlet_runtime_available()
}
