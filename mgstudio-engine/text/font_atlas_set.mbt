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
pub struct FontAtlasKey {
  font_id : Int
  font_size_bits : Int
  font_smoothing : FontSmoothing
}

///|
pub fn FontAtlasKey::new(
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  font_smoothing : FontSmoothing,
) -> FontAtlasKey {
  let bits = font_size.reinterpret_as_uint().reinterpret_as_int()
  FontAtlasKey::{ font_id: font.id(), font_size_bits: bits, font_smoothing }
}

///|
fn font_atlas_key_equals(a : FontAtlasKey, b : FontAtlasKey) -> Bool {
  a.font_id == b.font_id &&
  a.font_size_bits == b.font_size_bits &&
  font_smoothing_equals(a.font_smoothing, b.font_smoothing)
}

///|
fn font_smoothing_equals(a : FontSmoothing, b : FontSmoothing) -> Bool {
  match a {
    FontSmoothing::None => b is FontSmoothing::None
    FontSmoothing::AntiAliased => b is FontSmoothing::AntiAliased
  }
}

///|
pub struct FontAtlasSetEntry {
  key : FontAtlasKey
  atlases : Array[FontAtlas]
}

///|
pub struct FontAtlasSet {
  entries : Array[FontAtlasSetEntry]
}

///|
pub fn FontAtlasSet::default() -> FontAtlasSet {
  FontAtlasSet::{ entries: [] }
}

///|
pub fn FontAtlasSet::get(
  self : FontAtlasSet,
  key : FontAtlasKey,
) -> Array[FontAtlas]? {
  let count = self.entries.length()
  for i in 0..<count {
    let entry = self.entries[i]
    if font_atlas_key_equals(entry.key, key) {
      return Some(entry.atlases)
    }
  }
  None
}

///|
pub fn FontAtlasSet::get_or_insert(
  self : FontAtlasSet,
  key : FontAtlasKey,
) -> Array[FontAtlas] {
  if self.get(key) is Some(atlases) {
    return atlases
  }
  let atlases : Array[FontAtlas] = []
  self.entries.push(FontAtlasSetEntry::{ key, atlases })
  atlases
}

///|
pub fn FontAtlasSet::has_glyph(
  self : FontAtlasSet,
  cache_key : GlyphCacheKey,
  font_key : FontAtlasKey,
) -> Bool {
  let entries = self.get(font_key)
  if entries is None {
    return false
  }
  let atlases = if entries is Some(value) { value } else { return false }
  let count = atlases.length()
  for i in 0..<count {
    if atlases[i].has_glyph(cache_key) {
      return true
    }
  }
  false
}
