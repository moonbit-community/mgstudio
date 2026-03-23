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
  load : (AssetServer, AssetPath, Bytes) -> T
}

///|
priv struct TypedAssetLoaderEntry {
  load : (AssetServer, AssetPath, Bytes) -> @any.Any
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
  AssetLoader::{ extensions, load }
}

///|
fn typed_asset_loader_path_key(type_name : String, path : AssetPath) -> String {
  type_name + "::" + asset_canonical_path(asset_format_path(path))
}

///|
fn[T] asset_assets_ref_mut_or_init() -> Ref[Assets[T]] {
  let world = asset_world_or_abort()
  let key : @ecs.ResourceKey[Assets[T]] = assets_resource_key()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, Assets::new())
  }
  match (try! world.get_resource_ref_mut(key)) {
    Some(value) => value
    None =>
      abort("Failed to initialize Assets resource for custom asset loading")
  }
}

///|
fn[T, P : IntoAssetPath] AssetServer::load_registered_asset(
  self : AssetServer,
  path : P,
) -> Handle[T] {
  let parsed_path = path.into_asset_path()
  let formatted_path = asset_format_path(parsed_path)
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let cache_key = typed_asset_loader_path_key(type_name, parsed_path)
  if self.typed_asset_paths.val.get(cache_key) is Some(handle_id) {
    return Handle::new(handle_id)
  }
  let bytes = load_asset_file_bytes(asset_canonical_path(formatted_path))
  let value : T = self.load_direct(parsed_path, bytes)
  let handle = self.add(value)
  self.record_path(asset_canonical_path(formatted_path))
  self.typed_asset_paths.val.set(cache_key, handle.id())
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
    load: fn(asset_server, path, bytes) {
      @any.of((loader.load)(asset_server, path, bytes))
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
  let assets_ref : Ref[Assets[T]] = asset_assets_ref_mut_or_init()
  assets_ref.val.add(asset)
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
  match image_from_loaded_texture_bytes(bytes, settings.is_srgb) {
    Some(image) => image
    None =>
      abort(
        "Failed to decode image asset bytes for " +
        asset_format_path(parsed_path),
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
      match (entry.load)(self, parsed_path, bytes).try_to() {
        Some(value) => value
        None =>
          abort(
            "typed asset loader returned a mismatched asset value for " +
            type_name,
          )
      }
    None =>
      abort(
        "No typed asset loader is registered for " +
        type_name +
        "; register the loader before calling AssetServer::load_direct",
      )
  }
}
