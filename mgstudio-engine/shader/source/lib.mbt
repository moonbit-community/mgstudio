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
fn shader_source_collect_import_targets(
  source : String,
  out : Array[@wgsl_common.WgslImportTarget],
) -> Unit {
  for
    item in @wgsl_directive.parse_wgsl_directive_scan_items(
      source,
      include_glsl_version=false,
    ) {
    match item.kind() {
      @wgsl_directive.WgslDirectiveScanItemKind::Directive(directive) =>
        if @wgsl_directive.wgsl_effective_directive_kind(directive) ==
          @wgsl_ast.WgslDirectiveKind::Import {
          @wgsl_resolver.collect_wgsl_import_targets(
            @wgsl_directive.wgsl_effective_directive_tail(directive),
            "",
            out,
          )
        }
      _ => ()
    }
  }
}

///|
fn shader_source_has_define_import_path(source : String) -> Bool {
  for
    item in @wgsl_directive.parse_wgsl_directive_scan_items(
      source,
      include_glsl_version=false,
    ) {
    match item.kind() {
      @wgsl_directive.WgslDirectiveScanItemKind::Directive(directive) =>
        if @wgsl_directive.wgsl_effective_directive_kind(directive) ==
          @wgsl_ast.WgslDirectiveKind::DefineImportPath {
          return true
        }
      _ => ()
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
fn shader_source_file_by_rel_path(
  files : Array[ShaderSourceFile],
  rel_path : String,
) -> ShaderSourceFile? {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  for file in files {
    if @wgsl_resolver.normalize_shader_rel_path(file.rel_path) == normalized {
      return Some(file)
    }
  }
  None
}

///|
fn shader_source_extract_quoted_target_path(raw_path : String) -> String? {
  let text = raw_path.trim().to_owned()
  let mut first_quote = -1
  let mut second_quote = -1
  for index in 0..<text.length() {
    if text.code_unit_at(index).to_int() == 34 {
      if first_quote < 0 {
        first_quote = index
      } else {
        second_quote = index
        break
      }
    }
  }
  if first_quote < 0 || second_quote <= first_quote + 1 {
    None
  } else {
    Some(text[first_quote + 1:second_quote].to_owned())
  }
}

///|
fn shader_source_resolve_file_import_target(
  registry : @wgsl_resolver.WgslSourceRegistry,
  importer_rel_path : String,
  target : @wgsl_common.WgslImportTarget,
) -> String? {
  match
    @wgsl_resolver.resolve_wgsl_import_file_path_from_registry(
      registry,
      importer_rel_path,
      target.raw_path,
    ) {
    Some(path) => Some(path)
    None =>
      match shader_source_extract_quoted_target_path(target.raw_path) {
        Some(path) =>
          @wgsl_resolver.resolve_wgsl_import_file_path_from_registry(
            registry,
            importer_rel_path,
            "\"\{path}\"",
          )
        None => None
      }
  }
}

///|
fn shader_source_push_dependency_path(
  included_paths : Array[String],
  pending_paths : Array[String],
  rel_path : String,
) -> Unit {
  let normalized = @wgsl_resolver.normalize_shader_rel_path(rel_path)
  if normalized == "" || included_paths.contains(normalized) {
    return
  }
  if !pending_paths.contains(normalized) {
    pending_paths.push(normalized)
  }
}

///|
fn shader_source_collect_dependency_paths(
  registry : @wgsl_resolver.WgslSourceRegistry,
  modules : Map[String, String],
  importer_rel_path : String,
  importer_source : String,
  included_paths : Array[String],
  pending_paths : Array[String],
) -> Unit {
  let targets : Array[@wgsl_common.WgslImportTarget] = []
  shader_source_collect_import_targets(importer_source, targets)
  for target in targets {
    match
      shader_source_resolve_file_import_target(
        registry, importer_rel_path, target,
      ) {
      Some(rel_path) =>
        shader_source_push_dependency_path(
          included_paths, pending_paths, rel_path,
        )
      None =>
        match
          @wgsl_resolver.resolve_wgsl_import_module_in_registry(
            registry,
            target.raw_path,
            modules,
          ) {
          Some(resolved) =>
            shader_source_push_dependency_path(
              included_paths,
              pending_paths,
              resolved.rel_path(),
            )
          None => ()
        }
    }
  }
}

///|
fn embedded_shader_composer_source_files_for_root(
  root_rel_path : String,
) -> Array[ShaderSourceFile] {
  let root = @wgsl_resolver.normalize_shader_rel_path(root_rel_path)
  let files = embedded_shader_source_files()
  let registry = @wgsl_resolver.WgslSourceRegistry::default()
  registry.register_source_files(files)
  let modules = registry.copy_import_module_paths()
  let included_paths : Array[String] = []
  let pending_paths : Array[String] = []
  shader_source_push_dependency_path(included_paths, pending_paths, root)
  while pending_paths.length() > 0 {
    let next_index = pending_paths.length() - 1
    let rel_path = pending_paths[next_index]
    pending_paths.pop() |> ignore
    if included_paths.contains(rel_path) {
      continue
    }
    match shader_source_file_by_rel_path(files, rel_path) {
      Some(file) => {
        included_paths.push(rel_path)
        shader_source_collect_dependency_paths(
          registry,
          modules,
          rel_path,
          file.source,
          included_paths,
          pending_paths,
        )
      }
      None => ()
    }
  }

  let composer_files : Array[ShaderSourceFile] = []
  for file in files {
    if included_paths.contains(
        @wgsl_resolver.normalize_shader_rel_path(file.rel_path),
      ) {
      composer_files.push(file)
    }
  }
  composer_files
}

///|
pub fn embedded_shader_composer_source_files(
  root_rel_path : String?,
) -> Array[ShaderSourceFile] {
  match root_rel_path {
    Some(root) => embedded_shader_composer_source_files_for_root(root)
    None => {
      let files : Array[ShaderSourceFile] = []
      for file in embedded_shader_source_files() {
        if shader_source_has_define_import_path(file.source) {
          files.push(file)
        }
      }
      files
    }
  }
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
