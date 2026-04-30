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
pub type ComposerError = @compose.ComposerError

///|
pub type WgslSourceFile = @common.WgslSourceFile

///|
pub type WgslSourceScanOptions = @common.WgslSourceScanOptions

///|
let registered_wgsl_sources : Ref[@resolver.WgslSourceRegistry] = Ref::new(
  @resolver.WgslSourceRegistry::default(),
)

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  registered_wgsl_sources.val.clear()
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  ignore(registered_wgsl_sources.val.register_source(rel_path, source, None))
}

///|
pub fn register_wgsl_source_files(files : Array[WgslSourceFile]) -> Unit {
  registered_wgsl_sources.val.register_source_files(files)
}

///|
pub fn registered_wgsl_source(rel_path : String) -> String? {
  registered_wgsl_sources.val.registered_source(rel_path)
}

///|
pub fn registered_wgsl_source_required(
  rel_path : String,
) -> String raise ComposerError {
  match registered_wgsl_sources.val.registered_source(rel_path) {
    Some(source) => source
    None => raise @compose.ComposerError::MissingRegisteredSource(rel_path)
  }
}

///|
pub fn registered_wgsl_source_files() -> Array[WgslSourceFile] {
  let files : Array[WgslSourceFile] = []
  for entry in registered_wgsl_sources.val.rel_to_source_ref.val.iter() {
    let (rel_path, source) = entry
    files.push({ rel_path, source })
  }
  files
}

///|
pub fn copy_registered_wgsl_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  registered_wgsl_sources.val.copy_import_module_paths()
}

///|
pub fn scan_wgsl_source_files(
  root : String,
  options : WgslSourceScanOptions,
) -> Array[WgslSourceFile] raise @fs.IOError {
  @resolver.scan_wgsl_source_files(root, options)
}
