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
// Bevy source: `bevy/crates/bevy_image/src/dynamic_texture_atlas_builder.rs`.

///|
pub struct DynamicTextureAtlasBuilder {
  max_width : Int
  max_height : Int
  mut next_x : Int
  mut next_y : Int
  mut row_height : Int
}

///|
pub fn DynamicTextureAtlasBuilder::new(
  max_width : Int,
  max_height : Int,
) -> DynamicTextureAtlasBuilder {
  DynamicTextureAtlasBuilder::{
    max_width: if max_width <= 0 {
      1
    } else {
      max_width
    },
    max_height: if max_height <= 0 {
      1
    } else {
      max_height
    },
    next_x: 0,
    next_y: 0,
    row_height: 0,
  }
}

///|
pub fn DynamicTextureAtlasBuilder::reset(
  self : DynamicTextureAtlasBuilder,
) -> Unit {
  self.next_x = 0
  self.next_y = 0
  self.row_height = 0
}

///|
pub fn DynamicTextureAtlasBuilder::try_allocate(
  self : DynamicTextureAtlasBuilder,
  width : Int,
  height : Int,
) -> (Int, Int)? {
  if width <= 0 ||
    height <= 0 ||
    width > self.max_width ||
    height > self.max_height {
    return None
  }
  if self.next_x + width > self.max_width {
    self.next_x = 0
    self.next_y = self.next_y + self.row_height
    self.row_height = 0
  }
  if self.next_y + height > self.max_height {
    return None
  }
  let origin = (self.next_x, self.next_y)
  self.next_x = self.next_x + width
  if height > self.row_height {
    self.row_height = height
  }
  Some(origin)
}
