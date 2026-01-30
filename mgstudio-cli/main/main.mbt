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
/// - `mgstudio run`: run a game config in native runtime (calls `game_app`).
/// - `mgstudio serve`: serve the web runtime and run a game config in browser (calls `game_app`).
/// - `mgstudio new`: create a new game project template.
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
        if top == "run" || top == "serve" || top == "gen" || top == "new" {
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
        "new" => cmd_new(cmd)
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
          "check": @clap.Arg::flag(
            short='c',
            help="Verify generated files are up-to-date (do not write).",
          ),
          "verbose": @clap.Arg::flag(
            short='v',
            help="Print scanned modules and generated paths.",
          ),
        },
      ),
      "run": @clap.SubCommand::new(
        help="Run a game described by a game config file in native runtime (calls export `game_app`).",
        args={
          "game": @clap.Arg::named(
            short='g',
            nargs=@clap.Nargs::AtMost(1U),
            help="Path to game config file. If omitted, search for ./moon.game.json from current directory upwards.",
          ),
        },
      ),
      "serve": @clap.SubCommand::new(
        help="Serve the web runtime and run a game described by a game config file in browser (calls export `game_app`).",
        args={
          "game": @clap.Arg::named(
            short='g',
            nargs=@clap.Nargs::AtMost(1U),
            help="Path to game config file. If omitted, search for ./moon.game.json from current directory upwards.",
          ),
          "addr": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Override web server bind address (default: from game config or localhost).",
          ),
          "port": @clap.Arg::named(
            short='p',
            nargs=@clap.Nargs::AtMost(1U),
            help="Override web server port (default: from game config or 8099).",
          ),
        },
      ),
      "new": @clap.SubCommand::new(
        help="Create a new MoonBit game project (moon new + moon.game.json + index.html).",
        args={
          "name": @clap.Arg::positional(
            nargs=@clap.Nargs::Fixed(1U),
            help="Project name (directory to create).",
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
  check : Bool
  verbose : Bool
}

///|
struct RunOptions {
  game : String?
}

///|
struct ServeOptions {
  game : String?
  addr : String?
  port : String?
}

///|
suberror RunError {
  ProcessFailed(String, Int)
  MissingFile(String)
  InvalidArgs(String)
} derive(Show)

///|
struct EcsTags {
  components : Array[String]
  resources : Array[String]
}

///|
async fn cmd_gen(cmd : @clap.SimpleValue) -> Unit {
  let opts : GenOptions = parse_gen_options(cmd)
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
      match err {
        RunError::MissingFile(path) => {
          println("mgstudio run failed: Missing file: \{path}")
          println(
            "Hint: run in a directory containing moon.game.json, or pass --game <path>.",
          )
        }
        _ => println("mgstudio run failed: \{err}")
      }
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
      match err {
        RunError::MissingFile(path) => {
          println("mgstudio serve failed: Missing file: \{path}")
          println(
            "Hint: run in a directory containing moon.game.json, or pass --game <path>.",
          )
        }
        _ => println("mgstudio serve failed: \{err}")
      }
      @sys.exit(1)
    }
  }
}

///|
async fn cmd_new(cmd : @clap.SimpleValue) -> Unit {
  let name_args : Array[String] = cmd.get_positional()
  guard name_args.get(0) is Some(name) else {
    println("Missing required positional argument: name")
    @sys.exit(2)
    return
  }
  new_game_project(name) catch {
    err => {
      println("mgstudio new failed: \{err}")
      @sys.exit(1)
    }
  }
}

///|
fn parse_run_options_defaults(_workspace : String) -> RunOptions {
  { game: None }
}

///|
fn parse_run_options(
  cmd : @clap.SimpleValue,
) -> RunOptions raise @clap.ParserError {
  let game : String? = cmd.get_option("game")
  { game, }
}

///|
fn parse_serve_options_defaults() -> ServeOptions {
  { game: None, addr: None, port: None }
}

