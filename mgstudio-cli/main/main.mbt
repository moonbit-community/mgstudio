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
  check : Bool
  write : Bool
  verbose : Bool
}

///|
fn GenOptions::default(workspace : String) -> GenOptions {
  { workspace, modules: [], check: false, write: true, verbose: false }
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
  let check = cmd.get_flag("check").unwrap_or(false)
  let force_write = cmd.get_flag("write").unwrap_or(false)
  let write = force_write || !check
  let verbose = cmd.get_flag("verbose").unwrap_or(false)
  { workspace, modules, check, write, verbose }
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
  if any_diff {
    @sys.exit(1)
  }
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
    #| // Copyright 2025 International Digital Economy Academy
    #| //
    #| // Licensed under the Apache License, Version 2.0 (the "License");
    #| // you may not use this file except in compliance with the License.
    #| // You may obtain a copy of the License at
    #| //
    #| //     http://www.apache.org/licenses/LICENSE-2.0
    #| //
    #| // Unless required by applicable law or agreed to in writing, software
    #| // distributed under the License is distributed on an "AS IS" BASIS,
    #| // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #| // See the License for the specific language governing permissions and
    #| // limitations under the License.
    #|
    #| // Code generated by `mgstudio gen`. DO NOT EDIT.
    #|
  let sources_joined = srcs.join(", ")
  let header = static_header +
    "// Package dir: \{pkg_dir}\n" +
    "// Sources: \{sources_joined}\n" +
    "\n"
  let body = "///|\n" +
    "/// ECS component types discovered via `#ecs.component`.\n" +
    "pub const ECS_COMPONENTS : Array[String] = [\n" +
    comps.map(c => "  \"\{c}\",\n").join("") +
    "]\n"
  header + "\n" + body
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
