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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/extensions/khr_materials_clearcoat.rs`.
pub fn gltf_register_khr_materials_clearcoat_handler(
  handler : GltfExtensionHandler,
) -> Unit {
  gltf_register_extension_handler(handler)
}

///|
pub fn gltf_khr_materials_clearcoat_handler_enabled() -> Bool {
  gltf_pbr_material_handler_enabled()
}

///|
pub fn gltf_set_khr_materials_clearcoat_handler_enabled(enabled : Bool) -> Unit {
  gltf_set_pbr_material_handler_enabled(enabled)
}
