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
let embedded_shader_source_paths : Array[String] = []

///|
fn shader_source_push_unique(paths : Array[String], rel_path : String) -> Unit {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  if normalized == "" {
    return
  }
  if !paths.contains(normalized) {
    paths.push(normalized)
  }
}

///|
fn shader_source_parent_rel_path(rel_path : String) -> String {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  let segments : Array[String] = []
  for segment in normalized.split("/") {
    let text = segment.to_owned()
    if text != "" {
      segments.push(text)
    }
  }
  if segments.length() == 0 {
    return ""
  }
  segments.pop() |> ignore
  segments.join("/")
}

///|
fn shader_source_resolve_file_import(
  importer_rel_path : String,
  import_path : String,
) -> String {
  let raw = import_path.trim().to_owned()
  if raw.has_prefix("./") || raw.has_prefix("../") {
    let parent = shader_source_parent_rel_path(importer_rel_path)
    if parent == "" {
      @wgsl_resolver.normalize_shader_rel_path(raw)
    } else {
      @wgsl_resolver.normalize_shader_rel_path("\{parent}/\{raw}")
    }
  } else {
    @wgsl_resolver.normalize_shader_rel_path(raw)
  }
}

///|
fn shader_source_collect_quoted_imports_from_line(
  importer_rel_path : String,
  line : String,
  out : Array[String],
) -> Unit {
  guard line.contains("#import") else { return }
  let mut first_quote = -1
  let mut second_quote = -1
  for index in 0..<line.length() {
    if line.code_unit_at(index).to_int() == 34 {
      if first_quote < 0 {
        first_quote = index
      } else {
        second_quote = index
        break
      }
    }
  }
  if first_quote < 0 || second_quote <= first_quote + 1 {
    return
  }
  shader_source_push_unique(
    out,
    shader_source_resolve_file_import(
      importer_rel_path,
      line[first_quote + 1:second_quote].to_owned(),
    ),
  )
}

///|
fn shader_source_collect_quoted_imports(
  importer_rel_path : String,
  source : String,
  out : Array[String],
) -> Unit {
  for line in source.split("\n") {
    shader_source_collect_quoted_imports_from_line(
      importer_rel_path,
      line.to_owned(),
      out,
    )
  }
}

///|
fn shader_source_has_define_import_path(source : String) -> Bool {
  for line in source.split("\n") {
    if line.to_owned().trim().has_prefix("#define_import_path") {
      return true
    }
  }
  false
}

///|
pub fn clear_embedded_shader_sources() -> Unit {
  embedded_shader_source_paths.clear()
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
  for path in embedded_shader_source_paths {
    match embedded_shader_source(path) {
      Some(source) => files.push({ rel_path: path, source })
      None => ()
    }
  }
  files
}

///|
pub fn embedded_shader_composer_source_files(
  root_rel_path : String?,
) -> Array[ShaderSourceFile] {
  let root = match root_rel_path {
    Some(path) => @wgsl_resolver.normalize_shader_rel_path(path)
    None => ""
  }
  let quoted_imports : Array[String] = []
  let files = embedded_shader_source_files()
  for file in files {
    shader_source_collect_quoted_imports(
      file.rel_path,
      file.source,
      quoted_imports,
    )
  }
  let composer_files : Array[ShaderSourceFile] = []
  for file in files {
    let normalized_rel = @wgsl_resolver.normalize_shader_rel_path(file.rel_path)
    if normalized_rel == root ||
      shader_source_has_define_import_path(file.source) ||
      quoted_imports.contains(normalized_rel) {
      composer_files.push(file)
    }
  }
  composer_files
}

///|
fn upsert_embedded_shader_source_path(rel_path : String) -> Unit {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  let paths = embedded_shader_source_paths
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
  registry.register_source_files(embedded_shader_composer_source_files(None))
  @hashmap.HashMap(registry.copy_import_module_paths().to_array())
}

///|
pub fn scan_shader_source_files(
  root : String,
  options : ShaderSourceScanOptions,
) -> Array[ShaderSourceFile] raise @fs.IOError {
  @wgsl_resolver.scan_wgsl_source_files(root, options)
}
