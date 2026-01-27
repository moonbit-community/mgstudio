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
/// mgstudio CLI entrypoint.
///
/// Currently supported:
/// - `mgstudio gen`: generate `ecs.g.mbt` per package for `#ecs.component`.
async fn main {
  let argv = @sys.get_cli_args()
  let parser = make_cli_parser()
  let value = @clap.SimpleValue::new(parser.prog)
  let args : Array[String] = []
  for i in 1..<argv.length() {
    args.push(argv[i])
  }

  // Let clap generate and format help output.
  if args.length() == 0 {
    print_cli_help(parser)
    @sys.exit(2)
  }
  let help : String? = parser.parse(value, args) catch {
    err => {
      println(err)
      print_cli_help(parser)
      @sys.exit(2)
      None
    }
  }
  if help is Some(msg) {
    println(msg)
    @sys.exit(0)
  }
  match value.subcmd {
    Some(cmd) =>
      match cmd.name {
        "gen" => cmd_gen(cmd)
        _ => {
          println("Unknown command: \{cmd.name}")
          print_cli_help(parser)
          @sys.exit(2)
        }
      }
    None => {
      print_cli_help(parser)
      @sys.exit(2)
    }
  }
}

///|
fn make_cli_parser() -> @clap.Parser {
  @clap.Parser::new(
    prog="mgstudio",
    description="mgstudio developer CLI (codegen/build/run entrypoint).",
    subcmds={
      "gen": @clap.SubCommand::new(
        help="Generate ecs.g.mbt from #ecs.component.",
        args={
          "workspace": @clap.Arg::named(
            short='w',
            nargs=@clap.Nargs::One,
            defaults=["."],
            help="Workspace root (default: .)",
          ),
          // Repeatable: `--modules <path>` multiple times.
          "modules": @clap.Arg::named(
            short='m',
            nargs=@clap.Nargs::Any,
            help="Module root (repeatable). If absent, auto-discover moon.mod.json under workspace.",
          ),
          "check": @clap.Arg::flag(
            short='c',
            help="Verify generated files are up-to-date (do not write).",
          ),
          "write": @clap.Arg::flag(help="Write generated files (default)."),
          "world-pkg": @clap.Arg::named(
            nargs=@clap.Nargs::One,
            help="Optional output package directory for a generated concrete ECS World (e.g. mgstudio-engine/ecs_world).",
          ),
          "verbose": @clap.Arg::flag(
            short='v',
            help="Print scanned modules and generated paths.",
          ),
        },
      ),
    },
  )
}

///|
fn print_cli_help(parser : @clap.Parser) -> Unit {
  let v = @clap.SimpleValue::new(parser.prog)
  // `-h/--help` triggers `Parser::gen_help_message`.
  let msg_opt : String? = parser.parse(v, ["-h"]) catch {
    _ => Some("Help is unavailable.")
  }
  match msg_opt {
    Some(msg) => println(msg)
    None => println("No help message available.")
  }
}

///|
struct GenOptions {
  workspace : String
  modules : Array[String]
  world_pkg : String?
  check : Bool
  write : Bool
  verbose : Bool
}

///|
fn GenOptions::default(workspace : String) -> GenOptions {
  {
    workspace,
    modules: [],
    world_pkg: None,
    check: false,
    write: true,
    verbose: false,
  }
}

///|
async fn cmd_gen(cmd : @clap.SimpleValue) -> Unit {
  let opts : GenOptions = parse_gen_options(cmd) catch {
    err => {
      println(err)
      @sys.exit(2)
      GenOptions::default(".")
    }
  }
  run_gen(opts) catch {
    err => {
      println("mgstudio gen failed: \{err}")
      @sys.exit(1)
    }
  }
}

///|
fn parse_gen_options(
  cmd : @clap.SimpleValue,
) -> GenOptions raise @clap.ParserError {
  let workspace : String = cmd.get_one("workspace")
  let modules : Array[String] = cmd.get_array("modules")
  // `SimpleValue::get_option` is generic; let the expected type drive inference.
  let world_pkg : String? = cmd.get_option("world-pkg")
  let check = cmd.get_flag("check").unwrap_or(false)
  let force_write = cmd.get_flag("write").unwrap_or(false)
  let write = force_write || !check
  let verbose = cmd.get_flag("verbose").unwrap_or(false)
  { workspace, modules, world_pkg, check, write, verbose }
}

///|
fn path_basename(path : String) -> String {
  let mut last = ""
  for part in path.split("/") {
    last = part.to_string()
  }
  last
}

