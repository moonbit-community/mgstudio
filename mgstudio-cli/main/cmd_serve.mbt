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
fn render_web_index_html(
  default_wasm_path : String,
  default_assets_source : String,
  default_data_source : String,
) -> String {
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
  "    <script>\n" +
  "      (() => {\n" +
  "        const url = new URL(window.location.href)\n" +
  "        const params = url.searchParams\n" +
  "        let changed = false\n" +
  "        const ensure = (key, value) => {\n" +
  "          const raw = params.get(key)\n" +
  "          if (!raw || !raw.trim()) {\n" +
  "            params.set(key, value)\n" +
  "            changed = true\n" +
  "          }\n" +
  "        }\n" +
  "        ensure(\"wasm\", \"" +
  default_wasm_path +
  "\")\n" +
  "        ensure(\"assets_source\", \"" +
  default_assets_source +
  "\")\n" +
  "        ensure(\"data_source\", \"" +
  default_data_source +
  "\")\n" +
  "        if (changed) {\n" +
  "          window.location.replace(url.toString())\n" +
  "        }\n" +
  "      })()\n" +
  "    </script>\n" +
  "    <script type=\"module\" src=\"./mgstudio-runtime-web.js\"></script>\n" +
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
async fn serve_web(opts : ServeOptions) -> Unit {
  let game_cfg_path = resolve_game_config_path(opts.game)
  let cfg = load_game_config(game_cfg_path)
  println("Game config: \{cfg.file_path} (mgstudio=\{cfg.mgstudio})")
  let sdk = resolve_sdk_layout(cfg)
  let wasm_path = cfg.cart_path

  // Stage a served root alongside the game config.
  let stage_root = path_join(cfg.dir, ".mgstudio/serve")
  if @fs.exists(stage_root) {
    @fs.rmdir(stage_root, recursive=true) catch {
      _ => @fs.remove(stage_root) catch { _ => () }
    }
  }
  @fs.mkdir(stage_root, permission=0o755, recursive=true)

  // Copy mgstudio-runtime-web.js from SDK into served root (offline by default).
  let runtime_dst = path_join(stage_root, "mgstudio-runtime-web.js")
  copy_file(sdk.web_runtime_js, runtime_dst)

  // Copy game wasm into served root.
  let wasm_dst = path_join(stage_root, "game.wasm")
  run_process_checked("cp", [wasm_path, wasm_dst], cwd=cfg.dir)

  // Assets: either mount a local directory or use a URL base.
  let (assets_base, _mounted) = stage_assets(
    stage_root,
    sdk.assets_dir,
    cfg.assets_allow_sdk_override,
    cfg.assets_spec,
  )

  // Data source for web: fixed namespace for now.
  cfg.data_spec_web |> ignore
  let data_source = "idb:mgstudio"

  // Write index.html that loads the web runtime JS bundle from the staged SDK file.
  // Default to a playable base URL without requiring query parameters.
  // The runtime still supports overriding these via URL params for debugging.
  let index_dst = path_join(stage_root, "index.html")
  write_file_text(
    index_dst,
    render_web_index_html("./game.wasm", assets_base, data_source),
  )
  let raw_addr = opts.addr.unwrap_or(cfg.web_addr)
  // Prefer IPv4 loopback to avoid browsers/extensions that auto-upgrade
  // `localhost` to HTTPS or hit IPv6 (::1) with TLS probes.
  let addr = if raw_addr == "localhost" { "127.0.0.1" } else { raw_addr }
  let port = opts.port.unwrap_or(cfg.web_port)
  println("")
  println("Serving web runtime at: http://\{addr}:\{port}/")
  println("Note: opening the base URL will auto-run ./game.wasm.")
  println(
    "Full URL (explicit params): http://\{addr}:\{port}/?wasm=./game.wasm&assets_source=\{url_encode_component(assets_base)}&data_source=\{url_encode_component(data_source)}",
  )
  println("Note: this server is plain HTTP. Do not use https:// for this URL.")
  println("Press Ctrl+C to stop.")
  println("")
  let server_args = [
    "-m", "http.server", port, "--bind", addr, "--directory", stage_root,
  ]
  run_process_checked("python3", server_args, cwd=cfg.dir)
}
