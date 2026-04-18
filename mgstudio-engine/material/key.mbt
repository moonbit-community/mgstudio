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
// Bevy source: `bevy/crates/bevy_material/src/key.rs`.

///|
pub struct ErasedMeshPipelineKey {
  bits : UInt64
  type_tag : String
}

///|
pub fn ErasedMeshPipelineKey::new(
  bits : UInt64,
  type_tag : String,
) -> ErasedMeshPipelineKey {
  ErasedMeshPipelineKey::{ bits, type_tag }
}

///|
pub fn ErasedMeshPipelineKey::new_untyped(
  bits : UInt64,
) -> ErasedMeshPipelineKey {
  ErasedMeshPipelineKey::new(bits, "<unknown>")
}

///|
pub fn ErasedMeshPipelineKey::default() -> ErasedMeshPipelineKey {
  ErasedMeshPipelineKey::{ bits: 0UL, type_tag: "()" }
}

///|
pub fn ErasedMeshPipelineKey::bits(self : ErasedMeshPipelineKey) -> UInt64 {
  self.bits
}

///|
pub fn ErasedMeshPipelineKey::type_tag(self : ErasedMeshPipelineKey) -> String {
  self.type_tag
}

///|
pub fn ErasedMeshPipelineKey::downcast_u64(
  self : ErasedMeshPipelineKey,
  expected_type_tag : String,
) -> UInt64 {
  if self.type_tag != expected_type_tag {
    abort("ErasedMeshPipelineKey::downcast_u64 called with wrong type tag")
  }
  self.bits
}

///|
fn erased_material_key_hash(type_tag : String, value_json : String) -> UInt64 {
  (type_tag + ":" + value_json).hash().to_uint64()
}

///|
pub struct ErasedMaterialKey {
  type_tag : String
  hash : UInt64
  value_json : String
}

///|
pub fn[T : ToJson] ErasedMaterialKey::new(
  material_key : T,
  type_tag : String,
) -> ErasedMaterialKey {
  let value_json = material_key.to_json().stringify()
  ErasedMaterialKey::{
    type_tag,
    hash: erased_material_key_hash(type_tag, value_json),
    value_json,
  }
}

///|
pub fn[T : ToJson] ErasedMaterialKey::new_untyped(
  material_key : T,
) -> ErasedMaterialKey {
  ErasedMaterialKey::new(material_key, "<unknown>")
}

///|
pub fn ErasedMaterialKey::default() -> ErasedMaterialKey {
  ErasedMaterialKey::new((), "()")
}

///|
pub fn ErasedMaterialKey::type_tag(self : ErasedMaterialKey) -> String {
  self.type_tag
}

///|
pub fn ErasedMaterialKey::hash(self : ErasedMaterialKey) -> UInt64 {
  self.hash
}

///|
pub fn ErasedMaterialKey::value_json(self : ErasedMaterialKey) -> String {
  self.value_json
}

///|
pub fn ErasedMaterialKey::to_key_json(self : ErasedMaterialKey) -> Json raise {
  @json.parse(self.value_json)
}

///|
pub struct ErasedMaterialPipelineKey {
  mesh_key : ErasedMeshPipelineKey
  material_key : ErasedMaterialKey
  type_tag : String
}

///|
pub fn ErasedMaterialPipelineKey::new(
  mesh_key : ErasedMeshPipelineKey,
  material_key : ErasedMaterialKey,
  type_tag : String,
) -> ErasedMaterialPipelineKey {
  ErasedMaterialPipelineKey::{ mesh_key, material_key, type_tag }
}

///|
pub fn ErasedMaterialPipelineKey::new_untyped(
  mesh_key : ErasedMeshPipelineKey,
  material_key : ErasedMaterialKey,
) -> ErasedMaterialPipelineKey {
  ErasedMaterialPipelineKey::new(mesh_key, material_key, "<unknown>")
}
