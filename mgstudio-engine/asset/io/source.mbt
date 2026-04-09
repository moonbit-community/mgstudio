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
// Bevy source: `bevy/crates/bevy_asset/src/io/source.rs`.

///|
pub struct AssetSourcePath {
  source_name : String?
  path : String
}

///|
pub fn AssetSourcePath::new(path : String) -> AssetSourcePath {
  AssetSourcePath::{ source_name: None, path }
}

///|
pub fn AssetSourcePath::with_source_name(
  self : AssetSourcePath,
  source_name : String?,
) -> AssetSourcePath {
  AssetSourcePath::{ ..self, source_name, }
}

///|
pub fn AssetSourcePath::canonical(self : AssetSourcePath) -> String {
  @asset.asset_canonical_path(self.path)
}
