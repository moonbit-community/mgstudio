// Copyright 2026 International Digital Economy Academy
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
pub(all) suberror ShaderCompileError {
  UnresolvedImport(String)
  MissingRegisteredSource(String)
  MissingPreparedSourceDefs(String)
  MissingStartupRegisteredSource(String)
  Composer(String)
}

///|
pub(all) enum ShaderCompileTarget {
  Path(String)
  Source(String)
}

///|
pub(all) struct ShaderCompileRequest {
  assets_base : String
  target : ShaderCompileTarget
  defines : @hashmap.HashMap[String, Bool]
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue]
}

///|
pub fn ShaderCompileError::message(self : ShaderCompileError) -> String {
  match self {
    UnresolvedImport(import_path) =>
      "failed to resolve shader import: \{import_path}"
    MissingRegisteredSource(rel) => "missing registered WGSL source: \{rel}"
    MissingPreparedSourceDefs(rel) =>
      "missing prepared shader defs for WGSL source: \{rel}"
    MissingStartupRegisteredSource(rel) =>
      "shader source was not startup-registered: \{rel}"
    Composer(message) => message
  }
}

///|
pub fn ShaderCompileRequest::for_path(
  assets_base : String,
  rel : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> ShaderCompileRequest {
  ShaderCompileRequest::{
    assets_base,
    target: ShaderCompileTarget::Path(rel),
    defines,
    value_defines,
  }
}

///|
pub fn ShaderCompileRequest::for_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> ShaderCompileRequest {
  ShaderCompileRequest::{
    assets_base,
    target: ShaderCompileTarget::Source(source),
    defines,
    value_defines,
  }
}

///|
fn shader_compile_error_from_composer(
  err : @wgsl_compose.ComposerError,
) -> ShaderCompileError {
  match err {
    FailedToResolveImport(path) => ShaderCompileError::UnresolvedImport(path)
    MissingRegisteredSource(rel) =>
      ShaderCompileError::MissingRegisteredSource(rel)
    MissingPreparedSourceDefs(rel) =>
      ShaderCompileError::MissingPreparedSourceDefs(rel)
    MissingStartupRegisteredSource(rel) =>
      ShaderCompileError::MissingStartupRegisteredSource(rel)
    _ => ShaderCompileError::Composer(err.message())
  }
}

///|
priv struct ShaderCompileRuntimeState {
  mut startup_sources_registered : Bool
  composed_cache : Array[ShaderCompileCacheEntry]
}

///|
priv struct ShaderCompileCacheEntry {
  key : String
  source : String
}

///|
let shader_compile_runtime_state : ShaderCompileRuntimeState = {
  startup_sources_registered: false,
  composed_cache: [],
}

///|
pub fn normalize_shader_rel_path(rel : String) -> String {
  @wgsl_resolver.normalize_shader_rel_path(rel)
}

///|
pub fn ensure_startup_shader_sources_once(register : () -> Unit) -> Unit {
  if shader_compile_runtime_state.startup_sources_registered {
    return
  }
  register()
  shader_compile_runtime_state.startup_sources_registered = true
}

///|
fn runtime_composer(assets_base : String) -> @wgsl_compose.Composer {
  ignore(assets_base)
  let composer = @wgsl_compose.Composer::default()
  composer.register_source_files(@shader_source.embedded_shader_source_files())
  composer
}

///|
fn bool_hashmap_to_map(
  source : @hashmap.HashMap[String, Bool],
) -> Map[String, Bool] {
  Map(source.to_array())
}

///|
fn shader_def_hashmap_to_map(
  source : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> Map[String, @wgsl_common.ShaderDefValue] {
  Map(source.to_array())
}

///|
fn shader_def_map_to_hashmap(
  source : Map[String, @wgsl_common.ShaderDefValue],
) -> @hashmap.HashMap[String, @wgsl_common.ShaderDefValue] {
  @hashmap.HashMap(source.to_array())
}

///|
fn bool_define_cache_key(source : @hashmap.HashMap[String, Bool]) -> String {
  let entries = source.to_array()
  entries.sort_by(fn(left, right) { left.0.compare(right.0) })
  let parts : Array[String] = []
  for entry in entries {
    parts.push("\{entry.0}=\{entry.1.to_string()}")
  }
  parts.join(";")
}

///|
fn value_define_cache_key(
  source : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> String {
  let entries = source.to_array()
  entries.sort_by(fn(left, right) { left.0.compare(right.0) })
  let parts : Array[String] = []
  for entry in entries {
    parts.push("\{entry.0}=\{entry.1.value_as_string()}")
  }
  parts.join(";")
}

///|
fn shader_compile_cache_key(
  assets_base : String,
  target : ShaderCompileTarget,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> String {
  let target_key = match target {
    Path(rel) => "path:\{rel}"
    Source(source) => "source:\{source}"
  }
  "assets=\{assets_base}|target=\{target_key}|defines=\{bool_define_cache_key(defines)}|values=\{value_define_cache_key(value_defines)}"
}

///|
fn shader_compile_cache_get(key : String) -> String? {
  for entry in shader_compile_runtime_state.composed_cache {
    if entry.key == key {
      return Some(entry.source)
    }
  }
  None
}

///|
fn shader_compile_cache_insert(key : String, source : String) -> Unit {
  shader_compile_runtime_state.composed_cache.push(ShaderCompileCacheEntry::{
    key,
    source,
  })
}

///|
pub fn clear_registered_shader_sources() -> Unit {
  @shader_source.clear_embedded_shader_sources()
  shader_compile_runtime_state.startup_sources_registered = false
  shader_compile_runtime_state.composed_cache.clear()
}

///|
pub fn register_shader_source(rel_path : String, source : String) -> Unit {
  @shader_source.load_embedded_shader_source(rel_path, source)
}

///|
pub fn registered_shader_source_required(
  rel_path : String,
) -> String raise ShaderCompileError {
  @shader_source.embedded_shader_source_required(rel_path) catch {
    err => raise shader_compile_error_from_composer(err)
  }
}

///|
pub fn copy_registered_shader_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  @shader_source.copy_embedded_shader_import_module_paths()
}

///|
pub fn build_shader_import_module_paths(
  assets_base : String,
) -> @hashmap.HashMap[String, String] {
  ignore(assets_base)
  @shader_source.copy_embedded_shader_import_module_paths()
}

///|
pub fn default_shader_value_defines() -> @hashmap.HashMap[
  String,
  @wgsl_common.ShaderDefValue,
] {
  shader_def_map_to_hashmap(@wgsl_common.default_wgsl_value_defines())
}

///|
fn compose_options(
  assets_base : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> @wgsl_common.WgslComposeOptions {
  ignore(assets_base)
  @wgsl_common.WgslComposeOptions::{
    defines: bool_hashmap_to_map(defines),
    value_defines: shader_def_hashmap_to_map(value_defines),
    redirects: [],
    additional_imports: [],
  }
}

///|
pub fn preprocess_shader_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> String raise ShaderCompileError {
  let key = shader_compile_cache_key(
    assets_base,
    ShaderCompileTarget::Source(source),
    defines,
    value_defines,
  )
  if shader_compile_cache_get(key) is Some(cached) {
    return cached
  }
  let options = compose_options(assets_base, defines, value_defines)
  let composed = runtime_composer(assets_base).compose_wgsl_source(
    source, options,
  ) catch {
    err => raise shader_compile_error_from_composer(err)
  }
  shader_compile_cache_insert(key, composed)
  composed
}

///|
pub fn load_preprocessed_wgsl(
  assets_base : String,
  rel : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, @wgsl_common.ShaderDefValue],
) -> String raise ShaderCompileError {
  let key = shader_compile_cache_key(
    assets_base,
    ShaderCompileTarget::Path(rel),
    defines,
    value_defines,
  )
  if shader_compile_cache_get(key) is Some(cached) {
    return cached
  }
  let options = compose_options(assets_base, defines, value_defines)
  let composed = runtime_composer(assets_base).compose_wgsl(rel, options) catch {
    err => raise shader_compile_error_from_composer(err)
  }
  shader_compile_cache_insert(key, composed)
  composed
}

///|
pub fn load_wgsl_from_sources_required(
  assets_base : String,
  rel : String,
) -> String raise ShaderCompileError {
  load_preprocessed_wgsl(
    assets_base,
    rel,
    @hashmap.HashMap([]),
    default_shader_value_defines(),
  )
}

///|
pub fn ShaderCompileRequest::compile(
  self : ShaderCompileRequest,
) -> String raise ShaderCompileError {
  match self.target {
    Path(rel) =>
      load_preprocessed_wgsl(
        self.assets_base,
        rel,
        self.defines,
        self.value_defines,
      )
    Source(source) =>
      preprocess_shader_source(
        self.assets_base,
        source,
        self.defines,
        self.value_defines,
      )
  }
}
