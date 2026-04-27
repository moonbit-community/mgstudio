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
// Bevy source: `bevy/crates/bevy_asset/src/lib.rs`.
const ASSET_PLUGIN_NAME : String = "mgstudio.asset.AssetPlugin"

///|
pub fn asset_internal_system_set() -> @app.SystemSet {
  @app.system_set("mgstudio.asset.AssetInternalSystems")
}

///|
pub fn asset_tracking_system_set() -> @app.SystemSet {
  @app.system_set("mgstudio.asset.AssetTrackingSystems")
}

///|
pub fn asset_event_system_set() -> @app.SystemSet {
  @app.system_set("mgstudio.asset.AssetEventSystems")
}

///|
pub(all) struct AssetPlugin {
  default_sampler_nearest : Bool
  mode : AssetMode
  file_path : String?
  processed_file_path : String?
}

///|
pub fn AssetPlugin::default() -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: false,
    mode: AssetMode::Unprocessed,
    file_path: None,
    processed_file_path: None,
  }
}

///|
pub fn AssetPlugin::default_nearest() -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: true,
    mode: AssetMode::Unprocessed,
    file_path: None,
    processed_file_path: None,
  }
}

///|
pub fn AssetPlugin::with_default_sampler_nearest(
  self : AssetPlugin,
  enabled : Bool,
) -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: enabled,
    mode: self.mode,
    file_path: self.file_path,
    processed_file_path: self.processed_file_path,
  }
}

///|
pub fn AssetPlugin::with_mode(
  self : AssetPlugin,
  mode : AssetMode,
) -> AssetPlugin {
  AssetPlugin::{ ..self, mode, }
}

///|
pub fn AssetPlugin::with_file_path(
  self : AssetPlugin,
  file_path : String,
) -> AssetPlugin {
  AssetPlugin::{
    default_sampler_nearest: self.default_sampler_nearest,
    mode: self.mode,
    file_path: Some(file_path),
    processed_file_path: self.processed_file_path,
  }
}

///|
pub fn AssetPlugin::with_processed_file_path(
  self : AssetPlugin,
  processed_file_path : String,
) -> AssetPlugin {
  AssetPlugin::{ ..self, processed_file_path: Some(processed_file_path) }
}

///|
fn asset_plugin_with_server(
  app : @app.App[@ecs.World],
  asset_server : AssetServer,
  file_path : String?,
  mode : AssetMode,
  processed_file_path : String?,
) -> @app.App[@ecs.World] {
  let world = app.world()
  asset_with_world(world, fn() {
    let runtime_assets_dir_override = match
      asset_registered_default_source_dir_override() {
      Some(path) => Some(path)
      None => resolve_assets_dir_override(file_path)
    }
    asset_server.owner_world.val = Some(world)
    asset_register_builtin_loaders()
    set_runtime_assets_dir_override(runtime_assets_dir_override)
    set_runtime_asset_source_dir_overrides(
      asset_registered_source_dir_entries(),
    )
    set_runtime_asset_source_readers(asset_registered_source_reader_entries())
    asset_server.mode.val = mode
    asset_server.processed_file_path.val = resolve_assets_dir_override(
      processed_file_path,
    )
  })
  init_asset(
    init_asset(
      init_asset(app.insert_resource(asset_server), fn() {
        LoadedFolder::{ handles: [] }
      }),
      fn() { Image::new(0, 0, Bytes::from_array([])) },
    ),
    fn() { TextureAtlasLayout::new_empty(@math.UVec2::zero()) },
  )
  .configure_sets(@app.PreUpdate, asset_tracking_system_set(), after=[
    asset_internal_system_set(),
  ])
  .add_pre_update_system_config(
    @app.system(asset_system).in_set(asset_internal_system_set()),
  )
  .add_post_update_system_config(
    @app.system(asset_update_event_messages).in_set(asset_event_system_set()),
  )
}

///|
pub fn asset_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  asset_plugin_with_server(
    app,
    asset_server_standalone(),
    None,
    AssetMode::Unprocessed,
    None,
  )
}

///|
pub fn asset_plugin_nearest(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let asset_server = asset_server_standalone()
  asset_server.default_sampler_nearest.val = true
  asset_plugin_with_server(
    app,
    asset_server,
    None,
    AssetMode::Unprocessed,
    None,
  )
}

///|
pub impl @app.Plugin for AssetPlugin with name(_self) {
  ASSET_PLUGIN_NAME
}

///|
pub impl @app.Plugin for AssetPlugin with build(self, app) {
  let asset_server = asset_server_standalone()
  asset_server.default_sampler_nearest.val = self.default_sampler_nearest
  asset_plugin_with_server(
    app,
    asset_server,
    self.file_path,
    self.mode,
    self.processed_file_path,
  )
}
