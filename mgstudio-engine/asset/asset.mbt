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
pub struct Handle[T] {
  id : Int
  phantom : T?
}

///|
pub struct AssetId[T] {
  id : Int
  phantom : T?
} derive(Eq, Show)

///|
pub fn[T] AssetId::new(id : Int) -> AssetId[T] {
  AssetId::{ id, phantom: None }
}

///|
pub fn[T] AssetId::index(self : AssetId[T]) -> Int {
  self.id
}

///|
pub fn[T] Handle::new(id : Int) -> Handle[T] {
  Handle::{ id, phantom: None }
}

///|
pub fn[T] Handle::id(self : Handle[T]) -> Int {
  self.id
}

///|
pub fn[T] Handle::asset_id(self : Handle[T]) -> AssetId[T] {
  AssetId::new(self.id)
}

///|
pub fn[T] Handle::from_asset_id(asset_id : AssetId[T]) -> Handle[T] {
  Handle::new(asset_id.index())
}

///|
pub struct Image {
  width : Int
  height : Int
  pixels : Bytes
}

///|
pub fn Image::new(width : Int, height : Int, pixels : Bytes) -> Image {
  Image::{ width, height, pixels }
}

///|
pub struct Shader {
  source : String
}

///|
pub fn Shader::new(source : String) -> Shader {
  Shader::{ source, }
}

///|
pub struct Blob {}

///|
pub struct AssetServer {
  paths : Array[String]
}

///|
pub(all) enum ImageArrayLayout {
  RowCount(Int)
  RowHeight(Int)
}

///|
pub struct ImageLoaderSettings {
  sampler : ImageSampler
  is_srgb : Bool
  array_layout : ImageArrayLayout?
}

///|
pub fn ImageLoaderSettings::default() -> ImageLoaderSettings {
  ImageLoaderSettings::{
    sampler: ImageSampler::Linear,
    is_srgb: true,
    array_layout: None,
  }
}

///|
pub fn ImageLoaderSettings::with_sampler(
  self : ImageLoaderSettings,
  sampler : ImageSampler,
) -> ImageLoaderSettings {
  ImageLoaderSettings::{ ..self, sampler, }
}

///|
pub fn ImageLoaderSettings::with_is_srgb(
  self : ImageLoaderSettings,
  is_srgb : Bool,
) -> ImageLoaderSettings {
  ImageLoaderSettings::{ ..self, is_srgb, }
}

///|
pub fn ImageLoaderSettings::with_array_layout(
  self : ImageLoaderSettings,
  array_layout : ImageArrayLayout?,
) -> ImageLoaderSettings {
  ImageLoaderSettings::{ ..self, array_layout, }
}

///|
pub const COMPRESSED_IMAGE_FORMAT_NONE : Int = 0

///|
pub const COMPRESSED_IMAGE_FORMAT_ASTC_LDR : Int = 1

///|
pub const COMPRESSED_IMAGE_FORMAT_BC : Int = 2

///|
pub const COMPRESSED_IMAGE_FORMAT_ETC2 : Int = 4

///|
pub const IMAGE_USAGE_TEXTURE_BINDING : Int = 1

///|
pub const IMAGE_USAGE_COPY_DST : Int = 2

///|
pub const IMAGE_USAGE_COPY_SRC : Int = 4

///|
pub const IMAGE_USAGE_RENDER_ATTACHMENT : Int = 8

///|
const IMAGE_USAGE_ALL_MASK : Int = 15

///|
const IMAGE_USAGE_DEFAULT_SAMPLED : Int = 3

///|
const IMAGE_USAGE_DEFAULT_DYNAMIC : Int = 15

///|
pub fn AssetServer::new() -> AssetServer {
  AssetServer::{ paths: [] }
}

///|
let asset_image_paths : Ref[Array[(String, Handle[Image])]] = Ref::new([])

///|
let asset_image_array_layouts : Ref[Array[(Int, ImageArrayLayout)]] = Ref::new([])

///|
let asset_image_srgb_settings : Ref[Array[(Int, Bool)]] = Ref::new([])

///|
let asset_image_usage_settings : Ref[Array[(Int, Int)]] = Ref::new([])

///|
fn asset_register_image_path(path : String, handle : Handle[Image]) -> Unit {
  asset_image_paths.val.push((path, handle))
}

