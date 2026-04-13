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
// Bevy source: `bevy/crates/bevy_image/src/compressed_image_saver.rs`.

///|
pub struct CompressedImageSaveOptions {
  format_hint : String
  quality : Int
}

///|
pub fn CompressedImageSaveOptions::default() -> CompressedImageSaveOptions {
  CompressedImageSaveOptions::{ format_hint: "", quality: 90 }
}

///|
pub fn CompressedImageSaveOptions::with_format_hint(
  self : CompressedImageSaveOptions,
  format_hint : String,
) -> CompressedImageSaveOptions {
  CompressedImageSaveOptions::{ ..self, format_hint, }
}

///|
pub fn CompressedImageSaveOptions::with_quality(
  self : CompressedImageSaveOptions,
  quality : Int,
) -> CompressedImageSaveOptions {
  let clamped = if quality < 1 {
    1
  } else if quality > 100 {
    100
  } else {
    quality
  }
  CompressedImageSaveOptions::{ ..self, quality: clamped }
}

///|
pub fn image_can_use_compressed_saver(format : TextureFormat) -> Bool {
  match format {
    TextureFormat::Rgba8Unorm => true
    TextureFormat::Rgba8UnormSrgb => true
    TextureFormat::Rgba16Float => false
    TextureFormat::Rg16Float => false
  }
}
