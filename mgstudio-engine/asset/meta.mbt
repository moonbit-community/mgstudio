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
  mut sampler : ImageSampler
  mut is_srgb : Bool
  mut array_layout : ImageArrayLayout?
  mut asset_usage : RenderAssetUsages
  mut load_meshes : RenderAssetUsages
}

///|
pub fn ImageLoaderSettings::default() -> ImageLoaderSettings {
  ImageLoaderSettings::{
    sampler: ImageSampler::Default,
    is_srgb: true,
    array_layout: None,
    asset_usage: RenderAssetUsages::all(),
    load_meshes: RenderAssetUsages::all(),
  }
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
fn meta_render_asset_usages(content : String) -> RenderAssetUsages? {
  guard string_contains(content, "asset_usage: RenderAssetUsages(") else {
    return None
  }
  let has_main_world = string_contains(content, "MAIN_WORLD")
  let has_render_world = string_contains(content, "RENDER_WORLD")
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
fn image_meta_path(path : String) -> String {
  "\{path}.meta"
}

///|
fn apply_image_meta_settings(
  settings : ImageLoaderSettings,
  content : String,
) -> Unit {
  if string_contains(content, "is_srgb: false") {
    settings.is_srgb = false
  } else if string_contains(content, "is_srgb: true") {
    settings.is_srgb = true
  }
  if meta_render_asset_usages(content) is Some(asset_usage) {
    settings.asset_usage = asset_usage
  }

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
