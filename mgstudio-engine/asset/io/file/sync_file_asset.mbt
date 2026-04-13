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
fn sync_file_asset_ensure_parent_dir(path : String) -> Unit {
  let path_value : @path.Path = path
  let parent = path_value.dirname().to_string()
  if parent == "" || parent == "." || parent == path {
    return
  }
  if @fs.path_exists(parent) {
    return
  }
  sync_file_asset_ensure_parent_dir(parent)
  @fs.create_dir(parent) catch {
    _ => ()
  }
}

///|
pub fn sync_file_asset_bytes(path : String, bytes : Bytes) -> Unit {
  sync_file_asset_ensure_parent_dir(path)
  @fs.write_bytes_to_file(path, bytes) catch {
    _ => ()
  }
}

///|
pub fn sync_file_asset_texture_png(path : String, bytes : Bytes) -> Unit {
  sync_file_asset_bytes(path, bytes)
}