///|
fn path_join(dir : String, file : String) -> String {
  if dir is "" {
    file
  } else if dir is [.., '/'] {
    dir + file
  } else {
    "\{dir}/\{file}"
  }
}

///|
fn should_skip_dir(path : String) -> Bool {
  let name = path_basename(path)
  // Keep this list small and deterministic.
  name == ".git" ||
  name == ".private" ||
  name == ".mooncakes" ||
  name == "_build" ||
  name == "target" ||
  name == "node_modules" ||
  name == "bevy"
}

///|
async fn run_gen(opts : GenOptions) -> Unit {
  let check = opts.check || !opts.write
  let workspace = @fs.realpath(opts.workspace)
  let module_roots : Array[String] = []
  if opts.modules.length() > 0 {
    for m in opts.modules {
      module_roots.push(@fs.realpath(m))
    }
  } else {
    for m in discover_modules(workspace, verbose=opts.verbose) {
      module_roots.push(m)
    }
  }
  if module_roots.length() == 0 {
    println("No modules found under workspace: \{workspace}")
    @sys.exit(1)
  }
  if opts.verbose {
    println("Modules:")
    for m in module_roots {
      println("  - \{m}")
    }
  }
  let module_infos = load_module_infos(module_roots)

  // pkg_dir -> (components, source_files)
  let components_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  let sources_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  for module_root in module_roots {
    collect_ecs_components_for_module(
      module_root, components_by_pkg, sources_by_pkg,
    )
  }
  let mut any_diff = false
  for entry in components_by_pkg.iter() {
    let (pkg_dir, comps) = entry
    if comps.length() == 0 {
      continue
    }
    let sources : Array[String] = sources_by_pkg.get(pkg_dir).unwrap_or([])
    let out_path = path_join(pkg_dir, "ecs.g.mbt")
    let content = render_ecs_generated_file(pkg_dir, comps, sources)
    let ok = write_or_check(out_path, content, check~, verbose=opts.verbose)
    if !ok {
      any_diff = true
    }
  }
  if opts.world_pkg is Some(world_pkg) {
    let ok = generate_ecs_world(
      workspace,
      world_pkg,
      module_infos,
      components_by_pkg,
      check~,
      verbose=opts.verbose,
    )
    if !ok {
      any_diff = true
    }
  }
  if any_diff {
    @sys.exit(1)
  }
}

///|
struct ModuleInfo {
  root : String
  name : String
}

///|
async fn load_module_infos(module_roots : Array[String]) -> Array[ModuleInfo] {
  let infos : Array[ModuleInfo] = []
  for root in module_roots {
    let path = path_join(root, "moon.mod.json")
    match read_file_text(path) {
      Some(src) =>
        match parse_module_name(src) {
          Some(name) => infos.push({ root, name })
          None => {
            println("Failed to parse module name from: \{path}")
            @sys.exit(1)
          }
        }
      None => {
        println("Failed to read: \{path}")
        @sys.exit(1)
      }
    }
  }
  infos
}

///|
fn parse_module_name(src : String) -> String? {
  // Minimal JSON string scan for: "name": "<module-name>"
  let s = src.view()
  let key = "\"name\"".view()
  let mut i = 0
  while i + key.length() <= s.length() {
    if (try! s[i:i + key.length()]) == key {
      // Seek ':' then the first '"' and the closing '"'.
      let mut j = i + key.length()
      while j < s.length() && s.code_unit_at(j).to_int() != ':'.to_int() {
        j = j + 1
      }
      if j >= s.length() {
        return None
      }
      while j < s.length() && s.code_unit_at(j).to_int() != '"'.to_int() {
        j = j + 1
      }
      if j >= s.length() {
        return None
      }
      let start = j + 1
      let mut end = start
      while end < s.length() && s.code_unit_at(end).to_int() != '"'.to_int() {
        end = end + 1
      }
      if end >= s.length() {
        return None
      }
      return Some(try! s[start:end].to_string())
    }
    i = i + 1
  }
  None
}

///|
struct ComponentRef {
  pkg_import : String
  pkg_alias : String
  tycon : String
}

///|
fn module_for_pkg(
  module_infos : Array[ModuleInfo],
  pkg_dir : String,
) -> ModuleInfo? {
  let mut best : ModuleInfo? = None
  let mut best_len = -1
  for m in module_infos {
    if pkg_dir == m.root || pkg_dir.has_prefix(m.root + "/") {
      if m.root.length() > best_len {
        best = Some(m)
        best_len = m.root.length()
      }
    }
  }
  best
}