///|
fn parse_serve_options(
  cmd : @clap.SimpleValue,
) -> ServeOptions raise @clap.ParserError {
  let game : String? = cmd.get_option("game")
  let addr : String? = cmd.get_option("addr")
  let port : String? = cmd.get_option("port")
  { game, addr, port }
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
fn render_web_index_html(runtime_js_url : String) -> String {
  // Keep a dummy menu element so the web runtime doesn't overwrite the status
  // with "Missing menu element".
  "<!doctype html>\n" +
  "<html lang=\"en\">\n" +
  "  <head>\n" +
  "    <meta charset=\"utf-8\" />\n" +
  "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n" +
  "    <title>Moon Game Studio</title>\n" +
  "    <style>\n" +
  "      html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #0b0f16; }\n" +
  "      canvas { display: block; width: 100%; height: 100%; }\n" +
  "      #mgstudio-menu { display: none; }\n" +
  "    </style>\n" +
  "  </head>\n" +
  "  <body>\n" +
  "    <canvas id=\"mgstudio-canvas\"></canvas>\n" +
  "    <div id=\"mgstudio-menu\"></div>\n" +
  "    <script type=\"module\" src=\"" +
  runtime_js_url +
  "\"></script>\n" +
  "  </body>\n" +
  "</html>\n"
}

///|
async fn stage_assets(
  stage_root : String,
  assets_spec : String,
) -> (String, Bool) {
  let spec = assets_spec.trim().to_string()
  if spec.has_prefix("dir:") {
    let local_path = strip_dir_prefix(spec)
    if !@fs.exists(local_path) {
      raise RunError::MissingFile(local_path)
    }
    let mount = path_join(stage_root, "_mgstudio_assets")
    if @fs.exists(mount) {
      @fs.rmdir(mount, recursive=true) catch {
        _ => @fs.remove(mount) catch { _ => () }
      }
    }
    @fs.symlink(mount, target=local_path)
    ("./_mgstudio_assets/", true)
  } else if spec.has_prefix("http://") || spec.has_prefix("https://") {
    (ensure_trailing_slash(spec), false)
  } else {
    raise RunError::InvalidArgs("Unsupported assets spec for web: " + spec)
  }
}

///|
fn url_encode_component(value : String) -> String {
  // Minimal percent-encoding for query values. This is sufficient for our
  // expected values (relative paths, idb:*, and https://* base URLs).
  let b = StringBuilder::new(size_hint=value.length())
  for c in value {
    match c {
      ' ' => b.write_string("%20")
      '%' => b.write_string("%25")
      '&' => b.write_string("%26")
      '#' => b.write_string("%23")
      '?' => b.write_string("%3F")
      '=' => b.write_string("%3D")
      '+' => b.write_string("%2B")
      _ => b.write_char(c)
    }
  }
  b.to_string()
}

///|
async fn new_game_project(name : String) -> Unit {
  let project_name = name.trim().to_string()
  if project_name == "" {
    raise RunError::InvalidArgs("project name is empty")
  }
  let cwd = @fs.realpath(".")
  let project_dir = path_join(cwd, project_name)
  if @fs.exists(project_dir) {
    raise RunError::InvalidArgs("path already exists: " + project_dir)
  }
  run_process_checked("moon", ["new", project_name], cwd~)

  // Rewrite the template into a runnable mgstudio game (similar to
  // mgstudio-engine/examples/2d/*), while keeping the project minimal.

  // Remove template CI and hooks to keep the generated project focused.
  @fs.rmdir(path_join(project_dir, ".githooks"), recursive=true) catch {
    _ => ()
  }
  @fs.rmdir(path_join(project_dir, ".github"), recursive=true) catch {
    _ => ()
  }
  @fs.remove(path_join(project_dir, "AGENTS.md")) catch {
    _ => ()
  }
  // `moon new` creates `cmd/main` as the default binary package; mgstudio games
  // don't need a `main` entrypoint.
  @fs.rmdir(path_join(project_dir, "cmd"), recursive=true) catch {
    _ => ()
  }

  // Create assets/data directories. Game config defaults will pick these up.
  @fs.mkdir(
    path_join(project_dir, "assets/branding"),
    permission=0o755,
    recursive=true,
  )
  @fs.mkdir(
    path_join(project_dir, "tmp/data"),
    permission=0o755,
    recursive=true,
  )

  // Write a tiny icon.png (base64) so the default sprite/rotation demo runs
  // without requiring any external assets.
  let icon_dst = path_join(project_dir, "assets/branding/icon.png")
  // A 64x64 PNG with a simple colored pattern (opaque).
  let icon_b64 = "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"
  let icon_bytes = @base64.decode(icon_b64.view()) catch {
    err =>
      raise RunError::InvalidArgs(
        "Failed to decode built-in icon.png base64: " + err.to_string(),
      )
  }
  write_file_bytes(icon_dst, icon_bytes)

  // Update moon.mod.json to depend on mgstudio and prefer wasm-gc.
  let mod_json_path = path_join(project_dir, "moon.mod.json")
  let mod_src_opt = read_file_text(mod_json_path)
  let module_name = match mod_src_opt {
    Some(src) => parse_module_name(src).unwrap_or("username/" + project_name)
    None => "username/" + project_name
  }
  let deps_entry = "\"deps\": { \"Milky2018/mgstudio\": \"0.1.0\" },\n"
  let mod_json = "{\n" +
    "  \"name\": \"" +
    module_name +
    "\",\n" +
    "  \"version\": \"0.1.0\",\n" +
    "  " +
    deps_entry +
    "  \"readme\": \"README.mbt.md\",\n" +
    "  \"repository\": \"\",\n" +
    "  \"license\": \"Apache-2.0\",\n" +
    "  \"keywords\": [],\n" +
    "  \"description\": \"\",\n" +
    "  \"preferred-target\": \"wasm-gc\"\n" +
    "}\n"
  write_file_text(mod_json_path, mod_json)

  // Root package: export `game_app` (no `main` function needed).
  write_file_text(
    path_join(project_dir, "moon.pkg.json"),
    "{\n" +
    "  \"import\": [\n" +
    "    \"Milky2018/mgstudio/app\",\n" +
    "    \"Milky2018/mgstudio/asset\",\n" +
    "    \"Milky2018/mgstudio/core\",\n" +
    "    \"Milky2018/mgstudio/ecs_world\",\n" +
    "    \"Milky2018/mgstudio/math\",\n" +
    "    \"Milky2018/mgstudio\",\n" +
    "    \"Milky2018/mgstudio/render2d\",\n" +
    "    \"Milky2018/mgstudio/time\"\n" +
    "  ],\n" +
    "  \"link\": {\n" +
    "    \"wasm-gc\": {\n" +
    "      \"exports\": [\n" +
    "        \"game_app\"\n" +
    "      ]\n" +
    "    }\n" +
    "  }\n" +
    "}\n",
  )

  // Replace the root demo with a minimal rotating sprite example.
  write_file_text(
    path_join(project_dir, project_name + ".mbt"),
    "///|\n" +
    "pub fn game_app() -> Unit {\n" +
    "  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()\n" +
    "  @app.App::new(@ecs_world.World::new())\n" +
    "  .add_plugins(plugins)\n" +
    "  .add_startup_system(rotation_setup)\n" +
    "  .add_system(rotation_update)\n" +
    "  .run()\n" +
    "}\n\n" +
    "///|\n" +
    "fn rotation_setup(world : @ecs_world.World) -> Unit {\n" +
    "  let asset_server = @asset.AssetServer::new()\n" +
    "  let texture = asset_server.load(\"branding/icon.png\")\n" +
    "  let sprite = @render2d.Sprite::new(@render2d.Color::white())\n" +
    "  let transform = @math.Transform::identity()\n" +
    "  @render2d.SpriteBundle::new(sprite, transform, texture).spawn(world) |> ignore\n" +
    "  let camera = @render2d.Camera2d::default()\n" +
    "  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(world) |> ignore\n" +
    "}\n\n" +
    "///|\n" +
    "fn rotation_update(world : @ecs_world.World) -> Unit {\n" +
    "  let delta_secs = @time.time_delta_seconds()\n" +
    "  let speed = 1.0F\n" +
    "  let tick = @core.ChangeTickWorld::read_change_tick(world)\n" +
    "  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)\n" +
    "  let transform_store = @math.Has_Transform::get_transform_store(world)\n" +
    "  let entities : Array[(@core.Entity, @math.Transform)] = []\n" +
    "  @core.query2(transform_store, sprite_store, fn(entity, transform, _sprite) {\n" +
    "    entities.push((entity, transform))\n" +
    "  })\n" +
    "  for entry in entities {\n" +
    "    let transform = entry.1\n" +
    "    let next_rotation = transform.rotation + speed * delta_secs\n" +
    "    let next_transform = @math.Transform::new(\n" +
    "      transform.translation,\n" +
    "      next_rotation,\n" +
    "      transform.scale,\n" +
    "    )\n" +
    "    transform_store.set(entry.0, next_transform, tick) |> ignore\n" +
    "  }\n" +
    "}\n",
  )
  @fs.remove(path_join(project_dir, project_name + "_test.mbt")) catch {
    _ => ()
  }

  // Game config: minimal; assets/data default to ./assets and ./tmp/data.
  let cart = "./_build/wasm-gc/release/build/" + project_name + ".wasm"
  let game_json_raw = "{\"mgstudio\":\"0.1.0\",\"cart\":\"" +
    cart +
    "\",\"native\":{\"wgpu_lib\":\"\"},\"web\":{\"addr\":\"localhost\",\"port\":8099}}"
  let game_json = @json.parse(game_json_raw).stringify(indent=2) + "\n"
  write_file_text(path_join(project_dir, "moon.game.json"), game_json)

  // Optional: a standalone index.html that loads the web runtime directly.
  let index_html = "<!doctype html>\n" +
    "<html lang=\"en\">\n" +
    "  <head>\n" +
    "    <meta charset=\"utf-8\" />\n" +
    "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n" +
    "    <title>Moon Game Studio</title>\n" +
    "    <style>\n" +
    "      html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #0b0f16; }\n" +
    "      canvas { display: block; width: 100%; height: 100%; }\n" +
    "      #mgstudio-menu { display: none; }\n" +
    "    </style>\n" +
    "  </head>\n" +
    "  <body>\n" +
    "    <canvas id=\"mgstudio-canvas\"></canvas>\n" +
    "    <div id=\"mgstudio-menu\"></div>\n" +
    "    <script>\n" +
    "      // Default to the game build output when no query string is provided.\n" +
    "      const url = new URL(window.location.href);\n" +
    "      if (!url.searchParams.get('wasm')) {\n" +
    "        url.searchParams.set('wasm', '" +
    cart +
    "');\n" +
    "        url.searchParams.set('assets_source', './assets/');\n" +
    "        url.searchParams.set('data_source', 'idb:mgstudio');\n" +
    "        history.replaceState(null, '', url.toString());\n" +
    "      }\n" +
    "    </script>\n" +
    "    <script type=\"module\" src=\"" +
    DEFAULT_WEB_RUNTIME_JS +
    "\"></script>\n" +
    "  </body>\n" +
    "</html>\n"
  write_file_text(path_join(project_dir, "index.html"), index_html)

  // Replace README with mgstudio-oriented instructions.
  write_file_text(
    path_join(project_dir, "README.mbt.md"),
    "# " +
    project_name +
    "\n\n" +
    "A minimal MoonBit + mgstudio game.\n\n" +
    "## Build\n\n" +
    "```bash\n" +
    "moon build --release --target wasm-gc\n" +
    "```\n\n" +
    "## Run (Native)\n\n" +
    "```bash\n" +
    "mgstudio run\n" +
    "```\n\n" +
    "## Run (Web)\n\n" +
    "```bash\n" +
    "mgstudio serve\n" +
    "```\n",
  )
}

///|
async fn run_native(opts : RunOptions) -> Unit {
  let game_cfg_path = resolve_game_config_path(opts.game)
  let cfg = load_game_config(game_cfg_path)
  println("Game config: \{cfg.file_path} (mgstudio=\{cfg.mgstudio})")
  let assets_source = cfg.assets_spec
  let data_source = cfg.data_spec_native
  if assets_source.has_prefix("http://") || assets_source.has_prefix("https://") {
    raise RunError::InvalidArgs(
      "Native runtime only supports dir assets source today (got: " +
      assets_source +
      ")",
    )
  }
  if data_source.has_prefix("idb:") ||
    data_source.has_prefix("http://") ||
    data_source.has_prefix("https://") {
    raise RunError::InvalidArgs(
      "Native runtime only supports dir data source today (got: " +
      data_source +
      ")",
    )
  }
  let wgpu_lib = cfg.native_wgpu_lib
  if wgpu_lib is Some(p) && p.trim() != "" {
    println("Using MBT_WGPU_NATIVE_LIB: \{p}")
  }
  @native_rt.run_game(cfg.cart_path, assets_source, data_source, wgpu_lib?)
}

///|
async fn serve_web(opts : ServeOptions) -> Unit {
  let game_cfg_path = resolve_game_config_path(opts.game)
  let cfg = load_game_config(game_cfg_path)
  println("Game config: \{cfg.file_path} (mgstudio=\{cfg.mgstudio})")
  let wasm_path = cfg.cart_path

  // Stage a served root alongside the game config.
  let stage_root = path_join(cfg.dir, ".mgstudio/serve")
  if @fs.exists(stage_root) {
    @fs.rmdir(stage_root, recursive=true) catch {
      _ => @fs.remove(stage_root) catch { _ => () }
    }
  }
  @fs.mkdir(stage_root, permission=0o755, recursive=true)

  // Write index.html that loads the web runtime from CDN / GitHub release.
  let index_dst = path_join(stage_root, "index.html")
  write_file_text(index_dst, render_web_index_html(cfg.web_runtime_js))

  // Copy game wasm into served root.
  let wasm_dst = path_join(stage_root, "game.wasm")
  run_process_checked("cp", [wasm_path, wasm_dst], cwd=cfg.dir)

  // Assets: either mount a local directory or use a URL base.
  let (assets_base, _mounted) = stage_assets(stage_root, cfg.assets_spec)

  // Data source for web: prefer idb.
  let data_source = cfg.data_spec_web
  if !data_source.has_prefix("idb:") {
    raise RunError::InvalidArgs(
      "Web runtime only supports idb data source today (got: " +
      data_source +
      ")",
    )
  }
  let addr = opts.addr.unwrap_or(cfg.web_addr)
  let port = opts.port.unwrap_or(cfg.web_port)
  println("")
  println(
    "Serving web runtime at: http://\{addr}:\{port}/?wasm=./game.wasm&assets_source=\{url_encode_component(assets_base)}&data_source=\{url_encode_component(data_source)}",
  )
  println("Press Ctrl+C to stop.")
  println("")
  let server_args = [
    "-m", "http.server", port, "--bind", addr, "--directory", stage_root,
  ]
  run_process_checked("python3", server_args, cwd=cfg.dir)
}

///|
fn parse_gen_options(cmd : @clap.SimpleValue) -> GenOptions {
  let check = cmd.get_flag("check").unwrap_or(false)
  let verbose = cmd.get_flag("verbose").unwrap_or(false)
  { check, verbose }
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
  let check = opts.check
  let module_root = @fs.realpath(".")
  let mod_json = path_join(module_root, "moon.mod.json")
  if !@fs.exists(mod_json) {
    raise RunError::InvalidArgs(
      "mgstudio gen must run in a MoonBit module directory (missing moon.mod.json): " +
      module_root,
    )
  }
  if opts.verbose {
    println("Module: \{module_root}")
  }
  let module_roots : Array[String] = [module_root]
  let module_infos = load_module_infos(module_roots)

  // Track generated .mbt files and format only those. This avoids reformatting
  // unrelated user-edited files, while keeping codegen output consistent.
  let gen_mbt_paths : Array[String] = []

  // pkg_dir -> (components/resources, source_files)
  let components_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  let resources_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  let sources_by_pkg : @hashmap.HashMap[String, Array[String]] = @hashmap.HashMap::new()
  collect_ecs_components_for_module(
    module_root, components_by_pkg, resources_by_pkg, sources_by_pkg,
  )
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
  // Always generate the ECS world package at a fixed location.
  let ok = generate_ecs_world(
    module_root,
    "ecs_world",
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
  if !check {
    // Format only generated files so `mgstudio gen` doesn't touch unrelated code.
    for p in gen_mbt_paths {
      if opts.verbose {
        println("Formatting: \{p}")
      }
      let code = @process.run("moonfmt", ["-w", p], cwd=module_root)
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
async fn write_file_bytes(path : String, content : Bytes) -> Unit {
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
