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
  Basis
  Bmp
  Dds
  Exr
  Farbfeld
  Gif
  Hdr
  Ico
  Jpeg
  Ktx2
  Png
  Pnm
  Qoi
  Tga
  Tiff
  Webp
  Unknown(String)
} derive(Eq)

///|
pub struct ImageLoader {
  supported_compressed_formats : Int
} derive(Eq, Debug)

///|
pub(all) struct FileTextureError {
  error : String
  path : String
} derive(Eq, Debug)

///|
pub(all) suberror ImageLoaderError {
  Io(String)
  FileTexture(FileTextureError)
  ArrayLayout(String)
}

///|
pub fn ImageLoader::new(supported_compressed_formats : Int) -> ImageLoader {
  ImageLoader::{ supported_compressed_formats, }
}

///|
pub fn ImageLoader::default() -> ImageLoader {
  ImageLoader::new(0)
}

///|
pub fn ImageLoader::supported_compressed_formats(self : ImageLoader) -> Int {
  self.supported_compressed_formats
}

///|
pub fn ImageLoader::supported_formats(
  _self : ImageLoader,
) -> Array[ImageContainerFormat] {
  image_loader_supported_formats()
}

///|
pub fn ImageLoader::extensions(_self : ImageLoader) -> Array[String] {
  image_loader_supported_file_extensions()
}

///|
pub fn file_texture_error_message(error : FileTextureError) -> String {
  "Error reading image file \{error.path}: \{error.error}."
}

///|
pub fn image_loader_error_message(error : ImageLoaderError) -> String {
  match error {
    ImageLoaderError::Io(message) => "Failed to load image bytes: \{message}"
    ImageLoaderError::FileTexture(file_error) =>
      "Could not load texture file: \{file_texture_error_message(file_error)}"
    ImageLoaderError::ArrayLayout(message) => "Invalid array layout: \{message}"
  }
}

