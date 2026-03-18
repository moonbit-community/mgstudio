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
fn starts_with_text(text : String, prefix : String) -> Bool {
  text.length() >= prefix.length() &&
  text[:prefix.length()].to_string() == prefix
}

///|
fn trim_trailing_semicolons(text : String) -> String {
  let mut out = text.trim().to_string()
  while out.length() > 0 && out.code_unit_at(out.length() - 1).to_int() == 59 { // ';'
    out = out[:out.length() - 1].to_string().trim().to_string()
  }
  out
}

///|
fn strip_wgsl_line_comment(text : String) -> String {
  let mut i = 0
  while i + 1 < text.length() {
    if text.code_unit_at(i).to_int() == 47 && // '/'
      text.code_unit_at(i + 1).to_int() == 47 { // '/'
      return text[:i].to_string()
    }
    i = i + 1
  }
  text
}

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
fn wgsl_import_brace_balance(text : String) -> Int {
  let mut balance = 0
  for i in 0..<text.length() {
    let ch = text.code_unit_at(i).to_int()
    if ch == 123 { // '{'
      balance = balance + 1
      continue
    }
    if ch == 125 { // '}'
      balance = balance - 1
    }
  }
  balance
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
fn split_last_wgsl_path(text : String) -> (String, String)? {
  let mut index = -1
  let mut i = 0
  while i + 1 < text.length() {
    if text.code_unit_at(i).to_int() == 58 && // ':'
      text.code_unit_at(i + 1).to_int() == 58 { // ':'
      index = i
    }
    i = i + 1
  }
  if index < 0 {
    return None
  }
  Some(
    (
      text[:index].to_string().trim().to_string(),
      text[index + 2:text.length()].to_string().trim().to_string(),
    ),
  )
}

///|
fn split_import_head_and_tail(text : String) -> (String, String) {
  let trimmed = text.trim().to_string()
  if trimmed == "" {
    return ("", "")
  }
  if trimmed.code_unit_at(0).to_int() == 34 { // '"'
    let mut end_quote = 1
    while end_quote < trimmed.length() &&
          trimmed.code_unit_at(end_quote).to_int() != 34 {
      end_quote = end_quote + 1
    }
    if end_quote < trimmed.length() {
      let head = trimmed[:end_quote + 1].to_string().trim().to_string()
      let tail = trimmed[end_quote + 1:trimmed.length()]
        .to_string()
        .trim()
        .to_string()
      return (head, tail)
    }
  }
  let mut split_index = -1
  let mut i = 0
  while i < trimmed.length() {
    let ch = trimmed.code_unit_at(i).to_int()
    if ch == 32 || ch == 9 { // ' ' or '\t'
      split_index = i
      break
    }
    i = i + 1
  }
  if split_index < 0 {
    return (trimmed, "")
  }
  (
    trimmed[:split_index].to_string().trim().to_string(),
    trimmed[split_index:trimmed.length()].to_string().trim().to_string(),
  )
}

///|
fn parse_define_value(raw_value : String) -> ShaderDefValue {
  let value = trim_trailing_semicolons(strip_wgsl_line_comment(raw_value))
  if value == "" {
    return ShaderDefValue::Bool(true)
  }
  if value == "true" {
    return ShaderDefValue::Bool(true)
  }
  if value == "false" {
    return ShaderDefValue::Bool(false)
  }
  if ends_with_text(value, "u") || ends_with_text(value, "U") {
    let unsigned_text = value[:value.length() - 1]
      .to_string()
      .trim()
      .to_string()
    let parsed = @strconv.parse_int(unsigned_text[:], base=10) catch {
      _ => return ShaderDefValue::Bool(true)
    }
    return ShaderDefValue::UInt(parsed.reinterpret_as_uint())
  }
  let parsed = @strconv.parse_int(value[:], base=10) catch {
    _ => return ShaderDefValue::Bool(true)
  }
  ShaderDefValue::Int(parsed)
}

///|
fn ends_with_text(text : String, suffix : String) -> Bool {
  text.length() >= suffix.length() &&
  text[text.length() - suffix.length():text.length()].to_string() == suffix
}

///|
fn collect_import_definitions(
  spec : String,
  prefix : String,
  from_group : Bool,
  imports : Array[ImportDefinition],
) -> Unit {
  let text = trim_trailing_semicolons(strip_wgsl_line_comment(spec))
  if text == "" {
    return
  }

  let group_separator = find_top_level_wgsl_group_separator(text)
  if group_separator >= 0 {
    let group_prefix = text[:group_separator].to_string().trim().to_string()
    let body = extract_wgsl_group_body(text, group_separator + 2)
    let next_prefix = join_wgsl_import_prefix(prefix, group_prefix)
    for item in split_top_level_wgsl_import_items(body) {
      collect_import_definitions(item, next_prefix, true, imports)
    }
    return
  }

  let alias_split : Array[String] = []
  for part in text.split(" as ") {
    alias_split.push(part.to_string())
  }
  let raw_spec = alias_split[0].trim().to_string()
  let alias_name = if alias_split.length() > 1 {
    trim_trailing_semicolons(alias_split[1])
  } else {
    ""
  }
  let (head, tail) = split_import_head_and_tail(raw_spec)
  let full_head = if prefix != "" &&
    !(head.length() > 0 && head.code_unit_at(0).to_int() == 34) {
    join_wgsl_import_prefix(prefix, head)
  } else {
    head
  }

  if full_head == "" {
    return
  }

  if tail != "" {
    imports.push(ImportDefinition::{
      import_path: full_head,
      items: split_top_level_wgsl_import_items(tail),
    })
    return
  }

  if alias_name != "" {
    imports.push(ImportDefinition::{ import_path: full_head, items: [] })
    return
  }

  if from_group {
    if split_last_wgsl_path(full_head) is Some((module_path, item_name)) {
      imports.push(ImportDefinition::{
        import_path: module_path,
        items: [item_name],
      })
      return
    }
  }

  imports.push(ImportDefinition::{ import_path: full_head, items: [] })
}

///|
pub fn get_preprocessor_metadata(source : String) -> PreprocessorMetaData {
  let imports : Array[ImportDefinition] = []
  let defines : @hashmap.HashMap[String, ShaderDefValue] = @hashmap.HashMap::new()
  let cleaned_lines : Array[String] = []
  let lines : Array[String] = []
  let mut name : String? = None

  for line_item in source.split("\n") {
    lines.push(line_item.to_string())
  }

  let mut line_index = 0
  while line_index < lines.length() {
    let line = lines[line_index]
    let trimmed = strip_wgsl_line_comment(line).trim().to_string()

    if starts_with_text(trimmed, "#define_import_path ") {
      let raw_name = trimmed[20:trimmed.length()].to_string()
      let import_name = trim_trailing_semicolons(raw_name)
      if import_name != "" {
        name = Some(import_name)
      }
      line_index = line_index + 1
      continue
    }

    if starts_with_text(trimmed, "#define ") {
      let raw_define = trimmed[8:trimmed.length()]
        .to_string()
        .trim()
        .to_string()
      if raw_define != "" {
        let (define_name, define_tail) = split_import_head_and_tail(raw_define)
        if define_name != "" {
          defines.set(define_name, parse_define_value(define_tail))
        }
      }
      line_index = line_index + 1
      continue
    }

    if starts_with_text(trimmed, "#import ") {
      let mut spec = trimmed[8:trimmed.length()].to_string()
      let mut brace_balance = wgsl_import_brace_balance(spec)
      while brace_balance > 0 && line_index + 1 < lines.length() {
        line_index = line_index + 1
        let next_line = strip_wgsl_line_comment(lines[line_index])
        spec = spec + "\n" + next_line
        brace_balance = brace_balance + wgsl_import_brace_balance(next_line)
      }
      collect_import_definitions(spec, "", false, imports)
      line_index = line_index + 1
      continue
    }

    cleaned_lines.push(line)
    line_index = line_index + 1
  }

  let mut cleaned_source = ""
  for i in 0..<cleaned_lines.length() {
    if i > 0 {
      cleaned_source = cleaned_source + "\n"
    }
    cleaned_source = cleaned_source + cleaned_lines[i]
  }

  PreprocessorMetaData::{ name, imports, defines, cleaned_source }
}

///|
pub fn get_preprocessor_data(
  source : String,
) -> (
  String?,
  Array[ImportDefinition],
  @hashmap.HashMap[String, ShaderDefValue],
) {
  let metadata = get_preprocessor_metadata(source)
  (metadata.name, metadata.imports, metadata.defines)
}
