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
// Bevy source: `bevy/crates/bevy_asset/src/loader_builders.rs`.
pub struct AssetReader {
  read_fn : (String) -> Bytes?
  read_meta_fn : (String) -> Bytes?
  read_directory_fn : (String) -> Array[String]?
  is_directory_fn : (String) -> Bool
}

///|
pub struct AssetSourceBuilder {
  path : String
  reader_builder : ((AssetReader) -> AssetReader)?
}

///|
pub fn AssetReader::new(
  read : (String) -> Bytes?,
  read_meta : (String) -> Bytes?,
  read_directory : (String) -> Array[String]?,
  is_directory : (String) -> Bool,
) -> AssetReader {
  AssetReader::{
    read_fn: read,
    read_meta_fn: read_meta,
    read_directory_fn: read_directory,
    is_directory_fn: is_directory,
  }
}

///|
pub fn AssetReader::read(self : AssetReader, path : String) -> Bytes? {
  (self.read_fn)(path)
}

///|
pub fn AssetReader::read_meta(self : AssetReader, path : String) -> Bytes? {
  (self.read_meta_fn)(path)
}

///|
pub fn AssetReader::read_directory(
  self : AssetReader,
  path : String,
) -> Array[String]? {
  (self.read_directory_fn)(path)
}

///|
pub fn AssetReader::is_directory(self : AssetReader, path : String) -> Bool {
  (self.is_directory_fn)(path)
}

///|
pub fn AssetSourceBuilder::platform_default(
  path : String,
  _watcher : Unit?,
) -> AssetSourceBuilder {
  AssetSourceBuilder::{ path, reader_builder: None }
}

///|
pub fn AssetSourceBuilder::with_reader(
  self : AssetSourceBuilder,
  reader_builder : (AssetReader) -> AssetReader,
) -> AssetSourceBuilder {
  AssetSourceBuilder::{ path: self.path, reader_builder: Some(reader_builder) }
}

///|
fn asset_register_source_builder(
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
) -> Unit {
  let next : Array[(AssetSourceId, AssetSourceBuilder)] = []
  let mut replaced = false
  for entry in asset_source_builder_registry.val {
    if entry.0 == source_id {
      next.push((source_id, builder))
      replaced = true
    } else {
      next.push(entry)
    }
  }
  if !replaced {
    next.push((source_id, builder))
  }
  asset_source_builder_registry.val = next
}

///|
fn asset_registered_source_dir_entries() -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  for entry in asset_source_builder_registry.val {
    if entry.0 is AssetSourceId::Named(source_name) {
      if resolve_assets_dir_override(Some(entry.1.path)) is Some(resolved) {
        entries.push((source_name, resolved))
      }
    }
  }
  entries
}

///|
fn asset_registered_source_reader_entries() -> Array[
  (AssetSourceId, AssetSourceBuilder),
] {
  let entries : Array[(AssetSourceId, AssetSourceBuilder)] = []
  for entry in asset_source_builder_registry.val {
    if entry.1.reader_builder is Some(_) {
      entries.push(entry)
    }
  }
  entries
}

///|
pub fn register_asset_source(
  app : @app.App[@ecs.World],
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
) -> @app.App[@ecs.World] {
  asset_register_source_builder(source_id, builder)
  app
}
