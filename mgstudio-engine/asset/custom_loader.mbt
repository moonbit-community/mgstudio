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
pub struct AssetLoader[T] {
  extensions : Array[String]
  load : (LoadContext, Bytes) -> T
}

///|
pub struct LoadContext {
  world : @ecs.World?
  asset_server : AssetServer
  path : AssetPath
}

///|
priv struct TypedAssetLoaderEntry {
  extensions : Array[String]
  load : (LoadContext, Bytes) -> @any.Any
  insert : (@ecs.World, Int, @any.Any) -> Unit
}

///|
priv struct TypedAssetLoaderRegistryState {
  loaders : Ref[@hashmap.HashMap[String, Array[TypedAssetLoaderEntry]]]
}

///|
fn typed_asset_loader_registry_resource_key() -> @ecs.ResourceKey[
  TypedAssetLoaderRegistryState,
] {
  @ecs.register_resource(
    debug_name="mgstudio_asset::TypedAssetLoaderRegistryState",
  )
}

///|
fn typed_asset_loader_clone_entries(
  entries : Array[TypedAssetLoaderEntry],
) -> Array[TypedAssetLoaderEntry] {
  let next : Array[TypedAssetLoaderEntry] = []
  for entry in entries {
    next.push(entry)
  }
  next
}

///|
fn typed_asset_loader_registry_for_world(
  world : @ecs.World,
) -> Ref[@hashmap.HashMap[String, Array[TypedAssetLoaderEntry]]] {
  let key = typed_asset_loader_registry_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, TypedAssetLoaderRegistryState::{
      loaders: Ref::new(@hashmap.HashMap::new()),
    })
  }
  match (try! world.get_resource(key)) {
    Some(state) => state.loaders
    None => abort("Failed to initialize typed asset loader registry resource")
  }
}

///|
fn typed_asset_loader_registry_active() -> Ref[
  @hashmap.HashMap[String, Array[TypedAssetLoaderEntry]],
] {
  match asset_current_world() {
    Some(world) => typed_asset_loader_registry_for_world(world)
    None =>
      abort(
        "Typed asset loader registry requires an active world; use asset_with_world or call via a world-owned AssetServer",
      )
  }
}

///|
fn typed_asset_loader_is_registered(type_name : String) -> Bool {
  match typed_asset_loader_registry_active().val.get(type_name) {
    Some(entries) => entries.length() > 0
    None => false
  }
}

///|
pub fn[T] AssetLoader::new(
  extensions : Array[String],
  load : (AssetServer, AssetPath, Bytes) -> T,
) -> AssetLoader[T] {
  AssetLoader::{
    extensions,
    load: fn(context, bytes) {
      load(context.asset_server(), context.path(), bytes)
    },
  }
}

///|
pub fn[T] AssetLoader::new_with_context(
  extensions : Array[String],
  load : (LoadContext, Bytes) -> T,
) -> AssetLoader[T] {
  AssetLoader::{ extensions, load }
}

///|
fn LoadContext::new(
  world : @ecs.World,
  asset_server : AssetServer,
  path : AssetPath,
) -> LoadContext {
  LoadContext::{ world: Some(world), asset_server, path }
}

///|
fn LoadContext::new_detached(
  asset_server : AssetServer,
  path : AssetPath,
) -> LoadContext {
  LoadContext::{ world: None, asset_server, path }
}

///|
pub fn LoadContext::asset_server(self : LoadContext) -> AssetServer {
  self.asset_server
}

///|
pub fn LoadContext::path(self : LoadContext) -> AssetPath {
  self.path
}

///|
fn typed_asset_loader_path_key(type_name : String, path : AssetPath) -> String {
  "\{type_name}::\{asset_canonical_path(asset_format_path(path))}"
}

