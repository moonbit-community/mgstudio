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
struct ServeOptions {
  game : String?
  addr : String?
  port : String?
}

///|
fn launcher_js_output_path(
  launcher_root : String,
  launcher_pkg : String,
) -> String {
  path_join(
    launcher_root,
    path_join(
      "_build/js/release/build",
      path_join(launcher_pkg, launcher_pkg + ".js"),
    ),
  )
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
fn js_string_escape(value : String) -> String {
  // Minimal JS string escaping for embedding small default URLs into index.html.
  let b = StringBuilder::new(size_hint=value.length())
  for c in value {
    match c {
      '\\' => b.write_string("\\\\")
      '"' => b.write_string("\\\"")
      '\n' => b.write_string("\\n")
      '\r' => b.write_string("\\r")
      '\t' => b.write_string("\\t")
      _ => b.write_char(c)
    }
  }
  b.to_string()
}

///|
fn render_web_index_html(
  default_assets_source : String,
  default_data_source : String,
) -> String {
  "<!doctype html>\n" +
  "<html lang=\"en\">\n" +
  "  <head>\n" +
  "    <meta charset=\"utf-8\" />\n" +
  "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n" +
  "    <title>Moon Game Studio</title>\n" +
  "    <style>\n" +
  "      html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #0b0f16; }\n" +
  "      canvas { display: block; width: 100%; height: 100%; }\n" +
  "    </style>\n" +
  "  </head>\n" +
  "  <body>\n" +
  "    <canvas id=\"mgstudio-canvas\"></canvas>\n" +
  "    <script>\n" +
  "      window.__MGSTUDIO_CONFIG = {\n" +
  "        assets_source: \"" +
  js_string_escape(default_assets_source) +
  "\",\n" +
  "        data_source: \"" +
  js_string_escape(default_data_source) +
  "\",\n" +
  "        canvas_id: \"mgstudio-canvas\",\n" +
  "      };\n" +
  "    </script>\n" +
  "    <script type=\"module\" src=\"./game.js\"></script>\n" +
  "  </body>\n" +
  "</html>\n"
}

///|
async fn stage_assets(
  stage_root : String,
  sdk_assets_dir : String,
  allow_sdk_override : Bool,
  assets_spec : String,
) -> (String, Bool) {
  let spec = assets_spec.trim().to_string()
  if spec.has_prefix("dir:") {
    let local_path = strip_dir_prefix(spec)
    if !@fs.exists(local_path) {
      raise RunError::MissingFile(local_path)
    }
    let overlay = path_join(stage_root, "_mgstudio_assets")
    stage_assets_overlay(
      overlay, sdk_assets_dir, local_path, allow_sdk_override,
    )
    ("./_mgstudio_assets/", true)
  } else if spec.has_prefix("http://") || spec.has_prefix("https://") {
    raise RunError::InvalidArgs(
      "HTTP assets are not supported when using an SDK-root overlay (got: " +
      spec +
      ")",
    )
  } else {
    raise RunError::InvalidArgs("Unsupported assets spec for web: " + spec)
  }
}

///|
async fn serve_web(opts : ServeOptions) -> Unit {
  let game_cfg_path = resolve_game_config_path(opts.game)
  let cfg = load_game_config(game_cfg_path)
  println("Game config: \{cfg.file_path} (mgstudio=\{cfg.mgstudio})")
  let sdk = resolve_sdk_layout(cfg)
  let (launcher_root, launcher_pkg) = prepare_launcher(cfg, Web)
  run_process_checked("moon", [
    "-C", launcher_root, "build", "--release", "--target", "js", launcher_pkg,
  ])
  let game_js = launcher_js_output_path(launcher_root, launcher_pkg)
  if !@fs.exists(game_js) {
    raise RunError::MissingFile(game_js)
  }

  // Stage a served root alongside the game config.
  let stage_root = path_join(cfg.dir, ".mgstudio/serve")
  if @fs.exists(stage_root) {
    @fs.rmdir(stage_root, recursive=true) catch {
      _ => @fs.remove(stage_root) catch { _ => () }
    }
  }
  @fs.mkdir(stage_root, permission=0o755, recursive=true)

  // Copy game js entry into served root.
  let game_js_dst = path_join(stage_root, "game.js")
  run_process_checked("cp", [game_js, game_js_dst], cwd=cfg.dir)

  // Assets: either mount a local directory or use a URL base.
  let (assets_base, _mounted) = stage_assets(
    stage_root,
    sdk.assets_dir,
    cfg.assets_allow_sdk_override,
    cfg.assets_spec,
  )

  // Data source for web.
  let data_source = cfg.data_spec_web

  // Write index.html that loads the built game JS bundle directly.
  let index_dst = path_join(stage_root, "index.html")
  write_file_text(index_dst, render_web_index_html(assets_base, data_source))
  let raw_addr = opts.addr.unwrap_or(cfg.web_addr)
  // Prefer IPv4 loopback to avoid browsers/extensions that auto-upgrade
  // `localhost` to HTTPS or hit IPv6 (::1) with TLS probes.
  let addr = if raw_addr == "localhost" { "127.0.0.1" } else { raw_addr }
  let port = opts.port.unwrap_or(cfg.web_port)
  println("")
  println("Serving web app at: http://\{addr}:\{port}/")
  println("Note: opening the base URL will auto-run ./game.js.")
  println("Note: this server is plain HTTP. Do not use https:// for this URL.")
  println("Press Ctrl+C to stop.")
  println("")
  let server_args = [
    "-m", "http.server", port, "--bind", addr, "--directory", stage_root,
  ]
  run_process_checked("python3", server_args, cwd=cfg.dir)
}
