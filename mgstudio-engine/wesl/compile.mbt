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
pub struct CompileOptions {
  imports : Bool
  condcomp : Bool
  strip : Bool
  lower : Bool
  lazy_resolution : Bool
  mangle_root : Bool
  keep_root : Bool
  keep : Array[String]?
  features : @hashmap.HashMap[String, Bool]
}

///|
pub fn CompileOptions::default() -> CompileOptions {
  CompileOptions::{
    imports: true,
    condcomp: true,
    strip: true,
    lower: false,
    lazy_resolution: true,
    mangle_root: false,
    keep_root: false,
    keep: None,
    features: @hashmap.HashMap::new(),
  }
}

///|
pub fn CompileOptions::with_imports(
  self : CompileOptions,
  imports : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, imports, }
}

///|
pub fn CompileOptions::with_condcomp(
  self : CompileOptions,
  condcomp : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, condcomp, }
}

///|
pub fn CompileOptions::with_lower(
  self : CompileOptions,
  lower : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, lower, }
}

///|
pub fn CompileOptions::with_strip(
  self : CompileOptions,
  strip : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, strip, }
}

///|
pub fn CompileOptions::with_lazy(
  self : CompileOptions,
  enabled : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, lazy_resolution: enabled }
}

///|
pub fn CompileOptions::with_mangle_root(
  self : CompileOptions,
  mangle_root : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, mangle_root, }
}

///|
pub fn CompileOptions::with_keep_root(
  self : CompileOptions,
  keep_root : Bool,
) -> CompileOptions {
  CompileOptions::{ ..self, keep_root, }
}

///|
pub fn CompileOptions::keep_declarations(
  self : CompileOptions,
  keep : Array[String],
) -> CompileOptions {
  CompileOptions::{ ..self, keep: Some(keep) }
}

///|
pub fn CompileOptions::with_feature(
  self : CompileOptions,
  name : String,
  value : Bool,
) -> CompileOptions {
  self.features.set(name, value)
  self
}

///|
pub struct CompileResult {
  source : String
  modules : Array[ModulePath]
} derive(Debug)

///|
pub fn CompileResult::to_string(self : CompileResult) -> String {
  self.source
}

///|
pub(all) suberror WeslCompileError {
  Resolve(ResolveError)
  Parse(String)
  InvalidExpression(String)
  DuplicateSymbol(String)
  MissingDecl(ModulePath, String)
  Private(String, ModulePath)
}

///|
pub fn WeslCompileError::message(self : WeslCompileError) -> String {
  match self {
    Resolve(err) => err.message()
    Parse(reason) => reason
    InvalidExpression(expr) => "invalid if attribute expression: `\{expr}`"
    DuplicateSymbol(symbol) => "duplicate declaration of `\{symbol}`"
    MissingDecl(path, item) =>
      "module `\{path.to_string()}` has no declaration `\{item}`"
    Private(item, path) =>
      "import of `\{item}` in module `\{path.to_string()}` is not `@publish`, but another module tried to import it"
  }
}

///|
priv struct ImportItem {
  module_path : ModulePath
  item_name : String
  local_name : String
  public : Bool
}

///|
priv struct ModuleItem {
  name : String?
  source : String
  entrypoint : Bool
  is_const_assert : Bool
  raw_tokens : Array[String]
  local_refs : Array[String]
  import_refs : Array[String]
}

///|
priv struct ParsedModule {
  path : ModulePath
  imports : Array[ImportItem]
  import_by_local : @hashmap.HashMap[String, Int]
  items : Array[ModuleItem]
  named_items : @hashmap.HashMap[String, Int]
}

///|
priv enum ExportTarget {
  Local(Int)
  ReExport(ImportItem)
  Private
  Missing
}

///|
fn wesl_is_identifier_char(code : Int) -> Bool {
  (code >= 48 && code <= 57) ||
  (code >= 65 && code <= 90) ||
  (code >= 97 && code <= 122) ||
  code == 95
}

///|
fn wesl_is_whitespace(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
fn wesl_skip_whitespace(source : String, start : Int) -> Int {
  let mut i = start
  while i < source.length() &&
        wesl_is_whitespace(source.code_unit_at(i).to_int()) {
    i = i + 1
  }
  i
}

///|
fn wesl_starts_with_at(source : String, index : Int, needle : String) -> Bool {
  if index < 0 || index + needle.length() > source.length() {
    return false
  }
  source[index:index + needle.length()].to_string() == needle
}

///|
fn wesl_find_first(source : String, needle : String, start : Int) -> Int? {
  if needle == "" {
    return Some(start)
  }
  let mut index = start
  while index + needle.length() <= source.length() {
    if wesl_starts_with_at(source, index, needle) {
      return Some(index)
    }
    index = index + 1
  }
  None
}

///|
fn wesl_find_matching_delim(
  source : String,
  start : Int,
  open_code : Int,
  close_code : Int,
) -> Int raise WeslCompileError {
  let mut depth = 0
  let mut i = start
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    if code == open_code {
      depth = depth + 1
    } else if code == close_code {
      depth = depth - 1
      if depth == 0 {
        return i
      }
    }
    i = i + 1
  }
  raise WeslCompileError::Parse("unclosed delimiter in WESL source")
}

