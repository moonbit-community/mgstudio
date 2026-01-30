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
/// - `mgstudio gen`: generate `ecs.g.mbt` per package for `#ecs.component` / `#ecs.resource`.
/// - `mgstudio run`: run a wasm-gc game module in native runtime (calls `game_app`).
/// - `mgstudio serve`: serve the web runtime and run the game in browser (calls `game_app`).
async fn main {
  let argv = @sys.get_cli_args()
  let parser = make_cli_parser()
  let value = @clap.SimpleValue::new(parser.prog)
  let args : Array[String] = []
  for i in 1..<argv.length() {
    args.push(argv[i])
  }
  let normalized_args = args

  // Let clap generate and format help output.
  if normalized_args.length() == 0 {
    print_cli_help(parser)
    @sys.exit(2)
  }
  let help : String? = parser.parse(value, normalized_args) catch {
    err => {
      println(err)
      if normalized_args.length() > 0 {
        let top = normalized_args[0]
        if top == "run" || top == "serve" || top == "gen" {
          print_subcommand_help(parser, top)
        } else {
          print_cli_help(parser)
        }
      } else {
        print_cli_help(parser)
      }
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
        "run" => cmd_run(cmd)
        "serve" => cmd_serve(cmd)
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
        help="Generate ecs.g.mbt from #ecs.component / #ecs.resource.",
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
            nargs=@clap.Nargs::AtMost(1U),
            help="Optional output package directory for a generated concrete ECS World (e.g. mgstudio-engine/ecs_world).",
          ),
          "verbose": @clap.Arg::flag(
            short='v',
            help="Print scanned modules and generated paths.",
          ),
        },
      ),
      "run": @clap.SubCommand::new(
        help="Run a wasm-gc game module in native runtime (calls export `game_app`).",
        args={
          "runtime-root": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Runtime root directory. If omitted, auto-discover by searching parent folders for ./mgstudio-runtime/.",
          ),
          "debug": @clap.Arg::flag(help="Use debug builds (default: release)."),
          "assets-source": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Assets source spec (native default: dir:<wasm_dir>/assets if exists else dir:<wasm_dir>).",
          ),
          "data-source": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="User data source spec (native default: dir:<wasm_dir>/.mgstudio-data).",
          ),
          "wgpu-lib": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Override libwgpu_native path (sets MBT_WGPU_NATIVE_LIB).",
          ),
          "wasm": @clap.Arg::positional(
            nargs=@clap.Nargs::One,
            help="Path to the game wasm file (must export `game_app`).",
          ),
        },
      ),
      "serve": @clap.SubCommand::new(
        help="Serve the web runtime and run a wasm-gc game module in browser (calls export `game_app`).",
        args={
          "runtime-root": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Runtime root directory. If omitted, auto-discover by searching parent folders for ./mgstudio-runtime/.",
          ),
          "debug": @clap.Arg::flag(help="Use debug builds (default: release)."),
          "port": @clap.Arg::named(
            short='p',
            nargs=@clap.Nargs::AtMost(1U),
            help="HTTP port to serve on (default: 8099).",
          ),
          "assets-source": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Assets source spec. If a local dir (dir:<path> or an existing folder), it will be mounted under the served root automatically.",
          ),
          "data-source": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="User data source spec (web default: idb:mgstudio).",
          ),
          "wasm": @clap.Arg::positional(
            nargs=@clap.Nargs::One,
            help="Path to the game wasm file (must export `game_app`).",
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
fn print_subcommand_help(parser : @clap.Parser, name : String) -> Unit {
  let v = @clap.SimpleValue::new(parser.prog)
  let msg_opt : String? = parser.parse(v, [name, "-h"]) catch { _ => None }
  match msg_opt {
    Some(msg) => println(msg)
    None => print_cli_help(parser)
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
struct RunOptions {
  runtime_root : String?
  release : Bool
  wasm : String
  assets_source : String?
  data_source : String?
  wgpu_lib : String?
}

///|
struct ServeOptions {
  runtime_root : String?
  release : Bool
  port : String
  wasm : String
  assets_source : String?
  data_source : String?
}

///|
suberror RunError {
  ProcessFailed(String, Int)
  MissingFile(String)
  MissingRuntimeRoot(String)
  InvalidArgs(String)
}

///|
struct EcsTags {
  components : Array[String]
  resources : Array[String]
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
async fn cmd_run(cmd : @clap.SimpleValue) -> Unit {
  let opts : RunOptions = parse_run_options(cmd) catch {
    err => {
      println(err)
      @sys.exit(2)
      parse_run_options_defaults(".")
    }
  }
  run_native(opts) catch {
    err => {
      println("mgstudio run failed: \{err}")
      @sys.exit(1)
    }
  }
}

///|
async fn cmd_serve(cmd : @clap.SimpleValue) -> Unit {
  let opts : ServeOptions = parse_serve_options(cmd) catch {
    err => {
      println(err)
      @sys.exit(2)
      parse_serve_options_defaults()
    }
  }
  serve_web(opts) catch {
    err => {
      println("mgstudio serve failed: \{err}")
      @sys.exit(1)
    }
  }
}

///|
fn parse_run_options_defaults(_workspace : String) -> RunOptions {
  {
    release: true,
    runtime_root: None,
    wasm: "",
    assets_source: None,
    data_source: None,
    wgpu_lib: None,
  }
}

///|
fn parse_run_options(
  cmd : @clap.SimpleValue,
) -> RunOptions raise @clap.ParserError {
  let debug = cmd.get_flag("debug").unwrap_or(false)
  let runtime_root : String? = cmd.get_option("runtime-root")
  let wasm : String = cmd.get_one("wasm")
  let assets_source : String? = cmd.get_option("assets-source")
  let data_source : String? = cmd.get_option("data-source")
  let wgpu_lib : String? = cmd.get_option("wgpu-lib")
  { release: !debug, runtime_root, wasm, assets_source, data_source, wgpu_lib }
}

///|
fn parse_serve_options_defaults() -> ServeOptions {
  {
    runtime_root: None,
    release: true,
    port: "8099",
    wasm: "",
    assets_source: None,
    data_source: None,
  }
}

///|
fn parse_serve_options(
  cmd : @clap.SimpleValue,
) -> ServeOptions raise @clap.ParserError {
  let debug = cmd.get_flag("debug").unwrap_or(false)
  let runtime_root : String? = cmd.get_option("runtime-root")
  let port : String? = cmd.get_option("port")
  let wasm : String = cmd.get_one("wasm")
  let assets_source : String? = cmd.get_option("assets-source")
  let data_source : String? = cmd.get_option("data-source")
  {
    runtime_root,
    release: !debug,
    port: port.unwrap_or("8099"),
    wasm,
    assets_source,
    data_source,
  }
}

///|
async fn run_process_checked(
  cmd : String,
  args : Array[String],
  cwd? : String,
  extra_env? : Map[String, String] = {},
) -> Unit {
  let cwd_str = cwd.unwrap_or("(default)")
  println("Running: \{cmd} \{render_argv(args)} (cwd=\{cwd_str})")
  let code = @process.run(cmd, args, cwd?, extra_env~)
  if code != 0 {
    raise RunError::ProcessFailed("\{cmd} \{render_argv(args)}", code)
  }
}

///|
fn render_argv(args : Array[String]) -> String {
  let mut out = ""
  for i in 0..<args.length() {
    if i > 0 {
      out = out + " "
    }
    out = out + args[i]
  }
  out
}

///|
fn is_absolute_path(path : String) -> Bool {
  @path.Path(path).is_absolute()
}

///|
fn strip_dir_prefix(spec : String) -> String {
  if spec.has_prefix("dir:") {
    (try! spec[4:spec.length()]).to_string()
  } else {
    spec
  }
}

///|
fn ensure_trailing_slash(text : String) -> String {
  if text == "" {
    ""
  } else if text is [.., '/'] {
    text
  } else {
    text + "/"
  }
}

///|
async fn resolve_wasm_path(wasm_arg : String) -> String {
  if wasm_arg.trim() == "" {
    raise RunError::InvalidArgs("missing wasm path")
  }
  let cwd = @fs.realpath(".")
  let path = if is_absolute_path(wasm_arg) {
    wasm_arg
  } else {
    path_join(cwd, wasm_arg)
  }
  if !@fs.exists(path) {
    raise RunError::MissingFile(path)
  }
  path
}

///|
async fn find_runtime_root_from(start_dir : String) -> String? {
  let mut dir = start_dir
  while dir != "" {
    let marker = path_join(dir, "mgstudio-runtime")
    if @fs.exists(marker) {
      return Some(dir)
    }
    let parent = @path.Path(dir).dirname().to_string()
    if parent == dir {
      break
    }
    dir = parent
  }
  None
}

///|
async fn resolve_runtime_root(
  runtime_root : String?,
  wasm_path : String,
) -> String {
  let cwd = @fs.realpath(".")
  match runtime_root {
    Some(root) if root.trim() != "" => {
      let r = if is_absolute_path(root) { root } else { path_join(cwd, root) }
      let marker = path_join(r, "mgstudio-runtime")
      if !@fs.exists(marker) {
        raise RunError::MissingRuntimeRoot(r)
      }
      r
    }
    _ => {
      let wasm_dir = path_dirname(wasm_path)
      match find_runtime_root_from(wasm_dir) {
        Some(r) => r
        None =>
          match find_runtime_root_from(cwd) {
            Some(r) => r
            None =>
              raise RunError::MissingRuntimeRoot(
                "Cannot find ./mgstudio-runtime/ from " +
                cwd +
                " (or " +
                wasm_dir +
                "). Pass --runtime-root.",
              )
          }
      }
    }
  }
}

///|
async fn run_native(opts : RunOptions) -> Unit {
  let wasm_path = resolve_wasm_path(opts.wasm)
  let runtime_root = resolve_runtime_root(opts.runtime_root, wasm_path)
  let runtime_dir = path_join(runtime_root, "mgstudio-runtime/native")
  let profile = if opts.release { "release" } else { "debug" }
  let mut runtime_exe = path_join(runtime_dir, "mgstudio-runtime-native.exe")
  let built_exe = path_join(
    runtime_dir,
    "_build/native/\{profile}/build/mgstudio-runtime-native.exe",
  )
  if !@fs.exists(runtime_exe) && !@fs.exists(built_exe) {
    // Developer fallback: if sources are present, build the runtime.
    let has_sources = @fs.exists(path_join(runtime_dir, "moon.mod.json"))
    if has_sources {
      let runtime_args : Array[String] = if opts.release {
        ["build", "--release", "-C", runtime_dir]
      } else {
        ["build", "-C", runtime_dir]
      }
      run_process_checked("moon", runtime_args, cwd=runtime_root)
    }
  }
  if !@fs.exists(runtime_exe) && @fs.exists(built_exe) {
    runtime_exe = built_exe
  }
  if !@fs.exists(runtime_exe) {
    raise RunError::MissingFile(runtime_exe)
  }
  let wasm_dir = path_dirname(wasm_path)
  let default_assets_dir = path_join(wasm_dir, "assets")
  let assets_source = match opts.assets_source {
    Some(s) if s.trim() != "" => {
      let v = s.trim().to_string()
      if v.has_prefix("dir:") {
        v
      } else {
        "dir:" + v
      }
    }
    _ =>
      if @fs.exists(default_assets_dir) {
        "dir:" + default_assets_dir
      } else {
        "dir:" + wasm_dir
      }
  }
  let default_data_dir = path_join(wasm_dir, ".mgstudio-data")
  let data_source = match opts.data_source {
    Some(s) if s.trim() != "" => {
      let v = s.trim().to_string()
      if v.has_prefix("dir:") {
        v
      } else {
        "dir:" + v
      }
    }
    _ => "dir:" + default_data_dir
  }
  let extra_env : Map[String, String] = match opts.wgpu_lib {
    Some(p) if p != "" =>
      {
        "MGSTUDIO_ASSETS_SOURCE": assets_source,
        "MGSTUDIO_DATA_SOURCE": data_source,
        "MBT_WGPU_NATIVE_LIB": p,
      }
    _ =>
      {
        "MGSTUDIO_ASSETS_SOURCE": assets_source,
        "MGSTUDIO_DATA_SOURCE": data_source,
      }
  }
  run_process_checked(runtime_exe, [wasm_path], cwd=runtime_root, extra_env~)
}

///|
async fn serve_web(opts : ServeOptions) -> Unit {
  let wasm_path = resolve_wasm_path(opts.wasm)
  let runtime_root = resolve_runtime_root(opts.runtime_root, wasm_path)
  let template_dir = path_join(runtime_root, "mgstudio-runtime/web")

  // Ensure the web runtime bundle exists (build as a developer fallback).
  let bundle_src = path_join(template_dir, "mgstudio-runtime-web.js")
  if !@fs.exists(bundle_src) {
    let has_sources = @fs.exists(path_join(template_dir, "moon.mod.json"))
    if has_sources {
      let runtime_args : Array[String] = if opts.release {
        ["build", "--release", "--target", "js", "-C", template_dir]
      } else {
        ["build", "--target", "js", "-C", template_dir]
      }
      run_process_checked("moon", runtime_args, cwd=runtime_root)
      let js_profile = if opts.release { "release" } else { "debug" }
      let built_bundle = path_join(
        template_dir,
        "_build/js/\{js_profile}/build/mgstudio-runtime-web.js",
      )
      if @fs.exists(built_bundle) {
        run_process_checked("cp", [built_bundle, bundle_src], cwd=runtime_root)
      }
    }
  }
  if !@fs.exists(bundle_src) {
    raise RunError::MissingFile(bundle_src)
  }
  let index_src = path_join(template_dir, "index.html")
  if !@fs.exists(index_src) {
    raise RunError::MissingFile(index_src)
  }

  // Stage a served root to avoid mutating the runtime template folder.
  let cwd = @fs.realpath(".")
  let stage_root = path_join(cwd, ".mgstudio/serve")
  if @fs.exists(stage_root) {
    @fs.rmdir(stage_root, recursive=true) catch {
      _ => @fs.remove(stage_root) catch { _ => () }
    }
  }
  @fs.mkdir(stage_root, permission=0o755, recursive=true)

  // Copy runtime entry files.
  run_process_checked("cp", [index_src, stage_root], cwd=runtime_root)
  run_process_checked("cp", [bundle_src, stage_root], cwd=runtime_root)

  // Copy game wasm into served root.
  let wasm_dst = path_join(stage_root, "game.wasm")
  run_process_checked("cp", [wasm_path, wasm_dst], cwd=runtime_root)

  // Assets: either mount a local directory or use a URL base.
  let mut assets_base = "./assets/"
  let mut mounted_assets = false
  match opts.assets_source {
    Some(s) if s.trim() != "" => {
      let spec = s.trim().to_string()
      let local_path = strip_dir_prefix(spec)
      let is_remote = spec.has_prefix("http://") || spec.has_prefix("https://")
      if !is_remote && @fs.exists(local_path) {
        let mount = path_join(stage_root, "_mgstudio_assets")
        if @fs.exists(mount) {
          @fs.rmdir(mount, recursive=true) catch {
            _ => @fs.remove(mount) catch { _ => () }
          }
        }
        @fs.symlink(mount, target=local_path)
        assets_base = "./_mgstudio_assets/"
        mounted_assets = true
      } else if !is_remote && spec.has_prefix("dir:") {
        raise RunError::MissingFile(local_path)
      } else {
        // Treat as URL base (relative or absolute).
        assets_base = ensure_trailing_slash(strip_dir_prefix(spec))
      }
    }
    _ => ()
  }
  if !mounted_assets {
    // Default: mount the runtime template's bundled assets folder if present.
    let template_assets = path_join(template_dir, "assets")
    if @fs.exists(template_assets) {
      let mount = path_join(stage_root, "assets")
      if @fs.exists(mount) {
        @fs.rmdir(mount, recursive=true) catch {
          _ => @fs.remove(mount) catch { _ => () }
        }
      }
      @fs.symlink(mount, target=template_assets)
      assets_base = "./assets/"
    }
  }

  // Data source for web: default to IndexedDB.
  let data_source = match opts.data_source {
    Some(s) if s.trim() != "" => {
      let v = s.trim().to_string()
      if v.has_prefix("idb:") {
        v
      } else {
        "idb:" + v
      }
    }
    _ => "idb:mgstudio"
  }
  let port = opts.port
  println("")
  println(
    "Serving web runtime at: http://localhost:\{port}/?wasm=./game.wasm&assets_source=\{assets_base}&data_source=\{data_source}",
  )
  println("Press Ctrl+C to stop.")
  println("")
  let server_args = ["-m", "http.server", port, "--directory", stage_root]
  run_process_checked("python3", server_args, cwd=runtime_root)
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
  @path.Path(path).basename().to_string()
}

///|
fn path_join(dir : String, file : String) -> String {
  @path.Path(dir).join(file).to_string()
}

///|
fn path_dirname(path : String) -> String {
  @path.Path(path).dirname().to_string()
}

///|

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
  name == "bevy" ||
  // Vendored third-party modules (e.g. local forks of dependencies).
  name == "wasmoon" ||
  name == "wgpu_mbt"
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

  // Track generated .mbt files and format only those. This avoids reformatting
  // unrelated user-edited files, while keeping codegen output consistent.
  let gen_mbt_paths : Array[String] = []

  // pkg_dir -> (components/resources, source_files)
  let components_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  let resources_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  let sources_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  for module_root in module_roots {
    collect_ecs_components_for_module(
      module_root, components_by_pkg, resources_by_pkg, sources_by_pkg,
    )
  }
  let mut any_diff = false
  for entry in components_by_pkg.iter() {
    let (pkg_dir, comps) = entry
    let resources : Array[String] = resources_by_pkg.get(pkg_dir).unwrap_or([])
    if comps.length() == 0 && resources.length() == 0 {
      continue
    }

    // `ecs.g.mbt` defines access traits that reference `@core.ComponentStore`
    // and `@core.Resource`, so tagged packages must import mgstudio core.
    let pkg_json_path = path_join(pkg_dir, "moon.pkg.json")
    match read_file_text(pkg_json_path) {
      Some(pkg_src) => {
        let updated = ensure_moon_pkg_import(pkg_src, "Milky2018/mgstudio/core")
        let ok_pkg = write_or_check(
          pkg_json_path,
          updated,
          check~,
          verbose=opts.verbose,
        )
        if !ok_pkg.ok {
          any_diff = true
        }
      }
      None => ()
    }
    let sources : Array[String] = sources_by_pkg.get(pkg_dir).unwrap_or([])
    let out_path = path_join(pkg_dir, "ecs.g.mbt")
    let content = render_ecs_generated_file(pkg_dir, comps, resources, sources)
    let ok = write_or_check(out_path, content, check~, verbose=opts.verbose)
    if ok.changed {
      gen_mbt_paths.push(out_path)
    }
    if !ok.ok {
      any_diff = true
    }
  }
  if opts.world_pkg is Some(world_pkg) {
    let ok = generate_ecs_world(
      workspace,
      world_pkg,
      module_infos,
      components_by_pkg,
      resources_by_pkg,
      check~,
      verbose=opts.verbose,
      gen_mbt_paths,
    )
    if !ok {
      any_diff = true
    }
  }
  if !check {
    // Format only generated files so `mgstudio gen` doesn't touch unrelated code.
    for p in gen_mbt_paths {
      if opts.verbose {
        println("Formatting: \{p}")
      }
      let code = @process.run("moonfmt", ["-w", p], cwd=workspace)
      if code != 0 {
        println("moonfmt failed: \{p} (exit=\{code})")
        @sys.exit(1)
      }
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
struct TypeRef {
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

///|
fn fits_one_line(s : String) -> Bool {
  s.length() <= FMT_MAX_LINE
}

///|
fn render_string_array_one_line(items : Array[String]) -> String {
  if items.length() == 0 {
    "[]"
  } else {
    let quoted = items.map(fn(s) { "\"\{s}\"" }).join(",")
    "[\{quoted}]"
  }
}

///|
fn type_ref_key(c : TypeRef) -> String {
  c.pkg_import + "/" + c.tycon
}

///|
fn sort_type_refs(items : Array[TypeRef]) -> Unit {
  // Deterministic sort without relying on stdlib comparator APIs.
  // Insertion sort is fine because component counts are small.
  let mut i = 1
  while i < items.length() {
    let cur = items[i]
    let cur_key = type_ref_key(cur)
    let mut j = i
    while j > 0 && cur_key < type_ref_key(items[j - 1]) {
      items[j] = items[j - 1]
      j = j - 1
    }
    items[j] = cur
    i = i + 1
  }
}

///|
fn render_world_file(
  components : Array[TypeRef],
  resources : Array[TypeRef],
) -> String {
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
  sort_type_refs(comps)
  let res = resources.copy()
  sort_type_refs(res)
  let component_fields = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "  \{snake} : @core.ComponentStore[@\{c.pkg_alias}.\{c.tycon}]\n"
    })
    .join("")
  let resource_fields = res
    .map(fn(r) {
      let snake = camel_to_snake(r.tycon)
      "  res_\{snake} : @core.Resource[@\{r.pkg_alias}.\{r.tycon}]\n"
    })
    .join("")
  let init_fields = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "    \{snake}: @core.ComponentStore::new(),\n"
    })
    .join("") +
    res
    .map(fn(r) {
      let snake = camel_to_snake(r.tycon)
      "    res_\{snake}: @core.Resource::new(),\n"
    })
    .join("")
  let mut init_expr = "World::{ entities: @core.Entities::new(), change_tick: 0, system_context: @core.SystemContext::new()"
  for c in comps {
    let snake = camel_to_snake(c.tycon)
    init_expr = init_expr + ", \{snake}: @core.ComponentStore::new()"
  }
  for r in res {
    let snake = camel_to_snake(r.tycon)
    init_expr = init_expr + ", res_\{snake}: @core.Resource::new()"
  }
  init_expr = init_expr + " }"
  let world_new_body = if fits_one_line(init_expr) {
    "  \{init_expr}\n"
  } else {
    "  World::{\n" +
    "    entities: @core.Entities::new(),\n" +
    "    change_tick: 0,\n" +
    "    system_context: @core.SystemContext::new(),\n" +
    init_fields +
    "  }\n"
  }
  let component_trait_impls = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "///|\n" +
      "pub impl @\{c.pkg_alias}.Has_\{c.tycon} for World with get_\{snake}_store(self) {\n" +
      "  self.\{snake}\n" +
      "}\n"
    })
    .join("\n")
  let resource_trait_impls = res
    .map(fn(r) {
      let snake = camel_to_snake(r.tycon)
      "///|\n" +
      "pub impl @\{r.pkg_alias}.HasRes_\{r.tycon} for World with get_\{snake}_resource(self) {\n" +
      "  self.res_\{snake}\n" +
      "}\n"
    })
    .join("\n")
  let trait_impls = component_trait_impls +
    (if component_trait_impls.length() > 0 && resource_trait_impls.length() > 0 {
      "\n\n"
    } else {
      ""
    }) +
    resource_trait_impls
  let cleanup = comps
    .map(fn(c) {
      let snake = camel_to_snake(c.tycon)
      "  self.\{snake}.remove(entity) |> ignore\n"
    })
    .join("")
  header +
  "\n" +
  "///|\n" +
  "pub struct World {\n" +
  "  entities : @core.Entities\n" +
  "  mut change_tick : @core.Tick\n" +
  "  mut system_context : @core.SystemContext\n" +
  component_fields +
  resource_fields +
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
  "///|\n" +
  "pub impl @core.SpawnWorld for World with spawn_empty(self) {\n" +
  "  self.entities.spawn()\n" +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub impl @core.SpawnWorld for World with despawn(self, entity) {\n" +
  "  self.entities.despawn(entity)\n" +
  cleanup +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub impl @core.ChangeTickWorld for World with read_change_tick(self) {\n" +
  "  self.change_tick\n" +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub impl @core.ChangeTickWorld for World with increment_change_tick(self) {\n" +
  "  self.change_tick = self.change_tick + 1\n" +
  "  self.change_tick\n" +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub impl @core.SystemContextWorld for World with get_system_context(self) {\n" +
  "  self.system_context\n" +
  "}\n" +
  "\n" +
  "///|\n" +
  "pub impl @core.SystemContextWorld for World with set_system_context(self, ctx) {\n" +
  "  self.system_context = ctx\n" +
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
  resources_by_pkg : @hashmap.HashMap[String, Array[String]],
  check~ : Bool,
  verbose~ : Bool,
  gen_mbt_paths : Array[String],
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
  let all_components : Array[TypeRef] = []
  let all_resources : Array[TypeRef] = []
  for entry in components_by_pkg.iter() {
    let (pkg_dir, comps) = entry
    let resources : Array[String] = resources_by_pkg.get(pkg_dir).unwrap_or([])
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
      all_components.push({ pkg_import, pkg_alias, tycon })
    }
    for tycon in resources {
      all_resources.push({ pkg_import, pkg_alias, tycon })
    }
  }
  let world_mbt = render_world_file(all_components, all_resources)
  let world_path = path_join(world_pkg, "ecs_world.g.mbt")
  let ok_world = write_or_check(world_path, world_mbt, check~, verbose~)
  if ok_world.changed {
    gen_mbt_paths.push(world_path)
  }

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
  ok_world.ok && ok_pkg.ok
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
  resources_by_pkg : @hashmap.HashMap[String, Array[String]],
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
        let tags = parse_ecs_tags_from_file(file_path)
        if tags.components.length() == 0 && tags.resources.length() == 0 {
          continue
        }

        // Merge into package buckets.
        let bucket : Array[String] = components_by_pkg
          .get(dir_path)
          .unwrap_or([])
        for c in tags.components {
          if !bucket.contains(c) {
            bucket.push(c)
          }
        }
        components_by_pkg.set(dir_path, bucket)
        let res_bucket : Array[String] = resources_by_pkg
          .get(dir_path)
          .unwrap_or([])
        for r in tags.resources {
          if !res_bucket.contains(r) {
            res_bucket.push(r)
          }
        }
        resources_by_pkg.set(dir_path, res_bucket)
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
  match attr.parsed {
    Some(@attribute.Expr::Ident(id) | @attribute.Expr::Apply(id, _)) =>
      id.qual == Some("ecs") && id.name == "component"
    _ => false
  }
}

///|
fn is_ecs_resource_attr(attr : @attribute.Attribute) -> Bool {
  match attr.parsed {
    Some(@attribute.Expr::Ident(id) | @attribute.Expr::Apply(id, _)) =>
      id.qual == Some("ecs") && id.name == "resource"
    _ => false
  }
}

///|
async fn parse_ecs_tags_from_file(path : String) -> EcsTags {
  let text = read_file_text(path)
  guard text is Some(src) else { return { components: [], resources: [] } }
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
  let resources : Array[String] = []
  for impl_ in impls {
    match impl_ {
      @syntax.Impl::TopTypeDef(td) => {
        let mut component_marked = false
        let mut resource_marked = false
        for attr in td.attrs {
          if is_ecs_component_attr(attr) {
            component_marked = true
          }
          if is_ecs_resource_attr(attr) {
            resource_marked = true
          }
        }
        if component_marked && !comps.contains(td.tycon) {
          comps.push(td.tycon)
        }
        if resource_marked && !resources.contains(td.tycon) {
          resources.push(td.tycon)
        }
      }
      _ => ()
    }
  }
  { components: comps, resources }
}

///|
fn render_ecs_generated_file(
  pkg_dir : String,
  components : Array[String],
  resources : Array[String],
  sources : Array[String],
) -> String {
  let comps = components.copy()
  comps.sort()
  let res = resources.copy()
  res.sort()
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
  let comps_literal = render_string_array_one_line(comps)
  let res_literal = render_string_array_one_line(res)
  let comps_body = if fits_one_line(comps_literal) {
    "///|\n" +
    "/// ECS component types discovered via `#ecs.component`.\n" +
    "pub let ecs_components : Array[String] = \{comps_literal}\n"
  } else {
    "///|\n" +
    "/// ECS component types discovered via `#ecs.component`.\n" +
    "pub let ecs_components : Array[String] = [\n" +
    comps.map(c => "  \"\{c}\",\n").join("") +
    "]\n"
  }
  let res_body = if fits_one_line(res_literal) {
    "\n" +
    "///|\n" +
    "/// ECS resource types discovered via `#ecs.resource`.\n" +
    "pub let ecs_resources : Array[String] = \{res_literal}\n"
  } else {
    "\n" +
    "///|\n" +
    "/// ECS resource types discovered via `#ecs.resource`.\n" +
    "pub let ecs_resources : Array[String] = [\n" +
    res.map(c => "  \"\{c}\",\n").join("") +
    "]\n"
  }
  let component_traits = comps
    .map(fn(tycon) {
      let snake = camel_to_snake(tycon)
      "///|\n" +
      "pub(open) trait Has_\{tycon} {\n" +
      "  get_\{snake}_store(self : Self) -> @core.ComponentStore[\{tycon}]\n" +
      "}\n"
    })
    .join("\n")
  let resource_traits = res
    .map(fn(tycon) {
      let snake = camel_to_snake(tycon)
      "///|\n" +
      "pub(open) trait HasRes_\{tycon} {\n" +
      "  get_\{snake}_resource(self : Self) -> @core.Resource[\{tycon}]\n" +
      "}\n"
    })
    .join("\n")
  let traits_body = if component_traits.length() == 0 &&
    resource_traits.length() == 0 {
    ""
  } else {
    "\n" +
    component_traits +
    (if component_traits.length() > 0 && resource_traits.length() > 0 {
      "\n\n"
    } else {
      ""
    }) +
    resource_traits
  }
  header + comps_body + res_body + traits_body
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
fn contains_substring(haystack : String, needle : String) -> Bool {
  let h = haystack.view()
  let n = needle.view()
  if n.length() == 0 {
    return true
  }
  let hl = h.length()
  let nl = n.length()
  if nl > hl {
    return false
  }
  let mut i = 0
  while i + nl <= hl {
    if (try! h[i:i + nl]) == n {
      return true
    }
    i = i + 1
  }
  false
}

///|
fn find_substring(haystack : String, needle : String, start : Int) -> Int? {
  let h = haystack.view()
  let n = needle.view()
  let hl = h.length()
  let nl = n.length()
  if nl == 0 {
    return Some(start)
  }
  let mut i = if start < 0 { 0 } else { start }
  while i + nl <= hl {
    if (try! h[i:i + nl]) == n {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn find_char_forward(s : String, start : Int, ch : Char) -> Int? {
  let v = s.view()
  let target = ch.to_int()
  let mut i = if start < 0 { 0 } else { start }
  while i < v.length() {
    if v.code_unit_at(i).to_int() == target {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn find_char_backward(s : String, ch : Char) -> Int? {
  let v = s.view()
  let target = ch.to_int()
  let mut i = v.length() - 1
  while i >= 0 {
    if v.code_unit_at(i).to_int() == target {
      return Some(i)
    }
    i = i - 1
  }
  None
}

///|
fn is_all_whitespace(s : String, start : Int, end_ : Int) -> Bool {
  let v = s.view()
  let mut i = start
  while i < end_ {
    let c = v.code_unit_at(i).to_int()
    if c != ' '.to_int() &&
      c != '\n'.to_int() &&
      c != '\r'.to_int() &&
      c != '\t'.to_int() {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn rstrip_index(s : String, end_ : Int) -> Int {
  let v = s.view()
  let mut i = end_
  while i > 0 {
    let c = v.code_unit_at(i - 1).to_int()
    if c == ' '.to_int() ||
      c == '\n'.to_int() ||
      c == '\r'.to_int() ||
      c == '\t'.to_int() {
      i = i - 1
    } else {
      break
    }
  }
  i
}

///|
fn ensure_moon_pkg_import(src : String, import_path : String) -> String {
  let quoted = "\"\{import_path}\""
  if contains_substring(src, quoted) {
    return src
  }
  let trimmed = src.trim()
  if trimmed == "{}" {
    return "{\n  \"import\": [\n    \{quoted}\n  ]\n}\n"
  }
  let key = "\"import\""
  match find_substring(src, key, 0) {
    None => {
      // Insert a new import key before the last '}'.
      let close_i = find_char_backward(src, '}').unwrap_or(src.length())
      let prefix = try! src.view()[0:close_i].to_string()
      let suffix = try! src.view()[close_i:src.length()].to_string()
      let needs_comma = contains_substring(prefix, ":")
      let insert = (if needs_comma { ",\n" } else { "\n" }) +
        "  \"import\": [\n    \{quoted}\n  ]\n"
      prefix + insert + suffix
    }
    Some(key_i) => {
      // Find the '[' and matching ']'. This is a pragmatic edit for the repo's
      // simple moon.pkg.json formatting (no nested arrays in import items).
      let open_i = find_char_forward(src, key_i, '[').unwrap_or(src.length())
      let close_i = find_char_forward(src, open_i, ']').unwrap_or(src.length())
      if open_i >= close_i {
        return src
      }
      let inner_start = open_i + 1
      let inner_end = close_i
      let inner_ws = is_all_whitespace(src, inner_start, inner_end)
      if inner_ws {
        // Empty import array: replace with a single line item.
        let prefix = try! src.view()[0:inner_start].to_string()
        let suffix = try! src.view()[inner_start:src.length()].to_string()
        prefix + "\n    \{quoted}\n  " + suffix
      } else {
        // Append before ']' (but after the last non-whitespace item).
        let insert_i = rstrip_index(src, close_i)
        let before = try! src.view()[0:insert_i].to_string()
        let after = try! src.view()[insert_i:src.length()].to_string()
        before + ",\n    \{quoted}\n  " + after
      }
    }
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
struct WriteOrCheckResult {
  ok : Bool
  changed : Bool
}

///|
async fn write_or_check(
  path : String,
  content : String,
  check~ : Bool,
  verbose~ : Bool,
) -> WriteOrCheckResult {
  let existing = read_file_text(path)
  if existing is Some(s) && s == content {
    if verbose {
      println("OK: \{path}")
    }
    { ok: true, changed: false }
  } else if check {
    println("Out of date: \{path}")
    { ok: false, changed: false }
  } else {
    write_file_text(path, content)
    println("Generated: \{path}")
    { ok: true, changed: true }
  }
}
