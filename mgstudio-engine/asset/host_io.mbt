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
priv struct BlobRecord {
  id : Int
  bytes : Bytes
}

///|
priv struct FolderRecord {
  id : Int
  virtual_path : String
  source_name : String?
  relative_path : String
  absolute_path : String
  entries : Array[FolderEntry]
}

///|
priv struct FolderEntry {
  relative_path : String
  fingerprint : Int
  handle_id : Int
}

///|
priv struct FolderEvent {
  kind : Int
  folder_id : Int
}

///|
let next_id_ref : Ref[Int] = Ref::new(1)

///|
let blobs_ref : Ref[Array[BlobRecord]] = Ref::new([])

///|
let texture_pixels_ref : Ref[Array[BlobRecord]] = Ref::new([])

///|
let fonts_ref : Ref[Array[BlobRecord]] = Ref::new([])

///|
let folders_ref : Ref[Array[FolderRecord]] = Ref::new([])

///|
let folder_events_ref : Ref[Array[FolderEvent]] = Ref::new([])

///|
let pending_folder_event_ref : Ref[FolderEvent?] = Ref::new(None)

///|
const DEFAULT_ASSETS_DIR : String = "./assets"

///|
let assets_dir_override_ref : Ref[String?] = Ref::new(None)

///|
let asset_source_dir_overrides_ref : Ref[@hashmap.HashMap[String, String]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let asset_source_readers_ref : Ref[@hashmap.HashMap[String, AssetReader]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let embedded_assets_ref : Ref[@hashmap.HashMap[String, Bytes]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
const DEFAULT_DATA_DIR : String = "./tmp/data"

///|
const LOADER_KIND_TEXTURE : Int = 0

///|
const LOADER_KIND_WGSL : Int = 1

///|
const LOADER_KIND_BYTES : Int = 2

///|
const LOADER_KIND_FONT : Int = 3

///|
const LOADER_KIND_FOLDER : Int = 4

///|
priv struct Ktx2TexturePayload {
  width : Int
  height : Int
  depth : Int
  format_raw : Int
  pixels : Bytes
}

///|
priv struct Ktx2Texture2dPayload {
  width : Int
  height : Int
  is_cube : Bool
  slice_count : Int
  format_raw : Int
  levels : Array[Bytes]
}

///|
priv struct Ktx2FormatInfo {
  format_raw : Int
  block_width : Int
  block_height : Int
  block_bytes : Int
}

///|
const KTX2_HEADER_SIZE : Int = 80

///|
const KTX2_LEVEL_INDEX_STRIDE : Int = 24

///|
const KTX2_SUPERCOMPRESSION_NONE : Int = 0

///|
const KTX2_SUPERCOMPRESSION_ZSTD : Int = 2

///|
const KTX2_VK_FORMAT_R16G16B16A16_SFLOAT : Int = 97

///|
const KTX2_VK_FORMAT_E5B9G9R9_UFLOAT_PACK32 : Int = 123

///|
const KTX2_VK_FORMAT_BC7_UNORM_BLOCK : Int = 145

///|
const KTX2_VK_FORMAT_BC7_SRGB_BLOCK : Int = 146

///|
const KTX2_VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK : Int = 147

///|
const KTX2_VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK : Int = 148

///|
const KTX2_VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK : Int = 149

///|
const KTX2_VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK : Int = 150

///|
const KTX2_VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK : Int = 151

///|
const KTX2_VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK : Int = 152

///|
const KTX2_VK_FORMAT_ASTC_4X4_UNORM_BLOCK : Int = 157

///|
const KTX2_VK_FORMAT_ASTC_4X4_SRGB_BLOCK : Int = 158

///|
const WGPU_TEXTURE_FORMAT_RGB9_E5_UFLOAT : Int = 0x1C

///|
const WGPU_TEXTURE_FORMAT_RGBA16_FLOAT : Int = 0x22

///|
const WGPU_TEXTURE_FORMAT_BC7_RGBA_UNORM : Int = 0x38

///|
const WGPU_TEXTURE_FORMAT_BC7_RGBA_UNORM_SRGB : Int = 0x39

///|
const WGPU_TEXTURE_FORMAT_ETC2_RGB8_UNORM : Int = 0x3A

///|
const WGPU_TEXTURE_FORMAT_ETC2_RGB8_UNORM_SRGB : Int = 0x3B

///|
const WGPU_TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM : Int = 0x3C

///|
const WGPU_TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM_SRGB : Int = 0x3D

///|
const WGPU_TEXTURE_FORMAT_ETC2_RGBA8_UNORM : Int = 0x3E

///|
const WGPU_TEXTURE_FORMAT_ETC2_RGBA8_UNORM_SRGB : Int = 0x3F

///|
const WGPU_TEXTURE_FORMAT_ASTC4X4_UNORM : Int = 0x44

///|
const WGPU_TEXTURE_FORMAT_ASTC4X4_UNORM_SRGB : Int = 0x45

///|
let loader_extensions_ref : Ref[Array[(String, Int)]] = Ref::new([
  ("png", LOADER_KIND_TEXTURE),
  ("jpg", LOADER_KIND_TEXTURE),
  ("jpeg", LOADER_KIND_TEXTURE),
  ("bmp", LOADER_KIND_TEXTURE),
  ("tga", LOADER_KIND_TEXTURE),
  ("ktx2", LOADER_KIND_TEXTURE),
  ("wgsl", LOADER_KIND_WGSL),
  ("ttf", LOADER_KIND_FONT),
  ("otf", LOADER_KIND_FONT),
])

///|
fn clamp_dim(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn env_or_default(key : String, default_value : String) -> String {
  match @sys.get_env_var(key) {
    Some(value) if value.length() > 0 => value
    _ => default_value
  }
}

///|
fn default_runtime_assets_dir() -> String {
  env_or_default("MGSTUDIO_ASSETS_DIR", DEFAULT_ASSETS_DIR)
}

///|
fn runtime_assets_dir() -> String {
  match assets_dir_override_ref.val {
    Some(path) if path.length() > 0 => path
    _ => default_runtime_assets_dir()
  }
}

///|
fn runtime_data_dir() -> String {
  env_or_default("MGSTUDIO_DATA_DIR", DEFAULT_DATA_DIR)
}

///|
fn path_join(lhs : String, rhs : String) -> String {
  @path.Path::join(lhs, rhs).normalize().to_string()
}

///|
fn set_runtime_assets_dir_override(path : String?) -> Unit {
  match path {
    Some(value) if value.trim().to_string() != "" =>
      assets_dir_override_ref.val = Some(
        @path.Path::normalize(value).to_string(),
      )
    _ => assets_dir_override_ref.val = None
  }
}

///|
fn set_runtime_asset_source_dir_overrides(
  entries : Array[(String, String)],
) -> Unit {
  let next = @hashmap.HashMap::new()
  for entry in entries {
    next.set(entry.0, entry.1)
  }
  asset_source_dir_overrides_ref.val = next
}

///|
fn asset_source_reader_key(source_name : String?) -> String {
  match source_name {
    Some(name) => name
    None => ""
  }
}

///|
fn asset_source_reader_source_name(source_id : AssetSourceId) -> String? {
  match source_id {
    AssetSourceId::Default => None
    AssetSourceId::Named(name) => Some(name)
  }
}

///|
fn default_asset_source_reader(source_id : AssetSourceId) -> AssetReader {
  let source_name = asset_source_reader_source_name(source_id)
  AssetReader::new(
    fn(path) {
      let virtual_path = compose_virtual_asset_path(source_name, path, None)
      if embedded_asset_bytes(virtual_path) is Some(bytes) {
        return Some(bytes)
      }
      if resolve_asset_input_path(virtual_path) is Some(input_path) {
        return read_file_bytes(input_path)
      }
      None
    },
    fn(path) {
      let virtual_path = compose_virtual_asset_path(source_name, path, None)
      let meta_path = virtual_path + ".meta"
      if embedded_asset_bytes(meta_path) is Some(bytes) {
        return Some(bytes)
      }
      if resolve_asset_input_path(meta_path) is Some(input_path) {
        return read_file_bytes(input_path)
      }
      None
    },
    fn(path) {
      let virtual_path = compose_virtual_asset_path(source_name, path, None)
      let absolute_path = resolve_asset_path(virtual_path)
      if path_is_dir(absolute_path) {
        Some(sorted_directory_entries(absolute_path))
      } else {
        None
      }
    },
    fn(path) {
      let virtual_path = compose_virtual_asset_path(source_name, path, None)
      let absolute_path = resolve_asset_path(virtual_path)
      path_is_dir(absolute_path)
    },
  )
}

///|
fn set_runtime_asset_source_readers(
  entries : Array[(AssetSourceId, AssetSourceBuilder)],
) -> Unit {
  let next = @hashmap.HashMap::new()
  for entry in entries {
    guard entry.1.reader_builder is Some(reader_builder) else { continue }
    let source_id = entry.0
    let reader = reader_builder(default_asset_source_reader(source_id))
    next.set(
      asset_source_reader_key(asset_source_reader_source_name(source_id)),
      reader,
    )
  }
  asset_source_readers_ref.val = next
}

///|
fn asset_source_reader_for_path(path : String) -> AssetReader? {
  let parsed = parse_virtual_asset_path(path)
  asset_source_readers_ref.val.get(asset_source_reader_key(parsed.source_name))
}

///|
fn resolve_assets_dir_override(path : String?) -> String? {
  match path {
    Some(value) if value.trim().to_string() != "" => {
      let trimmed = value.trim().to_string()
      if @path.Path::is_absolute(trimmed) {
        Some(@path.Path::normalize(trimmed).to_string())
      } else {
        Some(path_join(default_runtime_assets_dir(), trimmed))
      }
    }
    _ => None
  }
}

///|
fn path_is_file(path : String) -> Bool {
  @fs.is_file(path) catch {
    _ => false
  }
}

///|
fn path_is_dir(path : String) -> Bool {
  @fs.is_dir(path) catch {
    _ => false
  }
}

///|
priv struct ParsedVirtualAssetPath {
  source_name : String?
  relative_path : String
}

///|
fn parse_virtual_asset_path(path : String) -> ParsedVirtualAssetPath {
  let hash_index = string_last_index_of_char(path, 35)
  let without_label = if hash_index >= 0 {
    let base = if hash_index > 0 { path[0:hash_index].to_string() } else { "" }
    base
  } else {
    path
  }
  let scheme_index = string_find_substring(without_label, "://")
  if scheme_index > 0 {
    let source_name = without_label[0:scheme_index].to_string()
    let relative_path = if scheme_index + 3 < without_label.length() {
      without_label[scheme_index + 3:without_label.length()].to_string()
    } else {
      ""
    }
    ParsedVirtualAssetPath::{ source_name: Some(source_name), relative_path }
  } else {
    ParsedVirtualAssetPath::{ source_name: None, relative_path: without_label }
  }
}

///|
fn compose_virtual_asset_path(
  source_name : String?,
  relative_path : String,
  label : String?,
) -> String {
  let prefix = match source_name {
    Some(name) if name.length() > 0 => name + "://" + relative_path
    _ => relative_path
  }
  match label {
    Some(label) if label.length() > 0 => prefix + "#" + label
    _ => prefix
  }
}

///|
fn canonical_virtual_asset_path(path : String) -> String {
  let parsed = parse_virtual_asset_path(path)
  compose_virtual_asset_path(parsed.source_name, parsed.relative_path, None)
}

///|
fn register_embedded_asset_bytes(path : String, bytes : Bytes) -> Unit {
  embedded_assets_ref.val.set(canonical_virtual_asset_path(path), bytes)
}

///|
fn embedded_asset_bytes(path : String) -> Bytes? {
  embedded_assets_ref.val.get(canonical_virtual_asset_path(path))
}

///|
fn source_env_suffix(source_name : String) -> String {
  let chars : Array[Char] = []
  for i in 0..<source_name.length() {
    let code = source_name.code_unit_at(i)
    let mapped = if code >= 97 && code <= 122 {
      code - 32
    } else if (code >= 65 && code <= 90) || (code >= 48 && code <= 57) {
      code
    } else {
      95
    }
    chars.push(Int::unsafe_to_char(mapped.to_int()))
  }
  String::from_array(chars)
}

///|
fn source_root_dir(source_name : String?) -> String {
  match source_name {
    Some(name) if name.length() > 0 => {
      if asset_source_dir_overrides_ref.val.get(name) is Some(override_root) {
        return override_root
      }
      let env_key = "MGSTUDIO_ASSET_SOURCE_" + source_env_suffix(name) + "_DIR"
      let default_root = path_join(runtime_assets_dir(), name)
      env_or_default(env_key, default_root)
    }
    _ => runtime_assets_dir()
  }
}

///|
fn resolve_asset_path(path : String) -> String {
  let parsed = parse_virtual_asset_path(path)
  if @path.Path::is_absolute(parsed.relative_path) {
    @path.Path::normalize(parsed.relative_path).to_string()
  } else {
    path_join(source_root_dir(parsed.source_name), parsed.relative_path)
  }
}

///|
fn resolve_output_path(path : String) -> String {
  if @path.Path::is_absolute(path) {
    @path.Path::normalize(path).to_string()
  } else {
    path_join(runtime_data_dir(), path)
  }
}

///|
fn resolve_asset_fallback_path(path : String) -> String? {
  let parsed = parse_virtual_asset_path(path)
  if parsed.source_name is Some(_) ||
    @path.Path::is_absolute(parsed.relative_path) {
    return None
  }
  let default_root = default_runtime_assets_dir()
  let current_root = runtime_assets_dir()
  if default_root == current_root {
    return None
  }
  let fallback = path_join(default_root, parsed.relative_path)
  if path_is_file(fallback) {
    Some(fallback)
  } else {
    None
  }
}

///|
fn resolve_asset_input_path(path : String) -> String? {
  let resolved = resolve_asset_path(path)
  if path_is_file(resolved) {
    return Some(resolved)
  }
  if resolve_asset_fallback_path(path) is Some(fallback) {
    return Some(fallback)
  }
  None
}

///|
fn read_file_bytes(path : String) -> Bytes? {
  Some(@fs.read_file_to_bytes(path)) catch {
    _ => None
  }
}

///|
fn load_asset_file_bytes(path : String) -> Bytes {
  if asset_source_reader_for_path(path) is Some(reader) {
    let parsed = parse_virtual_asset_path(path)
    if reader.read(parsed.relative_path) is Some(bytes) {
      return bytes
    }
    return Bytes::makei(0, _ => (0).to_byte())
  }
  if embedded_asset_bytes(path) is Some(bytes) {
    return bytes
  }
  if resolve_asset_input_path(path) is Some(input_path) {
    if read_file_bytes(input_path) is Some(bytes) {
      return bytes
    }
  }
  Bytes::makei(0, _ => (0).to_byte())
}

///|
fn next_id() -> Int {
  let id = next_id_ref.val
  next_id_ref.val = next_id_ref.val + 1
  id
}

///|
fn register_texture_with_id(
  id : Int,
  width : Int,
  height : Int,
  loaded : Bool,
) -> Int {
  width |> ignore
  height |> ignore
  loaded |> ignore
  id
}

///|
fn find_blob(records : Array[BlobRecord], blob_id : Int) -> BlobRecord? {
  for record in records {
    if record.id == blob_id {
      return Some(record)
    }
  }
  None
}

///|
fn set_texture_pixels(texture_id : Int, bytes : Bytes) -> Unit {
  for i in 0..<texture_pixels_ref.val.length() {
    if texture_pixels_ref.val[i].id == texture_id {
      texture_pixels_ref.val[i] = BlobRecord::{ id: texture_id, bytes }
      return
    }
  }
  texture_pixels_ref.val.push(BlobRecord::{ id: texture_id, bytes })
}

///|
fn texture_pixels(texture_id : Int) -> Bytes? {
  if find_blob(texture_pixels_ref.val, texture_id) is Some(record) {
    Some(record.bytes)
  } else {
    None
  }
}

///|
fn normalize_rgba8(bytes : Bytes, expected_len : Int) -> Bytes {
  let safe_len = if expected_len <= 0 { 0 } else { expected_len }
  if safe_len == bytes.length() {
    return bytes
  }
  Bytes::makei(safe_len, i => {
    match bytes.get(i) {
      Some(value) => value
      None => (0).to_byte()
    }
  })
}

///|
fn rgba8_len(width : Int, height : Int) -> Int {
  let w = clamp_dim(width)
  let h = clamp_dim(height)
  w * h * 4
}

///|
fn expand_alpha_mask(alpha_mask : Bytes, width : Int, height : Int) -> Bytes {
  let pixel_count = clamp_dim(width) * clamp_dim(height)
  Bytes::makei(pixel_count * 4, i => {
    let channel = i % 4
    if channel == 3 {
      match alpha_mask.get(i / 4) {
        Some(value) => value
        None => (0).to_byte()
      }
    } else {
      (255).to_byte()
    }
  })
}

///|
fn source_bytes_to_rgba8(bytes : Bytes, width : Int, height : Int) -> Bytes {
  let expected = rgba8_len(width, height)
  let alpha_len = clamp_dim(width) * clamp_dim(height)
  if bytes.length() == alpha_len {
    return expand_alpha_mask(bytes, width, height)
  }
  normalize_rgba8(bytes, expected)
}

///|
fn patch_texture_pixels(
  base_rgba8 : Bytes,
  base_width : Int,
  base_height : Int,
  dst_x : Int,
  dst_y : Int,
  src_width : Int,
  src_height : Int,
  src_rgba8 : Bytes,
) -> Bytes {
  let safe_base_width = clamp_dim(base_width)
  let safe_base_height = clamp_dim(base_height)
  let safe_src_width = clamp_dim(src_width)
  let safe_src_height = clamp_dim(src_height)
  let expected_base_len = rgba8_len(safe_base_width, safe_base_height)
  let base = normalize_rgba8(base_rgba8, expected_base_len)
  let src = normalize_rgba8(
    source_bytes_to_rgba8(src_rgba8, safe_src_width, safe_src_height),
    rgba8_len(safe_src_width, safe_src_height),
  )

  let src_offset_x = if dst_x < 0 { 0 - dst_x } else { 0 }
  let src_offset_y = if dst_y < 0 { 0 - dst_y } else { 0 }
  let write_x = if dst_x < 0 { 0 } else { dst_x }
  let write_y = if dst_y < 0 { 0 } else { dst_y }
  let write_width = {
    let a = safe_src_width - src_offset_x
    let b = safe_base_width - write_x
    if a < b {
      a
    } else {
      b
    }
  }
  let write_height = {
    let a = safe_src_height - src_offset_y
    let b = safe_base_height - write_y
    if a < b {
      a
    } else {
      b
    }
  }
  if write_width <= 0 || write_height <= 0 {
    return base
  }

  let base_stride = safe_base_width * 4
  let src_stride = safe_src_width * 4
  Bytes::makei(expected_base_len, i => {
    let pixel_y = i / base_stride
    let within_row = i % base_stride
    let pixel_x = within_row / 4
    let channel = within_row % 4
    if pixel_x >= write_x &&
      pixel_x < write_x + write_width &&
      pixel_y >= write_y &&
      pixel_y < write_y + write_height {
      let src_x = src_offset_x + (pixel_x - write_x)
      let src_y = src_offset_y + (pixel_y - write_y)
      let src_index = src_y * src_stride + src_x * 4 + channel
      match src.get(src_index) {
        Some(value) => value
        None => (0).to_byte()
      }
    } else {
      match base.get(i) {
        Some(value) => value
        None => (0).to_byte()
      }
    }
  })
}

///|
fn blob_u8_at(bytes : Bytes, index : Int) -> Int {
  if index < 0 {
    return 0
  }
  match bytes.get(index) {
    Some(value) => value.to_int() & 0xFF
    None => 0
  }
}

///|
fn blob_u32_at(bytes : Bytes, index : Int) -> Int {
  let b0 = blob_u8_at(bytes, index)
  let b1 = blob_u8_at(bytes, index + 1)
  let b2 = blob_u8_at(bytes, index + 2)
  let b3 = blob_u8_at(bytes, index + 3)
  let word_u : UInt = (b0 & 0xFF).reinterpret_as_uint() |
    ((b1 & 0xFF).reinterpret_as_uint() << 8) |
    ((b2 & 0xFF).reinterpret_as_uint() << 16) |
    ((b3 & 0xFF).reinterpret_as_uint() << 24)
  word_u.reinterpret_as_int()
}

///|
fn blob_u64_at_as_int(bytes : Bytes, index : Int) -> Int {
  let low = blob_u32_at(bytes, index)
  let high = blob_u32_at(bytes, index + 4)
  if high != 0 || low < 0 {
    -1
  } else {
    low
  }
}

///|
fn bytes_slice_copy(bytes : Bytes, start : Int, len : Int) -> Bytes? {
  if start < 0 || len < 0 || start + len > bytes.length() {
    return None
  }
  Some(
    Bytes::makei(len, i => {
      match bytes.get(start + i) {
        Some(value) => value
        None => (0).to_byte()
      }
    }),
  )
}

///|
fn blob_u32_be_at(bytes : Bytes, index : Int) -> Int {
  let b0 = blob_u8_at(bytes, index)
  let b1 = blob_u8_at(bytes, index + 1)
  let b2 = blob_u8_at(bytes, index + 2)
  let b3 = blob_u8_at(bytes, index + 3)
  let word_u : UInt = ((b0 & 0xFF).reinterpret_as_uint() << 24) |
    ((b1 & 0xFF).reinterpret_as_uint() << 16) |
    ((b2 & 0xFF).reinterpret_as_uint() << 8) |
    (b3 & 0xFF).reinterpret_as_uint()
  word_u.reinterpret_as_int()
}

///|
priv struct DecodedTextureImage {
  width : Int
  height : Int
  pixels : Bytes
}

///|
fn is_png_bytes(bytes : Bytes) -> Bool {
  bytes.length() >= 8 &&
  blob_u8_at(bytes, 0) == 0x89 &&
  blob_u8_at(bytes, 1) == 0x50 &&
  blob_u8_at(bytes, 2) == 0x4E &&
  blob_u8_at(bytes, 3) == 0x47 &&
  blob_u8_at(bytes, 4) == 0x0D &&
  blob_u8_at(bytes, 5) == 0x0A &&
  blob_u8_at(bytes, 6) == 0x1A &&
  blob_u8_at(bytes, 7) == 0x0A
}

///|
fn is_jpeg_bytes(bytes : Bytes) -> Bool {
  bytes.length() >= 2 &&
  blob_u8_at(bytes, 0) == 0xFF &&
  blob_u8_at(bytes, 1) == 0xD8
}

///|
fn is_bmp_bytes(bytes : Bytes) -> Bool {
  bytes.length() >= 2 &&
  blob_u8_at(bytes, 0) == 0x42 &&
  blob_u8_at(bytes, 1) == 0x4D
}

///|
fn decoded_texture_image_from_mizchi(
  decoded : @img_decode.ImageData,
) -> DecodedTextureImage {
  DecodedTextureImage::{
    width: clamp_dim(decoded.width),
    height: clamp_dim(decoded.height),
    pixels: decoded.data,
  }
}

///|
fn decoded_texture_image_from_gm_image(
  decoded : &@gm_image.Image,
) -> DecodedTextureImage {
  let bounds = decoded.bounds()
  let width = clamp_dim(bounds.dx())
  let height = clamp_dim(bounds.dy())
  let pixels = Array::make(rgba8_len(width, height), b'\x00')
  let mut out_index = 0
  for y in bounds.min.y..<bounds.max.y {
    for x in bounds.min.x..<bounds.max.x {
      let pixel = @gm_color.NRGBA::from(decoded.at(x, y))
      pixels[out_index] = pixel.r
      pixels[out_index + 1] = pixel.g
      pixels[out_index + 2] = pixel.b
      pixels[out_index + 3] = pixel.a
      out_index += 4
    }
  }
  DecodedTextureImage::{ width, height, pixels: Bytes::from_array(pixels) }
}

///|
fn decode_texture_image_from_gm_png(bytes : Bytes) -> DecodedTextureImage? {
  let reader = @gm_io.Buffer::from_bytes(bytes)
  match @gm_png.decode(reader) {
    (decoded, None) => Some(decoded_texture_image_from_gm_image(decoded))
    _ => None
  }
}

///|
fn decode_texture_image_from_mizchi_png(bytes : Bytes) -> DecodedTextureImage? {
  Some(decoded_texture_image_from_mizchi(@img_decode.decode_png(bytes))) catch {
    _ => None
  }
}

///|
const PNG_GM_DECODER_MAX_SAFE_PIXELS : Int = 1024 * 1024

///|
fn decode_texture_image(bytes : Bytes) -> DecodedTextureImage? {
  if is_png_bytes(bytes) {
    let prefer_mizchi = match png_dimensions(bytes) {
      Some((width, height)) => width * height >= PNG_GM_DECODER_MAX_SAFE_PIXELS
      None => false
    }
    if prefer_mizchi {
      return decode_texture_image_from_mizchi_png(bytes)
    }
    if decode_texture_image_from_gm_png(bytes) is Some(decoded) {
      return Some(decoded)
    }
    return decode_texture_image_from_mizchi_png(bytes)
  }
  if is_jpeg_bytes(bytes) {
    return Some(
      decoded_texture_image_from_mizchi(@img_decode.decode_jpeg(bytes)),
    ) catch {
      _ => None
    }
  }
  if is_bmp_bytes(bytes) {
    return Some(
      decoded_texture_image_from_mizchi(@img_decode.decode_bmp(bytes)),
    ) catch {
      _ => None
    }
  }
  None
}

///|
fn png_dimensions(bytes : Bytes) -> (Int, Int)? {
  if bytes.length() < 24 {
    return None
  }
  if blob_u8_at(bytes, 0) != 0x89 ||
    blob_u8_at(bytes, 1) != 0x50 ||
    blob_u8_at(bytes, 2) != 0x4E ||
    blob_u8_at(bytes, 3) != 0x47 ||
    blob_u8_at(bytes, 4) != 0x0D ||
    blob_u8_at(bytes, 5) != 0x0A ||
    blob_u8_at(bytes, 6) != 0x1A ||
    blob_u8_at(bytes, 7) != 0x0A ||
    blob_u8_at(bytes, 12) != 0x49 ||
    blob_u8_at(bytes, 13) != 0x48 ||
    blob_u8_at(bytes, 14) != 0x44 ||
    blob_u8_at(bytes, 15) != 0x52 {
    return None
  }
  Some(
    (clamp_dim(blob_u32_be_at(bytes, 16)), clamp_dim(blob_u32_be_at(bytes, 20))),
  )
}

///|
fn ktx2_dimensions(bytes : Bytes) -> (Int, Int)? {
  if bytes.length() < 28 {
    return None
  }
  if blob_u8_at(bytes, 0) != 0xAB ||
    blob_u8_at(bytes, 1) != 0x4B ||
    blob_u8_at(bytes, 2) != 0x54 ||
    blob_u8_at(bytes, 3) != 0x58 ||
    blob_u8_at(bytes, 4) != 0x20 ||
    blob_u8_at(bytes, 5) != 0x32 ||
    blob_u8_at(bytes, 6) != 0x30 ||
    blob_u8_at(bytes, 7) != 0xBB ||
    blob_u8_at(bytes, 8) != 0x0D ||
    blob_u8_at(bytes, 9) != 0x0A ||
    blob_u8_at(bytes, 10) != 0x1A ||
    blob_u8_at(bytes, 11) != 0x0A {
    return None
  }
  let width = blob_u32_at(bytes, 20)
  let height = blob_u32_at(bytes, 24)
  if width <= 0 || height <= 0 {
    return None
  } else {
    return Some((width, height))
  }
}

///|
fn ktx2_vulkan_format_info(vulkan_format : Int) -> Ktx2FormatInfo? {
  if vulkan_format == KTX2_VK_FORMAT_R16G16B16A16_SFLOAT {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_RGBA16_FLOAT,
      block_width: 1,
      block_height: 1,
      block_bytes: 8,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_E5B9G9R9_UFLOAT_PACK32 {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_RGB9_E5_UFLOAT,
      block_width: 1,
      block_height: 1,
      block_bytes: 4,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_BC7_UNORM_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_BC7_RGBA_UNORM,
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_BC7_SRGB_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_BC7_RGBA_UNORM_SRGB,
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ETC2_RGB8_UNORM,
      block_width: 4,
      block_height: 4,
      block_bytes: 8,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ETC2_RGB8_UNORM_SRGB,
      block_width: 4,
      block_height: 4,
      block_bytes: 8,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM,
      block_width: 4,
      block_height: 4,
      block_bytes: 8,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM_SRGB,
      block_width: 4,
      block_height: 4,
      block_bytes: 8,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ETC2_RGBA8_UNORM,
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ETC2_RGBA8_UNORM_SRGB,
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ASTC_4X4_UNORM_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ASTC4X4_UNORM,
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  if vulkan_format == KTX2_VK_FORMAT_ASTC_4X4_SRGB_BLOCK {
    return Some(Ktx2FormatInfo::{
      format_raw: WGPU_TEXTURE_FORMAT_ASTC4X4_UNORM_SRGB,
      block_width: 4,
      block_height: 4,
      block_bytes: 16,
    })
  }
  None
}

///|
fn ktx2_expected_level_bytes(
  format_info : Ktx2FormatInfo,
  width : Int,
  height : Int,
  slice_count : Int,
) -> Int? {
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let safe_slices = clamp_dim(slice_count)
  let blocks_w = (safe_width + format_info.block_width - 1) /
    format_info.block_width
  let blocks_h = (safe_height + format_info.block_height - 1) /
    format_info.block_height
  if blocks_w <= 0 || blocks_h <= 0 {
    return None
  }
  let bytes_per_slice = blocks_w * blocks_h * format_info.block_bytes
  if bytes_per_slice <= 0 {
    return None
  }
  let total = bytes_per_slice * safe_slices
  if total <= 0 {
    return None
  }
  Some(total)
}

///|
fn ktx2_decode_level_payload(
  bytes : Bytes,
  level_offset : Int,
  level_length : Int,
  level_uncompressed_length : Int,
  supercompression_scheme : Int,
) -> Bytes? {
  guard bytes_slice_copy(bytes, level_offset, level_length) is Some(raw_level) else {
    return None
  }
  if supercompression_scheme == KTX2_SUPERCOMPRESSION_NONE {
    return Some(raw_level)
  }
  if supercompression_scheme == KTX2_SUPERCOMPRESSION_ZSTD {
    let decoded = @zstd.decompress(raw_level) catch { _ => return None }
    if level_uncompressed_length > 0 &&
      decoded.length() != level_uncompressed_length {
      return None
    }
    return Some(decoded)
  }
  None
}

///|
fn ktx2_decode_uncompressed_3d_payload(bytes : Bytes) -> Ktx2TexturePayload? {
  if bytes.length() < KTX2_HEADER_SIZE {
    return None
  }
  let width = blob_u32_at(bytes, 20)
  let height = blob_u32_at(bytes, 24)
  let depth = blob_u32_at(bytes, 28)
  let level_count = blob_u32_at(bytes, 40)
  let supercompression_scheme = blob_u32_at(bytes, 44)
  if width <= 0 ||
    height <= 0 ||
    depth <= 1 ||
    level_count < 1 ||
    supercompression_scheme != 0 {
    return None
  }
  guard ktx2_vulkan_format_info(blob_u32_at(bytes, 12)) is Some(format_info) else {
    return None
  }
  let level0_offset = blob_u64_at_as_int(bytes, KTX2_HEADER_SIZE)
  let level0_length = blob_u64_at_as_int(bytes, KTX2_HEADER_SIZE + 8)
  if level0_offset < 0 || level0_length < 0 {
    return None
  }
  guard ktx2_expected_level_bytes(format_info, width, height, depth)
    is Some(expected_bytes) else {
    return None
  }
  if level0_length < expected_bytes {
    return None
  }
  guard bytes_slice_copy(bytes, level0_offset, expected_bytes) is Some(pixels) else {
    return None
  }
  Some(Ktx2TexturePayload::{
    width,
    height,
    depth,
    format_raw: format_info.format_raw,
    pixels,
  })
}

///|
fn ktx2_decode_2d_payload(bytes : Bytes) -> Ktx2Texture2dPayload? {
  if bytes.length() < KTX2_HEADER_SIZE {
    return None
  }
  let width = blob_u32_at(bytes, 20)
  let height = blob_u32_at(bytes, 24)
  let depth = blob_u32_at(bytes, 28)
  let layer_count_raw = blob_u32_at(bytes, 32)
  let face_count_raw = blob_u32_at(bytes, 36)
  let level_count = blob_u32_at(bytes, 40)
  let supercompression_scheme = blob_u32_at(bytes, 44)
  if width <= 0 ||
    height <= 0 ||
    depth > 1 ||
    level_count < 1 ||
    (
      supercompression_scheme != KTX2_SUPERCOMPRESSION_NONE &&
      supercompression_scheme != KTX2_SUPERCOMPRESSION_ZSTD
    ) {
    return None
  }
  let layer_count = if layer_count_raw <= 0 { 1 } else { layer_count_raw }
  let face_count = if face_count_raw <= 0 { 1 } else { face_count_raw }
  let is_cube = face_count > 1
  let slice_count = layer_count * face_count
  if slice_count <= 0 {
    return None
  }
  guard ktx2_vulkan_format_info(blob_u32_at(bytes, 12)) is Some(format_info) else {
    return None
  }
  let levels : Array[Bytes] = []
  for level_index in 0..<level_count {
    let entry_offset = KTX2_HEADER_SIZE + level_index * KTX2_LEVEL_INDEX_STRIDE
    let level_offset = blob_u64_at_as_int(bytes, entry_offset)
    let level_length = blob_u64_at_as_int(bytes, entry_offset + 8)
    let level_uncompressed_length = blob_u64_at_as_int(bytes, entry_offset + 16)
    if level_offset < 0 || level_length < 0 || level_uncompressed_length < 0 {
      return None
    }
    guard ktx2_decode_level_payload(
        bytes, level_offset, level_length, level_uncompressed_length, supercompression_scheme,
      )
      is Some(level_bytes) else {
      return None
    }
    let level_width = {
      let shifted = width >> level_index
      if shifted <= 0 {
        1
      } else {
        shifted
      }
    }
    let level_height = {
      let shifted = height >> level_index
      if shifted <= 0 {
        1
      } else {
        shifted
      }
    }
    guard ktx2_expected_level_bytes(
        format_info, level_width, level_height, slice_count,
      )
      is Some(expected_bytes) else {
      return None
    }
    if level_bytes.length() < expected_bytes {
      return None
    }
    if level_bytes.length() == expected_bytes {
      levels.push(level_bytes)
    } else {
      guard bytes_slice_copy(level_bytes, 0, expected_bytes) is Some(clipped) else {
        return None
      }
      levels.push(clipped)
    }
  }
  Some(Ktx2Texture2dPayload::{
    width,
    height,
    is_cube,
    slice_count,
    format_raw: format_info.format_raw,
    levels,
  })
}

///|
fn push_u16_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
}

///|
fn push_u32_be(out : Array[Byte], value : UInt) -> Unit {
  out.push(((value >> 24) & 0xFFU).to_byte())
  out.push(((value >> 16) & 0xFFU).to_byte())
  out.push(((value >> 8) & 0xFFU).to_byte())
  out.push((value & 0xFFU).to_byte())
}

///|
fn push_bytes(out : Array[Byte], bytes : Bytes) -> Unit {
  for i in 0..<bytes.length() {
    out.push(bytes[i])
  }
}

///|
fn ascii_bytes(text : String) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<text.length() {
    out.push(text.code_unit_at(i).to_byte())
  }
  Bytes::from_array(out)
}

///|
fn adler32(bytes : Bytes) -> UInt {
  let mut a = 1U
  let mut b = 0U
  for i in 0..<bytes.length() {
    a = (a + bytes[i].to_uint()) % 65521U
    b = (b + a) % 65521U
  }
  (b << 16) | a
}

///|
fn crc32(bytes : Bytes) -> UInt {
  let mut crc = 0xFFFFFFFFU
  for i in 0..<bytes.length() {
    let mut x = (crc ^ bytes[i].to_uint()) & 0xFFU
    for _ in 0..<8 {
      x = if (x & 1U) == 1U { 0xEDB88320U ^ (x >> 1) } else { x >> 1 }
    }
    crc = (crc >> 8) ^ x
  }
  crc ^ 0xFFFFFFFFU
}

///|
fn zlib_uncompressed(bytes : Bytes) -> Bytes {
  let out : Array[Byte] = [0x78U.to_byte(), 0x01U.to_byte()]
  let mut offset = 0
  while offset < bytes.length() {
    let remaining = bytes.length() - offset
    let block_len = if remaining > 65535 { 65535 } else { remaining }
    let is_last = offset + block_len >= bytes.length()
    out.push((if is_last { 1 } else { 0 }).to_byte())
    let len = block_len.reinterpret_as_uint()
    push_u16_le(out, len)
    push_u16_le(out, 0xFFFFU - len)
    let block_end = offset + block_len
    for i in offset..<block_end {
      out.push(bytes[i])
    }
    offset = offset + block_len
  }
  push_u32_be(out, adler32(bytes))
  Bytes::from_array(out)
}

///|
fn png_chunk(chunk_type : String, data : Bytes) -> Bytes {
  let out : Array[Byte] = []
  let chunk_type_bytes = ascii_bytes(chunk_type)
  push_u32_be(out, data.length().reinterpret_as_uint())
  push_bytes(out, chunk_type_bytes)
  push_bytes(out, data)
  let crc_input : Array[Byte] = []
  push_bytes(crc_input, chunk_type_bytes)
  push_bytes(crc_input, data)
  push_u32_be(out, crc32(Bytes::from_array(crc_input)))
  Bytes::from_array(out)
}

///|
fn ensure_parent_dir(path : String) -> Unit {
  let path_value : @path.Path = path
  let parent = path_value.dirname().to_string()
  if parent == "" || parent == "." || parent == path {
    return
  }
  if @fs.path_exists(parent) {
    return
  }
  ensure_parent_dir(parent)
  @fs.create_dir(parent) catch {
    _ => ()
  }
}

///|
fn png_encode_rgba8(width : Int, height : Int, pixels : Bytes) -> Bytes? {
  if width <= 0 || height <= 0 {
    return None
  }
  if pixels.length() != rgba8_len(width, height) {
    return None
  }
  let scanlines : Array[Byte] = []
  for y in 0..<height {
    scanlines.push((0).to_byte())
    let row_start = y * width * 4
    let row_end = row_start + width * 4
    for i in row_start..<row_end {
      scanlines.push(pixels[i])
    }
  }
  let compressed = zlib_uncompressed(Bytes::from_array(scanlines))
  let ihdr : Array[Byte] = []
  push_u32_be(ihdr, width.reinterpret_as_uint())
  push_u32_be(ihdr, height.reinterpret_as_uint())
  ihdr.push((8).to_byte())
  ihdr.push((6).to_byte())
  ihdr.push((0).to_byte())
  ihdr.push((0).to_byte())
  ihdr.push((0).to_byte())
  let png : Array[Byte] = [
    137U.to_byte(),
    80U.to_byte(),
    78U.to_byte(),
    71U.to_byte(),
    13U.to_byte(),
    10U.to_byte(),
    26U.to_byte(),
    10U.to_byte(),
  ]
  push_bytes(png, png_chunk("IHDR", Bytes::from_array(ihdr)))
  push_bytes(png, png_chunk("IDAT", compressed))
  push_bytes(png, png_chunk("IEND", Bytes::new(0)))
  Some(Bytes::from_array(png))
}

///|
fn save_rgba8_png(
  width~ : Int,
  height~ : Int,
  pixels~ : Bytes,
  path~ : String,
) -> Unit {
  guard png_encode_rgba8(width, height, pixels) is Some(encoded) else { return }
  let out_path = resolve_output_path(path)
  ensure_parent_dir(out_path)
  @fs.write_bytes_to_file(out_path, encoded) catch {
    _ => ()
  }
}

///|
fn save_asset_file_bytes(path : String, bytes : Bytes) -> Unit {
  let out_path = resolve_asset_path(path)
  ensure_parent_dir(out_path)
  @fs.write_bytes_to_file(out_path, bytes) catch {
    _ => ()
  }
}

///|
fn texture_dimensions_from_bytes(bytes : Bytes) -> (Int, Int)? {
  if png_dimensions(bytes) is Some(dims) {
    return Some(dims)
  }
  if ktx2_dimensions(bytes) is Some(dims) {
    return Some(dims)
  }
  None
}

///|
fn extension_normalize(extension : String) -> String {
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
fn path_extension(path : String) -> String? {
  let parsed = parse_virtual_asset_path(path)
  let relative = parsed.relative_path
  let mut last_dot = -1
  let mut last_slash = -1
  for i in 0..<relative.length() {
    let code = relative.code_unit_at(i)
    if code == 46 {
      last_dot = i
    } else if code == 47 || code == 92 {
      last_slash = i
    }
  }
  if last_dot <= last_slash || last_dot < 0 || last_dot + 1 >= relative.length() {
    None
  } else {
    Some(
      extension_normalize(relative[last_dot + 1:relative.length()].to_string()),
    )
  }
}

///|
fn register_loader_extension(extension~ : String, kind~ : Int) -> Unit {
  let normalized = extension_normalize(extension)
  let next : Array[(String, Int)] = []
  let mut replaced = false
  for item in loader_extensions_ref.val {
    if item.0 == normalized {
      if !replaced {
        next.push((normalized, kind))
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push((normalized, kind))
  }
  loader_extensions_ref.val = next
}

///|
fn remove_loader_extension(extension~ : String) -> Unit {
  let normalized = extension_normalize(extension)
  let next : Array[(String, Int)] = []
  for item in loader_extensions_ref.val {
    if item.0 != normalized {
      next.push(item)
    }
  }
  loader_extensions_ref.val = next
}

///|
fn loader_kind_for_path(path~ : String) -> Int {
  if path_extension(path) is Some(ext) {
    for item in loader_extensions_ref.val {
      if item.0 == ext {
        return item.1
      }
    }
  }
  LOADER_KIND_BYTES
}

///|
fn sorted_directory_entries(path : String) -> Array[String] {
  try {
    let entries = @fs.read_dir(path)
    entries.sort()
    entries
  } catch {
    _ => []
  }
}

///|
fn asset_path_is_directory(path : String) -> Bool {
  if asset_source_reader_for_path(path) is Some(reader) {
    let parsed = parse_virtual_asset_path(path)
    return reader.is_directory(parsed.relative_path)
  }
  path_is_dir(resolve_asset_path(path))
}

///|
fn asset_read_directory_entries(path : String) -> Array[String] {
  if asset_source_reader_for_path(path) is Some(reader) {
    let parsed = parse_virtual_asset_path(path)
    return reader.read_directory(parsed.relative_path).unwrap_or([])
  }
  sorted_directory_entries(resolve_asset_path(path))
}

///|
fn load_asset_meta_bytes(path : String) -> Bytes? {
  if asset_source_reader_for_path(path) is Some(reader) {
    let parsed = parse_virtual_asset_path(path)
    return reader.read_meta(parsed.relative_path)
  }
  let meta_path = path + ".meta"
  if embedded_asset_bytes(meta_path) is Some(bytes) {
    return Some(bytes)
  }
  if resolve_asset_input_path(meta_path) is Some(input_path) {
    return read_file_bytes(input_path)
  }
  None
}

///|
fn folder_handles(folder_id : Int) -> Array[Int]? {
  for folder in folders_ref.val {
    if folder.id == folder_id {
      let handles : Array[Int] = []
      for entry in folder.entries {
        handles.push(entry.handle_id)
      }
      return Some(handles)
    }
  }
  None
}

///|
fn bytes_fingerprint(bytes : Bytes) -> Int {
  let mut hash = 2166136261U
  for byte in bytes {
    hash = hash ^ (byte.to_int() & 0xFF).reinterpret_as_uint()
    hash = hash * 16777619U
  }
  hash.reinterpret_as_int()
}

///|
fn folder_entry_find_by_relative(
  entries : Array[FolderEntry],
  relative_path : String,
) -> FolderEntry? {
  for entry in entries {
    if entry.relative_path == relative_path {
      return Some(entry)
    }
  }
  None
}

///|
fn folder_collect_entries(folder : FolderRecord) -> (Array[FolderEntry], Bool) {
  let next_entries : Array[FolderEntry] = []
  let mut changed = false
  if asset_path_is_directory(folder.virtual_path) {
    let entries = asset_read_directory_entries(folder.virtual_path)
    for entry_name in entries {
      let child_relative = @path.Path::join(folder.relative_path, entry_name).to_string()
      let child_virtual = compose_virtual_asset_path(
        folder.source_name,
        child_relative,
        None,
      )
      if asset_path_is_directory(child_virtual) {
        continue
      }
      if loader_kind_for_path(path=child_virtual) != LOADER_KIND_TEXTURE {
        continue
      }
      if asset_source_reader_for_path(child_virtual) is Some(_) {
        let bytes = load_asset_file_bytes(child_virtual)
        if bytes.length() == 0 {
          continue
        }
        let fingerprint = bytes_fingerprint(bytes)
        if folder_entry_find_by_relative(folder.entries, child_relative)
          is Some(previous) {
          if previous.fingerprint == fingerprint {
            next_entries.push(previous)
            continue
          }
        }
        let handle_id = load_texture(path=child_virtual, nearest=false)
        next_entries.push(FolderEntry::{
          relative_path: child_relative,
          fingerprint,
          handle_id,
        })
      } else if read_file_bytes(path_join(folder.absolute_path, entry_name))
        is Some(bytes) {
        let fingerprint = bytes_fingerprint(bytes)
        if folder_entry_find_by_relative(folder.entries, child_relative)
          is Some(previous) {
          if previous.fingerprint == fingerprint {
            next_entries.push(previous)
            continue
          }
        }
        let handle_id = load_texture(path=child_virtual, nearest=false)
        next_entries.push(FolderEntry::{
          relative_path: child_relative,
          fingerprint,
          handle_id,
        })
      }
    }
  }
  if next_entries.length() != folder.entries.length() {
    changed = true
  } else {
    for i in 0..<next_entries.length() {
      if next_entries[i].relative_path != folder.entries[i].relative_path ||
        next_entries[i].fingerprint != folder.entries[i].fingerprint ||
        next_entries[i].handle_id != folder.entries[i].handle_id {
        changed = true
        break
      }
    }
  }
  (next_entries, changed)
}

///|
fn refresh_watched_folders() -> Unit {
  let next : Array[FolderRecord] = []
  for folder in folders_ref.val {
    let (entries, changed) = folder_collect_entries(folder)
    let refreshed = FolderRecord::{
      id: folder.id,
      virtual_path: folder.virtual_path,
      source_name: folder.source_name,
      relative_path: folder.relative_path,
      absolute_path: folder.absolute_path,
      entries,
    }
    next.push(refreshed)
    if changed {
      folder_events_ref.val.push(FolderEvent::{ kind: 1, folder_id: folder.id })
    }
  }
  folders_ref.val = next
}

///|
fn sync_texture_record(
  texture_id : Int,
  width : Int,
  height : Int,
  loaded : Bool,
) -> Unit {
  register_texture_with_id(texture_id, width, height, loaded) |> ignore
}

///|
fn texture_cached_or_empty(
  texture_id : Int,
  width : Int,
  height : Int,
) -> Bytes {
  if texture_pixels(texture_id) is Some(cached) {
    normalize_rgba8(cached, rgba8_len(width, height))
  } else {
    Bytes::makei(rgba8_len(width, height), _ => (0).to_byte())
  }
}

///|
fn load_texture(path~ : String, nearest~ : Bool) -> Int {
  let bytes = load_asset_file_bytes(path)
  load_texture_bytes(bytes~, nearest~)
}

///|
fn load_texture_bytes(bytes~ : Bytes, nearest~ : Bool) -> Int {
  let loaded = bytes.length() > 0
  if ktx2_decode_uncompressed_3d_payload(bytes) is Some(payload) {
    let texture_id = @render.asset_create_texture_3d_with_format(
      width=payload.width,
      height=payload.height,
      depth=payload.depth,
      format_raw=payload.format_raw,
      pixels=payload.pixels,
    )
    if texture_id > 0 {
      sync_texture_record(texture_id, payload.width, payload.height, loaded)
      return texture_id
    }
  }
  if ktx2_decode_2d_payload(bytes) is Some(payload) {
    payload.is_cube |> ignore
    // Current material/sprite bind-group layouts sample `texture_2d`, so KTX2
    // cubemaps are uploaded as stacked 2D textures for runtime compatibility.
    let texture_id = @render.asset_create_texture_stacked_2d_with_format(
      width=payload.width,
      height_per_slice=payload.height,
      slice_count=payload.slice_count,
      format_raw=payload.format_raw,
      levels=payload.levels,
      nearest~,
    )
    if texture_id > 0 {
      sync_texture_record(texture_id, payload.width, payload.height, loaded)
      return texture_id
    }
  }
  let (width, height, upload_pixels) = if decode_texture_image(bytes)
    is Some(decoded) {
    (decoded.width, decoded.height, decoded.pixels)
  } else if texture_dimensions_from_bytes(bytes) is Some(dims) {
    (dims.0, dims.1, source_bytes_to_rgba8(bytes, dims.0, dims.1))
  } else {
    (1, 1, source_bytes_to_rgba8(bytes, 1, 1))
  }
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let texture_id = @render.asset_create_texture_empty(
    width=safe_width,
    height=safe_height,
    mip_level_count=1,
    nearest~,
  )
  if texture_id <= 0 {
    return 0
  }
  @render.asset_write_texture_region_rgba8(
    texture_id~,
    x=0,
    y=0,
    width=safe_width,
    height=safe_height,
    pixels_rgba8=upload_pixels,
  )
  set_texture_pixels(texture_id, upload_pixels)
  sync_texture_record(texture_id, safe_width, safe_height, loaded)
  texture_id
}

///|
fn load_wgsl(path~ : String) -> Int {
  let id = next_id()
  blobs_ref.val.push(BlobRecord::{ id, bytes: load_asset_file_bytes(path) })
  id
}

///|
fn load_bytes(path~ : String) -> Int {
  let id = next_id()
  blobs_ref.val.push(BlobRecord::{ id, bytes: load_asset_file_bytes(path) })
  id
}

///|
fn load_with_registered_loader(path~ : String, nearest~ : Bool) -> Int {
  let loader_kind = loader_kind_for_path(path~)
  if loader_kind == LOADER_KIND_TEXTURE {
    return load_texture(path~, nearest~)
  }
  if loader_kind == LOADER_KIND_WGSL {
    return load_wgsl(path~)
  }
  if loader_kind == LOADER_KIND_FONT {
    return load_font(path~)
  }
  if loader_kind == LOADER_KIND_FOLDER {
    return load_folder(path~)
  }
  load_bytes(path~)
}

///|
fn bytes_len(blob_id : Int) -> Int {
  if find_blob(blobs_ref.val, blob_id) is Some(record) {
    record.bytes.length()
  } else {
    0
  }
}

///|
fn bytes_get_u32(blob_id~ : Int, index~ : Int) -> Int {
  if find_blob(blobs_ref.val, blob_id) is Some(record) {
    blob_u32_at(record.bytes, index)
  } else {
    0
  }
}

///|
fn create_dynamic_texture(width~ : Int, height~ : Int, nearest~ : Bool) -> Int {
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let texture_id = @render.asset_create_texture_empty(
    width=safe_width,
    height=safe_height,
    mip_level_count=1,
    nearest~,
  )
  if texture_id <= 0 {
    return 0
  }
  let pixels = Bytes::makei(rgba8_len(safe_width, safe_height), _ => {
    (0).to_byte()
  })
  @render.asset_write_texture_region_rgba8(
    texture_id~,
    x=0,
    y=0,
    width=safe_width,
    height=safe_height,
    pixels_rgba8=pixels,
  )
  set_texture_pixels(texture_id, pixels)
  sync_texture_record(texture_id, safe_width, safe_height, true)
  texture_id
}

///|
fn create_dynamic_texture_mipped(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  let safe_mip_level_count = if mip_level_count <= 0 {
    1
  } else {
    mip_level_count
  }
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let texture_id = @render.asset_create_texture_empty(
    width=safe_width,
    height=safe_height,
    mip_level_count=safe_mip_level_count,
    nearest~,
  )
  if texture_id <= 0 {
    return 0
  }
  let pixels = Bytes::makei(rgba8_len(safe_width, safe_height), _ => {
    (0).to_byte()
  })
  @render.asset_write_texture_region_rgba8(
    texture_id~,
    x=0,
    y=0,
    width=safe_width,
    height=safe_height,
    pixels_rgba8=pixels,
  )
  set_texture_pixels(texture_id, pixels)
  sync_texture_record(texture_id, safe_width, safe_height, true)
  texture_id
}

///|
fn create_render_target_with_formats(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  format_raw~ : Int,
  sample_format_raw : Int?,
) -> Int {
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let sample_format = match sample_format_raw {
    Some(raw) => raw
    None => -1
  }
  let texture_id = @render.asset_create_render_target_with_formats(
    width=safe_width,
    height=safe_height,
    nearest~,
    format_raw~,
    sample_format_raw=sample_format,
  )
  if texture_id <= 0 {
    return 0
  }
  sync_texture_record(texture_id, safe_width, safe_height, true)
  texture_id
}

///|
fn update_texture_region(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  glyph_id~ : Int,
) -> Unit {
  let source = if find_blob(blobs_ref.val, glyph_id) is Some(record) {
    record.bytes
  } else if find_blob(fonts_ref.val, glyph_id) is Some(record) {
    record.bytes
  } else {
    Bytes::makei(rgba8_len(width, height), _ => (0).to_byte())
  }
  update_texture_region_bytes(
    texture_id~,
    x~,
    y~,
    width~,
    height~,
    bytes=source,
  )
}

///|
fn update_texture_region_bytes(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  bytes~ : Bytes,
) -> Unit {
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let upload_pixels = source_bytes_to_rgba8(bytes, safe_width, safe_height)
  @render.asset_write_texture_region_rgba8(
    texture_id~,
    x~,
    y~,
    width=safe_width,
    height=safe_height,
    pixels_rgba8=upload_pixels,
  )
  let tex_width = texture_width(texture_id)
  let tex_height = texture_height(texture_id)
  if tex_width > 0 && tex_height > 0 {
    let base = texture_cached_or_empty(texture_id, tex_width, tex_height)
    let patched = patch_texture_pixels(
      base, tex_width, tex_height, x, y, safe_width, safe_height, upload_pixels,
    )
    set_texture_pixels(texture_id, patched)
  }
}

///|
fn update_texture_region_mip_bytes(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  bytes~ : Bytes,
) -> Unit {
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let upload_pixels = source_bytes_to_rgba8(bytes, safe_width, safe_height)
  @render.asset_write_texture_region_rgba8_mip(
    texture_id~,
    x~,
    y~,
    width=safe_width,
    height=safe_height,
    mip_level~,
    pixels_rgba8=upload_pixels,
  )
  if mip_level == 0 {
    let tex_width = texture_width(texture_id)
    let tex_height = texture_height(texture_id)
    if tex_width > 0 && tex_height > 0 {
      let base = texture_cached_or_empty(texture_id, tex_width, tex_height)
      let patched = patch_texture_pixels(
        base, tex_width, tex_height, x, y, safe_width, safe_height, upload_pixels,
      )
      set_texture_pixels(texture_id, patched)
    }
  }
}

///|
fn create_texture_mip_view(texture_id~ : Int, mip_level~ : Int) -> Int {
  let view_id = @render.asset_create_texture_mip_view(texture_id~, mip_level~)
  if view_id <= 0 {
    return 0
  }
  let width = @render.asset_texture_width(texture_id=view_id)
  let height = @render.asset_texture_height(texture_id=view_id)
  let loaded = @render.asset_is_texture_loaded(texture_id=view_id)
  sync_texture_record(view_id, width, height, loaded)
  if texture_pixels(texture_id) is Some(cached) {
    set_texture_pixels(
      view_id,
      normalize_rgba8(cached, rgba8_len(width, height)),
    )
  }
  view_id
}

///|
fn texture_width(texture_id : Int) -> Int {
  let width = @render.asset_texture_width(texture_id~)
  if width > 0 {
    let height = @render.asset_texture_height(texture_id~)
    let loaded = @render.asset_is_texture_loaded(texture_id~)
    sync_texture_record(texture_id, width, height, loaded)
  }
  width
}

///|
fn texture_height(texture_id : Int) -> Int {
  let height = @render.asset_texture_height(texture_id~)
  if height > 0 {
    let width = @render.asset_texture_width(texture_id~)
    let loaded = @render.asset_is_texture_loaded(texture_id~)
    sync_texture_record(texture_id, width, height, loaded)
  }
  height
}

///|
fn is_texture_loaded(texture_id : Int) -> Bool {
  let loaded = @render.asset_is_texture_loaded(texture_id~)
  let width = @render.asset_texture_width(texture_id~)
  let height = @render.asset_texture_height(texture_id~)
  if width > 0 && height > 0 {
    sync_texture_record(texture_id, width, height, loaded)
  }
  loaded
}

///|
fn supported_compressed_image_formats() -> Int {
  @render.asset_supported_compressed_image_formats()
}

///|
fn copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  @render.asset_copy_texture_to_texture(
    dst_texture_id~,
    dst_x~,
    dst_y~,
    src_texture_id~,
  )
  let src_width = texture_width(src_texture_id)
  let src_height = texture_height(src_texture_id)
  let dst_width = texture_width(dst_texture_id)
  let dst_height = texture_height(dst_texture_id)
  if src_width > 0 && src_height > 0 && dst_width > 0 && dst_height > 0 {
    if texture_pixels(src_texture_id) is Some(src_pixels) {
      let base = texture_cached_or_empty(dst_texture_id, dst_width, dst_height)
      let patched = patch_texture_pixels(
        base, dst_width, dst_height, dst_x, dst_y, src_width, src_height, src_pixels,
      )
      set_texture_pixels(dst_texture_id, patched)
    }
  }
}

///|
fn save_texture_png(texture_id~ : Int, path~ : String) -> Unit {
  let width = texture_width(texture_id)
  let height = texture_height(texture_id)
  if width <= 0 || height <= 0 {
    return
  }
  if @render.screenshot_capture_texture_sync(texture_id~) is Some(capture) {
    save_rgba8_png(
      width=capture.width,
      height=capture.height,
      pixels=capture.pixels,
      path~,
    )
    return
  }
  let pixels = texture_cached_or_empty(texture_id, width, height)
  save_rgba8_png(width~, height~, pixels~, path~)
}

///|
fn load_font(path~ : String) -> Int {
  let id = next_id()
  fonts_ref.val.push(BlobRecord::{ id, bytes: load_asset_file_bytes(path) })
  id
}

///|
fn font_bytes_len(font_id : Int) -> Int {
  if find_blob(fonts_ref.val, font_id) is Some(record) {
    record.bytes.length()
  } else {
    0
  }
}

///|
fn font_bytes_get(font_id~ : Int, index~ : Int) -> Int {
  if find_blob(fonts_ref.val, font_id) is Some(record) {
    blob_u8_at(record.bytes, index)
  } else {
    0
  }
}

///|
fn font_bytes_get_u32(font_id~ : Int, index~ : Int) -> Int {
  if find_blob(fonts_ref.val, font_id) is Some(record) {
    blob_u32_at(record.bytes, index)
  } else {
    0
  }
}

///|
fn load_folder(path~ : String) -> Int {
  let parsed = parse_virtual_asset_path(path)
  let folder_virtual = compose_virtual_asset_path(
    parsed.source_name,
    parsed.relative_path,
    None,
  )
  let folder_path = resolve_asset_path(folder_virtual)
  let folder_id = next_id()
  let seed_folder = FolderRecord::{
    id: folder_id,
    virtual_path: folder_virtual,
    source_name: parsed.source_name,
    relative_path: parsed.relative_path,
    absolute_path: folder_path,
    entries: [],
  }
  let (entries, _) = folder_collect_entries(seed_folder)
  folders_ref.val.push(FolderRecord::{
    id: folder_id,
    virtual_path: folder_virtual,
    source_name: parsed.source_name,
    relative_path: parsed.relative_path,
    absolute_path: folder_path,
    entries,
  })
  folder_events_ref.val.push(FolderEvent::{ kind: 3, folder_id })
  folder_id
}

///|
fn pop_next_folder_event() -> FolderEvent? {
  match folder_events_ref.val.pop() {
    Some(value) => Some(value)
    None => None
  }
}

///|
fn poll_loaded_folder_event_kind() -> Int {
  if pending_folder_event_ref.val is Some(event) {
    return event.kind
  }
  refresh_watched_folders()
  match pop_next_folder_event() {
    Some(event) => {
      pending_folder_event_ref.val = Some(event)
      event.kind
    }
    None => -1
  }
}

///|
fn poll_loaded_folder_event_id() -> Int {
  if pending_folder_event_ref.val is Some(event) {
    pending_folder_event_ref.val = None
    event.folder_id
  } else {
    -1
  }
}

///|
fn loaded_folder_handles_len(folder_id : Int) -> Int {
  if folder_handles(folder_id) is Some(handles) {
    handles.length()
  } else {
    0
  }
}

///|
fn loaded_folder_handles_get(folder_id~ : Int, index~ : Int) -> Int {
  if folder_handles(folder_id) is Some(handles) {
    if index < 0 || index >= handles.length() {
      -1
    } else {
      handles[index]
    }
  } else {
    -1
  }
}