///|
pub fn image_container_format_from_extension(
  extension : String,
) -> ImageContainerFormat {
  match extension {
    "basis" => ImageContainerFormat::Basis
    "bmp" => ImageContainerFormat::Bmp
    "dds" => ImageContainerFormat::Dds
    "exr" => ImageContainerFormat::Exr
    "ff" => ImageContainerFormat::Farbfeld
    "farbfeld" => ImageContainerFormat::Farbfeld
    "gif" => ImageContainerFormat::Gif
    "hdr" => ImageContainerFormat::Hdr
    "ico" => ImageContainerFormat::Ico
    "jpg" => ImageContainerFormat::Jpeg
    "jpeg" => ImageContainerFormat::Jpeg
    "ktx2" => ImageContainerFormat::Ktx2
    "png" => ImageContainerFormat::Png
    "pnm" => ImageContainerFormat::Pnm
    "ppm" => ImageContainerFormat::Pnm
    "pgm" => ImageContainerFormat::Pnm
    "pbm" => ImageContainerFormat::Pnm
    "qoi" => ImageContainerFormat::Qoi
    "tga" => ImageContainerFormat::Tga
    "tif" => ImageContainerFormat::Tiff
    "tiff" => ImageContainerFormat::Tiff
    "webp" => ImageContainerFormat::Webp
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
pub fn image_loader_supported_formats() -> Array[ImageContainerFormat] {
  [
    ImageContainerFormat::Basis,
    ImageContainerFormat::Bmp,
    ImageContainerFormat::Dds,
    ImageContainerFormat::Exr,
    ImageContainerFormat::Farbfeld,
    ImageContainerFormat::Gif,
    ImageContainerFormat::Hdr,
    ImageContainerFormat::Ico,
    ImageContainerFormat::Jpeg,
    ImageContainerFormat::Ktx2,
    ImageContainerFormat::Png,
    ImageContainerFormat::Pnm,
    ImageContainerFormat::Qoi,
    ImageContainerFormat::Tga,
    ImageContainerFormat::Tiff,
    ImageContainerFormat::Webp,
  ]
}

///|
fn image_container_format_extensions(
  format : ImageContainerFormat,
) -> Array[String] {
  match format {
    ImageContainerFormat::Basis => ["basis"]
    ImageContainerFormat::Bmp => ["bmp"]
    ImageContainerFormat::Dds => ["dds"]
    ImageContainerFormat::Exr => ["exr"]
    ImageContainerFormat::Farbfeld => ["ff", "farbfeld"]
    ImageContainerFormat::Gif => ["gif"]
    ImageContainerFormat::Hdr => ["hdr"]
    ImageContainerFormat::Ico => ["ico"]
    ImageContainerFormat::Jpeg => ["jpg", "jpeg"]
    ImageContainerFormat::Ktx2 => ["ktx2"]
    ImageContainerFormat::Png => ["png"]
    ImageContainerFormat::Pnm => ["pnm", "ppm", "pgm", "pbm"]
    ImageContainerFormat::Qoi => ["qoi"]
    ImageContainerFormat::Tga => ["tga"]
    ImageContainerFormat::Tiff => ["tif", "tiff"]
    ImageContainerFormat::Webp => ["webp"]
    ImageContainerFormat::Unknown(extension) => [extension]
  }
}

///|
pub fn image_loader_supported_file_extensions() -> Array[String] {
  let out : Array[String] = []
  for format in image_loader_supported_formats() {
    for extension in image_container_format_extensions(format) {
      out.push(extension)
    }
  }
  out
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
fn image_blob_u8_at(bytes : Bytes, index : Int) -> Int {
  guard index >= 0 && index < bytes.length() else { return -1 }
  bytes[index].to_int() & 0xFF
}

///|
fn image_bytes_starts_with(bytes : Bytes, prefix : Array[Int]) -> Bool {
  if bytes.length() < prefix.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if image_blob_u8_at(bytes, i) != prefix[i] {
      return false
    }
  }
  true
}

///|
pub fn image_guess_container_from_bytes(bytes : Bytes) -> ImageContainerFormat? {
  if image_bytes_starts_with(bytes, [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ]) {
    return Some(ImageContainerFormat::Png)
  }
  if image_bytes_starts_with(bytes, [0xFF, 0xD8]) {
    return Some(ImageContainerFormat::Jpeg)
  }
  if image_bytes_starts_with(bytes, [0x44, 0x44, 0x53, 0x20]) {
    return Some(ImageContainerFormat::Dds)
  }
  if image_bytes_starts_with(bytes, [
      0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A,
    ]) {
    return Some(ImageContainerFormat::Ktx2)
  }
  if image_bytes_starts_with(bytes, [0x76, 0x2F, 0x31, 0x01]) {
    return Some(ImageContainerFormat::Exr)
  }
  if image_bytes_starts_with(bytes, [
      0x23, 0x3F, 0x52, 0x41, 0x44, 0x49, 0x41, 0x4E, 0x43, 0x45,
    ]) ||
    image_bytes_starts_with(bytes, [0x23, 0x3F, 0x52, 0x47, 0x42, 0x45]) {
    return Some(ImageContainerFormat::Hdr)
  }
  if image_bytes_starts_with(bytes, [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) ||
    image_bytes_starts_with(bytes, [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) {
    return Some(ImageContainerFormat::Gif)
  }
  if image_bytes_starts_with(bytes, [0x42, 0x4D]) {
    return Some(ImageContainerFormat::Bmp)
  }
  if image_bytes_starts_with(bytes, [0x00, 0x00, 0x01, 0x00]) {
    return Some(ImageContainerFormat::Ico)
  }
  if image_bytes_starts_with(bytes, [
      0x66, 0x61, 0x72, 0x62, 0x66, 0x65, 0x6C, 0x64,
    ]) {
    return Some(ImageContainerFormat::Farbfeld)
  }
  if image_bytes_starts_with(bytes, [0x71, 0x6F, 0x69, 0x66]) {
    return Some(ImageContainerFormat::Qoi)
  }
  if image_bytes_starts_with(bytes, [0x49, 0x49, 0x2A, 0x00]) ||
    image_bytes_starts_with(bytes, [0x4D, 0x4D, 0x00, 0x2A]) {
    return Some(ImageContainerFormat::Tiff)
  }
  if bytes.length() >= 2 &&
    image_blob_u8_at(bytes, 0) == 0x50 &&
    image_blob_u8_at(bytes, 1) >= 0x31 &&
    image_blob_u8_at(bytes, 1) <= 0x36 {
    return Some(ImageContainerFormat::Pnm)
  }
  if bytes.length() >= 12 &&
    image_bytes_starts_with(bytes, [0x52, 0x49, 0x46, 0x46]) &&
    image_blob_u8_at(bytes, 8) == 0x57 &&
    image_blob_u8_at(bytes, 9) == 0x45 &&
    image_blob_u8_at(bytes, 10) == 0x42 &&
    image_blob_u8_at(bytes, 11) == 0x50 {
    return Some(ImageContainerFormat::Webp)
  }
  None
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
    Some(
      image_extension_normalize(
        file_name[dot + 1:file_name.length()].to_string(),
      ),
    )
  } else {
    None
  }
}

///|
pub fn image_loader_container_from_input(
  path : String,
  bytes : Bytes?,
  format_setting : ImageFormatSetting,
) -> ImageContainerFormat? {
  match format_setting {
    ImageFormatSetting::Format(format) => Some(format)
    ImageFormatSetting::Guess =>
      match bytes {
        Some(blob) => image_guess_container_from_bytes(blob)
        None => None
      }
    ImageFormatSetting::FromExtension =>
      match image_extension_from_path(path) {
        Some(extension) =>
          match image_container_format_from_extension(extension) {
            ImageContainerFormat::Unknown(_) => None
            known => Some(known)
          }
        None => None
      }
  }
}

///|
pub fn image_loader_container_from_path(
  path : String,
  format_setting : ImageFormatSetting,
) -> ImageContainerFormat? {
  image_loader_container_from_input(path, None, format_setting)
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
    ImageArrayLayout::RowCount(rows) => if rows > 0 { Some(rows) } else { None }
    ImageArrayLayout::RowHeight(row_height) =>
      if row_height > 0 && image_height % row_height == 0 {
        Some(image_height / row_height)
      } else {
        None
      }
  }
}
