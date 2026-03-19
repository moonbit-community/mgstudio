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
pub struct WgslImportTarget {
  raw_path : String
  alias_name : String
} derive(Eq, Show)

///|
pub struct WgslResolvedImportModule {
  module_path : String
  rel_path : String
} derive(Eq, Show)

///|
fn join_wgsl_import_prefix(prefix : String, path : String) -> String {
  let lhs = prefix.trim().to_string()
  let rhs = path.trim().to_string()
  if lhs == "" {
    rhs
  } else if rhs == "" {
    lhs
  } else {
    lhs + "::" + rhs
  }
}

///|
fn find_top_level_wgsl_group_separator(text : String) -> Int {
  let mut depth = 0
  let mut i = 0
  while i + 2 < text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      depth = depth + 1
      i = i + 1
      continue
    }
    if ch == 125 { // '}'
      depth = depth - 1
      i = i + 1
      continue
    }
    if depth == 0 &&
      ch == 58 &&
      text.code_unit_at(i + 1).to_int() == 58 &&
      text.code_unit_at(i + 2).to_int() == 123 {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn split_top_level_wgsl_import_items(text : String) -> Array[String] {
  let items : Array[String] = []
  let mut start = 0
  let mut depth = 0
  for i in 0..<text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      depth = depth + 1
      continue
    }
    if ch == 125 { // '}'
      depth = depth - 1
      continue
    }
    if ch == 44 && depth == 0 { // ','
      let item = text[start:i].to_string().trim().to_string()
      if item != "" {
        items.push(trim_trailing_semicolons(item))
      }
      start = i + 1
    }
  }
  let tail = text[start:text.length()].to_string().trim().to_string()
  if tail != "" {
    items.push(trim_trailing_semicolons(tail))
  }
  items
}

///|
fn extract_wgsl_group_body(text : String, open_brace_index : Int) -> String {
  let mut depth = 0
  let mut body_start = open_brace_index + 1
  for i in open_brace_index..<text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      depth = depth + 1
      if depth == 1 {
        body_start = i + 1
      }
      continue
    }
    if ch == 125 { // '}'
      depth = depth - 1
      if depth == 0 {
        return text[body_start:i].to_string()
      }
    }
  }
  ""
}

///|
pub fn collect_wgsl_import_targets(
  spec : String,
  prefix : String,
  targets : Array[WgslImportTarget],
) -> Unit {
  let text = trim_trailing_semicolons(spec.trim().to_string())
  if text == "" {
    return
  }
  let group_separator = find_top_level_wgsl_group_separator(text)
  if group_separator >= 0 {
    let group_prefix = text[:group_separator].to_string().trim().to_string()
    let body = extract_wgsl_group_body(text, group_separator + 2)
    let next_prefix = join_wgsl_import_prefix(prefix, group_prefix)
    for item in split_top_level_wgsl_import_items(body) {
      collect_wgsl_import_targets(item, next_prefix, targets)
    }
    return
  }
  let mut raw_path = text
  let mut alias_name = ""
  let mut saw_first = false
  for part in text.split(" as ") {
    if !saw_first {
      raw_path = part.to_string().trim().to_string()
      saw_first = true
      continue
    }
    alias_name = trim_trailing_semicolons(part.to_string().trim().to_string())
    break
  }
  raw_path = trim_trailing_semicolons(raw_path.trim().to_string())
  if raw_path == "" {
    return
  }
  targets.push(WgslImportTarget::{
    raw_path: join_wgsl_import_prefix(prefix, raw_path),
    alias_name,
  })
}

///|
pub fn normalize_shader_rel_path(rel : String) -> String {
  let mut text = rel.trim().to_string()
  let n = text.length()
  let mut i = 0
  while i < n && text.code_unit_at(i).to_int() == 47 { // '/'
    i = i + 1
  }
  if i != 0 {
    text = text[i:n].to_string()
  }
  while text.length() >= 2 && text[:2].to_string() == "./" {
    text = text[2:text.length()].to_string()
  }
  if text.length() >= 7 && text[:7].to_string() == "assets/" {
    text = text[7:text.length()].to_string()
  }
  text
}

///|
fn join_asset_path(base : String, rel : String) -> String {
  if base == "" {
    rel
  } else {
    @path.Path::join(base, rel).normalize().to_string()
  }
}

///|
fn path_is_file(path : String) -> Bool {
  @fs.is_file(path) catch {
    _ => false
  }
}

///|
fn path_is_file_exact(path : String) -> Bool {
  if !path_is_file(path) {
    return false
  }
  let mut sep_index = -1
  for i in 0..<path.length() {
    if path.code_unit_at(i).to_int() == 47 { // '/'
      sep_index = i
    }
  }
  let dir = if sep_index < 0 {
    "."
  } else if sep_index == 0 {
    "/"
  } else {
    path[:sep_index].to_string()
  }
  let base = if sep_index < 0 {
    path
  } else if sep_index + 1 >= path.length() {
    ""
  } else {
    path[sep_index + 1:path.length()].to_string()
  }
  if base == "" {
    return false
  }
  let entries : Array[String] = @fs.read_dir(dir) catch { _ => [] }
  for entry in entries {
    if entry.to_string() == base {
      return true
    }
  }
  false
}

///|
fn path_is_dir(path : String) -> Bool {
  @fs.is_dir(path) catch {
    _ => false
  }
}

