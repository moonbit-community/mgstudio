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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/bindless.rs`.

///|
pub struct BindlessDescriptor {
  max_storage_buffers : Int
  max_textures : Int
  max_samplers : Int
}

///|
pub struct BindlessSlabResourceLimit {
  storage_buffers : Int
  textures : Int
  samplers : Int
}

///|
pub fn BindlessDescriptor::new(
  max_storage_buffers : Int,
  max_textures : Int,
  max_samplers : Int,
) -> BindlessDescriptor {
  BindlessDescriptor::{ max_storage_buffers, max_textures, max_samplers }
}

///|
pub fn BindlessSlabResourceLimit::new(
  storage_buffers : Int,
  textures : Int,
  samplers : Int,
) -> BindlessSlabResourceLimit {
  BindlessSlabResourceLimit::{ storage_buffers, textures, samplers }
}

///|
pub fn BindlessDescriptor::slab_limit(
  self : BindlessDescriptor,
) -> BindlessSlabResourceLimit {
  BindlessSlabResourceLimit::{
    storage_buffers: self.max_storage_buffers,
    textures: self.max_textures,
    samplers: self.max_samplers,
  }
}
