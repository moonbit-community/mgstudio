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
// Bevy source: `bevy/crates/bevy_asset/src/handle.rs`.
pub struct Handle[T] {
  id : Int
  phantom : T?
}

///|
pub fn[T] Handle::new(id : Int) -> Handle[T] {
  Handle::{ id, phantom: None }
}

///|
pub impl[T] ToJson for Handle[T] with to_json(self) {
  self.id.to_json()
}

///|
pub impl[T] @json.FromJson for Handle[T] with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  Handle::new(id)
}

///|
pub fn[T] Handle::id(self : Handle[T]) -> Int {
  self.id
}

///|
pub fn[T] Handle::asset_id(self : Handle[T]) -> AssetId[T] {
  AssetId::new(self.id)
}

///|
pub fn[T] Handle::from_asset_id(asset_id : AssetId[T]) -> Handle[T] {
  Handle::new(asset_id.index())
}

///|
pub impl @image.TextureHandle for Handle[Image] with texture_id(self) {
  self.id()
}
