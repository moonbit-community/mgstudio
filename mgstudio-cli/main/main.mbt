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
  if argv.length() < 2 {
    print_help()
    @sys.exit(2)
  }
  match argv[1] {
    "gen" => cmd_gen(argv)
    "-h" | "--help" | "help" => {
      print_help()
      @sys.exit(0)
    }
    _ => {
      println("Unknown command: \{argv[1]}")
      print_help()
      @sys.exit(2)
    }
  }
}

///|
fn print_help() -> Unit {
  let help =
    #| mgstudio
    #|
    #| Usage:
    #|   mgstudio gen [--workspace <path>] [--modules <path>...] [--check] [--write] [--verbose]
    #|
    #| Commands:
    #|   gen    Generate `ecs.g.mbt` from `#ecs.component`
    #|
  println(help)
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
async fn cmd_gen(argv : Array[String]) -> Unit {
  let opts = parse_gen_args(argv)
  run_gen(opts) catch {
    err => {
      println("mgstudio gen failed: \{err}")
      @sys.exit(1)
    }
  }
}

///|
fn parse_gen_args(argv : Array[String]) -> GenOptions {
  // argv: [bin, "gen", ...]
  let mut i = 2
  let mut opts = GenOptions::default(".")
  while i < argv.length() {
    let a = argv[i]
    match a {
      "--workspace" => {
        guard i + 1 < argv.length() else {
          println("Missing value for --workspace")
          @sys.exit(2)
        }
        opts = { ..opts, workspace: argv[i + 1] }
        i = i + 2
      }
      "--modules" => {
        guard i + 1 < argv.length() else {
          println("Missing value for --modules")
          @sys.exit(2)
        }
        let modules = opts.modules
        modules.push(argv[i + 1])
        opts = { ..opts, modules, }
        i = i + 2
      }
      "--check" => {
        opts = { ..opts, check: true, write: false }
        i = i + 1
      }
      "--write" => {
        opts = { ..opts, write: true }
        i = i + 1
      }
      "--verbose" => {
        opts = { ..opts, verbose: true }
        i = i + 1
      }
      "-h" | "--help" => {
        let help =
          #| mgstudio gen
          #|
          #| Options:
          #|   --workspace <path>  Workspace root (default ".")
          #|   --modules <path>    Module roots (repeatable). If absent, auto-discover moon.mod.json under workspace.
          #|   --check             Verify generated files are up-to-date (do not write).
          #|   --write             Write generated files (default).
          #|   --verbose           Print scanned modules and generated paths.
          #|
        println(help)
        @sys.exit(0)
      }
      _ => {
        println("Unknown gen option: \{a}")
        @sys.exit(2)
      }
    }
  }
  opts
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
