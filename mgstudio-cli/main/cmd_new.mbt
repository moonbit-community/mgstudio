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
async fn cmd_new(cmd : @clap.SimpleValue) -> Unit {
  let name_args : Array[String] = cmd.get_positional()
  guard name_args.get(0) is Some(name) else {
    println("Missing required positional argument: name")
    @sys.exit(2)
    return
  }
  let use_local_engine = cmd.get_flag("local-engine").unwrap_or(false)
  new_game_project(name, use_local_engine) catch {
    err => {
      println("mgstudio new failed: \{err}")
      @sys.exit(1)
    }
  }
}

///|
async fn new_game_project(name : String, use_local_engine : Bool) -> Unit {
  let project_name = name.trim().to_string()
  if project_name == "" {
    raise RunError::InvalidArgs("project name is empty")
  }
  let cwd = @fs.realpath(".")
  if use_local_engine &&
    !@fs.exists(path_join(cwd, "mgstudio-engine/moon.mod.json")) {
    raise RunError::InvalidArgs(
      "--local-engine requires mgstudio-engine/ next to the new project (run from the mgstudio repo root).",
    )
  }
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
  @fs.mkdir(path_join(project_dir, "assets"), permission=0o755, recursive=true)
  @fs.mkdir(
    path_join(project_dir, "tmp/data"),
    permission=0o755,
    recursive=true,
  )

  // Update moon.mod.json to depend on mgstudio and prefer wasm-gc.
  let mod_json_path = path_join(project_dir, "moon.mod.json")
  let mod_src_opt = read_file_text(mod_json_path)
  let module_name = match mod_src_opt {
    Some(src) => parse_module_name(src).unwrap_or("username/" + project_name)
    None => "username/" + project_name
  }
  let deps_entry = if use_local_engine {
    // For local development: point to the repo working tree.
    "\"deps\": { \"Milky2018/mgstudio\": { \"path\": \"../mgstudio-engine\" } },\n"
  } else {
    "\"deps\": { \"Milky2018/mgstudio\": \"" +
    latest_mgstudio_version() +
    "\" },\n"
  }
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
    "    \"Milky2018/mgstudio/ecs_world\",\n" +
    "    \"Milky2018/mgstudio\"\n" +
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

  // Replace the root demo with a minimal mgstudio app.
  write_file_text(
    path_join(project_dir, project_name + ".mbt"),
    render_rotation_demo(),
  )
  @fs.remove(path_join(project_dir, project_name + "_test.mbt")) catch {
    _ => ()
  }

  // Game config: minimal; assets/data default to ./assets and ./tmp/data.
  let cart = "./_build/wasm-gc/release/build/" + project_name + ".wasm"
  // sdkroot is required. Default to a conventional user install location.
  //
  // We intentionally construct a structured Json object (instead of
  // concatenating a raw JSON string) to avoid quoting/escaping bugs.
  //
  // We prefer the built-in Json literal syntax here for readability.
  let game_cfg_json : Json = {
    "mgstudio": "0.1.0",
    "sdkroot": "$HOME/.local/share/mgstudio/current",
    // `cart` is not a literal, so it must be wrapped into Json explicitly.
    "cart": Json::string(cart),
    "web": { "addr": "127.0.0.1", "port": 8099 },
    "assets_allow_sdk_override": false,
  }
  // `moonbitlang/core/json` provides `Json.stringify(...)` as a method (there is
  // no `@json.stringify` function exported in the current toolchain).
  let game_json = game_cfg_json.stringify(indent=2) + "\n"
  write_file_text(path_join(project_dir, "moon.game.json"), game_json)

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

///|
const DEFAULT_MGSTUDIO_VERSION : String = "0.1.0"

///|
fn latest_mgstudio_version() -> String {
  // Keep `mgstudio new` deterministic by default. Update this constant when we
  // bump `Milky2018/mgstudio` on the registry.
  DEFAULT_MGSTUDIO_VERSION
}

///|
fn render_rotation_demo() -> String {
  // Keep the generated project minimal and API-stable: a runnable app with
  // default plugins.
  //
  // To see rendering and asset loading examples, check:
  // `mgstudio-engine/examples/*`.
  "///|\n" +
  "pub fn game_app() -> Unit {\n" +
  "  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()\n" +
  "  @app.App::new(@ecs_world.World::new()).add_plugins(plugins).run()\n" +
  "}\n"
}
