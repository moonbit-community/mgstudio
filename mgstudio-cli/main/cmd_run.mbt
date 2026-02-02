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
  backend : String?
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
  { game: None, backend: None }
}

///|
fn parse_run_options(
  cmd : @clap.SimpleValue,
) -> RunOptions raise @clap.ParserError {
  let game : String? = cmd.get_option("game")
  let backend : String? = cmd.get_option("backend")
  { game, backend, }
}

///|
async fn run_native(opts : RunOptions) -> Unit {
  let game_cfg_path = resolve_game_config_path(opts.game)
  let cfg = load_game_config(game_cfg_path)
  println("Game config: \{cfg.file_path} (mgstudio=\{cfg.mgstudio})")
  let sdk = resolve_sdk_layout(cfg)
  let backend = opts.backend.unwrap_or("wasmoon").trim().to_string()
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
  @fs.mkdir(stage_root, permission=0o755, recursive=true)
  let overlay_assets_dir = path_join(stage_root, "_mgstudio_assets")
  let game_assets_dir = strip_dir_prefix(assets_source)
  stage_assets_overlay(
    overlay_assets_dir,
    sdk.assets_dir,
    game_assets_dir,
    cfg.assets_allow_sdk_override,
  )
  let final_assets_source = "dir:" + overlay_assets_dir
  if backend == "" || backend == "wasmoon" {
    println("Using SDK libwgpu_native: \{sdk.native_wgpu_lib}")
    let wgpu_lib : String? = Some(sdk.native_wgpu_lib)
    @native_rt.run_game(
      cfg.cart_path,
      final_assets_source,
      data_source,
      wgpu_lib?,
    )
  } else if backend == "wasmtime" {
    run_native_wasmtime(cfg.cart_path, final_assets_source, data_source)
  } else {
    raise RunError::InvalidArgs(
      "Unknown --backend: " + backend + " (expected: wasmoon|wasmtime)",
    )
  }
}

///|
async fn run_native_wasmtime(
  cart_path : String,
  assets_source : String,
  data_source : String,
) -> Unit {
  // Option 1: user-provided binary path.
  match @sys.get_env_var("MGSTUDIO_WASMTIME_RUNTIME") {
    Some(bin) if bin.trim() != "" => {
      run_process_checked(
        bin.trim().to_string(),
        ["--cart", cart_path, "--assets", assets_source, "--data", data_source],
      )
      return
    }
    _ => ()
  }

  // Option 2: auto-discover within this repo by searching upward for the
  // Cargo project folder and building it if needed.
  let cwd = @fs.realpath(".")
  let mut dir = cwd
  let marker = "mgstudio-runtime/native-wasmtime/Cargo.toml"
  let mut crate_dir : String? = None
  while dir != "" {
    let candidate = path_join(dir, marker)
    if @fs.exists(candidate) {
      crate_dir = Some(path_join(dir, "mgstudio-runtime/native-wasmtime"))
      break
    }
    let parent = @path.Path(dir).dirname().to_string()
    if parent == dir {
      break
    }
    dir = parent
  }
  guard crate_dir is Some(cd) else {
    raise RunError::InvalidArgs(
      "Cannot locate native-wasmtime runtime. Set MGSTUDIO_WASMTIME_RUNTIME to the binary path, or run inside the mgstudio-dev repo.",
    )
  }

  // Build (release) and run.
  let cargo_target : String? = @sys.get_env_var("MGSTUDIO_WASMTIME_CARGO_TARGET")
  if cargo_target is Some(t) && t.trim() != "" {
    let triple = t.trim().to_string()
    run_process_checked(
      "cargo",
      ["build", "--release", "--target", triple],
      cwd=cd,
    )
  } else {
    run_process_checked("cargo", ["build", "--release"], cwd=cd)
  }
  let bin = match cargo_target {
    Some(t) if t.trim() != "" =>
      path_join(
        cd,
        "target/" + t.trim().to_string() + "/release/mgstudio-runtime-native-wasmtime",
      )
    _ => path_join(cd, "target/release/mgstudio-runtime-native-wasmtime")
  }
  run_process_checked(
    bin,
    ["--cart", cart_path, "--assets", assets_source, "--data", data_source],
  )
}
