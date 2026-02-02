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
  new_game_project(name) catch {
    err => {
      println("mgstudio new failed: \{err}")
      @sys.exit(1)
    }
  }
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
    "  let sprite = @render2d.Sprite::from_image(texture)\n" +
    "  let transform = @math.Transform::identity()\n" +
    "  @render2d.SpriteBundle::new(sprite, transform).spawn(world) |> ignore\n" +
    "  let camera = @render2d.Camera::default()\n" +
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
    "    let next_rotation_z = transform.rotation_z() + speed * delta_secs\n" +
    "    let next_transform = @math.Transform::from_xy_rotation_scale(\n" +
    "      @math.Vec2::new(transform.translation.x, transform.translation.y),\n" +
    "      next_rotation_z,\n" +
    "      @math.Vec2::new(transform.scale.x, transform.scale.y),\n" +
    "      z=transform.translation.z,\n" +
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
  // sdkroot is required. Default to a conventional user install location.
  //
  // We intentionally construct a structured Json object (instead of
  // concatenating a raw JSON string) to avoid quoting/escaping bugs.
  let game_cfg_json : Json = Json::object(
    Map::from_array([
      ("mgstudio", Json::string("0.1.0")),
      ("sdkroot", Json::string("$HOME/.local/share/mgstudio/current")),
      ("cart", Json::string(cart)),
      (
        "web",
        Json::object(
          Map::from_array([
            ("addr", Json::string("127.0.0.1")),
            ("port", Json::number(8099.0, repr="8099")),
          ]),
        ),
      ),
      ("assets_allow_sdk_override", Json::boolean(false)),
    ]),
  )
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
