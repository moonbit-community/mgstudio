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
// Bevy source: `bevy/crates/bevy_render/src/texture/manual_texture_view.rs`.

///|
pub type ManualTextureViewHandle = Int

///|
pub struct ManualTextureView {
  texture_id : Int
  mip_level : Int
}

///|
pub fn ManualTextureView::new(
  texture_id : Int,
  mip_level : Int,
) -> ManualTextureView {
  ManualTextureView::{ texture_id, mip_level }
}

///|
pub fn ManualTextureView::texture_id(self : ManualTextureView) -> Int {
  self.texture_id
}

///|
pub fn ManualTextureView::mip_level(self : ManualTextureView) -> Int {
  self.mip_level
}

///|
pub fn manual_texture_view_handle(
  texture_id~ : Int,
  mip_level~ : Int,
) -> ManualTextureViewHandle {
  texture_id + mip_level
}
