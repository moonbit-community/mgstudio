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
// Bevy source: `bevy/crates/bevy_render/src/texture/texture_attachment.rs`.

///|
pub struct TextureAttachment {
  texture_id : Int
  mip_level : Int
  layer : Int
}

///|
pub fn TextureAttachment::new(
  texture_id : Int,
  mip_level : Int,
  layer : Int,
) -> TextureAttachment {
  TextureAttachment::{ texture_id, mip_level, layer }
}

///|
pub fn TextureAttachment::texture_id(self : TextureAttachment) -> Int {
  self.texture_id
}

///|
pub fn TextureAttachment::mip_level(self : TextureAttachment) -> Int {
  self.mip_level
}

///|
pub fn TextureAttachment::layer(self : TextureAttachment) -> Int {
  self.layer
}

///|
pub fn TextureAttachment::as_manual_texture_view(
  self : TextureAttachment,
) -> ManualTextureViewHandle {
  self.texture_id + self.mip_level + self.layer
}