///|
fn asset_set_image_array_layout(
  image : Handle[Image],
  array_layout : ImageArrayLayout?,
) -> Unit {
  let next : Array[(Int, ImageArrayLayout)] = []
  for pair in asset_image_array_layouts.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  if array_layout is Some(layout) {
    next.push((image.id(), layout))
  }
  asset_image_array_layouts.val = next
}

///|
fn asset_set_image_is_srgb(image : Handle[Image], is_srgb : Bool) -> Unit {
  let next : Array[(Int, Bool)] = []
  for pair in asset_image_srgb_settings.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  next.push((image.id(), is_srgb))
  asset_image_srgb_settings.val = next
}

///|
fn asset_image_usage_sanitize(usage_bits : Int) -> Int {
  let usage = usage_bits.reinterpret_as_uint()
  let mask = IMAGE_USAGE_ALL_MASK.reinterpret_as_uint()
  (usage & mask).reinterpret_as_int()
}

///|
fn asset_set_image_usage_bits(image : Handle[Image], usage_bits : Int) -> Unit {
  let safe_usage_bits = asset_image_usage_sanitize(usage_bits)
  let next : Array[(Int, Int)] = []
  for pair in asset_image_usage_settings.val {
    if pair.0 != image.id() {
      next.push(pair)
    }
  }
  next.push((image.id(), safe_usage_bits))
  asset_image_usage_settings.val = next
}

///|
pub fn asset_image_array_layout(image : Handle[Image]) -> ImageArrayLayout? {
  for pair in asset_image_array_layouts.val {
    if pair.0 == image.id() {
      return Some(pair.1)
    }
  }
  None
}

///|
pub fn asset_image_is_srgb(image : Handle[Image]) -> Bool {
  for pair in asset_image_srgb_settings.val {
    if pair.0 == image.id() {
      return pair.1
    }
  }
  true
}

///|
pub fn asset_image_usage_bits(image : Handle[Image]) -> Int {
  for pair in asset_image_usage_settings.val {
    if pair.0 == image.id() {
      return pair.1
    }
  }
  IMAGE_USAGE_DEFAULT_SAMPLED
}

///|
pub fn asset_image_set_usage_bits(
  image : Handle[Image],
  usage_bits : Int,
) -> Unit {
  asset_set_image_usage_bits(image, usage_bits)
}

///|
pub fn asset_image_add_usage(image : Handle[Image], usage_bits : Int) -> Unit {
  let current = asset_image_usage_bits(image).reinterpret_as_uint()
  let add = asset_image_usage_sanitize(usage_bits).reinterpret_as_uint()
  let next = (current | add).reinterpret_as_int()
  asset_set_image_usage_bits(image, next)
}

///|
pub fn asset_image_remove_usage(
  image : Handle[Image],
  usage_bits : Int,
) -> Unit {
  let current = asset_image_usage_bits(image).reinterpret_as_uint()
  let remove = asset_image_usage_sanitize(usage_bits).reinterpret_as_uint()
  let next = (current & (IMAGE_USAGE_ALL_MASK.reinterpret_as_uint() ^ remove))
    .reinterpret_as_int()
  asset_set_image_usage_bits(image, next)
}

///|
pub fn asset_image_has_usage(
  image : Handle[Image],
  usage_bits : Int,
) -> Bool {
  let current = asset_image_usage_bits(image).reinterpret_as_uint()
  let required = asset_image_usage_sanitize(usage_bits).reinterpret_as_uint()
  (current & required) == required
}

///|
pub fn AssetServer::get_handle(
  _self : AssetServer,
  path : String,
) -> Handle[Image]? {
  let count = asset_image_paths.val.length()
  for i in 0..<count {
    let entry = asset_image_paths.val[i]
    if entry.0 == path {
      return Some(entry.1)
    }
  }
  None
}

///|
let asset_default_nearest : Ref[Bool] = Ref::new(false)

///|
pub fn asset_set_default_sampler_nearest(enabled : Bool) -> Unit {
  asset_default_nearest.val = enabled
}

///|
let asset_transparent_texture_handle : Ref[Handle[Image]?] = Ref::new(None)

