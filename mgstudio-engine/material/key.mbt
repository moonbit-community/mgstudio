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
} derive(Eq, Debug)

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
pub fn ErasedMeshPipelineKey::ErasedMeshPipelineKey() -> ErasedMeshPipelineKey {
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
fn erased_material_key_hash(type_tag : String, bits : UInt64) -> UInt64 {
  (type_tag + ":" + bits.to_string()).hash().to_uint64()
}

///|
pub struct ErasedMaterialKey {
  type_tag : String
  hash : UInt64
  bits : UInt64
} derive(Eq, Debug)

///|
pub fn ErasedMaterialKey::new(
  bits : UInt64,
  type_tag : String,
) -> ErasedMaterialKey {
  ErasedMaterialKey::{
    type_tag,
    hash: erased_material_key_hash(type_tag, bits),
    bits,
  }
}

///|
pub fn ErasedMaterialKey::new_untyped(bits : UInt64) -> ErasedMaterialKey {
  ErasedMaterialKey::new(bits, "<unknown>")
}

///|
pub fn ErasedMaterialKey::ErasedMaterialKey() -> ErasedMaterialKey {
  ErasedMaterialKey::new(0UL, "()")
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
pub fn ErasedMaterialKey::bits(self : ErasedMaterialKey) -> UInt64 {
  self.bits
}

///|
pub struct ErasedMaterialPipelineKey {
  mesh_key : ErasedMeshPipelineKey
  material_key : ErasedMaterialKey
  type_tag : String
} derive(Eq, Debug)

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

///|
pub fn ErasedMaterialPipelineKey::mesh_key(
  self : ErasedMaterialPipelineKey,
) -> ErasedMeshPipelineKey {
  self.mesh_key
}

///|
pub fn ErasedMaterialPipelineKey::material_key(
  self : ErasedMaterialPipelineKey,
) -> ErasedMaterialKey {
  self.material_key
}

///|
pub fn ErasedMaterialPipelineKey::type_tag(
  self : ErasedMaterialPipelineKey,
) -> String {
  self.type_tag
}
