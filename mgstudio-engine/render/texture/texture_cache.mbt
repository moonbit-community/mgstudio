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
// Bevy source: `bevy/crates/bevy_render/src/texture/texture_cache.rs`.

///|
pub struct TextureCache {
  texture_ids : Array[Int]
}

///|
pub fn TextureCache::new() -> TextureCache {
  TextureCache::{ texture_ids: [] }
}

///|
pub fn TextureCache::insert(
  self : TextureCache,
  texture_id : Int,
) -> TextureCache {
  if !self.contains(texture_id) {
    self.texture_ids.push(texture_id)
  }
  self
}

///|
pub fn TextureCache::contains(self : TextureCache, texture_id : Int) -> Bool {
  for cached_texture_id in self.texture_ids {
    if cached_texture_id == texture_id {
      return true
    }
  }
  false
}

///|
pub fn TextureCache::len(self : TextureCache) -> Int {
  self.texture_ids.length()
}

///|
pub fn TextureCache::is_empty(self : TextureCache) -> Bool {
  self.texture_ids.is_empty()
}
