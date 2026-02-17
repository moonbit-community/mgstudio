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
/// SDK layout helpers for mgstudio-cli.
///
/// The SDK root path is configured by `moon.game.json` (field: `sdkroot`).
/// The CLI uses it to locate:
/// - SDK assets (engine-default assets, including shaders)
/// - web runtime bundle (`mgstudio-runtime-web.js`)
/// - native `libwgpu_native` dynamic library

///|
struct SdkLayout {
  assets_dir : String
  web_runtime_js : String
  native_wgpu_lib : String
}

///|
fn sdk_assets_dir(sdk_root : String) -> String {
  path_join(sdk_root, "share/mgstudio/assets")
}

///|
fn sdk_web_runtime_js_path(sdk_root : String) -> String {
  path_join(sdk_root, "share/mgstudio/web/mgstudio-runtime-web.js")
}

///|
fn sdk_native_wgpu_lib_path(sdk_root : String) -> String {
  // Current platform target: darwin-arm64.
  path_join(sdk_root, "lib/libwgpu_native.dylib")
}

///|
async fn resolve_sdk_layout(cfg : GameConfig) -> SdkLayout raise Error {
  let assets_dir = sdk_assets_dir(cfg.sdk_root)
  let web_runtime_js = sdk_web_runtime_js_path(cfg.sdk_root)
  let native_wgpu_lib = sdk_native_wgpu_lib_path(cfg.sdk_root)
  if !@fs.exists(assets_dir) {
    raise RunError::MissingFile(assets_dir)
  }
  if !@fs.exists(web_runtime_js) {
    raise RunError::MissingFile(web_runtime_js)
  }
  // Native wgpu lib is required for native run.
  if !@fs.exists(native_wgpu_lib) {
    raise RunError::MissingFile(native_wgpu_lib)
  }
  { assets_dir, web_runtime_js, native_wgpu_lib }
}

///|
async fn ensure_empty_dir(path : String) -> Unit {
  if @fs.exists(path) {
    @fs.rmdir(path, recursive=true) catch {
      _ => @fs.remove(path) catch { _ => () }
    }
  }
  @fs.mkdir(path, permission=0o755, recursive=true)
}

///|
async fn remove_any(path : String) -> Unit {
  if !@fs.exists(path) {
    return
  }
  match @fs.kind(path, follow_symlink=false) {
    @fs.FileKind::Directory => @fs.rmdir(path, recursive=true)
    _ => @fs.remove(path)
  }
}

///|
async fn copy_file(src : String, dst : String) -> Unit {
  let dir = path_dirname(dst)
  if dir != "" && !@fs.exists(dir) {
    @fs.mkdir(dir, permission=0o755, recursive=true)
  }
  let data = @fs.read_file(src)
  @fs.write_file(dst, data, create=0o644, truncate=true)
}

///|
async fn copy_dir(src : String, dst : String) -> Unit {
  @fs.mkdir(dst, permission=0o755, recursive=true)
  let names = @fs.readdir(src, sort=true)
  for name in names {
    let src_path = path_join(src, name)
    let dst_path = path_join(dst, name)
    match @fs.kind(src_path, follow_symlink=false) {
      @fs.FileKind::Directory => copy_dir(src_path, dst_path)
      _ => copy_file(src_path, dst_path)
    }
  }
}

///|
async fn symlink_or_copy(src : String, dst : String) -> Unit {
  remove_any(dst) catch {
    _ => ()
  }
  @fs.symlink(dst, target=src) catch {
    _ =>
      match @fs.kind(src, follow_symlink=false) {
        @fs.FileKind::Directory => copy_dir(src, dst)
        _ => copy_file(src, dst)
      }
  }
}

///|
async fn stage_sdk_shaders_mgstudio(
  overlay_root : String,
  sdk_assets : String,
) -> Unit {
  let src = path_join(sdk_assets, "shaders/mgstudio")
  let dst = path_join(overlay_root, "shaders/mgstudio")
  if !@fs.exists(src) {
    raise RunError::MissingFile(src)
  }
  remove_any(dst) catch {
    _ => ()
  }
  copy_dir(src, dst)
}

///|
async fn stage_game_shaders(
  overlay_root : String,
  game_shaders_dir : String,
  allow_sdk_override : Bool,
) -> Unit {
  // Merge game `shaders/*` into overlay, while optionally protecting
  // `shaders/mgstudio/**`.
  let overlay_shaders = path_join(overlay_root, "shaders")
  @fs.mkdir(overlay_shaders, permission=0o755, recursive=true)
  let entries = @fs.readdir(game_shaders_dir, sort=true)
  for name in entries {
    if name == "mgstudio" && !allow_sdk_override {
      continue
    }
    let src = path_join(game_shaders_dir, name)
    let dst = path_join(overlay_shaders, name)
    // If override is enabled and the game provides `shaders/mgstudio`, replace
    // the SDK copy in the overlay.
    if name == "mgstudio" && allow_sdk_override {
      remove_any(dst) catch {
        _ => ()
      }
    }
    symlink_or_copy(src, dst)
  }
}

///|
async fn stage_game_assets(
  overlay_root : String,
  game_assets_dir : String,
  allow_sdk_override : Bool,
) -> Unit {
  let entries = @fs.readdir(game_assets_dir, sort=true)
  for name in entries {
    let src = path_join(game_assets_dir, name)
    if name == "shaders" &&
      @fs.kind(src, follow_symlink=false) is @fs.FileKind::Directory {
      stage_game_shaders(overlay_root, src, allow_sdk_override)
      continue
    }
    let dst = path_join(overlay_root, name)
    symlink_or_copy(src, dst)
  }
}

///|
/// Build the final assets directory used by runtimes (web/native).
///
/// Overlay rule:
/// - Default: SDK `shaders/mgstudio/**` always wins (no override).
/// - If `allow_sdk_override` is true, game assets may override SDK paths.
async fn stage_assets_overlay(
  overlay_root : String,
  sdk_assets : String,
  game_assets_dir : String,
  allow_sdk_override : Bool,
) -> Unit raise Error {
  ensure_empty_dir(overlay_root)
  if allow_sdk_override {
    // SDK first, then game overrides.
    stage_sdk_shaders_mgstudio(overlay_root, sdk_assets)
    stage_game_assets(overlay_root, game_assets_dir, allow_sdk_override)
  } else {
    // Game first, then force SDK defaults.
    stage_game_assets(overlay_root, game_assets_dir, allow_sdk_override)
    stage_sdk_shaders_mgstudio(overlay_root, sdk_assets)
  }
}
