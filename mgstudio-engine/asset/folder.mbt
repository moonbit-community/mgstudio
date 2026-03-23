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
pub fn loaded_folder_assets_resource_key() -> @ecs.ResourceKey[
  Assets[LoadedFolder],
] {
  registered_assets_resource_key()
}

///|
pub(all) enum AssetEvent[T] {
  Added(Handle[T])
  Modified(Handle[T])
  Removed(Handle[T])
  LoadedWithDependencies(Handle[T])
}

///|
pub fn host_asset_load_folder(path~ : String) -> Int {
  load_folder(path~)
}

///|
pub fn host_asset_poll_loaded_folder_event_kind() -> Int {
  poll_loaded_folder_event_kind()
}

///|
pub fn host_asset_poll_loaded_folder_event_id() -> Int {
  poll_loaded_folder_event_id()
}

///|
pub fn host_asset_loaded_folder_handles_len(folder_id : Int) -> Int {
  loaded_folder_handles_len(folder_id)
}

///|
pub fn host_asset_loaded_folder_handles_get(
  folder_id~ : Int,
  index~ : Int,
) -> Int {
  loaded_folder_handles_get(folder_id~, index~)
}

///|

///|
pub fn AssetServer::load_folder(
  self : AssetServer,
  path : String,
) -> Handle[LoadedFolder] {
  let canonical_path = asset_canonical_path(path)
  let host_id = host_asset_load_folder(path=canonical_path)
  self.record_path(canonical_path)
  let handle = Handle::new(host_id)
  handle
}

///|
fn loaded_folder_assets_mut_or_abort(
  world : @ecs.World,
) -> Ref[Assets[LoadedFolder]] {
  match (try! world.get_resource_ref_mut(loaded_folder_assets_resource_key())) {
    Some(assets) => assets
    None =>
      abort(
        "LoadedFolder assets resource is missing; AssetPlugin must initialize Assets<LoadedFolder> before folder polling runs",
      )
  }
}

///|
fn loaded_folder_assets_or_abort(world : @ecs.World) -> Assets[LoadedFolder] {
  match (try! world.get_resource(loaded_folder_assets_resource_key())) {
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
    Some(world) => loaded_folder_assets_mut_or_abort(world).val.drain_events()
    None =>
      abort(
        "LoadedFolder events require an active app world; query the world-owned Assets<LoadedFolder> resource directly outside scheduled systems",
      )
  }
}

///|
pub fn asset_update_loaded_folders(world : @ecs.World) -> Unit {
  let assets_ref = loaded_folder_assets_mut_or_abort(world)
  // Ensure any leftover internal asset events don't leak between frames.
  assets_ref.val.drain_events() |> ignore
  while true {
    let kind = host_asset_poll_loaded_folder_event_kind()
    if kind < 0 {
      break
    }
    let host_id = host_asset_poll_loaded_folder_event_id()
    let handle = Handle::new(host_id)
    if kind == 3 {
      let n = host_asset_loaded_folder_handles_len(host_id)
      let handles : Array[Handle[Image]] = []
      for j in 0..<n {
        handles.push(
          Handle::new(
            host_asset_loaded_folder_handles_get(folder_id=host_id, index=j),
          ),
        )
      }
      assets_ref.val.insert(handle, LoadedFolder::{ handles, }) |> ignore
      assets_ref.val.push_event(LoadedWithDependencies(handle))
    } else if kind == 0 {
      assets_ref.val.insert(handle, LoadedFolder::{ handles: [] }) |> ignore
    } else if kind == 1 {
      let n = host_asset_loaded_folder_handles_len(host_id)
      let handles : Array[Handle[Image]] = []
      for j in 0..<n {
        handles.push(
          Handle::new(
            host_asset_loaded_folder_handles_get(folder_id=host_id, index=j),
          ),
        )
      }
      assets_ref.val.insert(handle, LoadedFolder::{ handles, }) |> ignore
    } else if kind == 2 {
      assets_ref.val.remove(handle) |> ignore
    }
  }
}
