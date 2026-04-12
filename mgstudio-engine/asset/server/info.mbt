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
// Bevy source: `bevy/crates/bevy_asset/src/server/info.rs`.

///|
pub struct AssetServerInfo {
  supported_compressed_image_formats : Int
  default_sampler_nearest : Bool
}

///|
pub fn AssetServerInfo::default() -> AssetServerInfo {
  AssetServerInfo::{
    supported_compressed_image_formats: @asset.asset_supported_compressed_image_formats(),
    default_sampler_nearest: false,
  }
}

///|
pub fn AssetServerInfo::loader_kind(
  _self : AssetServerInfo,
  path : String,
) -> @asset.AssetLoaderKind {
  @asset.asset_loader_kind_for_path(path)
}

///|
pub fn AssetServerInfo::supported_compressed_image_formats(
  self : AssetServerInfo,
) -> Int {
  self.supported_compressed_image_formats
}

///|
pub fn AssetServerInfo::default_sampler_nearest(self : AssetServerInfo) -> Bool {
  self.default_sampler_nearest
}
