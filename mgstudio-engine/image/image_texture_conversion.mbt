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
// Bevy source: `bevy/crates/bevy_image/src/image_texture_conversion.rs`.

///|
pub fn image_to_target_texture(image : Image) -> Image {
  Image::new_target_texture(
    image.width,
    image.height,
    image.format,
    image.view_format,
  )
}

///|
pub fn image_with_srgb_view(image : Image) -> Image {
  let view_format = match image.format {
    TextureFormat::Rgba8Unorm => Some(TextureFormat::Rgba8UnormSrgb)
    TextureFormat::Rgba8UnormSrgb => Some(TextureFormat::Rgba8UnormSrgb)
    TextureFormat::Bgra8Unorm => Some(TextureFormat::Bgra8UnormSrgb)
    TextureFormat::Bgra8UnormSrgb => Some(TextureFormat::Bgra8UnormSrgb)
    _ => image.view_format
  }
  Image::{
    width: image.width,
    height: image.height,
    pixels: image.pixels,
    format: image.format,
    view_format,
    sampler: image.sampler,
    kind: image.kind,
    mip_level_count: image.mip_level_count,
    usage_bits: image.usage_bits,
    texture_descriptor_label: image.texture_descriptor_label,
    array_layout: image.array_layout,
    texture_view_dimension: image.texture_view_dimension,
  }
}
