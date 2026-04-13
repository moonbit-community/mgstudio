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
// Bevy source: `bevy/crates/bevy_image/src/texture_atlas_builder.rs`.

///|
pub struct TextureAtlasBuilder {
  atlas_width : Int
  atlas_height : Int
  padding : Int
}

///|
pub fn TextureAtlasBuilder::new(
  atlas_width : Int,
  atlas_height : Int,
) -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    atlas_width: if atlas_width <= 0 {
      1
    } else {
      atlas_width
    },
    atlas_height: if atlas_height <= 0 {
      1
    } else {
      atlas_height
    },
    padding: 0,
  }
}

///|
pub fn TextureAtlasBuilder::with_padding(
  self : TextureAtlasBuilder,
  padding : Int,
) -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    ..self,
    padding: if padding < 0 {
      0
    } else {
      padding
    },
  }
}

///|
pub fn TextureAtlasBuilder::build_grid(
  self : TextureAtlasBuilder,
  cell_width : Int,
  cell_height : Int,
) -> TextureAtlasLayout {
  let layout = TextureAtlasLayout::new(self.atlas_width, self.atlas_height)
  if cell_width <= 0 || cell_height <= 0 {
    return layout
  }
  let stride_x = cell_width + self.padding
  let stride_y = cell_height + self.padding
  if stride_x <= 0 || stride_y <= 0 {
    return layout
  }
  let mut y = 0
  while y + cell_height <= self.atlas_height {
    let mut x = 0
    while x + cell_width <= self.atlas_width {
      ignore(
        layout.add_region(TextureAtlasRegion::{
          x,
          y,
          width: cell_width,
          height: cell_height,
        }),
      )
      x = x + stride_x
    }
    y = y + stride_y
  }
  layout
}
