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
pub struct TextureAtlasLayout {
  size : @math.UVec2
  textures : Array[@math.URect]
}

///|
pub fn TextureAtlasLayout::new_empty(
  dimensions : @math.UVec2,
) -> TextureAtlasLayout {
  TextureAtlasLayout::{ size: dimensions, textures: [] }
}

///|
pub fn TextureAtlasLayout::from_grid(
  tile_size : @math.UVec2,
  columns : Int,
  rows : Int,
  padding? : @math.UVec2,
  offset? : @math.UVec2,
) -> TextureAtlasLayout {
  let padding_value = if padding is Some(value) {
    value
  } else {
    @math.UVec2::zero()
  }
  let offset_value = if offset is Some(value) {
    value
  } else {
    @math.UVec2::zero()
  }
  let sprites : Array[@math.URect] = []
  let mut current_padding = @math.UVec2::zero()
  for y in 0..<rows {
    if y > 0 {
      current_padding = @math.UVec2::new(current_padding.x, padding_value.y)
    }
    for x in 0..<columns {
      if x > 0 {
        current_padding = @math.UVec2::new(padding_value.x, current_padding.y)
      }
      let rect_min_x = (tile_size.x + current_padding.x) * x + offset_value.x
      let rect_min_y = (tile_size.y + current_padding.y) * y + offset_value.y
      let rect_min = @math.UVec2::new(rect_min_x, rect_min_y)
      let rect_max = @math.UVec2::new(
        rect_min_x + tile_size.x,
        rect_min_y + tile_size.y,
      )
      sprites.push(@math.URect::new(rect_min, rect_max))
    }
  }
  let grid_size = @math.UVec2::new(columns, rows)
  let size_x = (tile_size.x + current_padding.x) * grid_size.x -
    current_padding.x
  let size_y = (tile_size.y + current_padding.y) * grid_size.y -
    current_padding.y
  TextureAtlasLayout::{
    size: @math.UVec2::new(size_x, size_y),
    textures: sprites,
  }
}

///|
pub fn TextureAtlasLayout::add_texture(
  self : TextureAtlasLayout,
  rect : @math.URect,
) -> Int {
  self.textures.push(rect)
  self.textures.length() - 1
}

///|
pub fn TextureAtlasLayout::len(self : TextureAtlasLayout) -> Int {
  self.textures.length()
}

///|
pub fn TextureAtlasLayout::is_empty(self : TextureAtlasLayout) -> Bool {
  self.textures.length() == 0
}

///|

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct TextureAtlas {
  layout : Handle[TextureAtlasLayout]
  index : Int
}

///|
pub fn TextureAtlas::new(
  layout : Handle[TextureAtlasLayout],
  index : Int,
) -> TextureAtlas {
  TextureAtlas::{ layout, index }
}

///|
pub fn TextureAtlas::with_index(
  self : TextureAtlas,
  index : Int,
) -> TextureAtlas {
  TextureAtlas::{ ..self, index, }
}

///|
pub fn TextureAtlas::with_layout(
  self : TextureAtlas,
  layout : Handle[TextureAtlasLayout],
) -> TextureAtlas {
  TextureAtlas::{ ..self, layout, }
}

///|
pub fn TextureAtlas::texture_rect(
  self : TextureAtlas,
  layouts : Assets[TextureAtlasLayout],
) -> @math.URect? {
  if layouts.get(self.layout) is Some(layout_value) {
    if self.index >= 0 && self.index < layout_value.textures.length() {
      return Some(layout_value.textures[self.index])
    }
  }
  None
}

///|
pub struct TextureAtlasSources {
  texture_ids : Array[(Handle[Image], Int)]
}