///|
fn typed_asset_loader_normalize_extension(extension : String) -> String {
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
fn typed_asset_loader_normalize_extensions(
  extensions : Array[String],
) -> Array[String] {
  let normalized : Array[String] = []
  for extension in extensions {
    let value = typed_asset_loader_normalize_extension(extension)
    if value == "" {
      continue
    }
    if !normalized.contains(value) {
      normalized.push(value)
    }
  }
  normalized
}

///|
fn typed_asset_loader_filename(path : String) -> String {
  let mut split = -1
  for i in 0..<path.length() {
    let code = path.code_unit_at(i).to_int()
    if code == 47 || code == 92 {
      split = i
    }
  }
  if split < 0 {
    path
  } else if split + 1 < path.length() {
    path[split + 1:path.length()].to_string()
  } else {
    ""
  }
}

///|
fn typed_asset_loader_full_extension(path : AssetPath) -> String? {
  let file_name = typed_asset_loader_filename(asset_format_path(path))
  let mut split = -1
  for i in 0..<file_name.length() {
    if file_name.code_unit_at(i).to_int() == 46 {
      split = i
      break
    }
  }
  if split < 0 || split + 1 >= file_name.length() {
    None
  } else {
    Some(file_name[split + 1:file_name.length()].to_string())
  }
}

///|
fn typed_asset_loader_secondary_extensions(
  full_extension : String,
) -> Array[String] {
  let secondary : Array[String] = []
  for i in 0..<full_extension.length() {
    if full_extension.code_unit_at(i).to_int() == 46 &&
      i + 1 < full_extension.length() {
      secondary.push(full_extension[i + 1:full_extension.length()].to_string())
    }
  }
  secondary
}

///|
fn typed_asset_loader_entry_supports_extension(
  entry : TypedAssetLoaderEntry,
  extension : String,
) -> Bool {
  let normalized = typed_asset_loader_normalize_extension(extension)
  if normalized == "" {
    return false
  }
  entry.extensions.contains(normalized)
}

///|
fn typed_asset_loader_warn_duplicate_extensions(
  type_name : String,
  existing : Array[TypedAssetLoaderEntry],
  next_extensions : Array[String],
) -> Unit {
  let duplicates : Array[String] = []
  for extension in next_extensions {
    let mut duplicated = false
    for entry in existing {
      if typed_asset_loader_entry_supports_extension(entry, extension) {
        duplicated = true
        break
      }
    }
    if duplicated {
      duplicates.push(extension)
    }
  }
  if duplicates.length() > 0 {
    println(
      "Warning: duplicate typed asset loader extensions for \{type_name}: \{duplicates}; explicit loader metadata is required to disambiguate",
    )
  }
}

///|
fn typed_asset_loader_entry_for_path(
  registry : Ref[@hashmap.HashMap[String, Array[TypedAssetLoaderEntry]]],
  type_name : String,
  path : AssetPath,
) -> TypedAssetLoaderEntry? {
  guard registry.val.get(type_name) is Some(entries) else { return None }
  if entries.length() == 0 {
    return None
  }
  if entries.length() == 1 {
    return Some(entries[0])
  }

  fn search_entries_by_extension(
    entries : Array[TypedAssetLoaderEntry],
    extension : String,
  ) -> TypedAssetLoaderEntry? {
    for offset in 0..<entries.length() {
      let index = entries.length() - 1 - offset
      let entry = entries[index]
      if typed_asset_loader_entry_supports_extension(entry, extension) {
        return Some(entry)
      }
    }
    None
  }

  match typed_asset_loader_full_extension(path) {
    Some(full_extension) => {
      if search_entries_by_extension(entries, full_extension) is Some(entry) {
        return Some(entry)
      }
      for secondary in typed_asset_loader_secondary_extensions(full_extension) {
        if search_entries_by_extension(entries, secondary) is Some(entry) {
          return Some(entry)
        }
      }
    }
    None => ()
  }

  println(
    "Warning: multiple typed asset loaders found for \{type_name} at path \{asset_format_path(path)}; using latest registered loader",
  )
  Some(entries[entries.length() - 1])
}

///|
fn[T] asset_assets_mut_or_abort() -> @ecs.ResourceMut[Assets[T]] {
  asset_assets_mut_or_abort_in_world(asset_world_or_abort())
}

///|
fn[T] asset_assets_mut_or_abort_in_world(
  world : @ecs.World,
) -> @ecs.ResourceMut[Assets[T]] {
  let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
  match (try! world.get_resource_mut(key)) {
    Some(value) => value
    None =>
      abort(
        "Assets resource is missing for custom asset loading; call init_asset before loading this asset type",
      )
  }
}

///|
pub fn[T] LoadContext::add_labeled_asset(
  self : LoadContext,
  label : String,
  asset : T,
) -> Handle[T] {
  guard self.world is Some(world) else {
    abort("LoadContext::add_labeled_asset requires a world-backed load context")
  }
  let labeled_path = self.path.with_label(Some(label))
  let formatted_path = asset_format_path(labeled_path)
  let canonical_path = asset_canonical_path(formatted_path)
  let handle = asset_assets_mut_or_abort_in_world(world).modify(fn(assets) {
    assets.add(asset)
  })
  self.asset_server.record_path(canonical_path)
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let cache_key = typed_asset_loader_path_key(type_name, labeled_path)
  self.asset_server.typed_asset_paths.val.set(cache_key, handle.id())
  self.asset_server.set_typed_loaded_states(type_name, handle.id())
  handle
}

///|
fn[T, P : IntoAssetPath] AssetServer::load_registered_asset(
  self : AssetServer,
  path : P,
) -> Handle[T] {
  fn pending_processed_contains(
    asset_server : AssetServer,
    type_name : String,
    handle_id : Int,
    path : AssetPath,
  ) -> Bool {
    for pending in asset_server.pending_processed_asset_loads.val {
      if pending.type_name == type_name &&
        pending.handle_id == handle_id &&
        pending.path == path {
        return true
      }
    }
    false
  }

  fn pending_typed_contains(
    asset_server : AssetServer,
    type_name : String,
    handle_id : Int,
    path : AssetPath,
  ) -> Bool {
    for pending in asset_server.pending_typed_asset_loads.val {
      if pending.type_name == type_name &&
        pending.handle_id == handle_id &&
        pending.path == path {
        return true
      }
    }
    false
  }

  fn queue_registered_load(
    asset_server : AssetServer,
    type_name : String,
    handle : Handle[T],
    path : AssetPath,
  ) -> Unit {
    if asset_should_process_registered_asset(asset_server, type_name, path) {
      if !pending_processed_contains(asset_server, type_name, handle.id(), path) {
        asset_server.pending_processed_asset_loads.val.push(PendingProcessedAssetLoad::{
          type_name,
          handle_id: handle.id(),
          path,
        })
      }
    } else if !pending_typed_contains(
        asset_server,
        type_name,
        handle.id(),
        path,
      ) {
      asset_server.pending_typed_asset_loads.val.push(PendingTypedAssetLoad::{
        type_name,
        handle_id: handle.id(),
        path,
      })
    }
  }

  let parsed_path = path.into_asset_path()
  let formatted_path = asset_format_path(parsed_path)
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let cache_key = typed_asset_loader_path_key(type_name, parsed_path)
  if self.typed_asset_paths.val.get(cache_key) is Some(handle_id) {
    let handle = Handle::new(handle_id)
    if !asset_assets_ref_or_abort().contains(handle) {
      self.set_typed_loading_states(type_name, handle.id())
      queue_registered_load(self, type_name, handle, parsed_path)
    } else {
      self.set_typed_loaded_states(type_name, handle.id())
    }
    return handle
  }
  let _assets : Assets[T] = asset_assets_ref_or_abort()
  let handle : Handle[T] = Handle::new(
    self.reserve_typed_asset_handle_id(type_name),
  )
  self.set_typed_loading_states(type_name, handle.id())
  self.record_path(asset_canonical_path(formatted_path))
  self.typed_asset_paths.val.set(cache_key, handle.id())
  queue_registered_load(self, type_name, handle, parsed_path)
  handle
}

///|
pub fn[T] init_asset(
  app : @app.App[@ecs.World],
  asset_init : () -> T,
) -> @app.App[@ecs.World] {
  asset_init() |> ignore
  let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
  let event_key : @ecs.MessageKey[AssetEvent[T]] = @ecs.Message::message()
  let load_failed_key : @ecs.MessageKey[AssetLoadFailedEvent[T]] = @ecs.Message::message()
  let assets : Assets[T] = Assets::new()
  app
  .insert_world_resource(key, assets)
  .allow_ambiguous_resource(key~)
  .add_message(event_key)
  .add_message(load_failed_key)
}

///|
pub fn[T] register_asset_loader(
  app : @app.App[@ecs.World],
  loader : AssetLoader[T],
) -> @app.App[@ecs.World] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let registry = typed_asset_loader_registry_for_world(app.world())
  let normalized_extensions = typed_asset_loader_normalize_extensions(
    loader.extensions,
  )
  let existing = match registry.val.get(type_name) {
    Some(entries) => entries
    None => []
  }
  typed_asset_loader_warn_duplicate_extensions(
    type_name, existing, normalized_extensions,
  )
  let next_entries = typed_asset_loader_clone_entries(existing)
  next_entries.push(TypedAssetLoaderEntry::{
    extensions: normalized_extensions,
    load: fn(context, bytes) { @any.of((loader.load)(context, bytes)) },
    insert: fn(world, handle_id, value_any) {
      let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
      let assets = match (try! world.get_resource_mut(key)) {
        Some(value) => value
        None =>
          abort(
            "Assets resource is missing for custom loader insertion; call init_asset before registering or loading this asset type",
          )
      }
      let value : T = match value_any.try_to() {
        Some(value) => value
        None =>
          abort(
            "typed asset loader returned a mismatched asset value for \{type_name}",
          )
      }
      ignore(
        assets.modify(fn(store) {
          let handle = Handle::new(handle_id)
          store.push_event(AssetEvent::LoadedWithDependencies(handle))
          store.insert(handle, value)
        }),
      )
    },
  })
  registry.val.set(type_name, next_entries)
  app
}

