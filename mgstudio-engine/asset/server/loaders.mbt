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
// Bevy source: `bevy/crates/bevy_asset/src/server/loaders.rs`.

///|
pub struct AssetServerLoaderInfo {
  extension : String
  kind : @asset.AssetLoaderKind
}

///|
pub fn AssetServerLoaderInfo::new(
  extension : String,
  kind : @asset.AssetLoaderKind,
) -> AssetServerLoaderInfo {
  AssetServerLoaderInfo::{ extension, kind }
}

///|
pub fn AssetServerLoaderInfo::extension(self : AssetServerLoaderInfo) -> String {
  self.extension
}

///|
pub fn AssetServerLoaderInfo::kind(
  self : AssetServerLoaderInfo,
) -> @asset.AssetLoaderKind {
  self.kind
}

///|
pub fn asset_server_register_loader_extension(
  extension : String,
  kind : @asset.AssetLoaderKind,
) -> Unit {
  @asset.asset_register_loader_extension(extension, kind)
}

///|
pub fn asset_server_remove_loader_extension(extension : String) -> Unit {
  @asset.asset_remove_loader_extension(extension)
}

///|
pub fn asset_server_loader_info_for_path(
  path : String,
) -> AssetServerLoaderInfo {
  AssetServerLoaderInfo::new(path, @asset.asset_loader_kind_for_path(path))
}
