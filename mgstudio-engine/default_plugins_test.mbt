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
const DEFAULT_PLUGIN_NAME_RENDER3D : String = "mgstudio.pbr.PbrPlugin"

///|
const DEFAULT_PLUGIN_NAME_ANTI_ALIAS : String = "mgstudio.anti_alias.AntiAliasPlugin"

///|
const DEFAULT_PLUGIN_NAME_SHADER : String = "mgstudio.shader.ShaderPlugin"

///|
const DEFAULT_PLUGIN_NAME_WEB_ASSET : String = "mgstudio.asset.WebAssetPlugin"

///|
const DEFAULT_PLUGIN_NAME_SPRITE : String = "mgstudio.sprite.SpritePlugin"

///|
const DEFAULT_PLUGIN_NAME_SPRITE_RENDER : String = "mgstudio.sprite_render.SpriteRenderPlugin"

///|
fn plugin_index(
  builder : @app.PluginGroupBuilder[@ecs.World],
  plugin_id : String,
) -> Int {
  let mut index = -1
  for i, entry in builder.plugins {
    if index == -1 && entry.id == plugin_id {
      index = i
    }
  }
  index
}

///|
fn plugin_contains(
  builder : @app.PluginGroupBuilder[@ecs.World],
  plugin_id : String,
) -> Bool {
  plugin_index(builder, plugin_id) >= 0
}

///|
fn plugin_enabled(
  builder : @app.PluginGroupBuilder[@ecs.World],
  plugin_id : String,
) -> Bool {
  for entry in builder.plugins {
    if entry.id == plugin_id {
      return entry.enabled
    }
  }
  false
}

///|
test "default plugins: include winit plugin after window plugin" {
  let builder = @internal.DefaultPlugins::build()
  debug_inspect(
    plugin_contains(builder, "mgstudio.window.WindowPlugin"),
    content="true",
  )
  debug_inspect(
    plugin_contains(builder, "mgstudio.winit.WinitPlugin"),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, "mgstudio.winit.WinitPlugin"),
    content="true",
  )
  debug_inspect(
    plugin_contains(builder, DEFAULT_PLUGIN_NAME_SHADER),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, DEFAULT_PLUGIN_NAME_SHADER),
    content="true",
  )
  debug_inspect(
    plugin_contains(builder, DEFAULT_PLUGIN_NAME_WEB_ASSET),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, DEFAULT_PLUGIN_NAME_WEB_ASSET),
    content="true",
  )
  debug_inspect(
    plugin_contains(builder, DEFAULT_PLUGIN_NAME_ANTI_ALIAS),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, DEFAULT_PLUGIN_NAME_ANTI_ALIAS),
    content="true",
  )
  debug_inspect(
    plugin_contains(builder, DEFAULT_PLUGIN_NAME_SPRITE),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, DEFAULT_PLUGIN_NAME_SPRITE),
    content="true",
  )
  debug_inspect(
    plugin_contains(builder, DEFAULT_PLUGIN_NAME_SPRITE_RENDER),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, DEFAULT_PLUGIN_NAME_SPRITE_RENDER),
    content="true",
  )
  let shader_index = plugin_index(builder, DEFAULT_PLUGIN_NAME_SHADER)
  let web_asset_index = plugin_index(builder, DEFAULT_PLUGIN_NAME_WEB_ASSET)
  let render3d_index = plugin_index(builder, DEFAULT_PLUGIN_NAME_RENDER3D)
  let anti_alias_index = plugin_index(builder, DEFAULT_PLUGIN_NAME_ANTI_ALIAS)
  let sprite_index = plugin_index(builder, DEFAULT_PLUGIN_NAME_SPRITE)
  let sprite_render_index = plugin_index(
    builder,
    DEFAULT_PLUGIN_NAME_SPRITE_RENDER,
  )
  debug_inspect(
    web_asset_index < plugin_index(builder, "mgstudio.asset.AssetPlugin"),
    content="true",
  )
  debug_inspect(shader_index < render3d_index, content="true")
  debug_inspect(render3d_index < anti_alias_index, content="true")
  debug_inspect(anti_alias_index < sprite_index, content="true")
  debug_inspect(sprite_index < sprite_render_index, content="true")
  debug_inspect(
    plugin_contains(builder, "mgstudio.gltf.GltfPlugin"),
    content="true",
  )
  debug_inspect(
    plugin_enabled(builder, "mgstudio.gltf.GltfPlugin"),
    content="true",
  )
}

