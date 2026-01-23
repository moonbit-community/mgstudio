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
  host_id : Int
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
pub fn host_asset_poll_loaded_folder_events() -> String = "mgstudio_host" "asset_poll_loaded_folder_events"

///|
pub fn host_asset_get_loaded_folder_handles(folder_id : Int) -> String = "mgstudio_host" "asset_get_loaded_folder_handles"

///|
let loaded_folder_assets : Ref[Assets[LoadedFolder]] = Ref::new(Assets::new())

///|
let loaded_folder_host_map : Ref[Array[(Int, Handle[LoadedFolder])]] = Ref::new([],
)

///|
fn loaded_folder_handle_for_host(host_id : Int) -> Handle[LoadedFolder]? {
  let count = loaded_folder_host_map.val.length()
  for i in 0..<count {
    let entry = loaded_folder_host_map.val[i]
    if entry.0 == host_id {
      return Some(entry.1)
    }
  }
  None
}

///|
fn parse_csv_ints(text : String) -> Array[Int] {
  let values : Array[Int] = []
  let mut current = 0
  let mut has_value = false
  let mut negative = false
  let count = text.length()
  for i in 0..<count {
    let code = text.code_unit_at(i).to_int()
    if code == 45 { // '-'
      negative = true
    } else if code >= 48 && code <= 57 {
      current = current * 10 + (code - 48)
      has_value = true
    } else if code == 44 { // ','
      if has_value {
        let value = if negative { 0 - current } else { current }
        values.push(value)
        current = 0
        has_value = false
        negative = false
      }
    }
  }
  if has_value {
    let value = if negative { 0 - current } else { current }
    values.push(value)
  }
  values
}

///|
fn loaded_folder_update(
  handle : Handle[LoadedFolder],
  handles : Array[Handle[Image]],
) -> Unit {
  if loaded_folder_assets.val.get(handle) is Some(folder) {
    let updated = LoadedFolder::{ host_id: folder.host_id, handles }
    loaded_folder_assets.val.set(handle, updated) |> ignore
  }
}

///|
pub fn AssetServer::load_folder(
  self : AssetServer,
  path : String,
) -> Handle[LoadedFolder] {
  let host_id = host_asset_load_folder(path)
  let handle = loaded_folder_assets.val.add(LoadedFolder::{
    host_id,
    handles: [],
  })
  loaded_folder_host_map.val.push((host_id, handle))
  self.paths.push(path)
  handle
}

///|
pub fn asset_get_loaded_folder(handle : Handle[LoadedFolder]) -> LoadedFolder? {
  loaded_folder_assets.val.get(handle)
}

///|
pub fn asset_events_for_loaded_folder() -> Array[AssetEvent[LoadedFolder]] {
  let raw_events = parse_csv_ints(host_asset_poll_loaded_folder_events())
  let events : Array[AssetEvent[LoadedFolder]] = []
  let mut i = 0
  while i + 1 < raw_events.length() {
    let kind = raw_events[i]
    let host_id = raw_events[i + 1]
    i = i + 2
    let handle_opt = loaded_folder_handle_for_host(host_id)
    if handle_opt is None {
      continue
    }
    let handle = if handle_opt is Some(value) { value } else { continue }
    if kind == 3 {
      let image_ids = parse_csv_ints(
        host_asset_get_loaded_folder_handles(host_id),
      )
      let handles : Array[Handle[Image]] = []
      for image_id in image_ids {
        handles.push(Handle::new(image_id))
      }
      loaded_folder_update(handle, handles)
      events.push(LoadedWithDependencies(handle))
    } else if kind == 0 {
      events.push(Added(handle))
    } else if kind == 1 {
      events.push(Modified(handle))
    } else if kind == 2 {
      events.push(Removed(handle))
    }
  }
  events
}
