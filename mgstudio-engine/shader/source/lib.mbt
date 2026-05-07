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
pub type ShaderSourceFile = @wgsl_common.WgslSourceFile

///|
pub type ShaderSourceScanOptions = @wgsl_common.WgslSourceScanOptions

///|
let embedded_shader_source_paths : Ref[Array[String]] = Ref([])

///|
pub fn clear_embedded_shader_sources() -> Unit {
  embedded_shader_source_paths.val = []
}

///|
pub fn load_embedded_shader_source(rel_path : String, source : String) -> Unit {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  upsert_embedded_shader_source_path(normalized)
  @embedded_asset.register_embedded_asset_virtual_bytes(
    normalized,
    @embedded_asset.asset_text_to_bytes(source),
  )
}

///|
pub fn load_embedded_shader_source_files(
  files : Array[ShaderSourceFile],
) -> Unit {
  for file in files {
    load_embedded_shader_source(file.rel_path, file.source)
  }
}

///|
pub fn embedded_shader_source(rel_path : String) -> String? {
  match @embedded_asset.embedded_asset_virtual_bytes(rel_path) {
    Some(bytes) => Some(@utf8.decode_lossy(bytes[:], ignore_bom=true))
    None => None
  }
}

///|
pub fn embedded_shader_source_required(
  rel_path : String,
) -> String raise @wgsl_compose.ComposerError {
  match embedded_shader_source(rel_path) {
    Some(source) => source
    None => raise @wgsl_compose.ComposerError::MissingRegisteredSource(rel_path)
  }
}

///|
pub fn embedded_shader_source_files() -> Array[ShaderSourceFile] {
  let files : Array[ShaderSourceFile] = []
  for path in embedded_shader_source_paths.val {
    match embedded_shader_source(path) {
      Some(source) => files.push({ rel_path: path, source })
      None => ()
    }
  }
  files
}

///|
fn upsert_embedded_shader_source_path(rel_path : String) -> Unit {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  let paths = embedded_shader_source_paths.val
  for i in 0..<paths.length() {
    if @wgsl_resolver.normalize_shader_rel_path(paths[i]) == normalized {
      paths[i] = normalized
      return
    }
  }
  paths.push(normalized)
}

///|
pub fn copy_embedded_shader_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  let registry = @wgsl_resolver.WgslSourceRegistry::default()
  registry.register_source_files(embedded_shader_source_files())
  registry.copy_import_module_paths()
}

///|
pub fn scan_shader_source_files(
  root : String,
  options : ShaderSourceScanOptions,
) -> Array[ShaderSourceFile] raise @fs.IOError {
  @wgsl_resolver.scan_wgsl_source_files(root, options)
}