///|
fn relative_pkg_path(module_root : String, pkg_dir : String) -> String? {
  if pkg_dir == module_root {
    return Some(".")
  }
  if pkg_dir.has_prefix(module_root + "/") {
    let start = module_root.length() + 1
    let v = pkg_dir.view()
    Some(try! v[start:v.length()].to_string())
  } else {
    None
  }
}

///|
fn camel_to_snake(name : String) -> String {
  let out = StringBuilder::new()
  let mut first = true
  for c in name {
    if c >= 'A' && c <= 'Z' {
      if !first {
        out.write_char('_')
      }
      out.write_char(Int::unsafe_to_char(c.to_int() + 32))
    } else {
      out.write_char(c)
    }
    first = false
  }
  out.to_string()
}

///|
const FMT_MAX_LINE : Int = 80

fn fits_one_line(s : String) -> Bool {
  s.length() <= FMT_MAX_LINE
}

fn render_string_array_one_line(items : Array[String]) -> String {
  if items.length() == 0 {
    "[]"
  } else {
    let quoted = items.map(fn(s) { "\"\{s}\"" }).join(",")
    "[\{quoted}]"
  }
}

///|
fn component_ref_key(c : ComponentRef) -> String {
  c.pkg_import + "/" + c.tycon
}

///|
fn sort_component_refs(components : Array[ComponentRef]) -> Unit {
  // Deterministic sort without relying on stdlib comparator APIs.
  // Insertion sort is fine because component counts are small.
  let mut i = 1
  while i < components.length() {
    let cur = components[i]
    let cur_key = component_ref_key(cur)
    let mut j = i
    while j > 0 && cur_key < component_ref_key(components[j - 1]) {
      components[j] = components[j - 1]
      j = j - 1
    }
    components[j] = cur
    i = i + 1
  }
}

