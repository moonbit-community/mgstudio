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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/bind_group_entries.rs`.

///|
pub(all) enum BindingType {
  Buffer
  Texture
  Sampler
  StorageTexture
  External
  BufferBinding(BufferBindingType, Bool, UInt64)
  TextureBinding(TextureSampleType, TextureViewDimension, Bool)
  SamplerBinding(SamplerBindingType)
  StorageTextureBinding(StorageTextureAccess, UInt, TextureViewDimension)
}

///|
pub(all) enum SamplerBindingType {
  Filtering
  NonFiltering
  Comparison
}

///|
pub(all) enum BufferBindingType {
  Uniform
  Storage(Bool)
}

///|
pub(all) enum TextureSampleType {
  Float(Bool)
  Depth
  SInt
  UInt
}

///|
pub(all) enum TextureViewDimension {
  D1
  D2
  D2Array
  Cube
  CubeArray
  D3
}

///|
pub(all) enum StorageTextureAccess {
  WriteOnly
  ReadOnly
  ReadWrite
}

///|
pub(all) enum BindingResource {
  Buffer(BufferId)
  TextureView(TextureViewId)
  Sampler(SamplerId)
  Label(String)
}

///|
pub struct BindGroupEntry {
  binding : Int
  resource : BindingResource
}

///|
pub struct BindGroupDescriptor {
  entries : Array[BindGroupEntry]
}

///|
pub(all) enum MaterialBindGroupResolvedResource {
  Texture(Int)
  Sampler(Int)
  Uniform(Bytes)
} derive(Eq)

///|
pub struct MaterialBindGroupResolvedEntry {
  binding : Int
  resource : MaterialBindGroupResolvedResource
} derive(Eq)

///|
pub struct MaterialBindGroupResolvedData {
  entries : Array[MaterialBindGroupResolvedEntry]
}

///|
pub fn BindGroupEntry::buffer(
  binding : Int,
  buffer : BufferId,
) -> BindGroupEntry {
  BindGroupEntry::{ binding, resource: BindingResource::Buffer(buffer) }
}

///|
pub fn BindGroupEntry::texture_view(
  binding : Int,
  texture_view : TextureViewId,
) -> BindGroupEntry {
  BindGroupEntry::{
    binding,
    resource: BindingResource::TextureView(texture_view),
  }
}

///|
pub fn BindGroupEntry::sampler(
  binding : Int,
  sampler : SamplerId,
) -> BindGroupEntry {
  BindGroupEntry::{ binding, resource: BindingResource::Sampler(sampler) }
}

///|
pub fn BindGroupEntry::binding(self : BindGroupEntry) -> Int {
  self.binding
}

///|
pub fn BindGroupEntry::resource(self : BindGroupEntry) -> BindingResource {
  self.resource
}

///|
pub fn BindGroupDescriptor::new(
  entries : Array[BindGroupEntry],
) -> BindGroupDescriptor {
  BindGroupDescriptor::{ entries, }
}

///|
pub fn BindGroupDescriptor::entries(
  self : BindGroupDescriptor,
) -> Array[BindGroupEntry] {
  self.entries
}

///|
pub fn MaterialBindGroupResolvedEntry::texture(
  binding : Int,
  texture_id : Int,
) -> MaterialBindGroupResolvedEntry {
  MaterialBindGroupResolvedEntry::{
    binding,
    resource: MaterialBindGroupResolvedResource::Texture(texture_id),
  }
}

///|
pub fn MaterialBindGroupResolvedEntry::sampler(
  binding : Int,
  texture_id : Int,
) -> MaterialBindGroupResolvedEntry {
  MaterialBindGroupResolvedEntry::{
    binding,
    resource: MaterialBindGroupResolvedResource::Sampler(texture_id),
  }
}

///|
pub fn MaterialBindGroupResolvedEntry::uniform(
  binding : Int,
  bytes : Bytes,
) -> MaterialBindGroupResolvedEntry {
  MaterialBindGroupResolvedEntry::{
    binding,
    resource: MaterialBindGroupResolvedResource::Uniform(bytes),
  }
}

///|
pub fn MaterialBindGroupResolvedEntry::binding(
  self : MaterialBindGroupResolvedEntry,
) -> Int {
  self.binding
}

///|
pub fn MaterialBindGroupResolvedEntry::resource(
  self : MaterialBindGroupResolvedEntry,
) -> MaterialBindGroupResolvedResource {
  self.resource
}

///|
pub fn MaterialBindGroupResolvedData::MaterialBindGroupResolvedData() -> MaterialBindGroupResolvedData {
  MaterialBindGroupResolvedData::{ entries: [] }
}

///|
pub impl Default for MaterialBindGroupResolvedData with fn default() {
  MaterialBindGroupResolvedData::MaterialBindGroupResolvedData()
}

///|
pub fn MaterialBindGroupResolvedData::new(
  entries : Array[MaterialBindGroupResolvedEntry],
) -> MaterialBindGroupResolvedData {
  MaterialBindGroupResolvedData::{ entries, }
}

///|
pub fn MaterialBindGroupResolvedData::entries(
  self : MaterialBindGroupResolvedData,
) -> Array[MaterialBindGroupResolvedEntry] {
  self.entries
}

///|
pub fn MaterialBindGroupResolvedData::is_empty(
  self : MaterialBindGroupResolvedData,
) -> Bool {
  self.entries.length() == 0
}

///|
pub fn MaterialBindGroupResolvedData::equals(
  self : MaterialBindGroupResolvedData,
  other : MaterialBindGroupResolvedData,
) -> Bool {
  let entries = self.entries
  let other_entries = other.entries
  if entries.length() != other_entries.length() {
    return false
  }
  for index in 0..<entries.length() {
    if entries[index] != other_entries[index] {
      return false
    }
  }
  true
}
