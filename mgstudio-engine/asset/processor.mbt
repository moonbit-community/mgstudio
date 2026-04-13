// Copyright 2026 International Digital Economy Academy
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
pub(all) enum AssetMode {
  Unprocessed
  Processed
} derive(Eq, Debug)

///|
pub(all) suberror AssetProcessError {
  Message(String)
}

///|
pub fn AssetProcessError::message(self : AssetProcessError) -> String {
  match self {
    Message(message) => message
  }
}

///|
pub struct ProcessedAsset[T] {
  asset : T
  saved_bytes : Bytes?
}

///|
pub fn[T] ProcessedAsset::new(asset : T) -> ProcessedAsset[T] {
  ProcessedAsset::{ asset, saved_bytes: None }
}

///|
pub fn[T] ProcessedAsset::with_saved_bytes(
  self : ProcessedAsset[T],
  bytes : Bytes,
) -> ProcessedAsset[T] {
  ProcessedAsset::{ ..self, saved_bytes: Some(bytes) }
}

///|
pub fn[T] ProcessedAsset::asset(self : ProcessedAsset[T]) -> T {
  self.asset
}

///|
pub fn[T] ProcessedAsset::saved_bytes(self : ProcessedAsset[T]) -> Bytes? {
  self.saved_bytes
}

///|
pub struct LoadTransformAndSave[T] {
  extensions : Array[String]
  process : (AssetServer, AssetPath, Bytes) -> ProcessedAsset[T] raise AssetProcessError
}

///|
pub fn[T] LoadTransformAndSave::new(
  extensions : Array[String],
  process : (AssetServer, AssetPath, Bytes) -> ProcessedAsset[T] raise AssetProcessError,
) -> LoadTransformAndSave[T] {
  LoadTransformAndSave::{ extensions, process }
}

///|
struct PendingProcessedAssetLoad {
  type_name : String
  handle_id : Int
  path : AssetPath
}

///|
priv struct ProcessedAssetAny {
  asset : @any.Any
  saved_bytes : Bytes?
}

///|
priv struct AssetProcessorEntry {
  extensions : Array[String]
  process : (AssetServer, AssetPath, Bytes) -> ProcessedAssetAny raise AssetProcessError
  insert : (@ecs.World, Int, @any.Any) -> Unit
}

///|
let asset_processor_registry : Ref[
  @hashmap.HashMap[String, Array[AssetProcessorEntry]],
] = Ref::new(@hashmap.HashMap::new())

///|
pub fn[T] register_asset_processor(
  app : @app.App[@ecs.World],
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let entries = match asset_processor_registry.val.get(type_name) {
    Some(entries) => entries
    None => []
  }
  let next_entries : Array[AssetProcessorEntry] = []
  for entry in entries {
    next_entries.push(entry)
  }
  next_entries.push(AssetProcessorEntry::{
    extensions: processor.extensions,
    process: fn(asset_server, path, bytes) raise AssetProcessError {
      let processed = (processor.process)(asset_server, path, bytes)
      ProcessedAssetAny::{
        asset: @any.of(processed.asset()),
        saved_bytes: processed.saved_bytes(),
      }
    },
    insert: fn(world, handle_id, value_any) {
      let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
      if (try! world.get_resource(key)) is None {
        world.insert_resource(key, Assets::new())
      }
      let assets_ref = match (try! world.get_resource_ref_mut(key)) {
        Some(value) => value
        None =>
          abort(
            "Failed to initialize Assets resource for asset processor output",
          )
      }
      let value : T = match value_any.try_to() {
        Some(value) => value
        None =>
          abort(
            "asset processor produced a mismatched asset value for \{type_name}",
          )
      }
      ignore(assets_ref.val.insert(Handle::new(handle_id), value))
    },
  })
  asset_processor_registry.val.set(type_name, next_entries)
  let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
  if app.contains_resource(key) {
    app
  } else {
    app.init_resource(fn() {
      let assets : Assets[T] = Assets::new()
      assets
    })
  }
}

///|
pub fn[T] init_asset_processor(
  app : @app.App[@ecs.World],
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  register_asset_processor(app, processor)
}

///|
pub fn set_default_asset_processor(
  app : @app.App[@ecs.World],
  extension : String,
) -> @app.App[@ecs.World] {
  extension |> ignore
  app
}

///|
fn asset_processor_normalize_extension(extension : String) -> String {
  let trimmed = extension.trim().to_string()
  if trimmed == "" {
    return ""
  }
  if trimmed.code_unit_at(0) == 46 {
    return trimmed[1:trimmed.length()].to_string()
  }
  trimmed
}

///|
fn asset_processor_path_matches_extension(
  path : AssetPath,
  extension : String,
) -> Bool {
  let normalized = asset_processor_normalize_extension(extension)
  if normalized == "" {
    return false
  }
  let formatted = asset_format_path(path)
  if formatted.length() <= normalized.length() {
    return false
  }
  let start = formatted.length() - normalized.length()
  if formatted[start:formatted.length()].to_string() != normalized {
    return false
  }
  formatted.code_unit_at(start - 1) == 46
}

///|
fn asset_processor_entry_for_path(
  type_name : String,
  path : AssetPath,
) -> AssetProcessorEntry? {
  guard asset_processor_registry.val.get(type_name) is Some(entries) else {
    return None
  }
  let matched_entry : Ref[AssetProcessorEntry?] = Ref::new(None)
  let matched_length = Ref::new(-1)
  for entry in entries {
    for extension in entry.extensions {
      let normalized = asset_processor_normalize_extension(extension)
      if asset_processor_path_matches_extension(path, normalized) &&
        normalized.length() > matched_length.val {
        matched_entry.val = Some(entry)
        matched_length.val = normalized.length()
      }
    }
  }
  matched_entry.val
}

///|
fn asset_should_process_registered_asset(
  asset_server : AssetServer,
  type_name : String,
  path : AssetPath,
) -> Bool {
  asset_server.mode.val == AssetMode::Processed &&
  asset_processor_entry_for_path(type_name, path) is Some(_)
}

///|
fn asset_processed_output_path(
  asset_server : AssetServer,
  path : AssetPath,
) -> String? {
  match asset_server.processed_file_path.val {
    Some(processed_root) =>
      Some(path_join(processed_root, asset_format_path(path)))
    None => None
  }
}

///|
fn asset_process_pending_processed_asset_loads(
  world : @ecs.World,
  asset_server : AssetServer,
) -> Unit {
  let remaining : Array[PendingProcessedAssetLoad] = []
  for pending in asset_server.pending_processed_asset_loads.val {
    match asset_processor_entry_for_path(pending.type_name, pending.path) {
      Some(entry) => {
        let formatted_path = asset_format_path(pending.path)
        let bytes = load_asset_file_bytes(asset_canonical_path(formatted_path))
        let processed = (entry.process)(asset_server, pending.path, bytes) catch {
          _ => {
            remaining.push(pending)
            continue
          }
        }
        (entry.insert)(world, pending.handle_id, processed.asset)
        if processed.saved_bytes is Some(saved_bytes) {
          if asset_processed_output_path(asset_server, pending.path)
            is Some(output_path) {
            host_asset_save_bytes(path=output_path, bytes=saved_bytes)
          }
        }
      }
      None => remaining.push(pending)
    }
  }
  asset_server.pending_processed_asset_loads.val = remaining
}
