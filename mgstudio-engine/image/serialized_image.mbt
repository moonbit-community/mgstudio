// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_image/src/serialized_image.rs`.

///|
pub struct SerializedImage {
  width : Int
  height : Int
  pixels : Bytes
  format : TextureFormat
  view_format : TextureFormat?
  sampler : ImageSampler
  kind : ImageKind
  mip_level_count : Int
  usage_bits : Int
  array_layout : ImageArrayLayout?
  texture_view_dimension : ImageTextureViewDimension?
}

///|
pub fn SerializedImage::from_image(image : Image) -> SerializedImage {
  {
    width: image.width,
    height: image.height,
    pixels: image.pixels,
    format: image.format,
    view_format: image.view_format,
    sampler: image.sampler,
    kind: image.kind,
    mip_level_count: image.mip_level_count,
    usage_bits: image.usage_bits,
    array_layout: image.array_layout,
    texture_view_dimension: image.texture_view_dimension,
  }
}

///|
pub fn SerializedImage::into_image(self : SerializedImage) -> Image {
  {
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: self.view_format,
    sampler: self.sampler,
    kind: self.kind,
    mip_level_count: self.mip_level_count,
    usage_bits: self.usage_bits,
    texture_descriptor_label: None,
    array_layout: self.array_layout,
    texture_view_dimension: self.texture_view_dimension,
  }
}
