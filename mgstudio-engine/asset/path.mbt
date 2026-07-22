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
pub(all) enum UnapprovedPathMode {
  Allow
  Deny
  Forbid
} derive(Eq, Debug)

///|
pub type ParsedAssetPath = AssetPath

///|
pub(open) trait IntoAssetPath {
  fn into_asset_path(self : Self) -> AssetPath
}

///|
pub(open) trait AssetLoadGuard {
  fn release(self : Self) -> Unit
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
    InvalidSourceSyntax => "asset source must not contain `#`"
    InvalidLabelSyntax => "asset label must not contain `://`"
    MissingSource =>
      "asset source must contain at least one character before `://`"
    MissingLabel => "asset label must contain at least one character after `#`"
  }
}

///|
pub fn asset_try_parse_path(
  path : String,
) -> AssetPath raise ParseAssetPathError {
  let hash_index = string_last_index_of_char(path, 35)
  let scheme_index = string_find_substring(path, "://")
  if hash_index >= 0 && scheme_index > hash_index {
    raise InvalidSourceSyntax
  }
  let (without_label, label) = if hash_index >= 0 {
    if hash_index + 1 >= path.length() {
      raise MissingLabel
    }
    let base = if hash_index > 0 { path[0:hash_index].to_owned() } else { "" }
    let parsed_label = path[hash_index + 1:path.length()].to_owned()
    if string_find_substring(parsed_label, "://") >= 0 {
      raise InvalidLabelSyntax
    }
    (base, Some(parsed_label))
  } else {
    (path, None)
  }

  if scheme_index == 0 {
    raise MissingSource
  }

  let source_scheme_index = string_find_substring(without_label, "://")
  if source_scheme_index == 0 {
    raise MissingSource
  }

  if string_last_index_of_char(without_label, 35) >= 0 {
    raise InvalidSourceSyntax
  }

  if source_scheme_index > 0 {
    let source_name = without_label[0:source_scheme_index].to_owned()
    let relative_path = if source_scheme_index + 3 < without_label.length() {
      without_label[source_scheme_index + 3:without_label.length()].to_owned()
    } else {
      ""
    }
    { source: Named(source_name), path: relative_path, label }
  } else {
    { source: Default, path: without_label, label }
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
    Default => parsed.path
    Named(name) => "\{name}://\{parsed.path}"
  }
  match parsed.label {
    Some(label) if label.length() > 0 => "\{base}#\{label}"
    _ => base
  }
}

///|
pub fn AssetSourceId::from(name : String) -> AssetSourceId {
  if name == "" {
    Default
  } else {
    Named(name)
  }
}

///|
pub fn AssetPath::from_path(path : String) -> AssetPath {
  { source: Default, path, label: None }
}

///|
pub fn AssetPath::with_source(
  self : AssetPath,
  source : AssetSourceId,
) -> AssetPath {
  { source, path: self.path, label: self.label }
}

///|
pub fn AssetPath::with_label(self : AssetPath, label : String?) -> AssetPath {
  { source: self.source, path: self.path, label }
}

///|
fn asset_path_component_is_separator(path : String, index : Int) -> Bool {
  let code = path.code_unit_at(index).to_int()
  code == 47 || code == 92
}

///|
fn asset_path_has_windows_prefix(path : String) -> Bool {
  if path.length() < 2 {
    return false
  }
  let first = path.code_unit_at(0).to_int()
  let second = path.code_unit_at(1).to_int()
  ((first >= 65 && first <= 90) || (first >= 97 && first <= 122)) &&
  second == 58
}

///|
pub fn AssetPath::is_unapproved(self : AssetPath) -> Bool {
  let path = self.path
  if path.length() == 0 {
    return false
  }
  if asset_path_component_is_separator(path, 0) ||
    asset_path_has_windows_prefix(path) {
    return true
  }
  let simplified : Array[String] = []
  let mut start = 0
  for index in 0..<=path.length() {
    if index == path.length() || asset_path_component_is_separator(path, index) {
      let component = if index > start {
        path[start:index].to_owned()
      } else {
        ""
      }
      if component == "" || component == "." {
        ()
      } else if component == ".." {
        if simplified.length() == 0 {
          return true
        }
        ignore(simplified.pop())
      } else {
        simplified.push(component)
      }
      start = index + 1
    }
  }
  false
}

///|
pub impl IntoAssetPath for String with fn into_asset_path(self) {
  asset_parse_path(self)
}

///|
pub impl IntoAssetPath for AssetPath with fn into_asset_path(self) {
  self
}

///|
fn[P : IntoAssetPath] asset_path_string(path : P) -> String {
  asset_format_path(path.into_asset_path())
}

///|
pub fn asset_strip_label(path : String) -> String {
  let parsed = asset_parse_path(path)
  asset_format_path({ source: parsed.source, path: parsed.path, label: None })
}