///|
pub fn TextureAtlasSources::texture_index(
  self : TextureAtlasSources,
  texture : Handle[Image],
) -> Int? {
  let count = self.texture_ids.length()
  for i in 0..<count {
    let entry = self.texture_ids[i]
    if entry.0.id() == texture.id() {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn TextureAtlasSources::handle(
  self : TextureAtlasSources,
  layout : Handle[TextureAtlasLayout],
  texture : Handle[Image],
) -> TextureAtlas? {
  if self.texture_index(texture) is Some(index) {
    Some(TextureAtlas::{ layout, index })
  } else {
    None
  }
}

///|
pub(all) enum DynamicTextureAtlasBuilderError {
  FailedToAllocateSpace
}

///|
pub struct DynamicTextureAtlasBuilder {
  size : @math.UVec2
  padding : Int
  free_rects : Array[@math.URect]
}

///|
pub fn DynamicTextureAtlasBuilder::new(
  size : @math.UVec2,
  padding : Int,
) -> DynamicTextureAtlasBuilder {
  let padding_value = if padding < 0 { 0 } else { padding }
  let rect = @math.URect::new(@math.UVec2::zero(), size)
  DynamicTextureAtlasBuilder::{
    size,
    padding: padding_value,
    free_rects: [rect],
  }
}

///|
fn rect_contains(outer : @math.URect, inner : @math.URect) -> Bool {
  inner.min.x >= outer.min.x &&
  inner.min.y >= outer.min.y &&
  inner.max.x <= outer.max.x &&
  inner.max.y <= outer.max.y
}

///|
fn rect_area(rect : @math.URect) -> Int {
  let size = rect.size()
  size.x * size.y
}

///|
fn rect_split(
  rect : @math.URect,
  alloc_width : Int,
  alloc_height : Int,
  target : Array[@math.URect],
) -> Unit {
  let size = rect.size()
  let remaining_width = size.x - alloc_width
  let remaining_height = size.y - alloc_height
  if remaining_width < 0 || remaining_height < 0 {
    return
  }
  if remaining_width > remaining_height {
    if remaining_width > 0 {
      target.push(
        @math.URect::new(
          @math.UVec2::new(rect.min.x + alloc_width, rect.min.y),
          rect.max,
        ),
      )
    }
    if remaining_height > 0 {
      target.push(
        @math.URect::new(
          @math.UVec2::new(rect.min.x, rect.min.y + alloc_height),
          @math.UVec2::new(rect.min.x + alloc_width, rect.max.y),
        ),
      )
    }
  } else {
    if remaining_width > 0 {
      target.push(
        @math.URect::new(
          @math.UVec2::new(rect.min.x + alloc_width, rect.min.y),
          @math.UVec2::new(rect.max.x, rect.min.y + alloc_height),
        ),
      )
    }
    if remaining_height > 0 {
      target.push(
        @math.URect::new(
          @math.UVec2::new(rect.min.x, rect.min.y + alloc_height),
          rect.max,
        ),
      )
    }
  }
}

///|
fn prune_free_rects(free_rects : Array[@math.URect]) -> Unit {
  let mut i = 0
  while i < free_rects.length() {
    let current = free_rects[i]
    let mut removed = false
    let mut j = 0
    while j < free_rects.length() {
      if i != j {
        let other = free_rects[j]
        if rect_contains(other, current) {
          let last = free_rects.length() - 1
          free_rects[i] = free_rects[last]
          free_rects.pop() |> ignore
          removed = true
          break
        }
      }
      j = j + 1
    }
    if !removed {
      i = i + 1
    }
  }
}

///|
pub fn DynamicTextureAtlasBuilder::add_texture(
  self : DynamicTextureAtlasBuilder,
  layout : TextureAtlasLayout,
  texture_size : @math.UVec2,
) -> (Int, @math.URect)? {
  let padded_width = texture_size.x + self.padding
  let padded_height = texture_size.y + self.padding
  let mut best_index = -1
  let mut best_area = 0
  let count = self.free_rects.length()
  for i in 0..<count {
    let rect = self.free_rects[i]
    let size = rect.size()
    if size.x >= padded_width && size.y >= padded_height {
      let area = rect_area(rect)
      if best_index < 0 || area < best_area {
        best_index = i
        best_area = area
      }
    }
  }
  if best_index < 0 {
    return None
  }
  let selected = self.free_rects[best_index]
  let last = self.free_rects.length() - 1
  self.free_rects[best_index] = self.free_rects[last]
  self.free_rects.pop() |> ignore
  rect_split(selected, padded_width, padded_height, self.free_rects)
  prune_free_rects(self.free_rects)
  let alloc_min = selected.min
  let alloc_max = @math.UVec2::new(
    alloc_min.x + padded_width,
    alloc_min.y + padded_height,
  )
  let trimmed_max = @math.UVec2::new(
    alloc_max.x - self.padding,
    alloc_max.y - self.padding,
  )
  let trimmed = @math.URect::new(alloc_min, trimmed_max)
  let index = layout.add_texture(trimmed)
  Some((index, trimmed))
}

///|
pub(all) enum ImageSampler {
  Linear
  Nearest
}

///|
pub fn host_asset_set_texture_sampler(texture_id : Int, sampler : Int) -> Unit = "mgstudio_host" "asset_set_texture_sampler"

///|
pub fn asset_set_texture_sampler(
  texture : Handle[Image],
  sampler : ImageSampler,
) -> Unit {
  let sampler_id = match sampler {
    Linear => 0
    Nearest => 1
  }
  host_asset_set_texture_sampler(texture.id(), sampler_id)
}

///|
pub struct TextureAtlasBuilder {
  padding : @math.UVec2
  initial_size : @math.UVec2
  max_size : @math.UVec2
  nearest : Bool
  textures : Array[Handle[Image]]
}

///|
pub fn TextureAtlasBuilder::default() -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    padding: @math.UVec2::zero(),
    initial_size: @math.UVec2::splat(256),
    max_size: @math.UVec2::splat(2048),
    nearest: false,
    textures: [],
  }
}

///|
pub fn TextureAtlasBuilder::padding(
  self : TextureAtlasBuilder,
  padding : @math.UVec2,
) -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    padding,
    initial_size: self.initial_size,
    max_size: self.max_size,
    nearest: self.nearest,
    textures: self.textures,
  }
}

///|
pub fn TextureAtlasBuilder::initial_size(
  self : TextureAtlasBuilder,
  size : @math.UVec2,
) -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    padding: self.padding,
    initial_size: size,
    max_size: self.max_size,
    nearest: self.nearest,
    textures: self.textures,
  }
}

