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
priv struct AssetProcessorRegistryState {
  processors : Ref[@hashmap.HashMap[String, Array[AssetProcessorEntry]]]
  default_processor_by_extension : Ref[@hashmap.HashMap[String, (String, Int)]]
  named_processors : Ref[@hashmap.HashMap[String, Array[(String, Int)]]]
  last_registered_entry : Ref[(String, Int)?]
}

///|
fn asset_processor_registry_state_resource_key() -> @ecs.ResourceKey[
  AssetProcessorRegistryState,
] {
  @ecs.register_resource(
    debug_name="mgstudio_asset::AssetProcessorRegistryState",
  )
}

///|
fn asset_processor_registry_clone_entries(
  entries : Array[AssetProcessorEntry],
) -> Array[AssetProcessorEntry] {
  let next : Array[AssetProcessorEntry] = []
  for entry in entries {
    next.push(entry)
  }
  next
}

///|
fn asset_processor_registry_clone_entry_refs(
  entries : Array[(String, Int)],
) -> Array[(String, Int)] {
  let next : Array[(String, Int)] = []
  for entry in entries {
    next.push(entry)
  }
  next
}

///|
fn asset_processor_registry_push_entry_in_state(
  state : AssetProcessorRegistryState,
  type_name : String,
  entry : AssetProcessorEntry,
) -> Int {
  let entries = match state.processors.val.get(type_name) {
    Some(entries) => entries
    None => []
  }
  let next_entries = asset_processor_registry_clone_entries(entries)
  let next_index = next_entries.length()
  next_entries.push(entry)
  state.processors.val.set(type_name, next_entries)
  state.last_registered_entry.val = Some((type_name, next_index))
  next_index
}

///|
fn asset_processor_registry_register_name_in_state(
  state : AssetProcessorRegistryState,
  processor_name : String,
  entry_ref : (String, Int),
) -> Unit {
  let normalized_name = processor_name.trim().to_owned()
  if normalized_name == "" {
    return
  }
  let entries = match state.named_processors.val.get(normalized_name) {
    Some(entries) => entries
    None => []
  }
  let next_entries = asset_processor_registry_clone_entry_refs(entries)
  next_entries.push(entry_ref)
  state.named_processors.val.set(normalized_name, next_entries)
}

///|
fn asset_processor_registry_state_for_world(
  world : @ecs.World,
) -> AssetProcessorRegistryState {
  let key = asset_processor_registry_state_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, AssetProcessorRegistryState::{
      processors: Ref::new(@hashmap.HashMap::new()),
      default_processor_by_extension: Ref::new(@hashmap.HashMap::new()),
      named_processors: Ref::new(@hashmap.HashMap::new()),
      last_registered_entry: Ref::new(None),
    })
  }
  match (try! world.get_resource(key)) {
    Some(state) => state
    None => abort("Failed to initialize asset processor registry resource")
  }
}

///|
fn asset_processor_registry_state_active() -> AssetProcessorRegistryState {
  match asset_current_world() {
    Some(world) => asset_processor_registry_state_for_world(world)
    None =>
      abort(
        "AssetProcessor registry requires an active world; call this from an App context",
      )
  }
}

///|
fn asset_processor_registry_register_entry(
  type_name : String,
  entry : AssetProcessorEntry,
  processor_name : String?,
) -> Unit {
  let state = asset_processor_registry_state_active()
  let entry_index = asset_processor_registry_push_entry_in_state(
    state, type_name, entry,
  )
  match processor_name {
    Some(name) =>
      asset_processor_registry_register_name_in_state(
        state,
        name,
        (type_name, entry_index),
      )
    None => ()
  }
}

///|
fn[T] register_asset_processor_with_name(
  app : @app.App[@ecs.World],
  processor_name : String?,
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let world = app.world()
  asset_with_world(world, fn() {
    asset_processor_registry_register_entry(
      type_name,
      AssetProcessorEntry::{
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
          let assets = match (try! world.get_resource_mut(key)) {
            Some(value) => value
            None =>
              abort(
                "Assets resource is missing for asset processor output; call init_asset before registering or processing this asset type",
              )
          }
          let value : T = match value_any.try_to() {
            Some(value) => value
            None =>
              abort(
                "asset processor produced a mismatched asset value for \{type_name}",
              )
          }
          ignore(
            assets.modify(fn(store) {
              store.insert(Handle::new(handle_id), value)
            }),
          )
        },
      },
      processor_name,
    )
  })
  app
}

