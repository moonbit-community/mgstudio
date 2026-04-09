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
// Bevy source: `bevy/crates/bevy_asset/src/loader.rs`.
pub(all) enum AssetLoaderKind {
  Texture
  Wgsl
  Bytes
  Font
  Folder
}

///|
const NATIVE_LOADER_KIND_TEXTURE : Int = 0

///|
const NATIVE_LOADER_KIND_WGSL : Int = 1

///|
const NATIVE_LOADER_KIND_BYTES : Int = 2

///|
const NATIVE_LOADER_KIND_FONT : Int = 3

///|
const NATIVE_LOADER_KIND_FOLDER : Int = 4

///|
type AssetReloadHook = (@ecs.World, AssetServer, String) -> Unit

///|
fn[T] asset_loader_type_name(probe : Handle[T]) -> String {
  @any.of(probe).type_name()
}

///|
pub fn asset_register_reload_hook(
  hook : (@ecs.World, AssetServer, String) -> Unit,
) -> Unit {
  asset_reload_hook_registry.push(hook)
}

///|
pub fn[T] asset_register_loader(
  load : (AssetServer, String) -> Handle[T],
) -> Unit {
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  asset_loader_registry.val.set(type_name, AssetLoaderEntry::{
    load: fn(asset_server, path) { @any.of(load(asset_server, path)) },
  })
}

///|
pub fn[T] asset_register_ready_checker(
  check_ready : (@ecs.World, Handle[T]) -> Bool,
) -> Unit {
  let probe : Handle[T] = Handle::new(0)
  let type_name = asset_loader_type_name(probe)
  asset_ready_checker_registry.val.set(type_name, fn(world, handle_id) {
    check_ready(world, Handle::new(handle_id))
  })
}

///|
fn asset_loader_kind_to_raw(kind : AssetLoaderKind) -> Int {
  match kind {
    AssetLoaderKind::Texture => NATIVE_LOADER_KIND_TEXTURE
    AssetLoaderKind::Wgsl => NATIVE_LOADER_KIND_WGSL
    AssetLoaderKind::Bytes => NATIVE_LOADER_KIND_BYTES
    AssetLoaderKind::Font => NATIVE_LOADER_KIND_FONT
    AssetLoaderKind::Folder => NATIVE_LOADER_KIND_FOLDER
  }
}

///|
fn asset_loader_kind_from_raw(raw : Int) -> AssetLoaderKind {
  if raw == NATIVE_LOADER_KIND_TEXTURE {
    return AssetLoaderKind::Texture
  }
  if raw == NATIVE_LOADER_KIND_WGSL {
    return AssetLoaderKind::Wgsl
  }
  if raw == NATIVE_LOADER_KIND_FONT {
    return AssetLoaderKind::Font
  }
  if raw == NATIVE_LOADER_KIND_FOLDER {
    return AssetLoaderKind::Folder
  }
  AssetLoaderKind::Bytes
}

///|
pub fn[P : IntoAssetPath] load_asset_source_bytes(path : P) -> Bytes {
  let parsed = path.into_asset_path()
  load_asset_file_bytes(asset_canonical_path(asset_format_path(parsed)))
}

///|
pub fn[P : IntoAssetPath] load_optional_asset_source_text(path : P) -> String? {
  let parsed = path.into_asset_path()
  load_optional_asset_text(asset_canonical_path(asset_format_path(parsed)))
}

///|
pub fn asset_register_loader_extension(
  extension : String,
  kind : AssetLoaderKind,
) -> Unit {
  host_asset_register_loader_extension(
    extension~,
    kind=asset_loader_kind_to_raw(kind),
  )
}

///|
pub fn asset_remove_loader_extension(extension : String) -> Unit {
  host_asset_remove_loader_extension(extension~)
}

///|
pub fn asset_loader_kind_for_path(path : String) -> AssetLoaderKind {
  asset_loader_kind_from_raw(host_asset_loader_kind_for_path(path~))
}

///|
pub fn asset_set_default_sampler_nearest(enabled : Bool) -> Unit {
  asset_server_or_abort().default_sampler_nearest.val = enabled
}
