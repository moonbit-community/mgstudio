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
// Bevy source: `bevy/crates/bevy_asset/src/server/mod.rs`.

///|
pub type AssetLoaderKind = @asset.AssetLoaderKind

///|
pub type AssetServer = @asset.AssetServer

///|
pub fn asset_loader_kind_for_path(path : String) -> AssetLoaderKind {
  @asset.asset_loader_kind_for_path(path)
}

///|
pub fn asset_register_loader_extension(
  extension : String,
  kind : AssetLoaderKind,
) -> Unit {
  @asset.asset_register_loader_extension(extension, kind)
}

///|
pub fn asset_remove_loader_extension(extension : String) -> Unit {
  @asset.asset_remove_loader_extension(extension)
}

///|
pub fn asset_server_resource_key() -> @ecs.ResourceKey[AssetServer] {
  @asset.asset_server_resource_key()
}

///|
pub fn asset_set_default_sampler_nearest(enabled : Bool) -> Unit {
  @asset.asset_set_default_sampler_nearest(enabled)
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  @asset.asset_supported_compressed_image_formats()
}

///|
pub fn asset_system(world : @ecs.World) -> Unit {
  @asset.asset_system(world)
}

///|
pub fn asset_update_event_messages(world : @ecs.World) -> Unit {
  @asset.asset_update_event_messages(world)
}

///|
pub fn asset_update_loaded_folders(world : @ecs.World) -> Unit {
  @asset.asset_update_loaded_folders(world)
}