///|
pub fn[T] init_asset_loader(
  app : @app.App[@ecs.World],
  loader : AssetLoader[T],
) -> @app.App[@ecs.World] {
  register_asset_loader(app, loader)
}

///|
pub fn[T] AssetServer::add(self : AssetServer, asset : T) -> Handle[T] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let handle : Handle[T] = Handle::new(
    self.reserve_typed_asset_handle_id(type_name),
  )
  ignore(
    asset_assets_mut_or_abort().modify(fn(assets) {
      assets.insert(handle, asset)
    }),
  )
  self.set_typed_loaded_states(type_name, handle.id())
  handle
}

///|
pub fn[P : IntoAssetPath] AssetServer::load_image_direct(
  self : AssetServer,
  path : P,
  bytes : Bytes,
) -> Image {
  let parsed_path = path.into_asset_path()
  let canonical_path = asset_canonical_path(asset_format_path(parsed_path))
  let settings = self.image_loader_settings_for_path(canonical_path)
  match
    image_from_loaded_texture_bytes(
      canonical_path,
      bytes,
      settings.is_srgb,
      settings.format,
      settings.texture_format,
    ) {
    Some(image) => image
    None =>
      abort(
        "Failed to decode image asset bytes for \{asset_format_path(parsed_path)}",
      )
  }
}