///|
let registered_wgsl_sources_ref : Ref[@hashmap.HashMap[String, String]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let registered_wgsl_import_modules_ref : Ref[@hashmap.HashMap[String, String]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
pub fn clear_registered_wgsl_source_registry() -> Unit {
  registered_wgsl_sources_ref.val = @hashmap.HashMap::new()
  registered_wgsl_import_modules_ref.val = @hashmap.HashMap::new()
}

///|
pub fn register_wgsl_source(rel_path : String, source : String) -> Unit {
  let normalized_rel = normalize_shader_rel_path(rel_path)
  if normalized_rel == "" {
    return
  }
  registered_wgsl_sources_ref.val.set(normalized_rel, source)
  let (import_path, _, _) = get_preprocessor_data(source)
  if import_path is Some(path) && path != "" {
    registered_wgsl_import_modules_ref.val.set(path, normalized_rel)
  }
}

///|
pub fn registered_wgsl_source(rel_path : String) -> String? {
  let normalized_rel = normalize_shader_rel_path(rel_path)
  if normalized_rel == "" {
    return None
  }
  registered_wgsl_sources_ref.val.get(normalized_rel)
}

///|
pub fn copy_registered_wgsl_import_module_paths() -> @hashmap.HashMap[
  String,
  String,
] {
  let copied : @hashmap.HashMap[String, String] = @hashmap.HashMap::new()
  for entry in registered_wgsl_import_modules_ref.val.iter() {
    let (module_path, rel_path) = entry
    copied.set(module_path, rel_path)
  }
  copied
}

///|
fn wgsl_module_path_to_rel_path(module_path : String) -> String {
  let mut rel = "shaders/"
  let mut first = true
  for seg in module_path.split("::") {
    let text = seg.to_string()
    if text == "" {
      continue
    }
    if first {
      first = false
    } else {
      rel = rel + "/"
    }
    rel = rel + text
  }
  rel + ".wgsl"
}

///|
fn wgsl_module_path_to_rel_path_namespace(module_path : String) -> String {
  let segments : Array[String] = []
  for seg in module_path.split("::") {
    let text = seg.to_string().trim().to_string()
    if text != "" {
      segments.push(text)
    }
  }
  if segments.length() == 0 {
    return ""
  }
  let mut rel = "shaders/" + segments[0]
  for i in 1..<segments.length() {
    rel = rel + "/" + segments[i]
  }
  rel + ".wgsl"
}

///|
fn collect_wgsl_import_module_paths(
  assets_base : String,
  rel_dir : String,
  modules : @hashmap.HashMap[String, String],
) -> Unit {
  let dir_path = join_asset_path(assets_base, rel_dir)
  if !path_is_dir(dir_path) {
    return
  }
  let entries : Array[String] = @fs.read_dir(dir_path) catch { _ => [] }
  entries.sort()
  for entry in entries {
    let name = entry.trim().to_string()
    if name == "" {
      continue
    }
    let child_rel = if rel_dir == "" { name } else { rel_dir + "/" + name }
    let child_path = join_asset_path(assets_base, child_rel)
    if path_is_dir(child_path) {
      collect_wgsl_import_module_paths(assets_base, child_rel, modules)
      continue
    }
    if !path_is_file(child_path) || !name.has_suffix(".wgsl") {
      continue
    }
    let source = @fs.read_file_to_string(child_path) catch { _ => continue }
    let normalized_child_rel = normalize_shader_rel_path(child_rel)
    let (import_path, _, _) = get_preprocessor_data(source)
    guard import_path is Some(path) && path != "" else { continue }
    if !modules.contains(path) {
      modules.set(path, normalized_child_rel)
    }
  }
}

///|
pub fn build_wgsl_import_module_paths(
  assets_base : String,
) -> @hashmap.HashMap[String, String] {
  let modules = copy_registered_wgsl_import_module_paths()
  let normalized_assets_base = assets_base.trim().to_string()
  if normalized_assets_base != "" {
    collect_wgsl_import_module_paths(normalized_assets_base, "shaders", modules)
  }
  modules
}

///|
pub fn resolve_wgsl_import_module(
  assets_base : String,
  import_path : String,
  modules : @hashmap.HashMap[String, String],
) -> WgslResolvedImportModule? {
  let normalized_assets_base = assets_base.trim().to_string()
  let segments : Array[String] = []
  for seg in import_path.split("::") {
    let text = seg.to_string().trim().to_string()
    if text != "" {
      segments.push(text)
    }
  }
  while segments.length() > 0 {
    let mut module_path = segments[0]
    for i in 1..<segments.length() {
      module_path = module_path + "::" + segments[i]
    }
    if modules.get(module_path) is Some(rel_path) {
      return Some(WgslResolvedImportModule::{ module_path, rel_path })
    }
    if normalized_assets_base != "" {
      let default_rel = wgsl_module_path_to_rel_path(module_path)
      if path_is_file_exact(
          join_asset_path(normalized_assets_base, default_rel),
        ) {
        return Some(WgslResolvedImportModule::{
          module_path,
          rel_path: default_rel,
        })
      }
      let namespace_rel = wgsl_module_path_to_rel_path_namespace(module_path)
      if namespace_rel != "" &&
        namespace_rel != default_rel &&
        path_is_file_exact(
          join_asset_path(normalized_assets_base, namespace_rel),
        ) {
        return Some(WgslResolvedImportModule::{
          module_path,
          rel_path: namespace_rel,
        })
      }
    }
    segments.pop() |> ignore
  }
  None
}
