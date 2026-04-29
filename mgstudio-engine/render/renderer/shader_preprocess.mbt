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
fn u16le_pack(xs : Array[Int]) -> Bytes {
  Bytes::makei(xs.length() * 2, i => {
    let v = xs[i / 2]
    let b = if i % 2 == 0 { v & 0xFF } else { (v >> 8) & 0xFF }
    b.to_byte()
  })
}

///|
fn u32le_pack(xs : Array[UInt]) -> Bytes {
  let n = xs.length()
  let bytes = Array::make(n * 4, (0).to_byte())
  for i in 0..<n {
    u32le_write_into(bytes, i * 4, xs[i])
  }
  Bytes::from_array(bytes)
}

///|
fn f32le_pack(xs : Array[Float]) -> Bytes {
  let n = xs.length()
  let bytes = Array::make(n * 4, (0).to_byte())
  for i in 0..<n {
    u32le_write_into(bytes, i * 4, f32_bits(xs[i]))
  }
  Bytes::from_array(bytes)
}

///|
fn bytes_fixed_staging_make(len : Int) -> FixedArray[Byte] {
  if len <= 0 {
    return []
  }
  Bytes::make(len, (0).to_byte()).to_fixedarray()
}

///|
fn bytes_fixed_staging_zero(staging : FixedArray[Byte]) -> Unit {
  for i in 0..<staging.length() {
    staging[i] = (0).to_byte()
  }
}

///|
fn u32le_write_into(
  bytes : Array[Byte],
  byte_offset : Int,
  word : UInt,
) -> Unit {
  bytes[byte_offset] = (word & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 1] = ((word >> 8) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 2] = ((word >> 16) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 3] = ((word >> 24) & 0xFFU).reinterpret_as_int().to_byte()
}

///|
fn u32le_write_into_fixed(
  bytes : FixedArray[Byte],
  byte_offset : Int,
  word : UInt,
) -> Unit {
  bytes[byte_offset] = (word & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 1] = ((word >> 8) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 2] = ((word >> 16) & 0xFFU).reinterpret_as_int().to_byte()
  bytes[byte_offset + 3] = ((word >> 24) & 0xFFU).reinterpret_as_int().to_byte()
}

///|
fn f32le_write_into_fixed(
  bytes : FixedArray[Byte],
  byte_offset : Int,
  value : Float,
) -> Unit {
  u32le_write_into_fixed(bytes, byte_offset, f32_bits(value))
}

///|
fn normalize_shader_rel_path(rel : String) -> String {
  @wgsl.normalize_shader_rel_path(rel)
}

///|
let wgsl_runtime_source_tree_registered : Ref[Bool] = Ref::new(false)

///|
let wgsl_renderer_embedded_sources_registered : Ref[Bool] = Ref::new(false)

///|
fn wgsl_register_renderer_embedded_sources_once() -> Unit {
  if wgsl_renderer_embedded_sources_registered.val {
    return
  }
  register_embedded_wgsl_sources()
  wgsl_renderer_embedded_sources_registered.val = true
}

///|
fn wgsl_source_scan_options() -> @wgsl.WgslSourceScanOptions {
  @wgsl.WgslSourceScanOptions::{
    recursive: true,
    extensions: [".wgsl"],
    exclude_prefixes: [".mooncakes", "_build", ".private"],
  }
}

///|
fn wgsl_register_runtime_source_tree_once() -> Unit {
  if wgsl_runtime_source_tree_registered.val {
    return
  }
  try {
    let files = @wgsl.scan_wgsl_source_files(".", wgsl_source_scan_options())
    @wgsl.register_wgsl_source_files(files)
    wgsl_runtime_source_tree_registered.val = true
  } catch {
    _ => ()
  }
}

///|
fn wgsl_runtime_composer(assets_base : String) -> @wgsl.Composer {
  wgsl_register_renderer_embedded_sources_once()
  if assets_base.trim() != "" {
    wgsl_register_runtime_source_tree_once()
  }
  let composer = @wgsl.Composer::from_registered_wgsl_source_registry()
  composer
}

