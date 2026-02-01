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
struct GameConfig {
  /// Absolute path to the config file.
  file_path : String
  /// Absolute directory containing the config file.
  dir : String
  /// Config version string (e.g. "0.1.0").
  mgstudio : String
  /// Absolute path to the game wasm file.
  cart_path : String
  /// Assets source spec (e.g. "dir:/abs/path/assets" or "https://.../assets/").
  assets_spec : String
  /// Data source spec for native run (typically "dir:/abs/path/tmp/data").
  data_spec_native : String
  /// Data source spec for web serve (typically "idb:mgstudio").
  data_spec_web : String
  /// Web server bind address (for `mgstudio serve`).
  web_addr : String
  /// Web server port (for `mgstudio serve`).
  web_port : String
  /// URL to `mgstudio-runtime-web.js` (CDN / GitHub release).
  web_runtime_js : String
  /// Optional native-only override for libwgpu_native.
  native_wgpu_lib : String?
}

///|
const DEFAULT_WEB_RUNTIME_JS : String = "https://github.com/moonbit-community/mgstudio/releases/latest/download/mgstudio-runtime-web.js"

///|
async fn resolve_game_config_path(game_opt : String?) -> String raise Error {
  let cwd = @fs.realpath(".")
  match game_opt {
    Some(p) if p.trim() != "" => {
      let raw = p.trim().to_string()
      let candidate = if is_absolute_path(raw) {
        raw
      } else {
        path_join(cwd, raw)
      }
      if @fs.exists(candidate) {
        candidate
      } else if @fs.exists(path_join(candidate, "moon.game.json")) {
        path_join(candidate, "moon.game.json")
      } else {
        raise RunError::MissingFile(candidate)
      }
    }
    _ => {
      let mut dir = cwd
      while dir != "" {
        let candidate = path_join(dir, "moon.game.json")
        if @fs.exists(candidate) {
          return candidate
        }
        let parent = @path.Path(dir).dirname().to_string()
        if parent == dir {
          break
        }
        dir = parent
      }
      raise RunError::MissingFile("moon.game.json (searched from: " + cwd + ")")
    }
  }
}

///|
async fn load_game_config(file_path : String) -> GameConfig raise Error {
  fn expand_home_path(raw : String) -> String {
    let s = raw.trim().to_string()
    let home = @sys.get_env_var("HOME").unwrap_or("")
    if home == "" {
      return s
    }
    if s == "$HOME" {
      home
    } else if s.has_prefix("$HOME/") {
      let rest = (try! s[5:]).to_string()
      home + rest
    } else if s == "~" {
      home
    } else if s.has_prefix("~/") {
      let rest = (try! s[1:]).to_string()
      home + rest
    } else {
      s
    }
  }

  let abs_path = if is_absolute_path(file_path) {
    file_path
  } else {
    path_join(@fs.realpath("."), file_path)
  }
  let cfg_dir = path_dirname(abs_path)
  let src_opt = read_file_text(abs_path)
  guard src_opt is Some(src) else { raise RunError::MissingFile(abs_path) }
  let json = @json5.parse(src) catch {
    err =>
      raise RunError::InvalidArgs(
        "Failed to parse game config: " +
        abs_path +
        " (" +
        err.to_string() +
        ")",
      )
  }
  let root = expect_object(json, "root", abs_path)
  let mgstudio = get_required_string(root, "mgstudio", abs_path)
  let cart_raw = get_required_string(root, "cart", abs_path)
  let cart_path = resolve_path_relative(cfg_dir, cart_raw, abs_path)
  if !@fs.exists(cart_path) {
    raise RunError::MissingFile(cart_path)
  }

  // assets/data are optional; defaults are chosen to keep the config small.
  let assets_raw : String? = get_optional_string(root, "assets", abs_path)
  let data_raw : String? = get_optional_string(root, "data", abs_path)
  let assets_spec = match assets_raw {
    Some(raw) if raw.trim() != "" =>
      normalize_assets_spec(raw, cfg_dir, abs_path)
    _ => {
      let candidate = path_join(cfg_dir, "assets")
      if @fs.exists(candidate) {
        "dir:" + candidate
      } else {
        "dir:" + cfg_dir
      }
    }
  }
  let data_spec_native = match data_raw {
    Some(raw) if raw.trim() != "" =>
      normalize_data_spec_native(raw, cfg_dir, abs_path)
    _ => "dir:" + path_join(cfg_dir, "tmp/data")
  }
  let web_obj : Map[String, Json]? = get_optional_object(root, "web", abs_path)
  let web_addr = match web_obj {
    Some(web) =>
      get_optional_string(web, "addr", abs_path).unwrap_or("127.0.0.1")
    None => "127.0.0.1"
  }
  let web_port = match web_obj {
    Some(web) =>
      get_optional_number_as_port(web, "port", abs_path).unwrap_or("8099")
    None => "8099"
  }
  let web_runtime_js = match web_obj {
    Some(web) =>
      get_optional_string(web, "runtime_js", abs_path).unwrap_or(
        DEFAULT_WEB_RUNTIME_JS,
      )
    None => DEFAULT_WEB_RUNTIME_JS
  }

  // Web data source: prefer web.data; otherwise fall back to top-level data if
  // it is already an idb spec; else default to idb:mgstudio.
  let web_data_raw : String? = match web_obj {
    Some(web) => get_optional_string(web, "data", abs_path)
    None => None
  }
  let data_spec_web = normalize_source_spec_idb(
    web_data_raw, data_raw, "idb:mgstudio",
  )
  let native_obj : Map[String, Json]? = get_optional_object(
    root, "native", abs_path,
  )
  // Prefer native.wgpu_lib; fall back to legacy top-level wgpu_lib if present.
  let native_wgpu_lib_raw = match native_obj {
    Some(native) => get_optional_string(native, "wgpu_lib", abs_path)
    None => get_optional_string(root, "wgpu_lib", abs_path)
  }
  let native_wgpu_lib = match native_wgpu_lib_raw {
    Some(v) if v.trim() != "" => Some(expand_home_path(v))
    Some(_) => None
    None => None
  }
  {
    file_path: abs_path,
    dir: cfg_dir,
    mgstudio,
    cart_path,
    assets_spec,
    data_spec_native,
    data_spec_web,
    web_addr,
    web_port,
    web_runtime_js,
    native_wgpu_lib,
  }
}

