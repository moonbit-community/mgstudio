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
// Bevy source: `bevy/crates/bevy_asset/src/io/mod.rs`.
// Bridge surface to the root `asset` package implementation.

///|
pub type AssetPath = @asset.AssetPath

///|
pub type AssetReader = @asset.AssetReader

///|
pub type AssetLoaderKind = @asset.AssetLoaderKind

///|
pub type AssetSourceBuilder = @asset.AssetSourceBuilder

///|
pub type AssetSourceId = @asset.AssetSourceId

///|
pub type ParsedAssetPath = @asset.ParsedAssetPath

///|
pub fn asset_format_path(path : AssetPath) -> String {
  @asset.asset_format_path(path)
}

///|
pub fn asset_parse_path(path : String) -> AssetPath {
  @asset.asset_parse_path(path)
}

///|
pub fn asset_try_parse_path(
  path : String,
) -> AssetPath raise @asset.ParseAssetPathError {
  @asset.asset_try_parse_path(path)
}

///|
pub fn[P : @asset.IntoAssetPath] load_asset_source_bytes(path : P) -> Bytes {
  @asset.load_asset_source_bytes(path)
}

///|
pub fn[P : @asset.IntoAssetPath] load_optional_asset_source_text(
  path : P,
) -> String? {
  @asset.load_optional_asset_source_text(path)
}

///|
pub fn register_asset_source(
  app : @app.App[@ecs.World],
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
) -> @app.App[@ecs.World] {
  @asset.register_asset_source(app, source_id, builder)
}
