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
enum LauncherBackend {
  Native
  Web
}

///|
fn json_string_escape(value : String) -> String {
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
async fn entry_import_path(cfg : GameConfig) -> String raise Error {
  let mod_path = path_join(cfg.module_root, "moon.mod.json")
  let mod_src_opt = read_file_text(mod_path)
  guard mod_src_opt is Some(mod_src) else {
    raise RunError::MissingFile(mod_path)
  }
  let mod_name_opt = parse_module_name(mod_src)
  guard mod_name_opt is Some(mod_name) else {
    raise RunError::InvalidArgs(
      "Cannot parse module name from moon.mod.json: " + mod_path,
    )
  }
  if cfg.entry == "." {
    mod_name
  } else {
    mod_name + "/" + cfg.entry
  }
}

///|
async fn resolve_platform_module_root(
  module_root : String,
  env_name : String,
  sibling_dir_name : String,
) -> String raise Error {
  if @sys.get_env_var(env_name) is Some(path) {
    let abs = @fs.realpath(path)
    if !@fs.exists(path_join(abs, "moon.mod.json")) {
      raise RunError::InvalidArgs(
        env_name + " points to a directory without moon.mod.json: " + abs,
      )
    }
    return abs
  }
  let candidate = @fs.realpath(
    path_join(path_dirname(module_root), sibling_dir_name),
  )
  if @fs.exists(path_join(candidate, "moon.mod.json")) {
    return candidate
  }
  raise RunError::InvalidArgs(
    "Cannot locate " +
    sibling_dir_name +
    ". Set " +
    env_name +
    " to an absolute module path.",
  )
}

///|
fn render_launcher_mod_json(
  main_module_name : String,
  main_module_root : String,
  native_module_root : String,
  web_module_root : String,
) -> String {
  "{\n" +
  "  \"name\": \"mgstudio/internal-launcher\",\n" +
  "  \"version\": \"0.1.0\",\n" +
  "  \"deps\": {\n" +
  "    \"" +
  json_string_escape(main_module_name) +
  "\": { \"path\": \"" +
  json_string_escape(main_module_root) +
  "\" },\n" +
  "    \"Milky2018/mgstudio-platform-native\": { \"path\": \"" +
  json_string_escape(native_module_root) +
  "\" },\n" +
  "    \"Milky2018/mgstudio-platform-web\": { \"path\": \"" +
  json_string_escape(web_module_root) +
  "\" }\n" +
  "  },\n" +
  "  \"readme\": \"README.mbt.md\",\n" +
  "  \"license\": \"Apache-2.0\",\n" +
  "  \"keywords\": [],\n" +
  "  \"description\": \"\",\n" +
  "  \"preferred-target\": \"native\"\n" +
  "}\n"
}

///|
fn render_native_launcher_pkg(entry_import : String) -> String {
  "import {\n" +
  "  \"" +
  entry_import +
  "\" @game,\n" +
  "  \"Milky2018/mgstudio/platform\" @platform,\n" +
  "}\n\n" +
  "options(\n" +
  "  \"is-main\": true,\n" +
  "  overrides: [ \"Milky2018/mgstudio-platform-native/platform_native\" ],\n" +
  ")\n"
}

///|
fn render_web_launcher_pkg(entry_import : String) -> String {
  "import {\n" +
  "  \"" +
  entry_import +
  "\" @game,\n" +
  "  \"Milky2018/mgstudio/platform\" @platform,\n" +
  "}\n\n" +
  "options(\n" +
  "  \"is-main\": true,\n" +
  "  overrides: [ \"Milky2018/mgstudio-platform-web/platform_web\" ],\n" +
  ")\n"
}

///|
fn render_native_launcher_main() -> String {
  "fn main {\n" +
  "  @platform.run_after_ready(fn() {\n" +
  "    @game.app_main()\n" +
  "  })\n" +
  "}\n"
}

///|
fn render_web_launcher_main() -> String {
  "fn main {\n" +
  "  @platform.run_after_ready(fn() {\n" +
  "    @game.app_main()\n" +
  "  })\n" +
  "}\n"
}

///|
async fn module_name_or_raise(module_root : String) -> String raise Error {
  let mod_path = path_join(module_root, "moon.mod.json")
  let mod_src_opt = read_file_text(mod_path)
  guard mod_src_opt is Some(mod_src) else {
    raise RunError::MissingFile(mod_path)
  }
  let mod_name_opt = parse_module_name(mod_src)
  guard mod_name_opt is Some(mod_name) else {
    raise RunError::InvalidArgs(
      "Cannot parse module name from moon.mod.json: " + mod_path,
    )
  }
  mod_name
}

///|
async fn prepare_launcher(
  cfg : GameConfig,
  backend : LauncherBackend,
) -> (String, String) raise Error {
  let entry_import = entry_import_path(cfg)
  let stage_root = path_join(cfg.dir, ".mgstudio/launcher")
  let launcher_root = path_join(
    stage_root,
    match backend {
      Native => "native"
      Web => "web"
    },
  )
  if @fs.exists(launcher_root) {
    @fs.rmdir(launcher_root, recursive=true) catch {
      _ => @fs.remove(launcher_root) catch { _ => () }
    }
  }
  @fs.mkdir(launcher_root, permission=0o755, recursive=true)
  let main_module_name = module_name_or_raise(cfg.module_root)
  let native_module_root = resolve_platform_module_root(
    cfg.module_root,
    "MGSTUDIO_PLATFORM_NATIVE_MODULE",
    "mgstudio-platform-native",
  )
  let web_module_root = resolve_platform_module_root(
    cfg.module_root,
    "MGSTUDIO_PLATFORM_WEB_MODULE",
    "mgstudio-platform-web",
  )
  write_file_text(
    path_join(launcher_root, "moon.mod.json"),
    render_launcher_mod_json(
      main_module_name,
      cfg.module_root,
      native_module_root,
      web_module_root,
    ),
  )
  write_file_text(
    path_join(launcher_root, "README.mbt.md"),
    "# mgstudio internal launcher\n",
  )
  let launcher_pkg_dir = path_join(launcher_root, "launcher")
  @fs.mkdir(launcher_pkg_dir, permission=0o755, recursive=true)
  match backend {
    Native => {
      write_file_text(
        path_join(launcher_pkg_dir, "moon.pkg"),
        render_native_launcher_pkg(entry_import),
      )
      write_file_text(
        path_join(launcher_pkg_dir, "main.mbt"),
        render_native_launcher_main(),
      )
    }
    Web => {
      write_file_text(
        path_join(launcher_pkg_dir, "moon.pkg"),
        render_web_launcher_pkg(entry_import),
      )
      write_file_text(
        path_join(launcher_pkg_dir, "main.mbt"),
        render_web_launcher_main(),
      )
    }
  }
  (launcher_root, "launcher")
}
