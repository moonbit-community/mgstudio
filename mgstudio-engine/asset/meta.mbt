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
// Bevy source: `bevy/crates/bevy_asset/src/meta.rs`.
pub(all) struct ImageLoaderSettings {
  mut format : ImageFormatSetting
  mut texture_format : TextureFormat?
  mut sampler : ImageSampler
  mut is_srgb : Bool
  mut array_layout : ImageArrayLayout?
  mut asset_usage : RenderAssetUsages
  mut load_meshes : RenderAssetUsages
}

///|
pub fn ImageLoaderSettings::default() -> ImageLoaderSettings {
  ImageLoaderSettings::{
    format: ImageFormatSetting::FromExtension,
    texture_format: None,
    sampler: ImageSampler::Default,
    is_srgb: true,
    array_layout: None,
    asset_usage: RenderAssetUsages::all(),
    load_meshes: RenderAssetUsages::all(),
  }
}

///|
fn meta_image_format_setting(content : String) -> ImageFormatSetting? {
  if string_contains(content, "format: Guess") {
    return Some(ImageFormatSetting::Guess)
  }
  if string_contains(content, "format: FromExtension") {
    return Some(ImageFormatSetting::FromExtension)
  }
  guard string_contains(content, "format: Format") else {
    return None
  }
  if string_contains(content, "Format(Basis)") || string_contains(content, "Format (Basis)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Basis))
  }
  if string_contains(content, "Format(Bmp)") || string_contains(content, "Format (Bmp)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Bmp))
  }
  if string_contains(content, "Format(Dds)") || string_contains(content, "Format (Dds)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Dds))
  }
  if string_contains(content, "Format(Exr)") || string_contains(content, "Format (Exr)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Exr))
  }
  if string_contains(content, "Format(Farbfeld)") ||
    string_contains(content, "Format (Farbfeld)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Farbfeld))
  }
  if string_contains(content, "Format(Gif)") || string_contains(content, "Format (Gif)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Gif))
  }
  if string_contains(content, "Format(Hdr)") || string_contains(content, "Format (Hdr)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Hdr))
  }
  if string_contains(content, "Format(Ico)") || string_contains(content, "Format (Ico)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Ico))
  }
  if string_contains(content, "Format(Jpeg)") || string_contains(content, "Format (Jpeg)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Jpeg))
  }
  if string_contains(content, "Format(Ktx2)") || string_contains(content, "Format (Ktx2)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Ktx2))
  }
  if string_contains(content, "Format(Png)") || string_contains(content, "Format (Png)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Png))
  }
  if string_contains(content, "Format(Pnm)") || string_contains(content, "Format (Pnm)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Pnm))
  }
  if string_contains(content, "Format(Qoi)") || string_contains(content, "Format (Qoi)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Qoi))
  }
  if string_contains(content, "Format(Tga)") || string_contains(content, "Format (Tga)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Tga))
  }
  if string_contains(content, "Format(Tiff)") || string_contains(content, "Format (Tiff)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Tiff))
  }
  if string_contains(content, "Format(Webp)") || string_contains(content, "Format (Webp)") {
    return Some(ImageFormatSetting::Format(ImageContainerFormat::Webp))
  }
  None
}

///|
fn meta_texture_format_setting(content : String) -> TextureFormat? {
  if string_contains(content, "texture_format: Some(Rgba8UnormSrgb)") {
    return Some(TextureFormat::Rgba8UnormSrgb)
  }
  if string_contains(content, "texture_format: Some(Rgba8Unorm)") {
    return Some(TextureFormat::Rgba8Unorm)
  }
  if string_contains(content, "texture_format: Some(Rgba16Float)") {
    return Some(TextureFormat::Rgba16Float)
  }
  if string_contains(content, "texture_format: Some(Rg16Float)") {
    return Some(TextureFormat::Rg16Float)
  }
  None
}

///|
fn meta_image_filter_mode(
  content : String,
  field_name : String,
) -> ImageFilterMode? {
  if string_contains(content, "\{field_name}: Nearest") {
    return Some(ImageFilterMode::Nearest)
  }
  if string_contains(content, "\{field_name}: Linear") {
    return Some(ImageFilterMode::Linear)
  }
  None
}

///|
fn meta_image_address_mode(
  content : String,
  field_name : String,
) -> ImageAddressMode? {
  if string_contains(content, "\{field_name}: ClampToEdge") {
    return Some(ImageAddressMode::ClampToEdge)
  }
  if string_contains(content, "\{field_name}: Repeat") {
    return Some(ImageAddressMode::Repeat)
  }
  if string_contains(content, "\{field_name}: MirrorRepeat") {
    return Some(ImageAddressMode::MirrorRepeat)
  }
  if string_contains(content, "\{field_name}: ClampToBorder") {
    return Some(ImageAddressMode::ClampToBorder)
  }
  None
}

///|
fn meta_find_substring(content : String, pattern : String, start : Int) -> Int {
  let content_len = content.length()
  let pattern_len = pattern.length()
  if pattern_len <= 0 {
    return start
  }
  if start < 0 || start + pattern_len > content_len {
    return -1
  }
  let mut index = start
  while index + pattern_len <= content_len {
    let mut matched = true
    for offset in 0..<pattern_len {
      if content.code_unit_at(index + offset) != pattern.code_unit_at(offset) {
        matched = false
        break
      }
    }
    if matched {
      return index
    }
    index = index + 1
  }
  -1
}

