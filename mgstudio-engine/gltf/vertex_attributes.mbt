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
pub struct GltfCustomVertexAttribute {
  gltf_name : String
  mapped_name : String
}

///|
pub fn GltfCustomVertexAttribute::new(
  gltf_name : String,
  mapped_name : String,
) -> GltfCustomVertexAttribute {
  { gltf_name, mapped_name }
}

///|
pub fn GltfCustomVertexAttribute::gltf_name(
  self : GltfCustomVertexAttribute,
) -> String {
  self.gltf_name
}

///|
pub fn GltfCustomVertexAttribute::mapped_name(
  self : GltfCustomVertexAttribute,
) -> String {
  self.mapped_name
}

///|
let gltf_custom_vertex_attributes_registry : Array[GltfCustomVertexAttribute] = []

///|
fn gltf_attribute_name_matches(
  registered_name : String,
  attribute_name : String,
) -> Bool {
  if registered_name == attribute_name {
    return true
  }
  if attribute_name.length() > 0 && attribute_name.code_unit_at(0) == 95 {
    return registered_name ==
      attribute_name[1:attribute_name.length()].to_string()
  }
  false
}

///|
pub fn gltf_add_custom_vertex_attribute(
  gltf_name : String,
  mapped_name : String,
) -> Unit {
  for i in 0..<gltf_custom_vertex_attributes_registry.length() {
    if gltf_custom_vertex_attributes_registry[i].gltf_name() == gltf_name {
      gltf_custom_vertex_attributes_registry[i] = GltfCustomVertexAttribute::new(
        gltf_name, mapped_name,
      )
      return
    }
  }
  gltf_custom_vertex_attributes_registry.push(
    GltfCustomVertexAttribute::new(gltf_name, mapped_name),
  )
}

///|
pub fn gltf_custom_vertex_attributes() -> Array[GltfCustomVertexAttribute] {
  gltf_custom_vertex_attributes_registry
}

///|
pub fn gltf_clear_custom_vertex_attributes() -> Unit {
  gltf_custom_vertex_attributes_registry.clear()
}

///|
pub fn gltf_resolve_custom_vertex_attribute_name(
  attribute_name : String,
) -> String? {
  for attribute in gltf_custom_vertex_attributes_registry {
    if gltf_attribute_name_matches(attribute.gltf_name(), attribute_name) {
      return Some(attribute.mapped_name())
    }
  }
  None
}
