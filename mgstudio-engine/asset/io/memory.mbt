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
// Bevy source: `bevy/crates/bevy_asset/src/io/memory.rs`.

///|
pub struct MemoryAssetSource {
  name : String
  blobs : Array[(String, Bytes)]
}

///|
pub fn MemoryAssetSource::new(name : String) -> MemoryAssetSource {
  MemoryAssetSource::{ name, blobs: [] }
}

///|
pub fn MemoryAssetSource::name(self : MemoryAssetSource) -> String {
  self.name
}

///|
pub fn MemoryAssetSource::insert(
  self : MemoryAssetSource,
  path : String,
  bytes : Bytes,
) -> Unit {
  self.blobs.push((path, bytes))
}

///|
pub fn MemoryAssetSource::read(
  self : MemoryAssetSource,
  path : String,
) -> Bytes? {
  for entry in self.blobs {
    let (entry_path, entry_bytes) = entry
    if entry_path == path {
      return Some(entry_bytes)
    }
  }
  None
}
