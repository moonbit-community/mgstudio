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
// Bevy source: `bevy/crates/bevy_gltf/src/vertex_attributes.rs`.
pub fn gltf_add_custom_vertex_attribute(
  gltf_name : String,
  mapped_name : String,
) -> Unit {
  @gltf_loader.gltf_add_custom_vertex_attribute(gltf_name, mapped_name)
}

///|
pub fn gltf_custom_vertex_attributes() -> Array[GltfCustomVertexAttribute] {
  @gltf_loader.gltf_custom_vertex_attributes()
}

///|
pub fn gltf_clear_custom_vertex_attributes() -> Unit {
  @gltf_loader.gltf_clear_custom_vertex_attributes()
}

///|
pub fn gltf_resolve_custom_vertex_attribute_name(
  attribute_name : String,
) -> String? {
  @gltf_loader.gltf_resolve_custom_vertex_attribute_name(attribute_name)
}
