///|
priv struct ParsedVirtualAssetPath {
  source_name : String?
  relative_path : String
}

///|
let embedded_assets_ref : Ref[@hashmap.HashMap[String, Bytes]] = Ref(
  @hashmap.HashMap([]),
)

///|
fn string_last_index_of_char(input : String, code : Int) -> Int {
  let mut i = input.length() - 1
  while i >= 0 {
    if input.code_unit_at(i).to_int() == code {
      return i
    }
    i = i - 1
  }
  -1
}

///|
fn string_find_substring(input : String, pattern : String) -> Int {
  if pattern.length() == 0 {
    return 0
  }
  if pattern.length() > input.length() {
    return -1
  }
  let limit = input.length() - pattern.length()
  let mut i = 0
  while i <= limit {
    let mut matched = true
    let mut j = 0
    while j < pattern.length() {
      if input.code_unit_at(i + j) != pattern.code_unit_at(j) {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn parse_virtual_asset_path(path : String) -> ParsedVirtualAssetPath {
  let hash_index = string_last_index_of_char(path, 35)
  let without_label = if hash_index >= 0 {
    let base = if hash_index > 0 { path[0:hash_index].to_owned() } else { "" }
    base
  } else {
    path
  }
  let scheme_index = string_find_substring(without_label, "://")
  if scheme_index > 0 {
    let source_name = without_label[0:scheme_index].to_owned()
    let relative_path = if scheme_index + 3 < without_label.length() {
      without_label[scheme_index + 3:without_label.length()].to_owned()
    } else {
      ""
    }
    ParsedVirtualAssetPath::{ source_name: Some(source_name), relative_path }
  } else {
    ParsedVirtualAssetPath::{ source_name: None, relative_path: without_label }
  }
}

///|
fn compose_virtual_asset_path(
  source_name : String?,
  relative_path : String,
  label : String?,
) -> String {
  let prefix = match source_name {
    Some(name) if name.length() > 0 => "\{name}://\{relative_path}"
    _ => relative_path
  }
  match label {
    Some(label) if label.length() > 0 => "\{prefix}#\{label}"
    _ => prefix
  }
}

///|
fn canonical_virtual_asset_path(path : String) -> String {
  let parsed = parse_virtual_asset_path(path)
  compose_virtual_asset_path(parsed.source_name, parsed.relative_path, None)
}

///|
pub fn register_embedded_asset_virtual_bytes(
  path : String,
  bytes : Bytes,
) -> Unit {
  embedded_assets_ref.val.set(canonical_virtual_asset_path(path), bytes)
}

///|
pub fn embedded_asset_virtual_bytes(path : String) -> Bytes? {
  embedded_assets_ref.val.get(canonical_virtual_asset_path(path))
}

///|
pub fn asset_text_to_bytes(text : String) -> Bytes {
  @utf8.encode(text[:])
}
