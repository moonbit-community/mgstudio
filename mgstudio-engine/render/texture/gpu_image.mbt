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
// Bevy source: `bevy/crates/bevy_render/src/texture/gpu_image.rs`.

///|
pub struct GpuImage {
  texture_id : Int
  width : Int
  height : Int
  mip_level_count : Int
  base_mip_level : Int
  format : @wgpu.TextureFormat?
  texture : @wgpu.Texture?
  view : @wgpu.TextureView?
  sampler : @wgpu.Sampler?
}

///|
pub fn GpuImage::new(texture_id : Int) -> GpuImage {
  match GpuImage::from_texture_id(texture_id) {
    Some(image) => image
    None =>
      GpuImage::{
        texture_id,
        width: @renderer.asset_texture_width(texture_id~),
        height: @renderer.asset_texture_height(texture_id~),
        mip_level_count: 1,
        base_mip_level: 0,
        format: None,
        texture: None,
        view: None,
        sampler: None,
      }
  }
}

///|
pub fn GpuImage::from_texture_info(info : @renderer.GpuTextureInfo) -> GpuImage {
  GpuImage::{
    texture_id: info.id,
    width: info.width,
    height: info.height,
    mip_level_count: info.mip_level_count,
    base_mip_level: info.base_mip_level,
    format: Some(info.format),
    texture: Some(info.texture),
    view: Some(info.view),
    sampler: Some(info.sampler),
  }
}

///|
pub fn GpuImage::from_texture_id_and_format(
  texture_id : Int,
  format : @wgpu.TextureFormat,
) -> GpuImage {
  GpuImage::{
    texture_id,
    width: @renderer.asset_texture_width(texture_id~),
    height: @renderer.asset_texture_height(texture_id~),
    mip_level_count: 1,
    base_mip_level: 0,
    format: Some(format),
    texture: None,
    view: None,
    sampler: None,
  }
}

///|
pub fn GpuImage::from_texture_id(texture_id : Int) -> GpuImage? {
  match @renderer.asset_texture_info(texture_id~) {
    Some(info) => Some(GpuImage::from_texture_info(info))
    None => None
  }
}

///|
pub fn GpuImage::texture_id(self : GpuImage) -> Int {
  self.texture_id
}

///|
pub fn GpuImage::width(self : GpuImage) -> Int {
  self.width
}

///|
pub fn GpuImage::height(self : GpuImage) -> Int {
  self.height
}

///|
pub fn GpuImage::mip_level_count(self : GpuImage) -> Int {
  self.mip_level_count
}

///|
pub fn GpuImage::base_mip_level(self : GpuImage) -> Int {
  self.base_mip_level
}

///|
pub fn GpuImage::format(self : GpuImage) -> @wgpu.TextureFormat? {
  self.format
}

///|
pub fn GpuImage::texture(self : GpuImage) -> @wgpu.Texture? {
  self.texture
}

///|
pub fn GpuImage::view(self : GpuImage) -> @wgpu.TextureView? {
  self.view
}

///|
pub fn GpuImage::sampler(self : GpuImage) -> @wgpu.Sampler? {
  self.sampler
}

///|
pub fn GpuImage::is_loaded(self : GpuImage) -> Bool {
  self.texture is Some(_) &&
  @renderer.asset_is_texture_loaded(texture_id=self.texture_id)
}

///|
pub fn GpuImage::create_mip_view(self : GpuImage, mip_level : Int) -> Int {
  @renderer.asset_create_texture_mip_view(
    texture_id=self.texture_id,
    mip_level~,
  )
}
