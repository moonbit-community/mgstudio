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
// Bevy source: `bevy/crates/bevy_asset/src/io/file/mod.rs`.

///|
pub type FileAssetPath = @asset.AssetPath

///|
pub type FileAssetReader = @asset.AssetReader

///|
pub type FileAssetSourceId = @asset.AssetSourceId

///|
pub fn asset_file_format_path(path : FileAssetPath) -> String {
  @asset.asset_format_path(path)
}

///|
pub fn asset_file_parse_path(path : String) -> FileAssetPath {
  @asset.asset_parse_path(path)
}

///|
pub fn asset_file_try_parse_path(
  path : String,
) -> FileAssetPath raise @asset.ParseAssetPathError {
  @asset.asset_try_parse_path(path)
}

///|
pub fn[P : @asset.IntoAssetPath] asset_file_read_bytes(path : P) -> Bytes {
  @asset.load_asset_source_bytes(path)
}

///|
pub fn[P : @asset.IntoAssetPath] asset_file_read_text(path : P) -> String? {
  @asset.load_optional_asset_source_text(path)
}

///|
pub fn asset_file_loader_kind_for_path(path : String) -> @asset.AssetLoaderKind {
  @asset.asset_loader_kind_for_path(path)
}

///|
pub fn asset_file_register_source(
  app : @app.App[@ecs.World],
  source_id : FileAssetSourceId,
  builder : @asset.AssetSourceBuilder,
) -> @app.App[@ecs.World] {
  @asset.register_asset_source(app, source_id, builder)
}
