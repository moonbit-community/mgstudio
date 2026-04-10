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
// Bevy source: `bevy/crates/bevy_asset/src/path.rs`.
pub(all) enum AssetSourceId {
  Default
  Named(String)
} derive(Eq, Hash, Debug)

///|
pub(all) suberror ParseAssetPathError {
  InvalidSourceSyntax
  InvalidLabelSyntax
  MissingSource
  MissingLabel
}

///|
pub struct AssetPath {
  source : AssetSourceId
  path : String
  label : String?
} derive(Eq, Hash, Debug)

///|
pub type ParsedAssetPath = AssetPath

///|
pub(open) trait IntoAssetPath {
  into_asset_path(self : Self) -> AssetPath
}

///|
pub(open) trait AssetLoadGuard {
  release(self : Self) -> Unit
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
fn asset_parse_path_error_message(error : ParseAssetPathError) -> String {
  match error {
    ParseAssetPathError::InvalidSourceSyntax =>
      "asset source must not contain `#`"
    ParseAssetPathError::InvalidLabelSyntax =>
      "asset label must not contain `://`"
    ParseAssetPathError::MissingSource =>
      "asset source must contain at least one character before `://`"
    ParseAssetPathError::MissingLabel =>
      "asset label must contain at least one character after `#`"
  }
}

///|
pub fn asset_try_parse_path(
  path : String,
) -> AssetPath raise ParseAssetPathError {
  let hash_index = string_last_index_of_char(path, 35)
  let scheme_index = string_find_substring(path, "://")
  if hash_index >= 0 && scheme_index > hash_index {
    raise ParseAssetPathError::InvalidSourceSyntax
  }
  let (without_label, label) = if hash_index >= 0 {
    if hash_index + 1 >= path.length() {
      raise ParseAssetPathError::MissingLabel
    }
    let base = if hash_index > 0 { path[0:hash_index].to_string() } else { "" }
    let parsed_label = path[hash_index + 1:path.length()].to_string()
    if string_find_substring(parsed_label, "://") >= 0 {
      raise ParseAssetPathError::InvalidLabelSyntax
    }
    (base, Some(parsed_label))
  } else {
    (path, None)
  }

  if scheme_index == 0 {
    raise ParseAssetPathError::MissingSource
  }

  let source_scheme_index = string_find_substring(without_label, "://")
  if source_scheme_index == 0 {
    raise ParseAssetPathError::MissingSource
  }

  if string_last_index_of_char(without_label, 35) >= 0 {
    raise ParseAssetPathError::InvalidSourceSyntax
  }

  if source_scheme_index > 0 {
    let source_name = without_label[0:source_scheme_index].to_string()
    let relative_path = if source_scheme_index + 3 < without_label.length() {
      without_label[source_scheme_index + 3:without_label.length()].to_string()
    } else {
      ""
    }
    AssetPath::{
      source: AssetSourceId::Named(source_name),
      path: relative_path,
      label,
    }
  } else {
    AssetPath::{ source: AssetSourceId::Default, path: without_label, label }
  }
}

///|
pub fn asset_parse_path(path : String) -> AssetPath {
  asset_try_parse_path(path) catch {
    error =>
      abort(
        "invalid asset path syntax: \{asset_parse_path_error_message(error)}",
      )
  }
}

///|
pub fn asset_format_path(parsed : AssetPath) -> String {
  let base = match parsed.source {
    AssetSourceId::Default => parsed.path
    AssetSourceId::Named(name) => "\{name}://\{parsed.path}"
  }
  match parsed.label {
    Some(label) if label.length() > 0 => "\{base}#\{label}"
    _ => base
  }
}

///|
pub fn AssetSourceId::from(name : String) -> AssetSourceId {
  if name == "" {
    AssetSourceId::Default
  } else {
    AssetSourceId::Named(name)
  }
}

///|
pub fn AssetPath::from_path(path : String) -> AssetPath {
  AssetPath::{ source: AssetSourceId::Default, path, label: None }
}

///|
pub fn AssetPath::with_source(
  self : AssetPath,
  source : AssetSourceId,
) -> AssetPath {
  AssetPath::{ source, path: self.path, label: self.label }
}

///|
pub fn AssetPath::with_label(self : AssetPath, label : String?) -> AssetPath {
  AssetPath::{ source: self.source, path: self.path, label }
}

///|
pub impl IntoAssetPath for String with into_asset_path(self) {
  asset_parse_path(self)
}

///|
pub impl IntoAssetPath for AssetPath with into_asset_path(self) {
  self
}

///|
fn[P : IntoAssetPath] asset_path_string(path : P) -> String {
  asset_format_path(path.into_asset_path())
}

///|
pub fn asset_strip_label(path : String) -> String {
  let parsed = asset_parse_path(path)
  asset_format_path(AssetPath::{
    source: parsed.source,
    path: parsed.path,
    label: None,
  })
}