///|
fn expect_object(
  value : Json,
  ctx : String,
  path : String,
) -> Map[String, Json] raise Error {
  match value {
    Json::Object(map) => map
    _ => raise RunError::InvalidArgs(path + ": expected object at " + ctx)
  }
}

///|
fn get_required_string(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> String raise Error {
  guard obj.get(key) is Some(v) else {
    raise RunError::InvalidArgs(path + ": missing field: " + key)
  }
  match v {
    Json::String(s) => s
    _ =>
      raise RunError::InvalidArgs(path + ": field " + key + " must be string")
  }
}

///|
fn get_optional_string(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> String? raise Error {
  match obj.get(key) {
    None => None
    Some(v) =>
      match v {
        Json::String(s) => Some(s)
        _ =>
          raise RunError::InvalidArgs(
            path + ": field " + key + " must be string",
          )
      }
  }
}

///|
fn get_optional_object(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> Map[String, Json]? raise Error {
  match obj.get(key) {
    None => None
    Some(v) =>
      match v {
        Json::Object(map) => Some(map)
        _ =>
          raise RunError::InvalidArgs(
            path + ": field " + key + " must be object",
          )
      }
  }
}

///|
fn get_optional_number_as_port(
  obj : Map[String, Json],
  key : String,
  path : String,
) -> String? raise Error {
  match obj.get(key) {
    None => None
    Some(v) =>
      match v {
        Json::Number(n, ..) => Some(n.to_int().to_string())
        Json::String(s) => Some(s)
        _ =>
          raise RunError::InvalidArgs(
            path + ": field " + key + " must be number or string",
          )
      }
  }
}

///|
fn resolve_path_relative(
  base_dir : String,
  raw : String,
  path : String,
) -> String raise Error {
  if raw.trim() == "" {
    raise RunError::InvalidArgs(path + ": empty path")
  }
  let v = raw.trim().to_string()
  if is_absolute_path(v) {
    v
  } else {
    path_join(base_dir, v)
  }
}

///|
fn normalize_assets_spec(
  raw : String,
  base_dir : String,
  path : String,
) -> String raise Error {
  let v = raw.trim().to_string()
  if v.has_prefix("dir:") {
    "dir:" + resolve_path_relative(base_dir, strip_dir_prefix(v), path)
  } else if v.has_prefix("http://") || v.has_prefix("https://") {
    v
  } else if v.has_prefix("idb:") {
    raise RunError::InvalidArgs(path + ": assets must not be an idb spec")
  } else {
    "dir:" + resolve_path_relative(base_dir, v, path)
  }
}

///|
fn normalize_data_spec_native(
  raw : String,
  base_dir : String,
  path : String,
) -> String raise Error {
  let v = raw.trim().to_string()
  if v.has_prefix("dir:") {
    "dir:" + resolve_path_relative(base_dir, strip_dir_prefix(v), path)
  } else if v.has_prefix("http://") ||
    v.has_prefix("https://") ||
    v.has_prefix("idb:") {
    v
  } else {
    "dir:" + resolve_path_relative(base_dir, v, path)
  }
}

///|
fn normalize_source_spec_idb(
  web_data_raw : String?,
  top_data_raw : String?,
  default_spec : String,
) -> String {
  let pick = match web_data_raw {
    Some(s) if s.trim() != "" => Some(s.trim().to_string())
    _ =>
      match top_data_raw {
        Some(s) => {
          let v = s.trim().to_string()
          if v.has_prefix("idb:") {
            Some(v)
          } else {
            None
          }
        }
        _ => None
      }
  }
  match pick {
    Some(v) => if v.has_prefix("idb:") { v } else { "idb:" + v }
    None => default_spec
  }
}
