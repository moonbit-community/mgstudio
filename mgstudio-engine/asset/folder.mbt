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
pub(all) enum AssetEvent[T] {
  Added(Handle[T])
  Modified(Handle[T])
  Removed(Handle[T])
  LoadedWithDependencies(Handle[T])
}

///|
pub fn host_asset_load_folder(path : String) -> Int = "mgstudio_host" "asset_load_folder"

///|
pub fn host_asset_poll_loaded_folder_event_kind() -> Int = "mgstudio_host" "asset_poll_loaded_folder_event_kind"

///|
pub fn host_asset_poll_loaded_folder_event_id() -> Int = "mgstudio_host" "asset_poll_loaded_folder_event_id"

///|
pub fn host_asset_loaded_folder_handles_len(folder_id : Int) -> Int = "mgstudio_host" "asset_loaded_folder_handles_len"

///|
pub fn host_asset_loaded_folder_handles_get(
  folder_id : Int,
  index : Int,
) -> Int = "mgstudio_host" "asset_loaded_folder_handles_get"

///|
let loaded_folder_assets : Ref[Assets[LoadedFolder]] = Ref::new(Assets::new())

///|
let loaded_folder_events : Ref[Array[AssetEvent[LoadedFolder]]] = Ref::new([])

///|
pub fn AssetServer::load_folder(
  self : AssetServer,
  path : String,
) -> Handle[LoadedFolder] {
  let host_id = host_asset_load_folder(path)
  self.paths.push(path)
  Handle::new(host_id)
}

///|
pub fn asset_get_loaded_folder(handle : Handle[LoadedFolder]) -> LoadedFolder? {
  loaded_folder_assets.val.get(handle)
}

///|
pub fn asset_loaded_folder_drain_events() -> Array[AssetEvent[LoadedFolder]] {
  let out : Array[AssetEvent[LoadedFolder]] = []
  for ev in loaded_folder_events.val {
    out.push(ev)
  }
  loaded_folder_events.val.clear()
  out
}

///|
pub fn asset_update_loaded_folders() -> Unit {
  // Ensure any leftover internal asset events don't leak between frames.
  loaded_folder_assets.val.drain_events() |> ignore
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
          Handle::new(host_asset_loaded_folder_handles_get(host_id, j)),
        )
      }
      loaded_folder_assets.val.insert(handle, LoadedFolder::{ handles, })
      |> ignore
      for ev in loaded_folder_assets.val.drain_events() {
        loaded_folder_events.val.push(ev)
      }
      loaded_folder_events.val.push(LoadedWithDependencies(handle))
    } else if kind == 0 {
      loaded_folder_assets.val.insert(handle, LoadedFolder::{ handles: [] })
      |> ignore
      for ev in loaded_folder_assets.val.drain_events() {
        loaded_folder_events.val.push(ev)
      }
    } else if kind == 1 {
      let n = host_asset_loaded_folder_handles_len(host_id)
      let handles : Array[Handle[Image]] = []
      for j in 0..<n {
        handles.push(
          Handle::new(host_asset_loaded_folder_handles_get(host_id, j)),
        )
      }
      loaded_folder_assets.val.insert(handle, LoadedFolder::{ handles, })
      |> ignore
      for ev in loaded_folder_assets.val.drain_events() {
        loaded_folder_events.val.push(ev)
      }
    } else if kind == 2 {
      loaded_folder_assets.val.remove(handle) |> ignore
      for ev in loaded_folder_assets.val.drain_events() {
        loaded_folder_events.val.push(ev)
      }
    }
  }
}