///|
test "default plugins: set(WindowPlugin) replaces default window plugin config" {
  let configured_window = @window.Window::default()
  configured_window.title = "Scale Override"
  configured_window.resolution = @window.WindowResolution::new(500, 300).with_scale_factor_override(
    1.0F,
  )

  let app = @app.App::new(@ecs.World::new()).add_plugin_group(fn() {
    DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window),
      primary_cursor_options: Some(@window.CursorOptions::default()),
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    })
  })

  let primary_window_entity = Ref::new(None)
  try! app
  .world()
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(_query_entity, entity) {
    if primary_window_entity.val is None {
      primary_window_entity.val = Some(entity)
    }
  })

  let entity = match primary_window_entity.val {
    Some(entity) => entity
    None => abort("missing primary window entity")
  }
  let stored_window : @window.Window = match
    (try! app.world().entity(entity).get() : @window.Window?) {
    Some(window) => window
    None => abort("missing window component")
  }

  debug_inspect(stored_window.title, content="\"Scale Override\"")
  debug_inspect(stored_window.physical_width(), content="500")
  debug_inspect(stored_window.physical_height(), content="300")
  debug_inspect(
    stored_window.resolution.scale_factor_override(),
    content="Some(1)",
  )
}

///|
test "default plugins: set(AssetPlugin::default_nearest()) replaces default asset plugin config" {
  let app = @app.App::new(@ecs.World::new()).add_plugin_group(fn() {
    DefaultPlugins::set(@asset.AssetPlugin::default_nearest())
  })

  let asset_server : @asset.AssetServer = match
    (try! app.world().get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None => abort("missing asset server resource")
  }

  debug_inspect(asset_server.default_sampler_nearest.val, content="true")
}

///|
test "default plugins: set(AssetPlugin::with_file_path(...)) changes asset root" {
  let app = @app.App::new(@ecs.World::new()).add_plugin_group(fn() {
    DefaultPlugins::set(
      @asset.AssetPlugin::default().with_file_path("examples/asset/files"),
    )
  })

  let asset_server : @asset.AssetServer = match
    (try! app.world().get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None => abort("missing asset server resource")
  }
  let handle = asset_server.load_image("bevy_pixel_dark.png")
  for _ in 0..<120 {
    @asset.asset_system(app.world())
    if @asset.asset_is_texture_loaded(handle) {
      break
    }
  }

  debug_inspect(@asset.asset_is_texture_loaded(handle), content="true")
  debug_inspect(@asset.asset_texture_width(handle), content="16")
  debug_inspect(@asset.asset_texture_height(handle), content="12")
}

///|
test "default plugins: register_asset_source adds a named Bevy-style extra source" {
  let app = @asset.register_asset_source(
    @app.App::new(@ecs.World::new()),
    @asset.AssetSourceId::Named("example_files"),
    @asset.AssetSourceBuilder::platform_default("examples/asset/files", None),
  ).add_plugin_group(fn() { DefaultPlugins::build() })

  let asset_server : @asset.AssetServer = match
    (try! app.world().get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None => abort("missing asset server resource")
  }
  let handle : @asset.Handle[@asset.Image] = asset_server.load(
    @asset.AssetPath::from_path("bevy_pixel_light.png").with_source(
      @asset.AssetSourceId::from("example_files"),
    ),
  )
  for _ in 0..<120 {
    @asset.asset_system(app.world())
    if @asset.asset_is_texture_loaded(handle) {
      break
    }
  }

  debug_inspect(@asset.asset_is_texture_loaded(handle), content="true")
  debug_inspect(@asset.asset_texture_width(handle), content="128")
  debug_inspect(@asset.asset_texture_height(handle), content="96")
}