///|
fn render_world_file(components : Array[ComponentRef]) -> String {
  let header =
    #|// Copyright 2025 International Digital Economy Academy
    #|//
    #|// Licensed under the Apache License, Version 2.0 (the "License");
    #|// you may not use this file except in compliance with the License.
    #|// You may obtain a copy of the License at
    #|//
    #|//     http://www.apache.org/licenses/LICENSE-2.0
    #|//
    #|// Unless required by applicable law or agreed to in writing, software
    #|// distributed under the License is distributed on an "AS IS" BASIS,
    #|// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #|// See the License for the specific language governing permissions and
    #|// limitations under the License.
    #|
    #|// Code generated by `mgstudio gen`. DO NOT EDIT.
    #|
  let comps = components.copy()
  sort_component_refs(comps)
  let traits = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "///|\n" +
      "pub(open) trait Has_\{c.tycon} {\n" +
      "  get_\{snake}_store(self : Self) -> @core.SparseSet[@\{c.pkg_alias}.\{c.tycon}]\n" +
      "}\n"
    })
    .join("\n")
  let fields = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "  \{snake} : @core.SparseSet[@\{c.pkg_alias}.\{c.tycon}]\n"
    })
    .join("")
  let init_fields = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "    \{snake}: @core.SparseSet::new(),\n"
    })
    .join("")

  let mut init_expr = "World::{ entities: @core.Entities::new()"
  for c in comps {
    let snake = camel_to_snake(c.tycon)
    init_expr = init_expr + ", \{snake}: @core.SparseSet::new()"
  }
  init_expr = init_expr + " }"

  let world_new_body = if fits_one_line(init_expr) {
    "  \{init_expr}\n"
  } else {
    "  World::{\n" +
    "    entities: @core.Entities::new(),\n" +
    init_fields +
    "  }\n"
  }
  let trait_impls = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "///|\n" +
      "pub impl Has_\{c.tycon} for World with get_\{snake}_store(self) {\n" +
      "  self.\{snake}\n" +
      "}\n"
    })
    .join("\n")
  let cleanup = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "  self.\{snake}.remove(entity) |> ignore\n"
    })
    .join("")
  header +
  "\n" +
  traits +
  "\n" +
  "///|\n" +
  "pub struct World {\n" +
  "  entities : @core.Entities\n" +
  fields +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub fn World::new() -> World {\n" +
  world_new_body +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub fn World::spawn_empty(self : World) -> @core.Entity {\n" +
  "  self.entities.spawn()\n" +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub fn World::despawn(\n" +
  "  self : World,\n" +
  "  entity : @core.Entity,\n" +
  ") -> Unit raise @core.EntityError {\n" +
  "  self.entities.despawn(entity)\n" +
  cleanup +
  "}\n" +
  "\n" +
  trait_impls
}

///|
fn render_world_pkg_json(imports : Array[String]) -> String {
  let items = imports.copy()
  items.sort()
  let body = items.map(fn(s) { "    \"\{s}\"" }).join(",\n")
  "{\n  \"import\": [\n\{body}\n  ]\n}\n"
}

///|
async fn generate_ecs_world(
  workspace : String,
  world_pkg_arg : String,
  module_infos : Array[ModuleInfo],
  components_by_pkg : @hashmap.HashMap[String, Array[String]],
  check~ : Bool,
  verbose~ : Bool,
) -> Bool {
  let world_pkg = if world_pkg_arg.has_prefix("/") {
    world_pkg_arg
  } else {
    path_join(workspace, world_pkg_arg)
  }
  if check && !@fs.exists(world_pkg) {
    println("Out of date: \{world_pkg}")
    return false
  }
  if !@fs.exists(world_pkg) {
    @fs.mkdir(world_pkg, recursive=true, permission=493) |> ignore
  }

  // Collect components with package import info.
  let alias_to_import : @hashmap.HashMap[String, String] = @hashmap.HashMap::new()
  let all : Array[ComponentRef] = []
  for entry in components_by_pkg.iter() {
    let (pkg_dir, comps) = entry
    guard module_for_pkg(module_infos, pkg_dir) is Some(m) else {
      println("No module root matched for package: \{pkg_dir}")
      @sys.exit(1)
    }
    let rel = relative_pkg_path(m.root, pkg_dir).unwrap()
    let pkg_import = if rel == "." { m.name } else { m.name + "/" + rel }
    let pkg_alias = path_basename(pkg_dir)
    if alias_to_import.get(pkg_alias) is Some(prev) && prev != pkg_import {
      println(
        "World import alias collision: \{pkg_alias} => \{prev} vs \{pkg_import}",
      )
      @sys.exit(1)
    }
    alias_to_import.set(pkg_alias, pkg_import)
    for tycon in comps {
      all.push({ pkg_import, pkg_alias, tycon })
    }
  }
  let world_mbt = render_world_file(all)
  let world_path = path_join(world_pkg, "ecs_world.g.mbt")
  let ok_world = write_or_check(world_path, world_mbt, check~, verbose~)

  // Also manage the world package imports deterministically.
  let imports : Array[String] = []
  imports.push("Milky2018/mgstudio/core")
  for entry in alias_to_import.iter() {
    let (_alias, pkg_import) = entry
    if !imports.contains(pkg_import) {
      imports.push(pkg_import)
    }
  }
  let pkg_json = render_world_pkg_json(imports)
  let pkg_path = path_join(world_pkg, "moon.pkg.json")
  let ok_pkg = write_or_check(pkg_path, pkg_json, check~, verbose~)
  ok_world && ok_pkg
}

///|
async fn discover_modules(workspace : String, verbose~ : Bool) -> Array[String] {
  let modules : Array[String] = []
  @fs.walk(
    workspace,
    exclude=path => should_skip_dir(path),
    max_concurrency=64,
    fn(path, files) {
      if files.contains("moon.mod.json") {
        if verbose {
          println("Discovered module: \{path}")
        }
        modules.push(path)
      }
    },
  )
  modules.sort()
  modules
}

///|
async fn collect_ecs_components_for_module(
  module_root : String,
  components_by_pkg : @hashmap.HashMap[String, Array[String]],
  sources_by_pkg : @hashmap.HashMap[String, Array[String]],
) -> Unit {
  @fs.walk(
    module_root,
    exclude=path => should_skip_dir(path),
    max_concurrency=64,
    fn(dir_path, files) {
      // Only generate into real MoonBit packages.
      guard files.contains("moon.pkg.json") else { return }
      for file in files {
        guard file.has_suffix(".mbt") else { continue }
        guard !file.has_suffix("_test.mbt") else { continue }
        guard !file.has_suffix("_wbtest.mbt") else { continue }
        guard !file.has_suffix(".g.mbt") else { continue }
        let file_path = path_join(dir_path, file)
        let comps = parse_ecs_components_from_file(file_path)
        if comps.length() == 0 {
          continue
        }

        // Merge into package buckets.
        let bucket : Array[String] = components_by_pkg
          .get(dir_path)
          .unwrap_or([])
        for c in comps {
          if !bucket.contains(c) {
            bucket.push(c)
          }
        }
        components_by_pkg.set(dir_path, bucket)
        let sources : Array[String] = sources_by_pkg.get(dir_path).unwrap_or([])
        if !sources.contains(file) {
          sources.push(file)
        }
        sources_by_pkg.set(dir_path, sources)
      }
    },
  )
}

///|
fn is_ecs_component_attr(attr : @attribute.Attribute) -> Bool {
  // Prefer the parsed representation, but fall back to the raw text in case
  // attribute parsing fails (e.g. syntax errors inside the payload).
  match attr.parsed {
    Some(@attribute.Expr::Ident(id) | @attribute.Expr::Apply(id, _)) =>
      id.qual == Some("ecs") && id.name == "component"
    _ => attr.raw.trim().has_prefix("#ecs.component")
  }
}

///|
async fn parse_ecs_components_from_file(path : String) -> Array[String] {
  let text = read_file_text(path)
  guard text is Some(src) else { return [] }

  // `moonbitlang/parser` may lag behind the compiler syntax. To avoid blocking
  // codegen on unrelated files, only parse files that actually contain the tag.
  let mut has_tag = false
  for line in src.split("\n") {
    if line.trim().has_prefix("#ecs.component") {
      has_tag = true
      break
    }
  }
  if !has_tag {
    return []
  }
  let (impls, reports) = @parser.parse_string(
    src,
    name=path,
    parser=@parser.Parser::MoonYacc,
  )
  if reports.length() > 0 {
    println("Parse errors in: \{path}")
    for r in reports {
      println("  \{r}")
    }
    @sys.exit(1)
  }
  let comps : Array[String] = []
  for impl_ in impls {
    match impl_ {
      @syntax.Impl::TopTypeDef(td) => {
        let mut marked = false
        for attr in td.attrs {
          if is_ecs_component_attr(attr) {
            marked = true
            break
          }
        }
        if marked && !comps.contains(td.tycon) {
          comps.push(td.tycon)
        }
      }
      _ => ()
    }
  }
  comps
}

///|
fn render_ecs_generated_file(
  pkg_dir : String,
  components : Array[String],
  sources : Array[String],
) -> String {
  let comps = components.copy()
  comps.sort()
  let srcs = sources.copy()
  srcs.sort()
  let static_header =
    #|// Copyright 2025 International Digital Economy Academy
    #|//
    #|// Licensed under the Apache License, Version 2.0 (the "License");
    #|// you may not use this file except in compliance with the License.
    #|// You may obtain a copy of the License at
    #|//
    #|//     http://www.apache.org/licenses/LICENSE-2.0
    #|//
    #|// Unless required by applicable law or agreed to in writing, software
    #|// distributed under the License is distributed on an "AS IS" BASIS,
    #|// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #|// See the License for the specific language governing permissions and
    #|// limitations under the License.
    #|
    #|// Code generated by `mgstudio gen`. DO NOT EDIT.
    #|
  let sources_joined = srcs.join(", ")
  let header = static_header +
    "// Package dir: \{pkg_dir}\n" +
    "// Sources: \{sources_joined}\n" +
    "\n"
  // `const` cannot hold arrays in MoonBit, and `let` names must be lowercase.
  let literal = render_string_array_one_line(comps)
  let body = if fits_one_line(literal) {
    "///|\n" +
    "/// ECS component types discovered via `#ecs.component`.\n" +
    "pub let ecs_components : Array[String] = \{literal}\n"
  } else {
    "///|\n" +
    "/// ECS component types discovered via `#ecs.component`.\n" +
    "pub let ecs_components : Array[String] = [\n" +
    comps.map(c => "  \"\{c}\",\n").join("") +
    "]\n"
  }
  header + body
}

///|
async fn read_file_text(path : String) -> String? {
  try {
    let f = @fs.open(path, mode=@fs.Mode::ReadOnly)
    defer f.close()
    Some(f.read_all().text())
  } catch {
    _ => None
  }
}

///|
async fn write_file_text(path : String, content : String) -> Unit {
  // 0o644
  let f = @fs.create(path, permission=420)
  defer f.close()
  f.write(content)
}

///|
async fn write_or_check(
  path : String,
  content : String,
  check~ : Bool,
  verbose~ : Bool,
) -> Bool {
  let existing = read_file_text(path)
  if existing is Some(s) && s == content {
    if verbose {
      println("OK: \{path}")
    }
    true
  } else if check {
    println("Out of date: \{path}")
    false
  } else {
    write_file_text(path, content)
    println("Generated: \{path}")
    true
  }
}
