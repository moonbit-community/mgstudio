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
priv struct TextureRecord {
  id : Int
  width : Int
  height : Int
  loaded : Bool
}

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
  absolute_path : String
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
let textures_ref : Ref[Array[TextureRecord]] = Ref::new([])

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
fn runtime_assets_dir() -> String {
  env_or_default("MGSTUDIO_ASSETS_DIR", DEFAULT_ASSETS_DIR)
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
  label : String?
}

///|
fn string_last_index_of_char(input : String, code_unit : Int) -> Int {
  let mut out = -1
  for i in 0..<input.length() {
    if input.code_unit_at(i).to_int() == code_unit {
      out = i
    }
  }
  out
}

///|
fn string_find_substring(input : String, pattern : String) -> Int {
  let n = input.length()
  let m = pattern.length()
  if m <= 0 {
    return 0
  }
  if n < m {
    return -1
  }
  for i in 0..<(n - m + 1) {
    let mut matched = true
    for j in 0..<m {
      if input.code_unit_at(i + j) != pattern.code_unit_at(j) {
        matched = false
        break
      }
    }
    if matched {
      return i
    }
  }
  -1
}

///|
fn parse_virtual_asset_path(path : String) -> ParsedVirtualAssetPath {
  let hash_index = string_last_index_of_char(path, 35)
  let (without_label, label) = if hash_index >= 0 {
    let base = if hash_index > 0 {
      (try! path[0:hash_index]).to_string()
    } else {
      ""
    }
    let parsed_label = if hash_index + 1 < path.length() {
      Some((try! path[hash_index + 1:path.length()]).to_string())
    } else {
      None
    }
    (base, parsed_label)
  } else {
    (path, None)
  }
  let scheme_index = string_find_substring(without_label, "://")
  if scheme_index > 0 {
    let source_name = (try! without_label[0:scheme_index]).to_string()
    let relative_path = if scheme_index + 3 < without_label.length() {
      (try! without_label[scheme_index + 3:without_label.length()]).to_string()
    } else {
      ""
    }
    ParsedVirtualAssetPath::{
      source_name: Some(source_name),
      relative_path,
      label,
    }
  } else {
    ParsedVirtualAssetPath::{
      source_name: None,
      relative_path: without_label,
      label,
    }
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
fn resolve_asset_input_path(path : String) -> String? {
  let parsed = parse_virtual_asset_path(path)
  let resolved = resolve_asset_path(path)
  if path_is_file(resolved) {
    return Some(resolved)
  }
  if parsed.source_name is None &&
    resolved != parsed.relative_path &&
    path_is_file(parsed.relative_path) {
    return Some(parsed.relative_path)
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
fn register_texture(width : Int, height : Int, loaded : Bool) -> Int {
  let id = next_id()
  textures_ref.val.push(TextureRecord::{
    id,
    width: clamp_dim(width),
    height: clamp_dim(height),
    loaded,
  })
  id
}

///|
fn register_texture_with_id(
  id : Int,
  width : Int,
  height : Int,
  loaded : Bool,
) -> Int {
  let mut updated = false
  for i in 0..<textures_ref.val.length() {
    if textures_ref.val[i].id == id {
      textures_ref.val[i] = TextureRecord::{
        id,
        width: clamp_dim(width),
        height: clamp_dim(height),
        loaded,
      }
      updated = true
      break
    }
  }
  if !updated {
    textures_ref.val.push(TextureRecord::{
      id,
      width: clamp_dim(width),
      height: clamp_dim(height),
      loaded,
    })
  }
  id
}

///|
fn find_texture(texture_id : Int) -> TextureRecord? {
  for record in textures_ref.val {
    if record.id == texture_id {
      return Some(record)
    }
  }
  None
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
    None
  } else {
    Some((width, height))
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
      extension_normalize(
        (try! relative[last_dot + 1:relative.length()]).to_string(),
      ),
    )
  }
}

///|
pub fn register_loader_extension(extension~ : String, kind~ : Int) -> Unit {
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
pub fn remove_loader_extension(extension~ : String) -> Unit {
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
pub fn loader_kind_for_path(path~ : String) -> Int {
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
  if path_is_dir(folder.absolute_path) {
    let entries = sorted_directory_entries(folder.absolute_path)
    for entry_name in entries {
      let absolute_entry_path = path_join(folder.absolute_path, entry_name)
      if !path_is_file(absolute_entry_path) {
        continue
      }
      let child_relative = @path.Path::join(folder.relative_path, entry_name).to_string()
      let child_virtual = compose_virtual_asset_path(
        folder.source_name,
        child_relative,
        None,
      )
      if loader_kind_for_path(path=child_virtual) != LOADER_KIND_TEXTURE {
        continue
      }
      if read_file_bytes(absolute_entry_path) is Some(bytes) {
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
          absolute_path: absolute_entry_path,
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
pub fn load_texture(path~ : String, nearest~ : Bool) -> Int {
  let bytes = load_asset_file_bytes(path)
  load_texture_bytes(bytes~, nearest~)
}

///|
pub fn load_texture_bytes(bytes~ : Bytes, nearest~ : Bool) -> Int {
  let loaded = bytes.length() > 0
  let (width, height) = if texture_dimensions_from_bytes(bytes) is Some(dims) {
    dims
  } else {
    (1, 1)
  }
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let texture_id = @native_gpu.asset_create_texture_empty(
    width=safe_width,
    height=safe_height,
    mip_level_count=1,
    nearest~,
  )
  if texture_id <= 0 {
    return 0
  }
  let upload_pixels = source_bytes_to_rgba8(bytes, safe_width, safe_height)
  @native_gpu.asset_write_texture_region_rgba8(
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
pub fn load_wgsl(path~ : String) -> Int {
  let id = next_id()
  blobs_ref.val.push(BlobRecord::{ id, bytes: load_asset_file_bytes(path) })
  id
}

///|
pub fn load_bytes(path~ : String) -> Int {
  let id = next_id()
  blobs_ref.val.push(BlobRecord::{ id, bytes: load_asset_file_bytes(path) })
  id
}

///|
pub fn load_with_registered_loader(path~ : String, nearest~ : Bool) -> Int {
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
pub fn bytes_len(blob_id : Int) -> Int {
  if find_blob(blobs_ref.val, blob_id) is Some(record) {
    record.bytes.length()
  } else {
    0
  }
}

///|
pub fn bytes_get_u32(blob_id~ : Int, index~ : Int) -> Int {
  if find_blob(blobs_ref.val, blob_id) is Some(record) {
    blob_u32_at(record.bytes, index)
  } else {
    0
  }
}

///|
pub fn create_dynamic_texture(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  let safe_width = clamp_dim(width)
  let safe_height = clamp_dim(height)
  let texture_id = @native_gpu.asset_create_texture_empty(
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
  @native_gpu.asset_write_texture_region_rgba8(
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
pub fn create_dynamic_texture_mipped(
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
  let texture_id = @native_gpu.asset_create_texture_empty(
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
  @native_gpu.asset_write_texture_region_rgba8(
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
pub fn update_texture_region(
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
pub fn update_texture_region_bytes(
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
  @native_gpu.asset_write_texture_region_rgba8(
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
pub fn update_texture_region_mip_bytes(
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
  @native_gpu.asset_write_texture_region_rgba8_mip(
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
pub fn create_texture_mip_view(texture_id~ : Int, mip_level~ : Int) -> Int {
  let view_id = @native_gpu.asset_create_texture_mip_view(
    texture_id~,
    mip_level~,
  )
  if view_id <= 0 {
    return 0
  }
  let width = @native_gpu.asset_texture_width(texture_id=view_id)
  let height = @native_gpu.asset_texture_height(texture_id=view_id)
  let loaded = @native_gpu.asset_is_texture_loaded(texture_id=view_id)
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
pub fn texture_width(texture_id : Int) -> Int {
  let width = @native_gpu.asset_texture_width(texture_id~)
  if width > 0 {
    let height = @native_gpu.asset_texture_height(texture_id~)
    let loaded = @native_gpu.asset_is_texture_loaded(texture_id~)
    sync_texture_record(texture_id, width, height, loaded)
  }
  width
}

///|
pub fn texture_height(texture_id : Int) -> Int {
  let height = @native_gpu.asset_texture_height(texture_id~)
  if height > 0 {
    let width = @native_gpu.asset_texture_width(texture_id~)
    let loaded = @native_gpu.asset_is_texture_loaded(texture_id~)
    sync_texture_record(texture_id, width, height, loaded)
  }
  height
}

///|
pub fn is_texture_loaded(texture_id : Int) -> Bool {
  let loaded = @native_gpu.asset_is_texture_loaded(texture_id~)
  let width = @native_gpu.asset_texture_width(texture_id~)
  let height = @native_gpu.asset_texture_height(texture_id~)
  if width > 0 && height > 0 {
    sync_texture_record(texture_id, width, height, loaded)
  }
  loaded
}

///|
pub fn supported_compressed_image_formats() -> Int {
  @native_gpu.asset_supported_compressed_image_formats()
}

///|
pub fn copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  @native_gpu.asset_copy_texture_to_texture(
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
pub fn save_texture_png(texture_id~ : Int, path~ : String) -> Unit {
  let width = texture_width(texture_id)
  let height = texture_height(texture_id)
  if width <= 0 || height <= 0 {
    return
  }
  let out_path = resolve_output_path(path)
  let pixels = texture_cached_or_empty(texture_id, width, height)
  @fs.write_bytes_to_file(out_path, pixels) catch {
    _ => ()
  }
  let meta = "format=raw_rgba8 width=" +
    width.to_string() +
    " height=" +
    height.to_string() +
    " bytes=" +
    pixels.length().to_string() +
    "\n"
  @fs.write_string_to_file(out_path + ".meta", meta) catch {
    _ => ()
  }
}

///|
pub fn set_texture_sampler(
  texture_id~ : Int,
  address_mode_u~ : Int,
  address_mode_v~ : Int,
  address_mode_w~ : Int,
  mag_filter~ : Int,
  min_filter~ : Int,
  mipmap_filter~ : Int,
  lod_min_clamp~ : Float,
  lod_max_clamp~ : Float,
  compare~ : Int,
  anisotropy_clamp~ : Int,
  border_color~ : Int,
) -> Unit {
  @native_gpu.asset_set_texture_sampler(
    texture_id~,
    address_mode_u~,
    address_mode_v~,
    address_mode_w~,
    mag_filter~,
    min_filter~,
    mipmap_filter~,
    lod_min_clamp~,
    lod_max_clamp~,
    compare~,
    anisotropy_clamp~,
    border_color~,
  )
}

///|
pub fn load_font(path~ : String) -> Int {
  let id = next_id()
  fonts_ref.val.push(BlobRecord::{ id, bytes: load_asset_file_bytes(path) })
  id
}

///|
pub fn font_bytes_len(font_id : Int) -> Int {
  if find_blob(fonts_ref.val, font_id) is Some(record) {
    record.bytes.length()
  } else {
    0
  }
}

///|
pub fn font_bytes_get(font_id~ : Int, index~ : Int) -> Int {
  if find_blob(fonts_ref.val, font_id) is Some(record) {
    blob_u8_at(record.bytes, index)
  } else {
    0
  }
}

///|
pub fn font_bytes_get_u32(font_id~ : Int, index~ : Int) -> Int {
  if find_blob(fonts_ref.val, font_id) is Some(record) {
    blob_u32_at(record.bytes, index)
  } else {
    0
  }
}

///|
pub fn load_folder(path~ : String) -> Int {
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
pub fn poll_loaded_folder_event_kind() -> Int {
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
pub fn poll_loaded_folder_event_id() -> Int {
  if pending_folder_event_ref.val is Some(event) {
    pending_folder_event_ref.val = None
    event.folder_id
  } else {
    -1
  }
}

///|
pub fn loaded_folder_handles_len(folder_id : Int) -> Int {
  if folder_handles(folder_id) is Some(handles) {
    handles.length()
  } else {
    0
  }
}

///|
pub fn loaded_folder_handles_get(folder_id~ : Int, index~ : Int) -> Int {
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