///|
fn wesl_parse_if_primary(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let i = wesl_skip_whitespace(source, index)
  if i >= source.length() {
    raise WeslCompileError::InvalidExpression(source)
  }
  if source.code_unit_at(i).to_int() == 40 { // '('
    let (value, next_index) = wesl_parse_if_or(source, features, i + 1)
    let end_index = wesl_skip_whitespace(source, next_index)
    if end_index >= source.length() ||
      source.code_unit_at(end_index).to_int() != 41 {
      raise WeslCompileError::InvalidExpression(source)
    }
    return (value, end_index + 1)
  }
  let mut end_index = i
  while end_index < source.length() &&
        wesl_is_identifier_char(source.code_unit_at(end_index).to_int()) {
    end_index = end_index + 1
  }
  if end_index == i {
    raise WeslCompileError::InvalidExpression(source)
  }
  let ident = source[i:end_index].to_string()
  (features.get(ident).unwrap_or(false), end_index)
}

///|
fn wesl_parse_if_not(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let i = wesl_skip_whitespace(source, index)
  if i < source.length() && source.code_unit_at(i).to_int() == 33 { // '!'
    let (value, next_index) = wesl_parse_if_not(source, features, i + 1)
    (!value, next_index)
  } else {
    wesl_parse_if_primary(source, features, i)
  }
}

///|
fn wesl_parse_if_and(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let (initial, initial_index) = wesl_parse_if_not(source, features, index)
  let mut lhs = initial
  let mut next_index = initial_index
  let mut i = wesl_skip_whitespace(source, next_index)
  while i + 1 < source.length() && wesl_starts_with_at(source, i, "&&") {
    let (rhs, rhs_index) = wesl_parse_if_not(source, features, i + 2)
    lhs = lhs && rhs
    next_index = rhs_index
    i = wesl_skip_whitespace(source, next_index)
  }
  (lhs, next_index)
}

///|
fn wesl_parse_if_or(
  source : String,
  features : @hashmap.HashMap[String, Bool],
  index : Int,
) -> (Bool, Int) raise WeslCompileError {
  let (initial, initial_index) = wesl_parse_if_and(source, features, index)
  let mut lhs = initial
  let mut next_index = initial_index
  let mut i = wesl_skip_whitespace(source, next_index)
  while i + 1 < source.length() && wesl_starts_with_at(source, i, "||") {
    let (rhs, rhs_index) = wesl_parse_if_and(source, features, i + 2)
    lhs = lhs || rhs
    next_index = rhs_index
    i = wesl_skip_whitespace(source, next_index)
  }
  (lhs, next_index)
}

///|
fn wesl_parse_if_value(
  expr : String,
  features : @hashmap.HashMap[String, Bool],
) -> Bool raise WeslCompileError {
  let source = expr.trim().to_string()
  if source == "" {
    raise WeslCompileError::InvalidExpression(expr)
  }
  let (value, next_index) = wesl_parse_if_or(source, features, 0)
  let end_index = wesl_skip_whitespace(source, next_index)
  if end_index != source.length() {
    raise WeslCompileError::InvalidExpression(expr)
  }
  value
}

///|
fn wesl_apply_condcomp(
  source : String,
  features : @hashmap.HashMap[String, Bool],
) -> String raise WeslCompileError {
  let mut out = ""
  let mut index = 0
  while index < source.length() {
    if wesl_starts_with_at(source, index, "@if") {
      let expr_start = wesl_skip_whitespace(source, index + 3)
      if expr_start >= source.length() ||
        source.code_unit_at(expr_start).to_int() != 40 {
        raise WeslCompileError::InvalidExpression(
          source[index:source.length()].to_string(),
        )
      }
      let expr_end = wesl_find_matching_delim(source, expr_start, 40, 41)
      let expr = source[expr_start + 1:expr_end].to_string()
      let block_start = wesl_skip_whitespace(source, expr_end + 1)
      if block_start >= source.length() ||
        source.code_unit_at(block_start).to_int() != 123 {
        raise WeslCompileError::Parse("missing block after @if attribute")
      }
      let block_end = wesl_find_matching_delim(source, block_start, 123, 125)
      let mut selected : String? = None
      if wesl_parse_if_value(expr, features) {
        selected = Some(
          wesl_apply_condcomp(
            source[block_start + 1:block_end].to_string(),
            features,
          ),
        )
      }
      let mut next_index = block_end + 1
      while true {
        let else_start = wesl_skip_whitespace(source, next_index)
        if !wesl_starts_with_at(source, else_start, "@else") {
          next_index = else_start
          break
        }
        let tail_start = wesl_skip_whitespace(source, else_start + 5)
        if wesl_starts_with_at(source, tail_start, "if") {
          let elif_expr_start = wesl_skip_whitespace(source, tail_start + 2)
          if elif_expr_start >= source.length() ||
            source.code_unit_at(elif_expr_start).to_int() != 40 {
            raise WeslCompileError::InvalidExpression(
              source[else_start:source.length()].to_string(),
            )
          }
          let elif_expr_end = wesl_find_matching_delim(
            source, elif_expr_start, 40, 41,
          )
          let elif_expr = source[elif_expr_start + 1:elif_expr_end].to_string()
          let elif_block_start = wesl_skip_whitespace(source, elif_expr_end + 1)
          if elif_block_start >= source.length() ||
            source.code_unit_at(elif_block_start).to_int() != 123 {
            raise WeslCompileError::Parse(
              "missing block after @else if attribute",
            )
          }
          let elif_block_end = wesl_find_matching_delim(
            source, elif_block_start, 123, 125,
          )
          if selected is None && wesl_parse_if_value(elif_expr, features) {
            selected = Some(
              wesl_apply_condcomp(
                source[elif_block_start + 1:elif_block_end].to_string(),
                features,
              ),
            )
          }
          next_index = elif_block_end + 1
          continue
        }
        let else_block_start = wesl_skip_whitespace(source, tail_start)
        if else_block_start >= source.length() ||
          source.code_unit_at(else_block_start).to_int() != 123 {
          raise WeslCompileError::Parse("missing block after @else attribute")
        }
        let else_block_end = wesl_find_matching_delim(
          source, else_block_start, 123, 125,
        )
        if selected is None {
          selected = Some(
            wesl_apply_condcomp(
              source[else_block_start + 1:else_block_end].to_string(),
              features,
            ),
          )
        }
        next_index = else_block_end + 1
        break
      }
      out = out + selected.unwrap_or("")
      index = next_index
      continue
    }
    out = out + source[index:index + 1].to_string()
    index = index + 1
  }
  out
}