///|
/// Returns a lazily-created 1x1 fully transparent texture handle.
///
/// This is used to match Bevy's `TRANSPARENT_IMAGE_HANDLE` behavior in widgets
/// (e.g. `ImageNode::default()`).
pub fn asset_transparent_texture() -> Handle[Image] {
  match asset_transparent_texture_handle.val {
    Some(h) => h
    None => {
      let size = @math.UVec2::new(1, 1)
      let handle = asset_create_dynamic_texture(size, false)
      let rect = @math.URect::new(
        @math.UVec2::new(0, 0),
        @math.UVec2::new(1, 1),
      )
      // moonbitlang/parser may not accept method calls on integer literals.
      let u : Int = 0
      let b : Byte = u.to_byte()
      let bytes = Bytes::from_array([b, b, b, b])
      asset_update_texture_region_rgba8(handle, rect, bytes)
      asset_transparent_texture_handle.val = Some(handle)
      handle
    }
  }
}

///|
let asset_white_texture_handle : Ref[Handle[Image]?] = Ref::new(None)

///|
/// Returns a lazily-created 1x1 opaque white texture handle.
pub fn asset_white_texture() -> Handle[Image] {
  match asset_white_texture_handle.val {
    Some(h) => h
    None => {
      let size = @math.UVec2::new(1, 1)
      let handle = asset_create_dynamic_texture(size, false)
      let rect = @math.URect::new(
        @math.UVec2::new(0, 0),
        @math.UVec2::new(1, 1),
      )
      let white_u : Int = 255
      let white_b : Byte = white_u.to_byte()
      let bytes = Bytes::from_array([white_b, white_b, white_b, white_b])
      asset_update_texture_region_rgba8(handle, rect, bytes)
      asset_white_texture_handle.val = Some(handle)
      handle
    }
  }
}

///|
pub fn host_asset_load_texture(path~ : String, nearest~ : Bool) -> Int {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_load_texture_id(path_id~, nearest~)
  })
}

///|
fn host_asset_load_texture_id(path_id~ : Int, nearest~ : Bool) -> Int = "mgstudio_host" "asset_load_texture"

///|
pub fn host_asset_load_texture_bytes(bytes_id~ : Int, nearest~ : Bool) -> Int = "mgstudio_host" "asset_load_texture_bytes"

///|
pub fn host_asset_load_wgsl(path~ : String) -> Int {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_load_wgsl_id(path_id)
  })
}

///|
fn host_asset_load_wgsl_id(path_id : Int) -> Int = "mgstudio_host" "asset_load_wgsl"

///|
pub fn host_asset_load_bytes(path~ : String) -> Int {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_load_bytes_id(path_id)
  })
}

///|
fn host_asset_load_bytes_id(path_id : Int) -> Int = "mgstudio_host" "asset_load_bytes"

///|
pub fn host_asset_bytes_len(blob_id : Int) -> Int = "mgstudio_host" "asset_bytes_len"

///|
pub fn host_asset_bytes_get_u32(blob_id~ : Int, index~ : Int) -> Int = "mgstudio_host" "asset_bytes_get_u32"

///|
pub fn host_asset_create_dynamic_texture(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int = "mgstudio_host" "asset_create_dynamic_texture"

///|
pub fn host_asset_create_dynamic_texture_mipped(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int = "mgstudio_host" "asset_create_dynamic_texture_mipped"

///|
pub fn host_asset_update_texture_region(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  glyph_id~ : Int,
) -> Unit = "mgstudio_host" "asset_update_texture_region"

///|
pub fn host_asset_update_texture_region_bytes(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  bytes_id~ : Int,
) -> Unit = "mgstudio_host" "asset_update_texture_region_bytes"

///|
pub fn host_asset_update_texture_region_mip_bytes(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  bytes_id~ : Int,
) -> Unit = "mgstudio_host" "asset_update_texture_region_mip_bytes"

///|
pub fn host_asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int = "mgstudio_host" "asset_create_texture_mip_view"

///|
pub fn host_asset_texture_width(texture_id : Int) -> Int = "mgstudio_host" "asset_texture_width"

///|
pub fn host_asset_texture_height(texture_id : Int) -> Int = "mgstudio_host" "asset_texture_height"

///|
pub fn host_asset_is_texture_loaded(texture_id : Int) -> Bool = "mgstudio_host" "asset_is_texture_loaded"

///|
pub fn host_asset_supported_compressed_image_formats() -> Int = "mgstudio_host" "asset_supported_compressed_image_formats"

///|
pub fn host_asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit = "mgstudio_host" "asset_copy_texture_to_texture"

///|
fn host_asset_save_texture_png_id(texture_id~ : Int, path_id~ : Int) -> Unit = "mgstudio_host" "asset_save_texture_png"

///|
pub fn AssetServer::load(self : AssetServer, path : String) -> Handle[Image] {
  let id = host_asset_load_texture(path~, nearest=asset_default_nearest.val)
  self.paths.push(path)
  let handle = Handle::new(id)
  asset_register_image_path(path, handle)
  asset_set_image_array_layout(handle, None)
  asset_set_image_is_srgb(handle, true)
  asset_set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_SAMPLED)
  handle
}

///|
pub fn AssetServer::load_nearest(
  self : AssetServer,
  path : String,
) -> Handle[Image] {
  let id = host_asset_load_texture(path~, nearest=true)
  self.paths.push(path)
  let handle = Handle::new(id)
  asset_register_image_path(path, handle)
  asset_set_image_array_layout(handle, None)
  asset_set_image_is_srgb(handle, true)
  asset_set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_SAMPLED)
  handle
}

