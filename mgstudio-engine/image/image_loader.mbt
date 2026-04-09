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
// Bevy source: `bevy/crates/bevy_image/src/image_loader.rs`.

///|
pub(all) enum ImageContainerFormat {
  Png
  Jpeg
  Hdr
  Exr
  Dds
  Ktx2
  Basis
  Unknown(String)
} derive(Eq)

///|
pub fn image_container_format_from_extension(
  extension : String,
) -> ImageContainerFormat {
  match extension {
    "png" => ImageContainerFormat::Png
    "jpg" => ImageContainerFormat::Jpeg
    "jpeg" => ImageContainerFormat::Jpeg
    "hdr" => ImageContainerFormat::Hdr
    "exr" => ImageContainerFormat::Exr
    "dds" => ImageContainerFormat::Dds
    "ktx2" => ImageContainerFormat::Ktx2
    "basis" => ImageContainerFormat::Basis
    _ => ImageContainerFormat::Unknown(extension)
  }
}

///|
pub fn image_container_is_hdr(format : ImageContainerFormat) -> Bool {
  match format {
    Hdr => true
    Exr => true
    _ => false
  }
}

///|
pub fn image_container_is_gpu_compressed(format : ImageContainerFormat) -> Bool {
  match format {
    Dds => true
    Ktx2 => true
    Basis => true
    _ => false
  }
}