///|
fn wesl_push_unique(items : Array[String], value : String) -> Unit {
  if value == "" {
    return
  }
  for item in items {
    if item == value {
      return
    }
  }
  items.push(value)
}

///|
fn wesl_is_identifier_start(code : Int) -> Bool {
  (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code == 95
}

///|
fn wesl_strip_line_comment(text : String) -> String {
  match wesl_find_first(text, "//", 0) {
    Some(index) => text[:index].to_string()
    None => text
  }
}

///|
fn wesl_split_top_level_items(source : String) -> Array[String] {
  let items : Array[String] = []
  let current_lines : Array[String] = []
  let mut brace_depth = 0
  let mut seen_brace = false
  for raw_line in source.split("\n") {
    let line = raw_line.to_string()
    current_lines.push(line)
    let scan = wesl_strip_line_comment(line)
    for i in 0..<scan.length() {
      let code = scan.code_unit_at(i).to_int()
      if code == 123 { // '{'
        brace_depth = brace_depth + 1
        seen_brace = true
      } else if code == 125 { // '}'
        brace_depth = brace_depth - 1
      }
    }
    let current = current_lines.join("\n")
    let trimmed = current.trim().to_string()
    if trimmed == "" {
      current_lines.clear()
      continue
    }
    if brace_depth == 0 && (trimmed.has_suffix(";") || seen_brace) {
      items.push(current)
      current_lines.clear()
      seen_brace = false
    }
  }
  let tail = current_lines.join("\n")
  if tail.trim().to_string() != "" {
    items.push(tail)
  }
  items
}

///|
fn wesl_collect_leading_attr_names(source : String) -> Array[String] {
  let attrs : Array[String] = []
  let mut index = 0
  while true {
    index = wesl_skip_whitespace(source, index)
    if index >= source.length() || source.code_unit_at(index).to_int() != 64 {
      break
    }
    let name_start = index + 1
    let mut name_end = name_start
    while name_end < source.length() &&
          wesl_is_identifier_char(source.code_unit_at(name_end).to_int()) {
      name_end = name_end + 1
    }
    if name_end == name_start {
      break
    }
    attrs.push(source[name_start:name_end].to_string())
    index = wesl_skip_whitespace(source, name_end)
    if index < source.length() && source.code_unit_at(index).to_int() == 40 {
      index = (wesl_find_matching_delim(source, index, 40, 41) catch {
          _ => return attrs
        }) +
        1
    }
  }
  attrs
}

///|
fn wesl_strip_leading_attrs(source : String) -> String {
  let mut index = 0
  while index <= source.length() {
    index = wesl_skip_whitespace(source, index)
    if index >= source.length() || source.code_unit_at(index).to_int() != 64 {
      return source[index:source.length()].to_string()
    }
    let mut name_end = index + 1
    while name_end < source.length() &&
          wesl_is_identifier_char(source.code_unit_at(name_end).to_int()) {
      name_end = name_end + 1
    }
    index = wesl_skip_whitespace(source, name_end)
    if index < source.length() && source.code_unit_at(index).to_int() == 40 {
      index = (wesl_find_matching_delim(source, index, 40, 41) catch {
          _ => return source[index:source.length()].to_string()
        }) +
        1
    }
  }
  source[index:source.length()].to_string()
}

///|
fn wesl_attrs_contain(attrs : Array[String], target : String) -> Bool {
  for attr in attrs {
    if attr == target {
      return true
    }
  }
  false
}

///|
fn wesl_item_is_import(source : String) -> Bool {
  wesl_strip_leading_attrs(source).trim().to_string().has_prefix("import ")
}

///|
fn wesl_split_top_level_commas(source : String) -> Array[String] {
  let parts : Array[String] = []
  let mut brace_depth = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut start = 0
  for i in 0..<source.length() {
    let code = source.code_unit_at(i).to_int()
    if code == 123 { // '{'
      brace_depth = brace_depth + 1
    } else if code == 125 { // '}'
      brace_depth = brace_depth - 1
    } else if code == 40 { // '('
      paren_depth = paren_depth + 1
    } else if code == 41 { // ')'
      paren_depth = paren_depth - 1
    } else if code == 91 { // '['
      bracket_depth = bracket_depth + 1
    } else if code == 93 { // ']'
      bracket_depth = bracket_depth - 1
    } else if code == 44 && // ','
      brace_depth == 0 &&
      paren_depth == 0 &&
      bracket_depth == 0 {
      parts.push(source[start:i].to_string())
      start = i + 1
    }
  }
  parts.push(source[start:source.length()].to_string())
  parts
}

///|
fn wesl_find_top_level_pattern(source : String, pattern : String) -> Int? {
  if pattern == "" {
    return Some(0)
  }
  let mut brace_depth = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut index = 0
  while index + pattern.length() <= source.length() {
    let code = source.code_unit_at(index).to_int()
    if brace_depth == 0 &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      wesl_starts_with_at(source, index, pattern) {
      return Some(index)
    }
    if code == 123 {
      brace_depth = brace_depth + 1
    } else if code == 125 {
      brace_depth = brace_depth - 1
    } else if code == 40 {
      paren_depth = paren_depth + 1
    } else if code == 41 {
      paren_depth = paren_depth - 1
    } else if code == 91 {
      bracket_depth = bracket_depth + 1
    } else if code == 93 {
      bracket_depth = bracket_depth - 1
    }
    index = index + 1
  }
  None
}

///|
fn wesl_find_top_level_last_double_colon(source : String) -> Int? {
  let mut brace_depth = 0
  let mut paren_depth = 0
  let mut bracket_depth = 0
  let mut found : Int? = None
  let mut index = 0
  while index + 2 <= source.length() {
    let code = source.code_unit_at(index).to_int()
    if brace_depth == 0 &&
      paren_depth == 0 &&
      bracket_depth == 0 &&
      wesl_starts_with_at(source, index, "::") {
      found = Some(index)
    }
    if code == 123 {
      brace_depth = brace_depth + 1
    } else if code == 125 {
      brace_depth = brace_depth - 1
    } else if code == 40 {
      paren_depth = paren_depth + 1
    } else if code == 41 {
      paren_depth = paren_depth - 1
    } else if code == 91 {
      bracket_depth = bracket_depth + 1
    } else if code == 93 {
      bracket_depth = bracket_depth - 1
    }
    index = index + 1
  }
  found
}

///|
fn wesl_find_top_level_as(source : String) -> Int? {
  wesl_find_top_level_pattern(source, " as ")
}

///|
fn wesl_join_import_path_text(
  base_path_text : String?,
  suffix : String,
) -> String {
  let trimmed_suffix = suffix.trim().to_string()
  match base_path_text {
    Some(base) =>
      if trimmed_suffix == "" {
        base
      } else {
        "\{base}::\{trimmed_suffix}"
      }
    None => trimmed_suffix
  }
}

///|
fn wesl_resolve_import_module_path(
  current_path : ModulePath,
  module_path_text : String,
) -> ModulePath raise WeslCompileError {
  let raw_module_path = parse_module_path(module_path_text.trim().to_string()) catch {
    err => raise WeslCompileError::Parse(err.message())
  }
  current_path.join_path(raw_module_path)
}

///|
fn wesl_parse_simple_import(
  current_path : ModulePath,
  base_path_text : String?,
  text : String,
  public : Bool,
  imports : Array[ImportItem],
) -> Unit raise WeslCompileError {
  let trimmed = text.trim().to_string()
  if trimmed == "" {
    return
  }
  let (item_source, local_name) = match wesl_find_top_level_as(trimmed) {
    Some(index) =>
      (
        trimmed[:index].to_string().trim().to_string(),
        trimmed[index + 4:trimmed.length()].to_string().trim().to_string(),
      )
    None => (trimmed, "")
  }
  let (module_path_text, item_name) = match base_path_text {
    Some(base) =>
      match wesl_find_top_level_last_double_colon(item_source) {
        Some(index) =>
          (
            wesl_join_import_path_text(
              Some(base),
              item_source[:index].to_string(),
            ),
            item_source[index + 2:item_source.length()]
            .to_string()
            .trim()
            .to_string(),
          )
        None => (base, item_source.trim().to_string())
      }
    None =>
      match wesl_find_top_level_last_double_colon(item_source) {
        Some(index) =>
          (
            item_source[:index].to_string(),
            item_source[index + 2:item_source.length()]
            .to_string()
            .trim()
            .to_string(),
          )
        None => return
      }
  }
  let resolved_module_path = wesl_resolve_import_module_path(
    current_path, module_path_text,
  )
  imports.push(ImportItem::{
    module_path: resolved_module_path,
    item_name,
    local_name: if local_name == "" {
      item_name
    } else {
      local_name
    },
    public,
  })
}

///|
fn wesl_parse_import_content(
  current_path : ModulePath,
  base_path_text : String?,
  text : String,
  public : Bool,
  imports : Array[ImportItem],
) -> Unit raise WeslCompileError {
  let trimmed = text.trim().to_string()
  if trimmed == "" {
    return
  }
  if trimmed.has_prefix("{") {
    let end_index = wesl_find_matching_delim(trimmed, 0, 123, 125)
    if end_index + 1 != trimmed.length() {
      raise WeslCompileError::Parse("unsupported import statement: \{trimmed}")
    }
    let inner = trimmed[1:end_index].to_string()
    for part in wesl_split_top_level_commas(inner) {
      wesl_parse_import_content(
        current_path, base_path_text, part, public, imports,
      )
    }
    return
  }
  match wesl_find_top_level_pattern(trimmed, "::{") {
    Some(index) => {
      let prefix = trimmed[:index].to_string().trim().to_string()
      let nested_base = wesl_join_import_path_text(base_path_text, prefix)
      let nested = trimmed[index + 2:trimmed.length()].to_string()
      wesl_parse_import_content(
        current_path,
        Some(nested_base),
        nested,
        public,
        imports,
      )
    }
    None =>
      wesl_parse_simple_import(
        current_path, base_path_text, trimmed, public, imports,
      )
  }
}

///|
fn wesl_parse_import_statement(
  current_path : ModulePath,
  statement : String,
  imports : Array[ImportItem],
) -> Unit raise WeslCompileError {
  let attrs = wesl_collect_leading_attr_names(statement)
  let public = wesl_attrs_contain(attrs, "publish")
  let stripped = wesl_strip_leading_attrs(statement).trim().to_string()
  if !stripped.has_prefix("import ") || !stripped.has_suffix(";") {
    raise WeslCompileError::Parse(
      "unsupported import statement: \{statement.trim().to_string()}",
    )
  }
  let content = stripped[7:stripped.length() - 1].to_string()
  wesl_parse_import_content(current_path, None, content, public, imports)
}

///|
fn wesl_try_decl_name(trimmed : String) -> String? {
  if trimmed.has_prefix("fn ") {
    let rest = trimmed[3:trimmed.length()].to_string()
    match wesl_find_first(rest, "(", 0) {
      Some(end_index) => Some(rest[:end_index].trim().to_string())
      None => None
    }
  } else if trimmed.has_prefix("struct ") {
    let rest = trimmed[7:trimmed.length()].to_string().trim().to_string()
    let name = rest.split(" ").next().unwrap_or("").to_string()
    if name == "" {
      None
    } else {
      Some(name)
    }
  } else if trimmed.has_prefix("alias ") {
    let rest = trimmed[6:trimmed.length()].to_string().trim().to_string()
    match wesl_find_first(rest, "=", 0) {
      Some(end_index) => Some(rest[:end_index].trim().to_string())
      None => None
    }
  } else if trimmed.has_prefix("const ") ||
    trimmed.has_prefix("override ") ||
    trimmed.has_prefix("let ") {
    let head = if trimmed.has_prefix("const ") {
      trimmed[6:trimmed.length()].to_string()
    } else if trimmed.has_prefix("override ") {
      trimmed[9:trimmed.length()].to_string()
    } else {
      trimmed[4:trimmed.length()].to_string()
    }
    let name = head.split(" ").next().unwrap_or("").to_string()
    if name == "" {
      None
    } else {
      Some(name)
    }
  } else if trimmed.has_prefix("var") {
    let mut rest = trimmed[3:trimmed.length()].to_string().trim().to_string()
    if rest.has_prefix("<") {
      let end_index = wesl_find_matching_delim(rest, 0, 60, 62) catch {
        _ => return None
      }
      rest = rest[end_index + 1:rest.length()].to_string().trim().to_string()
    }
    let mut name_end = 0
    while name_end < rest.length() &&
          wesl_is_identifier_char(rest.code_unit_at(name_end).to_int()) {
      name_end = name_end + 1
    }
    if name_end == 0 {
      None
    } else {
      Some(rest[:name_end].to_string())
    }
  } else {
    None
  }
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
fn wesl_parse_alias_target(trimmed : String) -> String? {
  if !trimmed.has_prefix("alias ") {
    return None
  }
  match wesl_find_first(trimmed, "=", 0) {
    Some(index) =>
      Some(
        trim_trailing_semicolons(
          trimmed[index + 1:trimmed.length()].to_string().trim().to_string(),
        ),
      )
    None => None
  }
}

///|
fn wesl_parse_const_initializer(trimmed : String) -> String? {
  if !trimmed.has_prefix("const ") {
    return None
  }
  match wesl_find_first(trimmed, "=", 0) {
    Some(index) =>
      Some(
        trim_trailing_semicolons(
          trimmed[index + 1:trimmed.length()].to_string().trim().to_string(),
        ),
      )
    None => None
  }
}

///|
fn wesl_collect_identifiers(source : String) -> Array[String] {
  let tokens : Array[String] = []
  let mut index = 0
  let mut in_line_comment = false
  while index < source.length() {
    let code = source.code_unit_at(index).to_int()
    if in_line_comment {
      if code == 10 {
        in_line_comment = false
      }
      index = index + 1
      continue
    }
    if code == 47 &&
      index + 1 < source.length() &&
      source.code_unit_at(index + 1).to_int() == 47 {
      in_line_comment = true
      index = index + 2
      continue
    }
    if code == 64 { // '@'
      index = index + 1
      while index < source.length() &&
            wesl_is_identifier_char(source.code_unit_at(index).to_int()) {
        index = index + 1
      }
      continue
    }
    if wesl_is_identifier_start(code) {
      let prev_code = if index == 0 {
        -1
      } else {
        source.code_unit_at(index - 1).to_int()
      }
      let start = index
      index = index + 1
      while index < source.length() &&
            wesl_is_identifier_char(source.code_unit_at(index).to_int()) {
        index = index + 1
      }
      if prev_code != 46 { // '.'
        wesl_push_unique(tokens, source[start:index].to_string())
      }
      continue
    }
    index = index + 1
  }
  tokens
}

///|
fn wesl_parse_module_item(source : String) -> ModuleItem {
  let trimmed_source = source.trim().to_string()
  let stripped = wesl_strip_leading_attrs(trimmed_source).trim().to_string()
  let attrs = wesl_collect_leading_attr_names(trimmed_source)
  ModuleItem::{
    name: wesl_try_decl_name(stripped),
    source: trimmed_source,
    entrypoint: stripped.has_prefix("fn ") &&
    (
      wesl_attrs_contain(attrs, "fragment") ||
      wesl_attrs_contain(attrs, "vertex") ||
      wesl_attrs_contain(attrs, "compute")
    ),
    is_const_assert: stripped.has_prefix("const_assert"),
    raw_tokens: wesl_collect_identifiers(stripped),
    local_refs: [],
    import_refs: [],
  }
}

///|
fn wesl_replace_identifier(
  source : String,
  old_name : String,
  new_name : String,
) -> String {
  if old_name == new_name || old_name == "" {
    return source
  }
  let mut out = ""
  let mut index = 0
  while index < source.length() {
    let can_match = index + old_name.length() <= source.length() &&
      source[index:index + old_name.length()].to_string() == old_name
    if can_match {
      let prev_code = if index == 0 {
        -1
      } else {
        source.code_unit_at(index - 1).to_int()
      }
      let next_code = if index + old_name.length() >= source.length() {
        -1
      } else {
        source.code_unit_at(index + old_name.length()).to_int()
      }
      let prev_ok = prev_code < 0 || !wesl_is_identifier_char(prev_code)
      let next_ok = next_code < 0 || !wesl_is_identifier_char(next_code)
      if prev_ok && next_ok {
        out = out + new_name
        index = index + old_name.length()
        continue
      }
    }
    out = out + source[index:index + 1].to_string()
    index = index + 1
  }
  out
}

///|
fn wesl_decl_key(path : ModulePath, name : String) -> String {
  "\{path.to_string()}::\{name}"
}

///|
fn wesl_is_used_decl(
  used_decls : @hashmap.HashMap[String, Bool],
  path : ModulePath,
  name : String,
) -> Bool {
  used_decls.contains(wesl_decl_key(path, name))
}

///|
fn wesl_module_export_target(
  parsed_module : ParsedModule,
  name : String,
) -> ExportTarget {
  match parsed_module.named_items.get(name) {
    Some(index) => ExportTarget::Local(index)
    None =>
      match parsed_module.import_by_local.get(name) {
        Some(index) =>
          if parsed_module.imports[index].public {
            ExportTarget::ReExport(parsed_module.imports[index])
          } else {
            ExportTarget::Private
          }
        None => ExportTarget::Missing
      }
  }
}

///|
fn wesl_resolve_export_target(
  path : ModulePath,
  name : String,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
) -> (ModulePath, String) raise WeslCompileError {
  guard modules.get(path) is Some(parsed_module) else {
    raise WeslCompileError::MissingDecl(path, name)
  }
  match wesl_module_export_target(parsed_module, name) {
    ExportTarget::Local(_) => (path, name)
    ExportTarget::ReExport(import_item) =>
      wesl_resolve_export_target(
        import_item.module_path,
        import_item.item_name,
        modules,
      )
    ExportTarget::Private => raise WeslCompileError::Private(name, path)
    ExportTarget::Missing => raise WeslCompileError::MissingDecl(path, name)
  }
}

///|
fn[R : Resolver] wesl_load_module(
  path : ModulePath,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
) -> ParsedModule raise WeslCompileError {
  match modules.get(path) {
    Some(existing) => existing
    None => {
      let raw_source = R::resolve_source(resolver, path) catch {
        err => raise WeslCompileError::Resolve(err)
      }
      let source = if options.condcomp {
        wesl_apply_condcomp(raw_source, options.features)
      } else {
        raw_source
      }
      let imports : Array[ImportItem] = []
      let body_items : Array[String] = []
      for item in wesl_split_top_level_items(source) {
        if wesl_item_is_import(item) {
          if options.imports {
            wesl_parse_import_statement(path, item, imports)
          }
        } else if item.trim().to_string() != "" {
          body_items.push(item)
        }
      }
      let parsed_items : Array[ModuleItem] = []
      let named_items : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
      for item in body_items {
        let parsed = wesl_parse_module_item(item)
        match parsed.name {
          Some(name) =>
            if named_items.contains(name) {
              raise WeslCompileError::DuplicateSymbol(name)
            } else {
              named_items.set(name, parsed_items.length())
            }
          None => ()
        }
        parsed_items.push(parsed)
      }
      let import_by_local : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()
      for i in 0..<imports.length() {
        let import_item = imports[i]
        if named_items.contains(import_item.local_name) ||
          import_by_local.contains(import_item.local_name) {
          raise WeslCompileError::DuplicateSymbol(import_item.local_name)
        }
        import_by_local.set(import_item.local_name, i)
      }
      for i in 0..<parsed_items.length() {
        let parsed = parsed_items[i]
        let local_refs : Array[String] = []
        let import_refs : Array[String] = []
        for token in parsed.raw_tokens {
          if parsed.name is Some(name) && token == name {
            continue
          }
          if named_items.contains(token) {
            wesl_push_unique(local_refs, token)
          } else if import_by_local.contains(token) {
            wesl_push_unique(import_refs, token)
          }
        }
        parsed_items[i] = ModuleItem::{ ..parsed, local_refs, import_refs }
      }
      let parsed_module = ParsedModule::{
        path,
        imports,
        import_by_local,
        items: parsed_items,
        named_items,
      }
      modules.set(path, parsed_module)
      order.push(path)
      if options.imports && (!options.strip || !options.lazy_resolution) {
        for import_item in parsed_module.imports {
          let loaded = wesl_load_module(
            import_item.module_path,
            resolver,
            options,
            modules,
            order,
          )
          match wesl_module_export_target(loaded, import_item.item_name) {
            ExportTarget::Local(_) => ()
            ExportTarget::ReExport(_) => ()
            ExportTarget::Private =>
              raise WeslCompileError::Private(
                import_item.item_name,
                loaded.path,
              )
            ExportTarget::Missing =>
              raise WeslCompileError::MissingDecl(
                loaded.path,
                import_item.item_name,
              )
          }
        }
      }
      parsed_module
    }
  }
}

///|
fn[R : Resolver] wesl_mark_module_used(
  path : ModulePath,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
) -> ParsedModule raise WeslCompileError {
  let parsed_module = wesl_load_module(path, resolver, options, modules, order)
  if used_modules.contains(path) {
    return parsed_module
  }
  used_modules.set(path, true)
  for item in parsed_module.items {
    if !item.is_const_assert {
      continue
    }
    for local_ref in item.local_refs {
      ignore(
        wesl_mark_named_decl(
          path, local_ref, resolver, options, modules, order, used_modules, used_decls,
        ),
      )
    }
    for import_ref in item.import_refs {
      match parsed_module.import_by_local.get(import_ref) {
        Some(index) => {
          let import_item = parsed_module.imports[index]
          ignore(
            wesl_mark_named_decl(
              import_item.module_path,
              import_item.item_name,
              resolver,
              options,
              modules,
              order,
              used_modules,
              used_decls,
            ),
          )
        }
        None => ()
      }
    }
  }
  parsed_module
}

///|
fn[R : Resolver] wesl_mark_named_decl(
  path : ModulePath,
  name : String,
  resolver : R,
  options : CompileOptions,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  order : Array[ModulePath],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
) -> Unit raise WeslCompileError {
  let parsed_module = wesl_mark_module_used(
    path, resolver, options, modules, order, used_modules, used_decls,
  )
  let key = wesl_decl_key(path, name)
  if used_decls.contains(key) {
    return
  }
  match wesl_module_export_target(parsed_module, name) {
    ExportTarget::Local(index) => {
      used_decls.set(key, true)
      let item = parsed_module.items[index]
      for local_ref in item.local_refs {
        ignore(
          wesl_mark_named_decl(
            path, local_ref, resolver, options, modules, order, used_modules, used_decls,
          ),
        )
      }
      for import_ref in item.import_refs {
        match parsed_module.import_by_local.get(import_ref) {
          Some(import_index) => {
            let import_item = parsed_module.imports[import_index]
            ignore(
              wesl_mark_named_decl(
                import_item.module_path,
                import_item.item_name,
                resolver,
                options,
                modules,
                order,
                used_modules,
                used_decls,
              ),
            )
          }
          None => ()
        }
      }
    }
    ExportTarget::ReExport(import_item) => {
      used_decls.set(key, true)
      ignore(
        wesl_mark_named_decl(
          import_item.module_path,
          import_item.item_name,
          resolver,
          options,
          modules,
          order,
          used_modules,
          used_decls,
        ),
      )
    }
    ExportTarget::Private => raise WeslCompileError::Private(name, path)
    ExportTarget::Missing => raise WeslCompileError::MissingDecl(path, name)
  }
}

///|
fn wesl_root_keep_names(
  root : ParsedModule,
  options : CompileOptions,
) -> Array[String] {
  let keep_names : Array[String] = []
  if !options.strip || options.keep_root {
    for entry in root.named_items.iter() {
      let (name, _) = entry
      keep_names.push(name)
    }
    return keep_names
  }
  match options.keep {
    Some(keep) => {
      for name in keep {
        if root.named_items.contains(name) {
          keep_names.push(name)
        }
      }
      keep_names
    }
    None => {
      for item in root.items {
        if item.entrypoint && item.name is Some(name) {
          keep_names.push(name)
        }
      }
      keep_names
    }
  }
}

///|
fn wesl_apply_replacements(
  source : String,
  replacements : Array[(String, String)],
) -> String {
  let mut out = source
  for replacement in replacements {
    out = wesl_replace_identifier(out, replacement.0, replacement.1)
  }
  out
}

///|
fn wesl_lower_source(source : String) -> String {
  let alias_replacements : Array[(String, String)] = []
  let const_replacements : Array[(String, String)] = []
  let kept_items : Array[String] = []
  for item in wesl_split_top_level_items(source) {
    let trimmed_item = item.trim().to_string()
    if trimmed_item == "" {
      continue
    }
    let stripped = wesl_strip_leading_attrs(trimmed_item).trim().to_string()
    match wesl_try_decl_name(stripped) {
      Some(name) =>
        match wesl_parse_alias_target(stripped) {
          Some(target) => {
            alias_replacements.push(
              (
                name,
                wesl_apply_replacements(
                  wesl_apply_replacements(target, alias_replacements),
                  const_replacements,
                ),
              ),
            )
            continue
          }
          None =>
            match wesl_parse_const_initializer(stripped) {
              Some(initializer) => {
                const_replacements.push(
                  (
                    name,
                    "(\{wesl_apply_replacements(wesl_apply_replacements(initializer, alias_replacements), const_replacements)})",
                  ),
                )
                continue
              }
              None => ()
            }
        }
      None => ()
    }
    kept_items.push(trimmed_item)
  }
  let lowered : Array[String] = []
  for item in kept_items {
    let lowered_item = wesl_apply_replacements(
        wesl_apply_replacements(item, alias_replacements),
        const_replacements,
      )
      .trim()
      .to_string()
    if lowered_item != "" {
      lowered.push(lowered_item)
    }
  }
  lowered.join("\n\n")
}

///|
fn wesl_emit_item_source(
  parsed_module : ParsedModule,
  item : ModuleItem,
  root : ModulePath,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  used_decls : @hashmap.HashMap[String, Bool],
  mangler : EscapeMangler,
  options : CompileOptions,
) -> String {
  let mut current = item.source
  for import_ref in item.import_refs {
    match parsed_module.import_by_local.get(import_ref) {
      Some(import_index) => {
        let import_item = parsed_module.imports[import_index]
        let (target_path, target_name) = wesl_resolve_export_target(
          import_item.module_path,
          import_item.item_name,
          modules,
        ) catch {
          _ => (import_item.module_path, import_item.item_name)
        }
        current = wesl_replace_identifier(
          current,
          import_ref,
          EscapeMangler::mangle(mangler, target_path, target_name),
        )
      }
      None => ()
    }
  }
  if parsed_module.path != root || options.mangle_root {
    for entry in parsed_module.named_items.iter() {
      let (name, _) = entry
      if !options.strip ||
        wesl_is_used_decl(used_decls, parsed_module.path, name) {
        current = wesl_replace_identifier(
          current,
          name,
          EscapeMangler::mangle(mangler, parsed_module.path, name),
        )
      }
    }
  }
  current.trim().to_string()
}

///|
fn wesl_emit_module(
  path : ModulePath,
  root : ModulePath,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  used_modules : @hashmap.HashMap[ModulePath, Bool],
  used_decls : @hashmap.HashMap[String, Bool],
  emitted : @hashmap.HashMap[ModulePath, Bool],
  parts : Array[String],
  mangler : EscapeMangler,
  options : CompileOptions,
) -> Unit {
  if emitted.contains(path) || !used_modules.contains(path) {
    return
  }
  emitted.set(path, true)
  guard modules.get(path) is Some(parsed_module) else { return }
  if !options.strip || !options.lazy_resolution {
    for import_item in parsed_module.imports {
      wesl_emit_module(
        import_item.module_path,
        root,
        modules,
        used_modules,
        used_decls,
        emitted,
        parts,
        mangler,
        options,
      )
    }
  } else {
    for import_item in parsed_module.imports {
      if import_item.public &&
        wesl_is_used_decl(
          used_decls,
          parsed_module.path,
          import_item.local_name,
        ) {
        wesl_emit_module(
          import_item.module_path,
          root,
          modules,
          used_modules,
          used_decls,
          emitted,
          parts,
          mangler,
          options,
        )
      }
    }
    for item in parsed_module.items {
      let should_emit = match item.name {
        Some(name) => wesl_is_used_decl(used_decls, parsed_module.path, name)
        None => true
      }
      if !should_emit {
        continue
      }
      for import_ref in item.import_refs {
        match parsed_module.import_by_local.get(import_ref) {
          Some(import_index) =>
            wesl_emit_module(
              parsed_module.imports[import_index].module_path,
              root,
              modules,
              used_modules,
              used_decls,
              emitted,
              parts,
              mangler,
              options,
            )
          None => ()
        }
      }
    }
  }
  for item in parsed_module.items {
    let should_emit = match item.name {
      Some(name) =>
        if options.strip {
          wesl_is_used_decl(used_decls, parsed_module.path, name)
        } else {
          true
        }
      None => true
    }
    if !should_emit {
      continue
    }
    let emitted_item = wesl_emit_item_source(
      parsed_module, item, root, modules, used_decls, mangler, options,
    )
    if emitted_item != "" {
      parts.push(emitted_item)
    }
  }
}

///|
pub fn[R : Resolver] compile(
  root : ModulePath,
  resolver : R,
  mangler : EscapeMangler,
  options : CompileOptions,
) -> CompileResult raise WeslCompileError {
  let _ = options.lower
  let modules : @hashmap.HashMap[ModulePath, ParsedModule] = @hashmap.HashMap::new()
  let order : Array[ModulePath] = []
  let used_modules : @hashmap.HashMap[ModulePath, Bool] = @hashmap.HashMap::new()
  let used_decls : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let root_module = wesl_mark_module_used(
    root, resolver, options, modules, order, used_modules, used_decls,
  )
  for keep_name in wesl_root_keep_names(root_module, options) {
    ignore(
      wesl_mark_named_decl(
        root, keep_name, resolver, options, modules, order, used_modules, used_decls,
      ),
    )
  }
  if !options.strip {
    for module_path in order {
      used_modules.set(module_path, true)
    }
  }
  let emitted : @hashmap.HashMap[ModulePath, Bool] = @hashmap.HashMap::new()
  let parts : Array[String] = []
  wesl_emit_module(
    root, root, modules, used_modules, used_decls, emitted, parts, mangler, options,
  )
  let assembled = parts.filter(fn(part) { part != "" }).join("\n\n")
  CompileResult::{
    source: if options.lower {
      wesl_lower_source(assembled)
    } else {
      assembled
    },
    modules: order,
  }
}
