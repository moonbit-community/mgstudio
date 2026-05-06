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
  value_defines : @hashmap.HashMap[String, Int]
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
  value_defines : @hashmap.HashMap[String, Int],
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
  value_defines : @hashmap.HashMap[String, Int],
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
let runtime_source_tree_registered : Ref[Bool] = Ref::new(false)

///|
let startup_sources_registered : Ref[Bool] = Ref::new(false)

///|
pub fn normalize_shader_rel_path(rel : String) -> String {
  @wgsl_resolver.normalize_shader_rel_path(rel)
}

///|
pub fn ensure_startup_shader_sources_once(register : () -> Unit) -> Unit {
  if startup_sources_registered.val {
    return
  }
  register()
  startup_sources_registered.val = true
}

///|
fn source_scan_options() -> @wgsl_common.WgslSourceScanOptions {
  @wgsl_common.WgslSourceScanOptions::{
    recursive: true,
    extensions: [".wgsl"],
    exclude_prefixes: [".mooncakes", "_build", ".private"],
  }
}

///|
fn register_runtime_source_tree_once() -> Unit {
  if runtime_source_tree_registered.val {
    return
  }
  try {
    let files = @shader_source.scan_shader_source_files(
      ".",
      source_scan_options(),
    )
    @shader_source.load_embedded_shader_source_files(files)
    runtime_source_tree_registered.val = true
  } catch {
    _ => ()
  }
}

///|
fn runtime_composer(assets_base : String) -> @wgsl_compose.Composer {
  if assets_base.trim() != "" {
    register_runtime_source_tree_once()
  }
  let composer = @wgsl_compose.Composer::default()
  composer.register_source_files(@shader_source.embedded_shader_source_files())
  composer
}

///|
fn runtime_composer_with_source_tree() -> @wgsl_compose.Composer {
  register_runtime_source_tree_once()
  let composer = @wgsl_compose.Composer::default()
  composer.register_source_files(@shader_source.embedded_shader_source_files())
  composer
}

///|
pub fn clear_registered_shader_sources() -> Unit {
  @shader_source.clear_embedded_shader_sources()
  startup_sources_registered.val = false
  runtime_source_tree_registered.val = false
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
pub fn default_shader_value_defines() -> @hashmap.HashMap[String, Int] {
  @wgsl_common.default_wgsl_value_defines()
}

///|
fn compose_options(
  assets_base : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> @wgsl_common.WgslComposeOptions {
  ignore(assets_base)
  @wgsl_common.WgslComposeOptions::{
    defines,
    value_defines,
    redirects: [],
    additional_imports: [],
  }
}

///|
pub fn preprocess_shader_source(
  assets_base : String,
  source : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> String raise ShaderCompileError {
  let options = compose_options(assets_base, defines, value_defines)
  let composed = runtime_composer(assets_base).compose_wgsl_source(
    source, options,
  ) catch {
    @wgsl_compose.ComposerError::MissingStartupRegisteredSource(_) =>
      runtime_composer_with_source_tree().compose_wgsl_source(source, options) catch {
        err => raise shader_compile_error_from_composer(err)
      }
    err => raise shader_compile_error_from_composer(err)
  }
  composed
}

///|
pub fn load_preprocessed_wgsl(
  assets_base : String,
  rel : String,
  defines : @hashmap.HashMap[String, Bool],
  value_defines : @hashmap.HashMap[String, Int],
) -> String raise ShaderCompileError {
  let options = compose_options(assets_base, defines, value_defines)
  let composed = runtime_composer(assets_base).compose_wgsl(rel, options) catch {
    @wgsl_compose.ComposerError::MissingStartupRegisteredSource(_) =>
      runtime_composer_with_source_tree().compose_wgsl(rel, options) catch {
        err => raise shader_compile_error_from_composer(err)
      }
    err => raise shader_compile_error_from_composer(err)
  }
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
    @hashmap.HashMap::new(),
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
