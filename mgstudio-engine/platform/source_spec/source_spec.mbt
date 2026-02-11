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
/// Source specs and safe path joining shared by runtimes.
///
/// Goals:
/// - Keep engine-facing paths as logical, relative, `/`-separated paths.
/// - Prevent `..` traversal and absolute paths when mapping to backend storage.

///|
pub(all) suberror SourceSpecError {
  InvalidSpec(String)
  UnsupportedSpec(String)
  UnsafePath(String)
}

///|
pub(all) enum SourceBackend {
  Dir
  Url
  Idb
}

///|
pub struct SourceSpec {
  backend : SourceBackend
  base : String
}

///|
/// Construct a dir source spec without validation (caller must ensure non-empty).
pub fn dir_source(base : String) -> SourceSpec {
  SourceSpec::{ backend: SourceBackend::Dir, base }
}

///|
/// Construct a url source spec without validation beyond trailing slash normalization.
pub fn url_source(base : String) -> SourceSpec {
  SourceSpec::{ backend: SourceBackend::Url, base: ensure_trailing_slash(base) }
}

///|
/// Construct an IndexedDB source spec without validation (caller must ensure non-empty).
pub fn idb_source(ns : String) -> SourceSpec {
  SourceSpec::{ backend: SourceBackend::Idb, base: ns }
}

///|
pub fn is_http_url(text : String) -> Bool {
  text.has_prefix("http://") || text.has_prefix("https://")
}

///|
fn strip_prefix(text : String, prefix : String) -> String? {
  if text.has_prefix(prefix) {
    Some((try! text[prefix.length():text.length()]).to_string())
  } else {
    None
  }
}

///|
pub fn ensure_trailing_slash(base : String) -> String {
  if base == "" {
    ""
  } else {
    let n = base.length()
    if n > 0 && base.code_unit_at(n - 1).to_int() == 47 { // '/'
      base
    } else {
      base + "/"
    }
  }
}

///|
pub fn normalize_logical_path(path : String) -> String raise {
  if path == "" {
    return ""
  }
  if path.has_prefix("/") || path.has_prefix("\\") {
    raise SourceSpecError::UnsafePath("absolute path: " + path)
  }
  // Normalize: split by '/', reject dot segments, and re-join.
  let parts : Array[String] = []
  for seg in path.split("/") {
    let s = seg.to_string()
    if s == "" {
      continue
    }
    if s == "." || s == ".." {
      raise SourceSpecError::UnsafePath("path traversal segment: " + path)
    }
    if s.contains("\\") {
      raise SourceSpecError::UnsafePath("backslash is not allowed: " + path)
    }
    if s.contains(":") {
      // Block drive letters like "C:" and other platform-specific schemes.
      raise SourceSpecError::UnsafePath("colon is not allowed: " + path)
    }
    parts.push(s)
  }
  if parts.length() == 0 {
    raise SourceSpecError::UnsafePath("empty/invalid path: " + path)
  }
  let mut out = ""
  for i in 0..<parts.length() {
    if i > 0 {
      out = out + "/"
    }
    out = out + parts[i]
  }
  out
}

///|
pub fn join_dir(base : String, logical_path : String) -> String raise {
  let rel = normalize_logical_path(logical_path)
  @path.Path(
    // Use the official path library for filesystem joining.
    // Note: join() returns rhs if rhs is absolute on some platforms; rel is validated to be relative.
    base,
  )
  .join(rel)
  .to_string()
}

///|
pub fn join_url(base : String, logical_path : String) -> String raise {
  let rel = normalize_logical_path(logical_path)
  let b = ensure_trailing_slash(base)
  if b == "" {
    rel
  } else {
    b + rel
  }
}

///|
pub fn parse_dir_source(
  spec : String?,
  default_base : String,
) -> SourceSpec raise {
  let raw = match spec {
    Some(s) if s.trim() != "" => s.trim().to_string()
    _ => default_base
  }
  let base = match strip_prefix(raw, "dir:") {
    Some(rest) => rest.trim().to_string()
    None => raw
  }
  if base == "" {
    raise SourceSpecError::InvalidSpec("dir source base is empty")
  }
  SourceSpec::{ backend: SourceBackend::Dir, base }
}

///|
pub fn parse_url_source(
  spec : String?,
  default_base : String,
) -> SourceSpec raise {
  let raw = match spec {
    Some(s) if s.trim() != "" => s.trim().to_string()
    _ => default_base
  }
  // Accept:
  // - http(s)://... (absolute URL)
  // - ./assets/ (relative URL)
  // - dir:./assets/ (shorthand for relative URL base in web runner)
  let base0 = match strip_prefix(raw, "dir:") {
    Some(rest) => rest.trim().to_string()
    None => raw
  }
  if base0 == "" {
    raise SourceSpecError::InvalidSpec("url source base is empty")
  }
  let base = ensure_trailing_slash(base0)
  SourceSpec::{ backend: SourceBackend::Url, base }
}

///|
pub fn parse_idb_source(
  spec : String?,
  default_namespace : String,
) -> SourceSpec raise {
  let raw = match spec {
    Some(s) if s.trim() != "" => s.trim().to_string()
    _ => default_namespace
  }
  let ns = match strip_prefix(raw, "idb:") {
    Some(rest) => rest.trim().to_string()
    None => raw
  }
  if ns == "" {
    raise SourceSpecError::InvalidSpec("idb namespace is empty")
  }
  SourceSpec::{ backend: SourceBackend::Idb, base: ns }
}
