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
  load : (LoadContext, Bytes) -> @any.Any
  insert : (@ecs.World, Int, @any.Any) -> Unit
}

///|
let typed_asset_loader_registry : Ref[
  @hashmap.HashMap[String, TypedAssetLoaderEntry],
] = Ref::new(@hashmap.HashMap::new())

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
fn[T] asset_assets_mut_or_init() -> @ecs.ResourceMut[Assets[T]] {
  asset_assets_mut_or_init_in_world(asset_world_or_abort())
}

///|
fn[T] asset_assets_mut_or_init_in_world(
  world : @ecs.World,
) -> @ecs.ResourceMut[Assets[T]] {
  let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, Assets::new())
  }
  match (try! world.get_resource_mut(key)) {
    Some(value) => value
    None =>
      abort("Failed to initialize Assets resource for custom asset loading")
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
  let handle = asset_assets_mut_or_init_in_world(world).modify(fn(assets) {
    assets.add(asset)
  })
  self.asset_server.record_path(canonical_path)
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let cache_key = typed_asset_loader_path_key(type_name, labeled_path)
  self.asset_server.typed_asset_paths.val.set(cache_key, handle.id())
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
    } else if !pending_typed_contains(asset_server, type_name, handle.id(), path) {
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
      queue_registered_load(self, type_name, handle, parsed_path)
    }
    return handle
  }
  let handle = asset_assets_mut_or_init().modify(fn(assets) {
    assets.reserve_handle()
  })
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
pub fn[T] register_asset_loader(
  app : @app.App[@ecs.World],
  loader : AssetLoader[T],
) -> @app.App[@ecs.World] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  typed_asset_loader_registry.val.set(type_name, TypedAssetLoaderEntry::{
    load: fn(context, bytes) { @any.of((loader.load)(context, bytes)) },
    insert: fn(world, handle_id, value_any) {
      let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
      if (try! world.get_resource(key)) is None {
        world.insert_resource(key, Assets::new())
      }
      let assets = match (try! world.get_resource_mut(key)) {
        Some(value) => value
        None =>
          abort(
            "Failed to initialize Assets resource for custom loader insertion",
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
pub fn[T] init_asset_loader(
  app : @app.App[@ecs.World],
  loader : AssetLoader[T],
) -> @app.App[@ecs.World] {
  register_asset_loader(app, loader)
}

///|
pub fn[T] AssetServer::add(self : AssetServer, asset : T) -> Handle[T] {
  self |> ignore
  asset_assets_mut_or_init().modify(fn(assets) { assets.add(asset) })
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
  let parsed_path = path.into_asset_path()
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()

  match typed_asset_loader_registry.val.get(type_name) {
    Some(entry) =>
      match
        (entry.load)(LoadContext::new_detached(self, parsed_path), bytes).try_to() {
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
}

///|
fn asset_process_pending_typed_asset_loads(
  world : @ecs.World,
  asset_server : AssetServer,
) -> Unit {
  let remaining : Array[PendingTypedAssetLoad] = []
  for pending in asset_server.pending_typed_asset_loads.val {
    match typed_asset_loader_registry.val.get(pending.type_name) {
      Some(entry) => {
        let formatted_path = asset_format_path(pending.path)
        let bytes = load_asset_file_bytes(asset_canonical_path(formatted_path))
        let value_any = (entry.load)(
          LoadContext::new(world, asset_server, pending.path),
          bytes,
        )
        (entry.insert)(world, pending.handle_id, value_any)
      }
      None => remaining.push(pending)
    }
  }
  asset_server.pending_typed_asset_loads.val = remaining
}
