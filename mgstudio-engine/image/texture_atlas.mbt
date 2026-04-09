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
// Bevy source: `bevy/crates/bevy_image/src/texture_atlas.rs`.

///|
pub struct TextureAtlasRegion {
  x : Int
  y : Int
  width : Int
  height : Int
}

///|
pub struct TextureAtlasLayout {
  width : Int
  height : Int
  regions : Array[TextureAtlasRegion]
}

///|
pub fn TextureAtlasLayout::new(width : Int, height : Int) -> TextureAtlasLayout {
  TextureAtlasLayout::{
    width: if width <= 0 {
      1
    } else {
      width
    },
    height: if height <= 0 {
      1
    } else {
      height
    },
    regions: [],
  }
}

///|
pub fn TextureAtlasLayout::add_region(
  self : TextureAtlasLayout,
  region : TextureAtlasRegion,
) -> Int {
  self.regions.push(region)
  self.regions.length() - 1
}

///|
pub fn TextureAtlasLayout::region(
  self : TextureAtlasLayout,
  index : Int,
) -> TextureAtlasRegion? {
  if index < 0 || index >= self.regions.length() {
    None
  } else {
    Some(self.regions[index])
  }
}