///|
fn image_sampler_is_nearest(sampler : ImageSampler) -> Bool {
  match sampler {
    ImageSampler::Nearest => true
    ImageSampler::NearestRepeat => true
    _ => false
  }
}

///|
pub fn AssetServer::load_with_settings(
  self : AssetServer,
  path : String,
  settings : ImageLoaderSettings,
) -> Handle[Image] {
  let id = host_asset_load_texture(
    path~,
    nearest=image_sampler_is_nearest(settings.sampler),
  )
  self.paths.push(path)
  let handle = Handle::new(id)
  asset_register_image_path(path, handle)
  asset_set_texture_sampler(handle, settings.sampler)
  asset_set_image_array_layout(handle, settings.array_layout)
  asset_set_image_is_srgb(handle, settings.is_srgb)
  asset_set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_SAMPLED)
  handle
}

///|
pub fn AssetServer::load_texture_bytes(
  self : AssetServer,
  bytes : Bytes,
  nearest : Bool,
) -> Handle[Image] {
  self |> ignore
  let id = @core.with_host_bytes_id(bytes, fn(bytes_id) {
    host_asset_load_texture_bytes(bytes_id~, nearest~)
  })
  let handle = Handle::new(id)
  asset_set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_SAMPLED)
  handle
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  host_asset_supported_compressed_image_formats()
}

///|
pub fn asset_compressed_image_formats_contains(
  supported_formats : Int,
  required_format : Int,
) -> Bool {
  let required = required_format.reinterpret_as_uint()
  if required == COMPRESSED_IMAGE_FORMAT_NONE.reinterpret_as_uint() {
    return true
  }
  let supported = supported_formats.reinterpret_as_uint()
  (supported & required) == required
}

///|
pub fn AssetServer::load_wgsl(
  self : AssetServer,
  path : String,
) -> Handle[Shader] {
  let id = host_asset_load_wgsl(path~)
  self.paths.push(path)
  Handle::new(id)
}

///|
pub fn AssetServer::load_bytes(
  self : AssetServer,
  path : String,
) -> Handle[Blob] {
  let id = host_asset_load_bytes(path~)
  self.paths.push(path)
  Blob::{  } |> ignore
  Handle::new(id)
}

///|
pub fn asset_blob_read_bytes(blob : Handle[Blob]) -> Bytes? {
  let len = host_asset_bytes_len(blob.id())
  if len <= 0 {
    return None
  }
  let bytes : Array[Byte] = []
  let mut i = 0
  while i < len {
    let u = host_asset_bytes_get_u32(blob_id=blob.id(), index=i).reinterpret_as_uint()
    bytes.push((u & 0xFFU).reinterpret_as_int().to_byte())
    if i + 1 < len {
      bytes.push(((u >> 8) & 0xFFU).reinterpret_as_int().to_byte())
    }
    if i + 2 < len {
      bytes.push(((u >> 16) & 0xFFU).reinterpret_as_int().to_byte())
    }
    if i + 3 < len {
      bytes.push(((u >> 24) & 0xFFU).reinterpret_as_int().to_byte())
    }
    i = i + 4
  }
  Some(Bytes::from_array(bytes))
}