///|
fn wgsl_runtime_composer_with_source_tree() -> @wgsl.Composer {
  wgsl_register_renderer_embedded_sources_once()
  wgsl_register_runtime_source_tree_once()
  @wgsl.Composer::from_registered_wgsl_source_registry()
}

///|
fn[T] raise_composer_error(
  err : @wgsl.ComposerError,
) -> T raise GpuBackendError {
  fatal("wgpu: \{err.message()}")
}

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  @wgsl.clear_registered_wgsl_source_registry()
  wgsl_renderer_embedded_sources_registered.val = false
  wgsl_runtime_source_tree_registered.val = false
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  @wgsl.register_wgsl_source(rel_path, source)
}

///|
fn registered_wgsl_source_required(
  rel_path : String,
) -> String raise GpuBackendError {
  @wgsl.registered_wgsl_source_required(rel_path) catch {
    err => raise_composer_error(err)
  }
}

///|
fn copy_registered_wgsl_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  @wgsl.copy_registered_wgsl_import_module_paths()
}

///|
fn build_wgsl_import_module_paths(
  assets_base : String,
) -> @hashmap.HashMap[String, String] {
  @wgsl.build_wgsl_import_module_paths(assets_base)
}

///|
fn split_once_text(text : String, sep : String) -> (String, String)? {
  let parts : Array[String] = []
  for piece in text.split(sep) {
    parts.push(piece.to_string())
  }
  if parts.length() != 2 {
    return None
  }
  Some((parts[0], parts[1]))
}

///|
fn default_wgsl_value_defines() -> @hashmap.HashMap[String, Int] {
  @wgsl.default_wgsl_value_defines()
}

///|
fn wgsl_compose_options(
  assets_base : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> @wgsl.WgslComposeOptions {
  @wgsl.WgslComposeOptions::{
    assets_base,
    defines,
    value_defines,
    redirects: [],
    additional_imports: [],
    preserve_imported_entry_points: true,
  }
}

///|
fn preprocess_wgsl_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  visited : @hashmap.HashMap[String, Bool],
  modules : @hashmap.HashMap[String, String],
) -> String raise GpuBackendError {
  ignore(visited)
  ignore(modules)
  let options = wgsl_compose_options(assets_base, defines, value_defines)
  wgsl_runtime_composer(assets_base).compose_wgsl_source(source, options) catch {
    @wgsl.ComposerError::MissingStartupRegisteredSource(_) =>
      wgsl_runtime_composer_with_source_tree().compose_wgsl_source(
        source, options,
      ) catch {
        err => raise_composer_error(err)
      }
    err => raise_composer_error(err)
  }
}

///|
fn load_wgsl_preprocessed(
  assets_base : String,
  rel : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  visited : @hashmap.HashMap[String, Bool],
  modules : @hashmap.HashMap[String, String],
) -> String raise GpuBackendError {
  ignore(visited)
  ignore(modules)
  let options = wgsl_compose_options(assets_base, defines, value_defines)
  wgsl_runtime_composer(assets_base).compose_wgsl(rel, options) catch {
    @wgsl.ComposerError::MissingStartupRegisteredSource(_) =>
      wgsl_runtime_composer_with_source_tree().compose_wgsl(rel, options) catch {
        err => raise_composer_error(err)
      }
    err => raise_composer_error(err)
  }
}

///|
fn load_wgsl_from_assets_required(
  backend : GpuBackend,
  rel : String,
) -> String raise GpuBackendError {
  load_wgsl_from_assets_base_required(backend.assets_base, rel)
}

///|
fn load_wgsl_from_assets_base_required(
  assets_base : String,
  rel : String,
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    assets_base,
    rel,
    @hashmap.HashMap::new(),
    default_wgsl_value_defines(),
    @hashmap.HashMap::new(),
    @hashmap.HashMap::new(),
  )
}