///|
pub fn[T] register_asset_processor(
  app : @app.App[@ecs.World],
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  register_asset_processor_with_name(app, None, processor)
}

///|
pub fn[T] register_asset_processor_named(
  app : @app.App[@ecs.World],
  processor_name : String,
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  register_asset_processor_with_name(app, Some(processor_name), processor)
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
  let normalized = asset_processor_normalize_extension(extension)
  if normalized == "" {
    return app
  }
  let world = app.world()
  asset_with_world(world, fn() {
    fn set_default_to_last_registered(
      state : AssetProcessorRegistryState,
    ) -> Unit {
      match state.last_registered_entry.val {
        Some(last_entry) =>
          state.default_processor_by_extension.val.set(normalized, last_entry)
        None => ()
      }
    }

    set_default_to_last_registered(asset_processor_registry_state_active())
  })
  app
}

///|
pub fn set_default_asset_processor_by_name(
  app : @app.App[@ecs.World],
  extension : String,
  processor_name : String,
) -> @app.App[@ecs.World] {
  let normalized_extension = asset_processor_normalize_extension(extension)
  if normalized_extension == "" {
    return app
  }
  let normalized_name = processor_name.trim().to_owned()
  if normalized_name == "" {
    return app
  }
  let world = app.world()
  asset_with_world(world, fn() {
    let state = asset_processor_registry_state_active()
    match state.named_processors.val.get(normalized_name) {
      Some(entries) if entries.length() == 1 =>
        state.default_processor_by_extension.val.set(
          normalized_extension,
          entries[0],
        )
      Some(entries) if entries.length() > 1 =>
        println(
          "Warning: default asset processor `\{normalized_name}` is ambiguous (\{entries.length()} registrations); keep the previous default for extension `\{normalized_extension}`",
        )
      _ =>
        println(
          "Warning: default asset processor `\{normalized_name}` is not registered; keep the previous default for extension `\{normalized_extension}`",
        )
    }
  })
  app
}

///|
fn asset_processor_normalize_extension(extension : String) -> String {
  let trimmed = extension.trim().to_owned()
  if trimmed == "" {
    return ""
  }
  if trimmed.code_unit_at(0) == 46 {
    return trimmed[1:trimmed.length()].to_owned()
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
  if formatted[start:formatted.length()].to_owned() != normalized {
    return false
  }
  formatted.code_unit_at(start - 1) == 46
}

///|
fn asset_processor_entry_for_path(
  type_name : String,
  path : AssetPath,
) -> AssetProcessorEntry? {
  let state = asset_processor_registry_state_active()
  guard state.processors.val.get(type_name) is Some(entries) else {
    return None
  }
  let default_candidate : Ref[AssetProcessorEntry?] = Ref::new(None)
  let default_length = Ref::new(-1)
  let matched_entry : Ref[AssetProcessorEntry?] = Ref::new(None)
  let matched_length = Ref::new(-1)
  for entry_index in 0..<entries.length() {
    let entry = entries[entry_index]
    for extension in entry.extensions {
      let normalized = asset_processor_normalize_extension(extension)
      if !asset_processor_path_matches_extension(path, normalized) {
        continue
      }
      if normalized.length() > matched_length.val {
        matched_entry.val = Some(entry)
        matched_length.val = normalized.length()
      }
      match state.default_processor_by_extension.val.get(normalized) {
        Some(default_entry) => {
          let default_type_name = default_entry.0
          let default_entry_index = default_entry.1
          if default_type_name == type_name &&
            default_entry_index == entry_index &&
            normalized.length() > default_length.val {
            default_candidate.val = Some(entry)
            default_length.val = normalized.length()
          }
        }
        _ => ()
      }
    }
  }
  match default_candidate.val {
    Some(entry) => Some(entry)
    None => matched_entry.val
  }
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
        asset_server.set_typed_loaded_states(
          pending.type_name,
          pending.handle_id,
        )
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
