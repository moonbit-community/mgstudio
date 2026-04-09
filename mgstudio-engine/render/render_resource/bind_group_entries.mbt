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
}

///|
pub(all) enum SamplerBindingType {
  Filtering
  NonFiltering
  Comparison
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
