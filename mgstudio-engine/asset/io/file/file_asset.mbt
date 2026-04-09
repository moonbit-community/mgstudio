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
// Bevy source: `bevy/crates/bevy_asset/src/io/file/file_asset.rs`.

///|
pub struct FileAsset {
  path : String
  bytes : Bytes
}

///|
pub fn FileAsset::new(path : String, bytes : Bytes) -> FileAsset {
  FileAsset::{ path, bytes }
}

///|
pub fn FileAsset::path(self : FileAsset) -> String {
  self.path
}

///|
pub fn FileAsset::bytes(self : FileAsset) -> Bytes {
  self.bytes
}

///|
pub fn FileAsset::size(self : FileAsset) -> Int {
  self.bytes.length()
}