///|
pub fn asset_blob_read_text(blob : Handle[Blob]) -> String? {
  guard asset_blob_read_bytes(blob) is Some(bytes) else { return None }
  let chars : Array[Char] = []
  for byte in bytes {
    let code = byte.to_int() & 0xFF
    if code.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
pub fn asset_create_dynamic_texture(
  size : @math.UVec2,
  nearest : Bool,
) -> Handle[Image] {
  asset_create_dynamic_texture_with_mips(size, 1, nearest)
}

///|
pub fn asset_create_dynamic_texture_with_mips(
  size : @math.UVec2,
  mip_level_count : Int,
  nearest : Bool,
) -> Handle[Image] {
  let safe_mip_level_count = if mip_level_count <= 0 {
    1
  } else {
    mip_level_count
  }
  let id = host_asset_create_dynamic_texture_mipped(
    width=size.x,
    height=size.y,
    mip_level_count=safe_mip_level_count,
    nearest~,
  )
  let handle = Handle::new(id)
  asset_set_image_usage_bits(handle, IMAGE_USAGE_DEFAULT_DYNAMIC)
  handle
}

///|
pub fn asset_update_texture_region(
  texture : Handle[Image],
  rect : @math.URect,
  glyph_id : Int,
) -> Unit {
  let size = rect.size()
  host_asset_update_texture_region(
    texture_id=texture.id(),
    x=rect.min.x,
    y=rect.min.y,
    width=size.x,
    height=size.y,
    glyph_id~,
  )
}

///|
pub fn asset_update_texture_region_rgba8(
  texture : Handle[Image],
  rect : @math.URect,
  pixels_rgba8 : Bytes,
) -> Unit {
  asset_update_texture_region_rgba8_mip(texture, rect, 0, pixels_rgba8)
}

///|
pub fn asset_update_texture_region_rgba8_mip(
  texture : Handle[Image],
  rect : @math.URect,
  mip_level : Int,
  pixels_rgba8 : Bytes,
) -> Unit {
  let size = rect.size()
  let safe_mip_level = if mip_level < 0 { 0 } else { mip_level }
  @core.with_host_bytes_id(pixels_rgba8, fn(bytes_id) {
    host_asset_update_texture_region_mip_bytes(
      texture_id=texture.id(),
      x=rect.min.x,
      y=rect.min.y,
      width=size.x,
      height=size.y,
      mip_level=safe_mip_level,
      bytes_id~,
    )
  })
  |> ignore
}

///|
pub fn asset_create_texture_mip_view(
  texture : Handle[Image],
  mip_level : Int,
) -> Handle[Image] {
  let safe_mip_level = if mip_level < 0 { 0 } else { mip_level }
  let id = host_asset_create_texture_mip_view(
    texture_id=texture.id(),
    mip_level=safe_mip_level,
  )
  let handle = Handle::new(id)
  asset_set_image_usage_bits(handle, asset_image_usage_bits(texture))
  handle
}

///|
pub fn asset_texture_width(texture : Handle[Image]) -> Int {
  host_asset_texture_width(texture.id())
}

///|
pub fn asset_texture_height(texture : Handle[Image]) -> Int {
  host_asset_texture_height(texture.id())
}

///|
pub fn asset_is_texture_loaded(texture : Handle[Image]) -> Bool {
  host_asset_is_texture_loaded(texture.id())
}

///|
pub fn asset_copy_texture_to_texture(
  dst : Handle[Image],
  dst_pos : @math.UVec2,
  src : Handle[Image],
) -> Unit {
  host_asset_copy_texture_to_texture(
    dst_texture_id=dst.id(),
    dst_x=dst_pos.x,
    dst_y=dst_pos.y,
    src_texture_id=src.id(),
  )
}

///|
pub fn asset_save_texture_png(texture : Handle[Image], path : String) -> Unit {
  @core.with_host_string_id(path, fn(path_id) {
    host_asset_save_texture_png_id(texture_id=texture.id(), path_id~)
  })
}

///|
pub fn[W] asset_system(_world : W) -> Unit {
  asset_update_loaded_folders()
}

///|
pub fn[W] asset_plugin(app : @app.App[W]) -> @app.App[W] {
  app.add_pre_update_system(asset_system)
}

///|
pub fn[W] asset_plugin_nearest(app : @app.App[W]) -> @app.App[W] {
  asset_set_default_sampler_nearest(true)
  app.add_pre_update_system(asset_system)
}
