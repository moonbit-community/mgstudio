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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/texture.rs`.

///|
pub struct Texture {
  id : TextureId
  value : @wgpu.Texture
}

///|
pub struct TextureView {
  id : TextureViewId
  value : @wgpu.TextureView
}

///|
pub struct SurfaceTexture {
  value : @wgpu.SurfaceTexture
}

///|
pub struct Sampler {
  id : SamplerId
  value : @wgpu.Sampler
}

///|
pub struct DefaultImageSampler {
  sampler : Sampler
}

///|
pub fn Texture::new(value : @wgpu.Texture) -> Texture {
  Texture::{ id: next_texture_id(), value }
}

///|
pub fn Texture::from_wgpu(value : @wgpu.Texture) -> Texture {
  Texture::new(value)
}

///|
pub fn Texture::id(self : Texture) -> TextureId {
  self.id
}

///|
pub fn Texture::create_view(self : Texture) -> TextureView {
  TextureView::{ id: next_texture_view_id(), value: self.value.create_view() }
}

///|
pub fn Texture::into_inner(self : Texture) -> @wgpu.Texture {
  self.value
}

///|
pub fn Texture::set_label(self : Texture, label : String) -> Unit {
  self.value.set_label(label)
}

///|
pub fn TextureView::id(self : TextureView) -> TextureViewId {
  self.id
}

///|
pub fn TextureView::into_inner(self : TextureView) -> @wgpu.TextureView {
  self.value
}

///|
pub fn TextureView::set_label(self : TextureView, label : String) -> Unit {
  self.value.set_label(label)
}

///|
pub fn SurfaceTexture::from_wgpu(
  value : @wgpu.SurfaceTexture,
) -> SurfaceTexture {
  SurfaceTexture::{ value, }
}

///|
pub fn SurfaceTexture::present(self : SurfaceTexture) -> Unit {
  self.value.release()
}

///|
pub fn SurfaceTexture::take_texture(self : SurfaceTexture) -> Texture {
  Texture::from_wgpu(self.value.take_texture())
}

///|
pub fn Sampler::new(value : @wgpu.Sampler) -> Sampler {
  Sampler::{ id: next_sampler_id(), value }
}

///|
pub fn Sampler::from_wgpu(value : @wgpu.Sampler) -> Sampler {
  Sampler::new(value)
}

///|
pub fn Sampler::id(self : Sampler) -> SamplerId {
  self.id
}

///|
pub fn Sampler::set_label(self : Sampler, label : String) -> Unit {
  self.value.set_label(label)
}

///|
pub fn Sampler::into_inner(self : Sampler) -> @wgpu.Sampler {
  self.value
}

///|
pub fn DefaultImageSampler::new(sampler : Sampler) -> DefaultImageSampler {
  DefaultImageSampler::{ sampler, }
}

///|
pub fn DefaultImageSampler::sampler(self : DefaultImageSampler) -> Sampler {
  self.sampler
}
