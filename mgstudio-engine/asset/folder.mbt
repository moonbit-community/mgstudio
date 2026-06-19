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
pub struct LoadedFolder {
  handles : Array[Handle[Image]]
}

///|
struct PendingLoadedFolderLoad {
  handle_id : Int
  handles : Array[Handle[Image]]
}

///|
pub impl Asset for LoadedFolder with fn asset_debug_name() {
  "mgstudio_asset::LoadedFolder"
}

///|
pub impl Asset for LoadedFolder with fn asset_as_image(_self) {
  None
}

///|
pub let loaded_folder_asset_resource_keys : AssetResourceKeys[LoadedFolder] = register_asset_resource_keys(
  "mgstudio_asset::LoadedFolder",
)

///|
pub impl Asset for LoadedFolder with fn asset_resource_keys() {
  loaded_folder_asset_resource_keys
}

///|
pub let loaded_folder_assets_resource_key : @ecs.ResourceKey[
  Assets[LoadedFolder],
] = registered_assets_resource_key()

///|
fn folder_collect_image_asset_paths_recursive(
  source_name : String?,
  relative_path : String,
  virtual_path : String,
  out : Array[String],
) -> Unit {
  if !asset_path_is_directory(virtual_path) {
    return
  }
  let entries = asset_read_directory_entries(virtual_path)
  for entry_name in entries {
    let child_relative = @path.Path::join(relative_path, entry_name).to_string()
    let child_virtual = compose_virtual_asset_path(
      source_name,
      child_relative,
      None,
    )
    if asset_path_is_directory(child_virtual) {
      folder_collect_image_asset_paths_recursive(
        source_name, child_relative, child_virtual, out,
      )
      continue
    }
    if loader_kind_for_path(path=child_virtual) == LOADER_KIND_TEXTURE {
      out.push(child_virtual)
    }
  }
}

///|
fn folder_collect_image_asset_paths(path : String) -> Array[String] {
  let parsed = parse_virtual_asset_path(path)
  let folder_virtual = compose_virtual_asset_path(
    parsed.source_name,
    parsed.relative_path,
    None,
  )
  let paths : Array[String] = []
  folder_collect_image_asset_paths_recursive(
    parsed.source_name,
    parsed.relative_path,
    folder_virtual,
    paths,
  )
  paths
}

///|
fn AssetServer::enqueue_loaded_folder(
  self : AssetServer,
  handle : Handle[LoadedFolder],
  handles : Array[Handle[Image]],
) -> Unit {
  for pending in self.pending_loaded_folder_loads {
    if pending.handle_id == handle.id() {
      return
    }
  }
  self.pending_loaded_folder_loads.push(PendingLoadedFolderLoad::{
    handle_id: handle.id(),
    handles,
  })
}

///|
pub fn AssetServer::load_folder(
  self : AssetServer,
  path : String,
) -> Handle[LoadedFolder] {
  asset_with_server_world(self, fn() {
    let parsed_path = asset_parse_path(path)
    let canonical_path = asset_canonical_path(asset_format_path(parsed_path))
    let type_name = assets_type_name((None : LoadedFolder?))
    if !self.unapproved_asset_load_allowed(parsed_path, false) {
      return self.reserve_unapproved_path_handle(parsed_path, type_name)
    }
    let cache_key = typed_asset_loader_path_key(type_name, parsed_path)
    if self.typed_asset_paths.get(cache_key) is Some(handle_id) {
      return Handle::new(handle_id)
    }
    let handle : Handle[LoadedFolder] = Handle::new(
      self.reserve_typed_asset_handle_id(type_name),
    )
    self.set_typed_loading_states(type_name, handle.id())
    self.typed_asset_paths.set(cache_key, handle.id())
    self.record_path(canonical_path)
    let handles : Array[Handle[Image]] = []
    for image_path in folder_collect_image_asset_paths(canonical_path) {
      handles.push(self.load_image(image_path))
    }
    self.enqueue_loaded_folder(handle, handles)
    handle
  })
}

///|
fn loaded_folder_assets_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[Assets[LoadedFolder]] {
  match world.get_resource_mut(loaded_folder_assets_resource_key) {
    Some(assets) => assets
    None =>
      abort(
        "LoadedFolder assets resource is missing; AssetPlugin must initialize Assets<LoadedFolder> before folder polling runs",
      )
  }
}

///|
fn loaded_folder_assets_or_abort(world : @ecs.World) -> Assets[LoadedFolder] {
  match world.get_resource(loaded_folder_assets_resource_key) {
    Some(assets) => assets
    None =>
      abort(
        "LoadedFolder assets resource is missing; AssetPlugin must initialize Assets<LoadedFolder> before folder polling runs",
      )
  }
}

///|
pub fn asset_get_loaded_folder(handle : Handle[LoadedFolder]) -> LoadedFolder? {
  match asset_current_world() {
    Some(world) => loaded_folder_assets_or_abort(world).get(handle)
    None =>
      abort(
        "LoadedFolder lookups require an active app world; query the world-owned Assets<LoadedFolder> resource directly outside scheduled systems",
      )
  }
}

///|
pub fn asset_loaded_folder_drain_events() -> Array[AssetEvent[LoadedFolder]] {
  match asset_current_world() {
    Some(world) =>
      loaded_folder_assets_mut_or_abort(world).modify(fn(assets) {
        assets.drain_events()
      })
    None =>
      abort(
        "LoadedFolder events require an active app world; query the world-owned Assets<LoadedFolder> resource directly outside scheduled systems",
      )
  }
}

///|
pub fn asset_update_loaded_folders(world : @ecs.World) -> Unit {
  guard world.get_resource(asset_server_resource_key) is Some(asset_server) else {
    return
  }
  let assets = loaded_folder_assets_mut_or_abort(world)
  let type_name = assets_type_name((None : LoadedFolder?))
  let remaining : Array[PendingLoadedFolderLoad] = []
  assets.modify(fn(store) {
    for pending in asset_server.pending_loaded_folder_loads {
      let mut loaded = true
      let mut failed : String? = None
      for image in pending.handles {
        match asset_server.load_state(image) {
          LoadState::Failed(error) => {
            loaded = false
            failed = Some(error)
            break
          }
          _ =>
            if !asset_server.is_loaded_with_dependencies(image) {
              loaded = false
              break
            }
        }
      }
      let handle : Handle[LoadedFolder] = Handle::new(pending.handle_id)
      match failed {
        Some(error) =>
          asset_server.set_typed_failed_states(
            type_name,
            handle.id(),
            "Failed to load folder dependency: \{error}",
          )
        None =>
          if loaded {
            store.push_event(LoadedWithDependencies(handle))
            store.insert(handle, LoadedFolder::{ handles: pending.handles })
            |> ignore
            asset_server.set_typed_loaded_states(type_name, handle.id())
          } else {
            remaining.push(pending)
          }
      }
    }
  })
  asset_server.pending_loaded_folder_loads.clear()
  for pending in remaining {
    asset_server.pending_loaded_folder_loads.push(pending)
  }
}