///|
test "default plugins: register_asset_source can wrap source reader callbacks" {
  let reads : Ref[Array[String]] = Ref::new([])
  let metas : Ref[Array[String]] = Ref::new([])
  let directories : Ref[Array[String]] = Ref::new([])
  let dir_checks : Ref[Array[String]] = Ref::new([])

  let app = @asset.register_asset_source(
    @app.App::new(@ecs.World::new()),
    @asset.AssetSourceId::Named("example_files"),
    @asset.AssetSourceBuilder::platform_default("examples/asset/files", None).with_reader(fn(
        base_reader,
      ) {
        @asset.AssetReader::new(
          fn(path) {
            reads.val.push(path)
            base_reader.read(path)
          },
          fn(path) {
            metas.val.push(path)
            base_reader.read_meta(path)
          },
          fn(path) {
            directories.val.push(path)
            base_reader.read_directory(path)
          },
          fn(path) {
            dir_checks.val.push(path)
            base_reader.is_directory(path)
          },
        )
      },
    ),
  ).add_plugin_group(fn() { DefaultPlugins::build() })

  let asset_server : @asset.AssetServer = match
    (try! app.world().get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None => abort("missing asset server resource")
  }
  let image_handle : @asset.Handle[@asset.Image] = asset_server.load(
    @asset.AssetPath::from_path("bevy_pixel_dark_with_meta.png").with_source(
      @asset.AssetSourceId::Named("example_files"),
    ),
  )
  let folder_handle = asset_server.load_folder("example_files://")
  for _ in 0..<120 {
    @asset.asset_system(app.world())
    if @asset.asset_is_texture_loaded(image_handle) {
      break
    }
  }

  debug_inspect(@asset.asset_is_texture_loaded(image_handle), content="true")
  debug_inspect(
    reads.val.contains("bevy_pixel_dark_with_meta.png"),
    content="true",
  )
  debug_inspect(
    metas.val.contains("bevy_pixel_dark_with_meta.png"),
    content="true",
  )
  debug_inspect(directories.val.contains(""), content="true")
  debug_inspect(dir_checks.val.contains(""), content="true")
  debug_inspect(
    match
      (try! app.world().get_resource(@asset.loaded_folder_assets_resource_key())) {
      Some(loaded_folders) =>
        match loaded_folders.get(folder_handle) {
          Some(folder) => folder.handles.length() >= 1
          None => false
        }
      None => false
    },
    content="true",
  )
}

///|
test "default plugins: register_asset_source can wrap the default source reader" {
  let reads : Ref[Array[String]] = Ref::new([])

  let app = @asset.register_asset_source(
    @app.App::new(@ecs.World::new()),
    @asset.AssetSourceId::Default,
    @asset.AssetSourceBuilder::platform_default("", None).with_reader(fn(
      base_reader,
    ) {
      @asset.AssetReader::new(
        fn(path) {
          reads.val.push(path)
          base_reader.read(path)
        },
        fn(path) { base_reader.read_meta(path) },
        fn(path) { base_reader.read_directory(path) },
        fn(path) { base_reader.is_directory(path) },
      )
    }),
  ).add_plugin_group(fn() { DefaultPlugins::build() })

  let asset_server : @asset.AssetServer = match
    (try! app.world().get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None => abort("missing asset server resource")
  }
  let handle : @asset.Handle[@asset.Image] = asset_server.load(
    "branding/icon.png",
  )
  for _ in 0..<120 {
    @asset.asset_system(app.world())
    if @asset.asset_is_texture_loaded(handle) {
      break
    }
  }

  debug_inspect(@asset.asset_is_texture_loaded(handle), content="true")
  debug_inspect(reads.val.contains("branding/icon.png"), content="true")
}
