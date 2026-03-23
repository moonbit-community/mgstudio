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
const DEFAULT_PLUGIN_ID_RENDER3D : String = "bevy_pbr::PbrPlugin"

///|
const DEFAULT_PLUGIN_ID_ANTI_ALIAS : String = "bevy_anti_alias::AntiAliasPlugin"

///|
const DEFAULT_PLUGIN_ID_SHADER : String = "mgstudio::ShaderPlugin"

///|
const DEFAULT_PLUGIN_ID_SPRITE : String = "bevy_sprite::SpritePlugin"

///|
const DEFAULT_PLUGIN_ID_SPRITE_RENDER : String = "bevy_sprite_render::SpriteRenderPlugin"

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
test "default plugins: include winit plugin after window plugin" {
  let builder = @internal.DefaultPlugins::build()
  inspect(builder.contains(@window.WINDOW_PLUGIN_ID), content="true")
  inspect(builder.contains("bevy_winit::WinitPlugin"), content="true")
  inspect(builder.enabled("bevy_winit::WinitPlugin"), content="true")
  inspect(builder.contains(DEFAULT_PLUGIN_ID_SHADER), content="true")
  inspect(builder.enabled(DEFAULT_PLUGIN_ID_SHADER), content="true")
  inspect(builder.contains(DEFAULT_PLUGIN_ID_ANTI_ALIAS), content="true")
  inspect(builder.enabled(DEFAULT_PLUGIN_ID_ANTI_ALIAS), content="true")
  inspect(builder.contains(DEFAULT_PLUGIN_ID_SPRITE), content="true")
  inspect(builder.enabled(DEFAULT_PLUGIN_ID_SPRITE), content="true")
  inspect(builder.contains(DEFAULT_PLUGIN_ID_SPRITE_RENDER), content="true")
  inspect(builder.enabled(DEFAULT_PLUGIN_ID_SPRITE_RENDER), content="true")
  let shader_index = plugin_index(builder, DEFAULT_PLUGIN_ID_SHADER)
  let render3d_index = plugin_index(builder, DEFAULT_PLUGIN_ID_RENDER3D)
  let anti_alias_index = plugin_index(builder, DEFAULT_PLUGIN_ID_ANTI_ALIAS)
  let sprite_index = plugin_index(builder, DEFAULT_PLUGIN_ID_SPRITE)
  let sprite_render_index = plugin_index(
    builder,
    DEFAULT_PLUGIN_ID_SPRITE_RENDER,
  )
  inspect(shader_index < render3d_index, content="true")
  inspect(render3d_index < anti_alias_index, content="true")
  inspect(anti_alias_index < sprite_index, content="true")
  inspect(sprite_index < sprite_render_index, content="true")
  inspect(builder.contains("bevy_gltf::GltfPlugin"), content="true")
  inspect(builder.enabled("bevy_gltf::GltfPlugin"), content="true")
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
  app
  .world()
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(entity) {
    if primary_window_entity.val is None {
      primary_window_entity.val = Some(entity)
    }
  })

  let entity = match primary_window_entity.val {
    Some(entity) => entity
    None => abort("missing primary window entity")
  }
  let stored_window : @window.Window = match
    (try! app.world().get_component(entity) : @window.Window?) {
    Some(window) => window
    None => abort("missing window component")
  }

  inspect(stored_window.title, content="Scale Override")
  inspect(stored_window.physical_width(), content="500")
  inspect(stored_window.physical_height(), content="300")
  inspect(stored_window.resolution.scale_factor_override(), content="Some(1)")
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

  inspect(asset_server.default_sampler_nearest.val, content="true")
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

  inspect(@asset.asset_is_texture_loaded(handle), content="true")
  inspect(@asset.asset_texture_width(handle), content="16")
  inspect(@asset.asset_texture_height(handle), content="12")
}

///|
test "default plugins: register_asset_source adds a named Bevy-style extra source" {
  let app = @asset.register_asset_source(
    @app.App::new(@ecs.World::new()),
    "example_files",
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

  inspect(@asset.asset_is_texture_loaded(handle), content="true")
  inspect(@asset.asset_texture_width(handle), content="128")
  inspect(@asset.asset_texture_height(handle), content="96")
}
