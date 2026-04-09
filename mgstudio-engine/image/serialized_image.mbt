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
}

///|
pub fn SerializedImage::from_image(image : Image) -> SerializedImage {
  SerializedImage::{
    width: image.width,
    height: image.height,
    pixels: image.pixels,
    format: image.format,
  }
}

///|
pub fn SerializedImage::into_image(self : SerializedImage) -> Image {
  Image::{
    width: self.width,
    height: self.height,
    pixels: self.pixels,
    format: self.format,
    view_format: None,
    kind: ImageKind::Data,
  }
}