///|
pub fn[T, P : IntoAssetPath] AssetServer::load_direct(
  self : AssetServer,
  path : P,
  bytes : Bytes,
) -> T {
  asset_with_server_world(self, fn() {
    let parsed_path = path.into_asset_path()
    let probe : Assets[T] = Assets::new()
    let type_name = @any.of(probe).type_name()
    let registry = typed_asset_loader_registry_active()

    let context = match asset_current_world() {
      Some(world) => LoadContext::new(world, self, parsed_path)
      None => LoadContext::new_detached(self, parsed_path)
    }

    match typed_asset_loader_entry_for_path(registry, type_name, parsed_path) {
      Some(entry) =>
        match (entry.load)(context, bytes).try_to() {
          Some(value) => value
          None =>
            abort(
              "typed asset loader returned a mismatched asset value for \{type_name}",
            )
        }
      None =>
        abort(
          "No typed asset loader is registered for \{type_name}; register the loader before calling AssetServer::load_direct",
        )
    }
  })
}

///|
fn asset_process_pending_typed_asset_loads(
  world : @ecs.World,
  asset_server : AssetServer,
) -> Unit {
  let remaining : Array[PendingTypedAssetLoad] = []
  let registry = typed_asset_loader_registry_for_world(world)
  for pending in asset_server.pending_typed_asset_loads.val {
    match
      typed_asset_loader_entry_for_path(
        registry,
        pending.type_name,
        pending.path,
      ) {
      Some(entry) => {
        let formatted_path = asset_format_path(pending.path)
        let bytes = load_asset_file_bytes(asset_canonical_path(formatted_path))
        let value_any = (entry.load)(
          LoadContext::new(world, asset_server, pending.path),
          bytes,
        )
        (entry.insert)(world, pending.handle_id, value_any)
        asset_server.set_typed_loaded_states(
          pending.type_name,
          pending.handle_id,
        )
      }
      None => remaining.push(pending)
    }
  }
  asset_server.pending_typed_asset_loads.val = remaining
}
