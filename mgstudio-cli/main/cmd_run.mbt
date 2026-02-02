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
struct RunOptions {
  game : String?
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
        @native_rt.NativeRuntimeError::MissingExport(name) =>
          println("mgstudio run failed: Missing wasm export: \{name}")
        @native_rt.NativeRuntimeError::ExportCallFailed(name, msg) => {
          println("mgstudio run failed: Export call failed: \{name}")
          println(msg)
        }
        @native_rt.NativeRuntimeError::InstantiateFailed(path, msg) => {
          println("mgstudio run failed: Wasm instantiate failed: \{path}")
          println(msg)
        }
        @native_rt.NativeRuntimeError::ParseWasmFailed(path, msg) => {
          println("mgstudio run failed: Wasm parse failed: \{path}")
          println(msg)
        }
        @native_rt.NativeRuntimeError::ReadWasmFailed(path, msg) => {
          println("mgstudio run failed: Failed to read wasm: \{path}")
          println(msg)
        }
        _ => println("mgstudio run failed: \{err}")
      }
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
async fn run_native(opts : RunOptions) -> Unit {
  let game_cfg_path = resolve_game_config_path(opts.game)
  let cfg = load_game_config(game_cfg_path)
  println("Game config: \{cfg.file_path} (mgstudio=\{cfg.mgstudio})")
  let sdk = resolve_sdk_layout(cfg)
  let assets_source = cfg.assets_spec
  let data_source = cfg.data_spec_native
  if assets_source.has_prefix("http://") || assets_source.has_prefix("https://") {
    raise RunError::InvalidArgs(
      "Native runtime only supports dir assets source today (got: " +
      assets_source +
      ")",
    )
  }
  if !assets_source.has_prefix("dir:") {
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
  // Stage an overlay assets dir so the native runtime sees both game assets and
  // SDK-provided engine assets (e.g. built-in shaders).
  let stage_root = path_join(cfg.dir, ".mgstudio/run")
  if @fs.exists(stage_root) {
    if @fs.kind(stage_root, follow_symlink=true) != @fs.FileKind::Directory {
      raise RunError::InvalidArgs(
        "Expected a directory, but found a non-directory path at: " + stage_root,
      )
    }
  } else {
    @fs.mkdir(stage_root, permission=0o755, recursive=true)
  }
  let overlay_assets_dir = path_join(stage_root, "_mgstudio_assets")
  let game_assets_dir = strip_dir_prefix(assets_source)
  stage_assets_overlay(
    overlay_assets_dir,
    sdk.assets_dir,
    game_assets_dir,
    cfg.assets_allow_sdk_override,
  )
  let final_assets_source = "dir:" + overlay_assets_dir
  println("Using SDK libwgpu_native: \{sdk.native_wgpu_lib}")
  let wgpu_lib : String? = Some(sdk.native_wgpu_lib)
  @native_rt.run_game(
    cfg.cart_path,
    final_assets_source,
    data_source,
    wgpu_lib?,
  )
}
