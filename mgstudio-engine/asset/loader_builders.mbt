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
fn asset_source_id_debug_name(source_id : AssetSourceId) -> String {
  match source_id {
    AssetSourceId::Default => "default"
    AssetSourceId::Named(name) => name
  }
}

///|
priv struct AssetSourceBuilderRegistryState {
  named_builders : Ref[@hashmap.HashMap[String, AssetSourceBuilder]]
  default_builder : Ref[AssetSourceBuilder?]
}

///|
fn asset_source_builder_registry_resource_key() -> @ecs.ResourceKey[
  AssetSourceBuilderRegistryState,
] {
  @ecs.register_resource(
    debug_name="mgstudio_asset::AssetSourceBuilderRegistryState",
  )
}

///|
fn asset_source_builder_registry_upsert_in_state(
  state : AssetSourceBuilderRegistryState,
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
  replace_existing : Bool,
) -> Unit {
  match source_id {
    AssetSourceId::Default => {
      if replace_existing || state.default_builder.val is None {
        state.default_builder.val = Some(builder)
      }
    }
    AssetSourceId::Named(source_name) => {
      if replace_existing || state.named_builders.val.get(source_name) is None {
        state.named_builders.val.set(source_name, builder)
      }
    }
  }
}

///|
fn asset_source_builder_registry_for_world(
  world : @ecs.World,
) -> AssetSourceBuilderRegistryState {
  let key = asset_source_builder_registry_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(
      key,
      AssetSourceBuilderRegistryState::{
        named_builders: Ref::new(@hashmap.HashMap::new()),
        default_builder: Ref::new(None),
      },
    )
  }
  match (try! world.get_resource(key)) {
    Some(state) => state
    None => abort("Failed to initialize asset source builder registry resource")
  }
}

///|
fn asset_source_builder_registry_state_active() -> AssetSourceBuilderRegistryState {
  match asset_current_world() {
    Some(world) => asset_source_builder_registry_for_world(world)
    None =>
      abort(
        "AssetSourceBuilder registry requires an active world; call this from an App context",
      )
  }
}

///|
fn asset_register_source_builder(
  source_id : AssetSourceId,
  builder : AssetSourceBuilder,
) -> Unit {
  asset_source_builder_registry_upsert_in_state(
    asset_source_builder_registry_state_active(),
    source_id,
    builder,
    true,
  )
}

///|
fn asset_registered_source_dir_entries() -> Array[(String, String)] {
  let entries : Array[(String, String)] = []
  let state = asset_source_builder_registry_state_active()
  for entry in state.named_builders.val.iter() {
    let (source_name, builder) = entry
    if resolve_assets_dir_override(Some(builder.path)) is Some(resolved) {
      entries.push((source_name, resolved))
    }
  }
  entries
}

///|
fn asset_registered_default_source_dir_override() -> String? {
  let state = asset_source_builder_registry_state_active()
  match state.default_builder.val {
    Some(default_builder) => resolve_assets_dir_override(Some(default_builder.path))
    None => None
  }
}

///|
fn asset_registered_source_reader_entries() -> Array[
  (AssetSourceId, AssetSourceBuilder),
] {
  let entries : Array[(AssetSourceId, AssetSourceBuilder)] = []
  let state = asset_source_builder_registry_state_active()
  match state.default_builder.val {
    Some(default_builder) =>
      if default_builder.reader_builder is Some(_) {
        entries.push((AssetSourceId::Default, default_builder))
      }
    None => ()
  }
  for entry in state.named_builders.val.iter() {
    let (source_name, builder) = entry
    if builder.reader_builder is Some(_) {
      entries.push((AssetSourceId::Named(source_name), builder))
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
  if app.contains_resource(asset_server_resource_key()) {
    println(
      "Warning: asset source `\{asset_source_id_debug_name(source_id)}` must be registered before AssetPlugin (typically added via DefaultPlugins)",
    )
  }
  let world = app.world()
  asset_with_world(world, fn() {
    asset_register_source_builder(source_id, builder)
  })
  app
}
