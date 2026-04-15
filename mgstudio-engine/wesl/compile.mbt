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
  lower : Bool
  features : @hashmap.HashMap[String, Bool]
}

///|
pub fn CompileOptions::default() -> CompileOptions {
  CompileOptions::{
    imports: true,
    condcomp: true,
    lower: false,
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
  MissingDecl(ModulePath, String)
}

///|
pub fn WeslCompileError::message(self : WeslCompileError) -> String {
  match self {
    Resolve(err) => err.message()
    Parse(reason) => reason
    InvalidExpression(expr) => "invalid if attribute expression: `\{expr}`"
    MissingDecl(path, item) =>
      "module `\{path.to_string()}` has no declaration `\{item}`"
  }
}

///|
priv struct ImportItem {
  module_path : ModulePath
  item_name : String
  local_name : String
}

///|
priv struct ParsedModule {
  path : ModulePath
  source : String
  imports : Array[ImportItem]
  declarations : Array[String]
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
fn wesl_find_last(source : String, needle : String) -> Int? {
  if needle == "" {
    return Some(source.length())
  }
  if needle.length() > source.length() {
    return None
  }
  let mut index = source.length() - needle.length()
  while true {
    if wesl_starts_with_at(source, index, needle) {
      return Some(index)
    }
    if index == 0 {
      break
    }
    index = index - 1
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
fn wesl_extract_import_blocks(source : String) -> (Array[String], String) {
  let imports : Array[String] = []
  let body_lines : Array[String] = []
  let lines : Array[String] = []
  for line in source.split("\n") {
    lines.push(line.to_string())
  }
  let mut brace_depth = 0
  let mut index = 0
  while index < lines.length() {
    let line = lines[index]
    let trimmed = line.trim().to_string()
    if brace_depth == 0 && trimmed.has_prefix("import ") {
      let mut block = line
      while !block.trim().to_string().has_suffix(";") &&
            index + 1 < lines.length() {
        index = index + 1
        block = "\{block}\n\{lines[index]}"
      }
      imports.push(block)
    } else {
      body_lines.push(line)
    }
    for i in 0..<line.length() {
      let code = line.code_unit_at(i).to_int()
      if code == 123 { // '{'
        brace_depth = brace_depth + 1
      } else if code == 125 { // '}'
        brace_depth = brace_depth - 1
      }
    }
    index = index + 1
  }
  (imports, body_lines.join("\n"))
}

///|
fn wesl_parse_import_item(
  current_path : ModulePath,
  module_path_text : String,
  item_text : String,
) -> ImportItem raise WeslCompileError {
  let item_source = item_text.trim().to_string()
  let rename_parts : Array[String] = []
  for piece in item_source.split(" as ") {
    rename_parts.push(piece.to_string())
  }
  let item_name = rename_parts[0].trim().to_string()
  let local_name = if rename_parts.length() > 1 {
    rename_parts[1].trim().to_string()
  } else {
    item_name
  }
  let raw_module_path = parse_module_path(module_path_text.trim().to_string()) catch {
    err => raise WeslCompileError::Parse(err.message())
  }
  ImportItem::{
    module_path: current_path.join_path(raw_module_path),
    item_name,
    local_name,
  }
}

///|
fn wesl_parse_imports(
  current_path : ModulePath,
  import_blocks : Array[String],
) -> Array[ImportItem] raise WeslCompileError {
  let imports : Array[ImportItem] = []
  for block in import_blocks {
    let trimmed = block.trim().to_string()
    let text = trimmed[7:trimmed.length() - 1].to_string().trim().to_string()
    match wesl_find_first(text, "::{", 0) {
      Some(start_index) => {
        let module_path_text = text[:start_index].to_string()
        let items_text = text[start_index + 3:text.length() - 1].to_string()
        for piece in items_text.split(",") {
          let item = piece.to_string().trim().to_string()
          if item != "" {
            imports.push(
              wesl_parse_import_item(current_path, module_path_text, item),
            )
          }
        }
      }
      None =>
        match wesl_find_last(text, "::") {
          Some(separator_index) =>
            imports.push(
              wesl_parse_import_item(
                current_path,
                text[:separator_index].to_string(),
                text[separator_index + 2:text.length()].to_string(),
              ),
            )
          None =>
            raise WeslCompileError::Parse(
              "unsupported import statement: \{trimmed}",
            )
        }
    }
  }
  imports
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
  } else {
    None
  }
}

///|
fn wesl_collect_top_level_declarations(source : String) -> Array[String] {
  let declarations : Array[String] = []
  let lines : Array[String] = []
  for line in source.split("\n") {
    lines.push(line.to_string())
  }
  let mut brace_depth = 0
  for line in lines {
    let trimmed = line.trim().to_string()
    if brace_depth == 0 &&
      trimmed != "" &&
      !trimmed.has_prefix("//") &&
      !trimmed.has_prefix("@") {
      if wesl_try_decl_name(trimmed) is Some(name) {
        declarations.push(name)
      }
    }
    for i in 0..<line.length() {
      let code = line.code_unit_at(i).to_int()
      if code == 123 {
        brace_depth = brace_depth + 1
      } else if code == 125 {
        brace_depth = brace_depth - 1
      }
    }
  }
  declarations
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
      let extracted = if options.imports {
        wesl_extract_import_blocks(source)
      } else {
        ([], source)
      }
      let import_blocks = extracted.0
      let body_source = extracted.1
      let imports = if options.imports {
        wesl_parse_imports(path, import_blocks)
      } else {
        []
      }
      let parsed_module = ParsedModule::{
        path,
        source: body_source,
        declarations: wesl_collect_top_level_declarations(body_source),
        imports,
      }
      modules.set(path, parsed_module)
      order.push(path)
      for import_item in parsed_module.imports {
        let loaded = wesl_load_module(
          import_item.module_path,
          resolver,
          options,
          modules,
          order,
        )
        let has_decl = loaded.declarations.any(fn(name) {
          name == import_item.item_name
        })
        if !has_decl {
          raise WeslCompileError::MissingDecl(
            loaded.path,
            import_item.item_name,
          )
        }
      }
      parsed_module
    }
  }
}

///|
fn wesl_emit_module(
  path : ModulePath,
  root : ModulePath,
  modules : @hashmap.HashMap[ModulePath, ParsedModule],
  emitted : @hashmap.HashMap[ModulePath, Bool],
  parts : Array[String],
  mangler : EscapeMangler,
) -> Unit {
  if emitted.contains(path) {
    return
  }
  emitted.set(path, true)
  guard modules.get(path) is Some(parsed_module) else { return }
  for import_item in parsed_module.imports {
    wesl_emit_module(
      import_item.module_path,
      root,
      modules,
      emitted,
      parts,
      mangler,
    )
  }
  let mut current = parsed_module.source
  for import_item in parsed_module.imports {
    let replacement = EscapeMangler::mangle(
      mangler,
      import_item.module_path,
      import_item.item_name,
    )
    current = wesl_replace_identifier(
      current,
      import_item.local_name,
      replacement,
    )
  }
  if parsed_module.path != root {
    for decl_name in parsed_module.declarations {
      current = wesl_replace_identifier(
        current,
        decl_name,
        EscapeMangler::mangle(mangler, parsed_module.path, decl_name),
      )
    }
  }
  parts.push(current.trim().to_string())
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
  ignore(wesl_load_module(root, resolver, options, modules, order))
  let emitted : @hashmap.HashMap[ModulePath, Bool] = @hashmap.HashMap::new()
  let parts : Array[String] = []
  wesl_emit_module(root, root, modules, emitted, parts, mangler)
  CompileResult::{
    source: parts.filter(fn(part) { part != "" }).join("\n\n"),
    modules: order,
  }
}
