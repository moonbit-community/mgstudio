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
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs`.

///|
pub struct ManualTextureViewHandle {
  value : Int
} derive(Eq, Hash, Debug)

///|
pub fn ManualTextureViewHandle::new(value : Int) -> ManualTextureViewHandle {
  ManualTextureViewHandle::{ value, }
}

///|
pub fn ManualTextureViewHandle::value(self : ManualTextureViewHandle) -> Int {
  self.value
}

///|
pub struct ImageRenderTarget {
  handle_id : Int
} derive(Eq, Hash, Debug)

///|
pub fn ImageRenderTarget::new(handle_id : Int) -> ImageRenderTarget {
  ImageRenderTarget::{ handle_id, }
}

///|
pub fn ImageRenderTarget::from_handle(
  handle : @asset.Handle[@asset.Image],
) -> ImageRenderTarget {
  ImageRenderTarget::new(handle.id())
}

///|
pub fn ImageRenderTarget::handle_id(self : ImageRenderTarget) -> Int {
  self.handle_id
}

///|
pub(all) enum NormalizedRenderTarget {
  Window(@window.WindowRef)
  Image(ImageRenderTarget)
  TextureView(ManualTextureViewHandle)
  None(Int, Int)
} derive(Eq, Hash, Debug)
