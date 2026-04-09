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
// Bevy source: `bevy/crates/bevy_render/src/storage.rs`.

///|
pub struct RenderStorage[K, V] {
  values : @hashmap.HashMap[K, V]
}

///|
pub fn[K, V] RenderStorage::new() -> RenderStorage[K, V] {
  RenderStorage::{ values: @hashmap.HashMap::new() }
}

///|
pub fn[K, V] RenderStorage::len(self : RenderStorage[K, V]) -> Int {
  self.values.length()
}

///|
pub fn[K, V] RenderStorage::is_empty(self : RenderStorage[K, V]) -> Bool {
  self.values.is_empty()
}

///|
pub fn[K : Hash + Eq, V] RenderStorage::contains(
  self : RenderStorage[K, V],
  key : K,
) -> Bool {
  self.values.contains(key)
}

///|
pub fn[K : Hash + Eq, V] RenderStorage::get(
  self : RenderStorage[K, V],
  key : K,
) -> V? {
  self.values.get(key)
}

///|
pub fn[K : Hash + Eq, V] RenderStorage::insert(
  self : RenderStorage[K, V],
  key : K,
  value : V,
) -> Unit {
  self.values.set(key, value)
}

///|
pub fn[K : Hash + Eq, V] RenderStorage::remove(
  self : RenderStorage[K, V],
  key : K,
) -> V? {
  guard self.values.get(key) is Some(value) else { return None }
  self.values.remove(key)
  Some(value)
}

///|
pub fn[K, V] RenderStorage::clear(self : RenderStorage[K, V]) -> Unit {
  self.values.clear()
}
