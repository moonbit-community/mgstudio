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
  Bytes::makei(n * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn f32le_pack(xs : Array[Float]) -> Bytes {
  u32le_pack(xs.map(f32_bits))
}

///|
fn normalize_shader_rel_path(rel : String) -> String {
  @wgsl.normalize_shader_rel_path(rel)
}

///|
type WgslComposer = @wgsl.Composer

///|
fn wgsl_composer() -> WgslComposer {
  @wgsl.Composer::default()
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
fn preprocess_wgsl_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
  visited : @hashmap.HashMap[String, Bool],
  modules : @hashmap.HashMap[String, String],
) -> String raise GpuBackendError {
  wgsl_composer().preprocess_wgsl_source(
    assets_base, source, defines, value_defines, visited, modules,
  ) catch {
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
  wgsl_composer().load_wgsl_preprocessed(
    assets_base, rel, defines, value_defines, visited, modules,
  ) catch {
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
  wgsl_composer().load_wgsl_from_assets_base_required(assets_base, rel) catch {
    err => raise_composer_error(err)
  }
}
