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
// Bevy source: `bevy/crates/bevy_asset/src/io/file/sync_file_asset.rs`.

///|
pub fn sync_file_asset_bytes(path : String, bytes : Bytes) -> Unit {
  @asset.host_asset_save_bytes(path=path, bytes~)
}

///|
pub fn sync_file_asset_texture_png(path : String, bytes : Bytes) -> Unit {
  sync_file_asset_bytes(path, bytes)
}
