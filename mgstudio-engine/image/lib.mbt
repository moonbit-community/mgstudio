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
// Bevy source: `bevy/crates/bevy_image/src/lib.rs`.

///|
pub fn image_package_bevy_source() -> String {
  "bevy/crates/bevy_image/src/lib.rs"
}

///|
pub fn image_new_rgba8(width : Int, height : Int, pixels : Bytes) -> Image {
  Image::new(width, height, pixels).with_format(TextureFormat::Rgba8Unorm)
}

///|
pub fn image_new_target_texture(
  width : Int,
  height : Int,
  format? : TextureFormat = TextureFormat::Rgba8Unorm,
) -> Image {
  Image::new_target_texture(width, height, format, None)
}