///|
fn meta_extract_render_asset_usage_value(
  content : String,
  field_name : String,
) -> String? {
  let marker = "\{field_name}: RenderAssetUsages(\""
  let start = meta_find_substring(content, marker, 0)
  if start < 0 {
    return None
  }
  let value_start = start + marker.length()
  let value_end = meta_find_substring(content, "\")", value_start)
  if value_end < value_start {
    return None
  }
  Some(content[value_start:value_end].to_string())
}

///|
fn meta_render_asset_usages_field(
  content : String,
  field_name : String,
) -> RenderAssetUsages? {
  guard meta_extract_render_asset_usage_value(content, field_name) is Some(value) else {
    return None
  }
  let has_main_world = string_contains(value, "MAIN_WORLD")
  let has_render_world = string_contains(value, "RENDER_WORLD")
  if has_main_world && has_render_world {
    return Some(RenderAssetUsages::all())
  }
  if has_main_world {
    return Some(RenderAssetUsages::main_world())
  }
  if has_render_world {
    return Some(RenderAssetUsages::render_world())
  }
  None
}

///|
fn meta_parse_positive_int_after(content : String, marker : String) -> Int? {
  let start = meta_find_substring(content, marker, 0)
  if start < 0 {
    return None
  }
  let mut index = start + marker.length()
  let mut value = 0
  let mut parsed = false
  while index < content.length() {
    let code = content.code_unit_at(index).to_int()
    if code < 48 || code > 57 {
      break
    }
    parsed = true
    value = value * 10 + code - 48
    index = index + 1
  }
  if parsed && value > 0 {
    Some(value)
  } else {
    None
  }
}

///|
fn meta_image_array_layout(content : String) -> ImageArrayLayout? {
  if meta_parse_positive_int_after(content, "array_layout: Some(RowCount(rows: ") is Some(rows) {
    return Some(ImageArrayLayout::RowCount(rows))
  }
  if meta_parse_positive_int_after(content, "array_layout: Some(RowCount (rows: ") is Some(rows) {
    return Some(ImageArrayLayout::RowCount(rows))
  }
  if meta_parse_positive_int_after(content, "array_layout: Some(RowCount { rows: ") is Some(rows) {
    return Some(ImageArrayLayout::RowCount(rows))
  }
  if meta_parse_positive_int_after(content, "array_layout: Some(RowHeight(pixels: ") is Some(
    pixels,
  ) {
    return Some(ImageArrayLayout::RowHeight(pixels))
  }
  if meta_parse_positive_int_after(content, "array_layout: Some(RowHeight (pixels: ") is Some(
    pixels,
  ) {
    return Some(ImageArrayLayout::RowHeight(pixels))
  }
  if meta_parse_positive_int_after(content, "array_layout: Some(RowHeight { pixels: ") is Some(
    pixels,
  ) {
    return Some(ImageArrayLayout::RowHeight(pixels))
  }
  None
}

///|
fn image_meta_path(path : String) -> String {
  "\{path}.meta"
}

///|
fn apply_image_meta_settings(
  settings : ImageLoaderSettings,
  content : String,
) -> Unit {
  if meta_image_format_setting(content) is Some(format_setting) {
    settings.format = format_setting
  }
  settings.texture_format = meta_texture_format_setting(content)

  if string_contains(content, "is_srgb: false") {
    settings.is_srgb = false
  } else if string_contains(content, "is_srgb: true") {
    settings.is_srgb = true
  }
  if meta_render_asset_usages_field(content, "asset_usage") is Some(asset_usage) {
    settings.asset_usage = asset_usage
  }
  if meta_render_asset_usages_field(content, "load_meshes") is Some(load_meshes) {
    settings.load_meshes = load_meshes
  }
  settings.array_layout = meta_image_array_layout(content)

  let address_mode_u = meta_image_address_mode(content, "address_mode_u")
  let address_mode_v = meta_image_address_mode(content, "address_mode_v")
  let address_mode_w = meta_image_address_mode(content, "address_mode_w")
  let mag_filter = meta_image_filter_mode(content, "mag_filter")
  let min_filter = meta_image_filter_mode(content, "min_filter")
  let mipmap_filter = meta_image_filter_mode(content, "mipmap_filter")
  let has_descriptor = address_mode_u is Some(_) ||
    address_mode_v is Some(_) ||
    address_mode_w is Some(_) ||
    mag_filter is Some(_) ||
    min_filter is Some(_) ||
    mipmap_filter is Some(_)
  if !has_descriptor {
    return
  }

  let descriptor = ImageSamplerDescriptor::default()
  if address_mode_u is Some(value) {
    descriptor.address_mode_u = value
  }
  if address_mode_v is Some(value) {
    descriptor.address_mode_v = value
  }
  if address_mode_w is Some(value) {
    descriptor.address_mode_w = value
  }
  if mag_filter is Some(value) {
    descriptor.mag_filter = value
  }
  if min_filter is Some(value) {
    descriptor.min_filter = value
  }
  if mipmap_filter is Some(value) {
    descriptor.mipmap_filter = value
  }
  settings.sampler = ImageSampler::Descriptor(descriptor)
}