///|
pub fn TextureAtlasBuilder::max_size(
  self : TextureAtlasBuilder,
  size : @math.UVec2,
) -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    padding: self.padding,
    initial_size: self.initial_size,
    max_size: size,
    nearest: self.nearest,
    textures: self.textures,
  }
}

///|
pub fn TextureAtlasBuilder::sampler_nearest(
  self : TextureAtlasBuilder,
  nearest : Bool,
) -> TextureAtlasBuilder {
  TextureAtlasBuilder::{
    padding: self.padding,
    initial_size: self.initial_size,
    max_size: self.max_size,
    nearest,
    textures: self.textures,
  }
}

///|
pub fn TextureAtlasBuilder::add_texture(
  self : TextureAtlasBuilder,
  texture : Handle[Image],
) -> TextureAtlasBuilder {
  self.textures.push(texture)
  self
}

///|
let texture_atlas_layouts_state : Ref[Assets[TextureAtlasLayout]] = Ref::new(
  Assets::new(),
)

///|
pub fn asset_add_texture_atlas_layout(
  layout : TextureAtlasLayout,
) -> Handle[TextureAtlasLayout] {
  texture_atlas_layouts_state.val.add(layout)
}

///|
pub fn asset_get_texture_atlas_layout(
  handle : Handle[TextureAtlasLayout],
) -> TextureAtlasLayout? {
  texture_atlas_layouts_state.val.get(handle)
}

///|
pub fn asset_set_texture_atlas_layout(
  handle : Handle[TextureAtlasLayout],
  layout : TextureAtlasLayout,
) -> Bool {
  texture_atlas_layouts_state.val.set(handle, layout)
}

///|
fn int_clamp_max(value : Int, max : Int) -> Int {
  if value > max {
    max
  } else {
    value
  }
}

///|
pub fn TextureAtlasBuilder::try_build(
  self : TextureAtlasBuilder,
) -> (TextureAtlasLayout, TextureAtlasSources, Handle[Image])? {
  let texture_count = self.textures.length()
  if texture_count <= 0 {
    return None
  }
  let padding_value = if self.padding.x > self.padding.y {
    self.padding.x
  } else {
    self.padding.y
  }
  let mut current_size = @math.UVec2::new(
    if self.initial_size.x > 0 {
      self.initial_size.x
    } else {
      1
    },
    if self.initial_size.y > 0 {
      self.initial_size.y
    } else {
      1
    },
  )
  let max_size = @math.UVec2::new(
    if self.max_size.x > 0 {
      self.max_size.x
    } else {
      1
    },
    if self.max_size.y > 0 {
      self.max_size.y
    } else {
      1
    },
  )
  let mut attempts = 0
  while attempts < 64 {
    if current_size.x > max_size.x || current_size.y > max_size.y {
      break
    }
    let allocator = DynamicTextureAtlasBuilder::new(current_size, padding_value)
    let layout = TextureAtlasLayout::new_empty(current_size)
    let sources = TextureAtlasSources::{ texture_ids: [] }
    let rects : Array[@math.URect] = []
    let mut ok = true
    for i in 0..<texture_count {
      let texture = self.textures[i]
      let width = asset_texture_width(texture)
      let height = asset_texture_height(texture)
      if width <= 0 || height <= 0 {
        ok = false
        break
      }
      let size = @math.UVec2::new(width, height)
      let allocation = allocator.add_texture(layout, size)
      if allocation is None {
        ok = false
        break
      }
      let index = if allocation is Some(value) { value.0 } else { 0 }
      let rect = if allocation is Some(value) {
        value.1
      } else {
        ok = false
        break
      }
      sources.texture_ids.push((texture, index))
      rects.push(rect)
    }
    if ok {
      let atlas_texture = asset_create_dynamic_texture(
        current_size,
        self.nearest,
      )
      for i in 0..<rects.length() {
        let rect = rects[i]
        asset_copy_texture_to_texture(atlas_texture, rect.min, self.textures[i])
      }
      return Some((layout, sources, atlas_texture))
    }
    let next_w = if current_size.x < max_size.x {
      int_clamp_max(current_size.x * 2, max_size.x)
    } else {
      current_size.x
    }
    let next_h = if current_size.y < max_size.y {
      int_clamp_max(current_size.y * 2, max_size.y)
    } else {
      current_size.y
    }
    if next_w == current_size.x && next_h == current_size.y {
      break
    }
    current_size = @math.UVec2::new(next_w, next_h)
    attempts = attempts + 1
  }
  None
}

///|
pub fn TextureAtlasBuilder::build(
  self : TextureAtlasBuilder,
) -> (TextureAtlasLayout, TextureAtlasSources, Handle[Image]) {
  if self.try_build() is Some(value) {
    value
  } else {
    let layout = TextureAtlasLayout::new_empty(@math.UVec2::zero())
    let sources = TextureAtlasSources::{ texture_ids: [] }
    (layout, sources, Handle::new(-1))
  }
}
