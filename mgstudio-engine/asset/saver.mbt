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
pub struct Writer {
  buffer : Array[Byte]
}

///|
pub(all) suberror AssetSaveError {
  Message(String)
}

///|
pub fn AssetSaveError::message(self : AssetSaveError) -> String {
  match self {
    Message(message) => message
  }
}

///|
pub fn Writer::new() -> Writer {
  Writer::{ buffer: [] }
}

///|
pub fn Writer::write_all(self : Writer, bytes : Bytes) -> Unit {
  for byte in bytes {
    self.buffer.push(byte)
  }
}

///|
pub fn Writer::finish(self : Writer) -> Bytes {
  Bytes::from_array(self.buffer)
}

///|
pub struct SavedAsset[T] {
  asset : T
  labeled_assets : Array[(String, @any.Any)]
  handle_labels : Array[(Int, String)]
}

///|
pub fn[T] SavedAsset::from_asset(asset : T) -> SavedAsset[T] {
  SavedAsset::{ asset, labeled_assets: [], handle_labels: [] }
}

///|
pub fn[T] SavedAsset::get(self : SavedAsset[T]) -> T {
  self.asset
}

///|
pub fn[T, U] SavedAsset::get_labeled(
  self : SavedAsset[T],
  label : String,
) -> SavedAsset[U]? {
  for entry in self.labeled_assets {
    let (candidate, asset) = entry
    if candidate == label {
      return asset.try_to()
    }
  }
  None
}

///|
pub fn[T, U] SavedAsset::label_for(
  self : SavedAsset[T],
  handle : Handle[U],
) -> String? {
  for entry in self.handle_labels {
    let (candidate_handle_id, label) = entry
    if candidate_handle_id == handle.id() {
      return Some(label)
    }
  }
  None
}

///|
pub struct SavedAssetBuilder {
  asset_server : AssetServer
  path : AssetPath
  labeled_assets : Array[(String, @any.Any)]
  handle_labels : Array[(Int, String)]
  mut next_handle_id : Int
}

///|
pub fn SavedAssetBuilder::new(
  asset_server : AssetServer,
  path : AssetPath,
) -> SavedAssetBuilder {
  SavedAssetBuilder::{
    asset_server,
    path,
    labeled_assets: [],
    handle_labels: [],
    next_handle_id: 0,
  }
}

///|
pub fn[T] SavedAssetBuilder::add_labeled_asset_with_new_handle(
  self : SavedAssetBuilder,
  label : String,
  asset : SavedAsset[T],
) -> Handle[T] {
  self.asset_server |> ignore
  self.path |> ignore
  let handle = Handle::new(self.next_handle_id)
  self.next_handle_id = self.next_handle_id + 1
  self.labeled_assets.push((label, @any.of(asset)))
  self.handle_labels.push((handle.id(), label))
  handle
}

///|
pub fn[T] SavedAssetBuilder::build(
  self : SavedAssetBuilder,
  asset : T,
) -> SavedAsset[T] {
  SavedAsset::{
    asset,
    labeled_assets: self.labeled_assets,
    handle_labels: self.handle_labels,
  }
}

///|
pub struct AssetSaver[T, Settings] {
  save : (Writer, SavedAsset[T], Settings) -> Unit raise AssetSaveError
}

///|
pub fn[T, Settings] AssetSaver::new(
  save : (Writer, SavedAsset[T], Settings) -> Unit raise AssetSaveError,
) -> AssetSaver[T, Settings] {
  AssetSaver::{ save, }
}

///|
pub fn[T, Settings, P : IntoAssetPath] save_using_saver(
  asset_server : AssetServer,
  saver : AssetSaver[T, Settings],
  path : P,
  asset : SavedAsset[T],
  settings : Settings,
) -> Unit raise AssetSaveError {
  let asset_path = path.into_asset_path()
  let formatted_path = asset_format_path(asset_path)
  let writer = Writer::new()
  (saver.save)(writer, asset, settings)
  let bytes = writer.finish()
  host_asset_save_bytes(path=formatted_path, bytes~)
  let canonical_path = asset_canonical_path(formatted_path)
  let seen = Ref::new(false)
  for existing_path in asset_server.paths.val {
    if existing_path == canonical_path {
      seen.val = true
      break
    }
  }
  if !seen.val {
    asset_server.paths.val.push(canonical_path)
  }
  asset_server.path_fingerprints.val.set(
    canonical_path,
    bytes_fingerprint(bytes),
  )
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let cache_key = typed_asset_loader_path_key(type_name, asset_path)
  asset_server.typed_asset_paths.val.remove(cache_key) |> ignore
}
