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
struct RunOptions {
  game : String?
}

///|
async fn cmd_run(cmd : @clap.SimpleValue) -> Unit {
  let opts : RunOptions = parse_run_options(cmd) catch {
    err => {
      println(err)
      @sys.exit(2)
      parse_run_options_defaults()
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
fn parse_run_options_defaults() -> RunOptions {
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
      "Native mode only supports dir assets source today (got: " +
      assets_source +
      ")",
    )
  }
  if !assets_source.has_prefix("dir:") {
    raise RunError::InvalidArgs(
      "Native mode only supports dir assets source today (got: " +
      assets_source +
      ")",
    )
  }
  if data_source.has_prefix("idb:") ||
    data_source.has_prefix("http://") ||
    data_source.has_prefix("https://") {
    raise RunError::InvalidArgs(
      "Native mode only supports dir data source today (got: " +
      data_source +
      ")",
    )
  }
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

  let (launcher_root, launcher_pkg) = prepare_launcher(cfg, Native)
  run_process_checked("moon", [
    "-C", launcher_root, "build", "--release", "--target", "native", launcher_pkg,
  ])
  println("Using SDK libwgpu_native: \{sdk.native_wgpu_lib}")
  let lib_dir = path_dirname(sdk.native_wgpu_lib)
  let prev_dyld = @sys.get_env_var("DYLD_LIBRARY_PATH").unwrap_or("")
  let prev_ld = @sys.get_env_var("LD_LIBRARY_PATH").unwrap_or("")
  let dyld = if prev_dyld == "" { lib_dir } else { lib_dir + ":" + prev_dyld }
  let ld = if prev_ld == "" { lib_dir } else { lib_dir + ":" + prev_ld }
  let env : Map[String, String] = {
    "MGSTUDIO_ASSETS_SOURCE": final_assets_source,
    "MGSTUDIO_DATA_SOURCE": data_source,
    "DYLD_LIBRARY_PATH": dyld,
    "LD_LIBRARY_PATH": ld,
  }
  run_process_checked(
    "moon",
    [
      "-C", launcher_root, "run", "--release", "--target", "native", launcher_pkg,
    ],
    extra_env=env,
  )
}
