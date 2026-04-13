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

///|
pub(all) enum ImageFormatSetting {
  FromExtension
  Format(ImageContainerFormat)
  Guess
} derive(Eq)

///|
pub fn ImageFormatSetting::default() -> ImageFormatSetting {
  ImageFormatSetting::FromExtension
}

///|
pub(all) struct ImageLoaderSettings {
  format : ImageFormatSetting
  texture_format : TextureFormat?
  is_srgb : Bool
  sampler : ImageSampler
  array_layout : ImageArrayLayout?
}

///|
pub fn ImageLoaderSettings::default() -> ImageLoaderSettings {
  ImageLoaderSettings::{
    format: ImageFormatSetting::default(),
    texture_format: None,
    is_srgb: true,
    sampler: ImageSampler::default(),
    array_layout: None,
  }
}

///|
fn image_string_last_index_of_char(input : String, code_unit : Int) -> Int {
  let mut out = -1
  for i in 0..<input.length() {
    if input.code_unit_at(i).to_int() == code_unit {
      out = i
    }
  }
  out
}

///|
fn image_extension_normalize(extension : String) -> String {
  let chars : Array[Char] = []
  let mut seen_dot = false
  for i in 0..<extension.length() {
    let mut code = extension.code_unit_at(i)
    if !seen_dot && code == 46 {
      seen_dot = true
      continue
    }
    seen_dot = true
    if code >= 65 && code <= 90 {
      code = code + 32
    }
    chars.push(Int::unsafe_to_char(code.to_int()))
  }
  String::from_array(chars)
}

///|
pub fn image_extension_from_path(path : String) -> String? {
  let slash = image_string_last_index_of_char(path, 47)
  let file_name = match slash {
    -1 => path
    index => path[index + 1:path.length()].to_string()
  }
  let dot = image_string_last_index_of_char(file_name, 46)
  if dot >= 0 && dot + 1 < file_name.length() {
    Some(image_extension_normalize(file_name[dot + 1:file_name.length()].to_string()))
  } else {
    None
  }
}

///|
pub fn image_loader_container_from_path(
  path : String,
  format_setting : ImageFormatSetting,
) -> ImageContainerFormat? {
  match format_setting {
    ImageFormatSetting::Format(format) => Some(format)
    ImageFormatSetting::Guess => None
    ImageFormatSetting::FromExtension =>
      match image_extension_from_path(path) {
        Some(extension) => {
          let guessed = image_container_format_from_extension(extension)
          match guessed {
            ImageContainerFormat::Unknown(_) => None
            _ => Some(guessed)
          }
        }
        None => None
      }
  }
}

///|
pub fn image_array_layout_layers(
  image_height : Int,
  layout : ImageArrayLayout,
) -> Int? {
  if image_height <= 0 {
    return None
  }
  match layout {
    ImageArrayLayout::RowCount(rows) =>
      if rows > 0 {
        Some(rows)
      } else {
        None
      }
    ImageArrayLayout::RowHeight(row_height) =>
      if row_height > 0 && image_height % row_height == 0 {
        Some(image_height / row_height)
      } else {
        None
      }
  }
}
