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
pub impl Asset for TextureAtlasLayout with fn asset_debug_name() {
  "mgstudio_asset::TextureAtlasLayout"
}

///|
pub impl Asset for TextureAtlasLayout with fn asset_as_image(_self) {
  None
}

///|
pub let texture_atlas_layout_asset_resource_keys : AssetResourceKeys[
  TextureAtlasLayout,
] = register_asset_resource_keys("mgstudio_asset::TextureAtlasLayout")

///|
pub impl Asset for TextureAtlasLayout with fn asset_resource_keys() {
  texture_atlas_layout_asset_resource_keys
}

///|
pub fn TextureAtlasLayout::new_empty(
  dimensions : @math.UVec2,
) -> TextureAtlasLayout {
  { size: dimensions, textures: [] }
}

///|
pub fn TextureAtlasLayout::size(self : TextureAtlasLayout) -> @math.UVec2 {
  self.size
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
  { size: @math.UVec2::new(size_x, size_y), textures: sprites }
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
pub fn TextureAtlasLayout::texture(
  self : TextureAtlasLayout,
  index : Int,
) -> @math.URect? {
  if index >= 0 && index < self.textures.length() {
    Some(self.textures[index])
  } else {
    None
  }
}

///|
// Bevy source: `bevy/crates/bevy_image/src/texture_atlas.rs::TextureAtlas`.
// Bevy stores this as an inline component field. MoonBit value types cannot
// contain the current generic reference-typed Handle, so preserve the same
// value semantics by storing its scalar asset id.
#valtype
pub struct TextureAtlas {
  priv layout_id : Int
  index : Int
}

///|
pub impl ToJson for TextureAtlas with fn to_json(self) {
  (self.layout_id, self.index) |> ToJson::to_json
}

///|
pub impl @json.FromJson for TextureAtlas with fn from_json(json, path) {
  let (layout_id, index) : (Int, Int) = @json.from_json(json, path~)
  { layout_id, index }
}

///|
pub fn TextureAtlas::new(
  layout : Handle[TextureAtlasLayout],
  index : Int,
) -> TextureAtlas {
  { layout_id: layout.id(), index }
}

///|
pub fn TextureAtlas::with_index(
  self : TextureAtlas,
  index : Int,
) -> TextureAtlas {
  { ..self, index, }
}

///|
pub fn TextureAtlas::with_layout(
  self : TextureAtlas,
  layout : Handle[TextureAtlasLayout],
) -> TextureAtlas {
  { ..self, layout_id: layout.id() }
}

///|
pub fn TextureAtlas::layout(self : TextureAtlas) -> Handle[TextureAtlasLayout] {
  Handle::new(self.layout_id)
}

///|
pub fn TextureAtlas::index(self : TextureAtlas) -> Int {
  self.index
}

///|
pub fn TextureAtlas::layout_asset(
  self : TextureAtlas,
  layouts : Assets[TextureAtlasLayout],
) -> TextureAtlasLayout? {
  layouts.get_by_id(self.layout_id)
}

///|
pub fn TextureAtlas::texture_rect(
  self : TextureAtlas,
  layouts : Assets[TextureAtlasLayout],
) -> @math.URect? {
  if self.layout_asset(layouts) is Some(layout_value) {
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
    Some(TextureAtlas::new(layout, index))
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
  { size, padding: padding_value, free_rects: [rect] }
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
pub fn asset_set_texture_sampler(
  texture : Handle[Image],
  sampler : ImageSampler,
) -> Unit {
  let (
    address_mode_u,
    address_mode_v,
    address_mode_w,
    mag_filter,
    min_filter,
    mipmap_filter,
    lod_min_clamp,
    lod_max_clamp,
    compare,
    anisotropy_clamp,
    border_color,
  ) = @image.image_sampler_runtime_args(sampler, false)
  host_asset_set_texture_sampler(
    texture_id=texture.id(),
    address_mode_u~,
    address_mode_v~,
    address_mode_w~,
    mag_filter~,
    min_filter~,
    mipmap_filter~,
    lod_min_clamp~,
    lod_max_clamp~,
    compare~,
    anisotropy_clamp~,
    border_color~,
  )
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
pub fn TextureAtlasBuilder::TextureAtlasBuilder() -> TextureAtlasBuilder {
  {
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
  {
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
  {
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
  {
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
  {
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
priv struct TextureAtlasPackSection {
  x : Int
  y : Int
  z : Int
  width : Int
  height : Int
  depth : Int
}

///|
priv struct TextureAtlasPackedLocation {
  x : Int
  y : Int
}

///|
fn texture_atlas_pack_section(
  x : Int,
  y : Int,
  z : Int,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  { x, y, z, width, height, depth }
}

///|
fn texture_atlas_pack_section_volume(section : TextureAtlasPackSection) -> Int {
  section.width * section.height * section.depth
}

///|
fn texture_atlas_pack_compare_int(left : Int, right : Int) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

///|
fn texture_atlas_pack_compare_container_sets(
  left : Array[TextureAtlasPackSection],
  right : Array[TextureAtlasPackSection],
) -> Int {
  let left_sorted : Array[TextureAtlasPackSection] = []
  let right_sorted : Array[TextureAtlasPackSection] = []
  for section in left {
    left_sorted.push(section)
  }
  for section in right {
    right_sorted.push(section)
  }
  left_sorted.sort_by(fn(a, b) {
    texture_atlas_pack_section_volume(a) - texture_atlas_pack_section_volume(b)
  })
  right_sorted.sort_by(fn(a, b) {
    texture_atlas_pack_section_volume(a) - texture_atlas_pack_section_volume(b)
  })
  let first = texture_atlas_pack_compare_int(
    texture_atlas_pack_section_volume(right_sorted[0]),
    texture_atlas_pack_section_volume(left_sorted[0]),
  )
  if first != 0 {
    return first
  }
  texture_atlas_pack_compare_int(
    texture_atlas_pack_section_volume(right_sorted[1]),
    texture_atlas_pack_section_volume(left_sorted[1]),
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_above(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(width)
  ignore(depth)
  texture_atlas_pack_section(
    self.x,
    self.y + height,
    self.z,
    self.width,
    self.height - height,
    self.depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_right(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(height)
  ignore(depth)
  texture_atlas_pack_section(
    self.x + width,
    self.y,
    self.z,
    self.width - width,
    self.height,
    self.depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_behind(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(width)
  ignore(height)
  texture_atlas_pack_section(
    self.x,
    self.y,
    self.z + depth,
    self.width,
    self.height,
    self.depth - depth,
  )
}

///|
fn TextureAtlasPackSection::empty_space_directly_above(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  texture_atlas_pack_section(
    self.x,
    self.y + height,
    self.z,
    width,
    self.height - height,
    depth,
  )
}

///|
fn TextureAtlasPackSection::empty_space_directly_right(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  texture_atlas_pack_section(
    self.x + width,
    self.y,
    self.z,
    self.width - width,
    height,
    depth,
  )
}

///|
fn TextureAtlasPackSection::empty_space_directly_behind(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  texture_atlas_pack_section(
    self.x,
    self.y,
    self.z + depth,
    width,
    height,
    self.depth - depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_above_excluding_right(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(depth)
  texture_atlas_pack_section(
    self.x,
    self.y + height,
    self.z,
    width,
    self.height - height,
    self.depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_above_excluding_behind(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(width)
  texture_atlas_pack_section(
    self.x,
    self.y + height,
    self.z,
    self.width,
    self.height - height,
    depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_right_excluding_above(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(height)
  ignore(depth)
  texture_atlas_pack_section(
    self.x + width,
    self.y,
    self.z,
    self.width - width,
    height,
    self.depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_right_excluding_behind(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(height)
  texture_atlas_pack_section(
    self.x + width,
    self.y,
    self.z,
    self.width - width,
    self.height,
    depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_behind_excluding_above(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(width)
  texture_atlas_pack_section(
    self.x,
    self.y,
    self.z + depth,
    self.width,
    height,
    self.depth - depth,
  )
}

///|
fn TextureAtlasPackSection::all_empty_space_behind_excluding_right(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> TextureAtlasPackSection {
  ignore(height)
  texture_atlas_pack_section(
    self.x,
    self.y,
    self.z + depth,
    width,
    self.height,
    self.depth - depth,
  )
}

///|
fn TextureAtlasPackSection::try_place(
  self : TextureAtlasPackSection,
  width : Int,
  height : Int,
  depth : Int,
) -> (TextureAtlasPackedLocation, Array[TextureAtlasPackSection])? {
  if width > self.width || height > self.height || depth > self.depth {
    return None
  }
  let combinations : Array[Array[TextureAtlasPackSection]] = [
    [
      self.all_empty_space_right(width, height, depth),
      self.all_empty_space_above_excluding_right(width, height, depth),
      self.empty_space_directly_behind(width, height, depth),
    ],
    [
      self.all_empty_space_right_excluding_above(width, height, depth),
      self.all_empty_space_above(width, height, depth),
      self.empty_space_directly_behind(width, height, depth),
    ],
    [
      self.all_empty_space_right(width, height, depth),
      self.empty_space_directly_above(width, height, depth),
      self.all_empty_space_behind_excluding_right(width, height, depth),
    ],
    [
      self.all_empty_space_right_excluding_behind(width, height, depth),
      self.empty_space_directly_above(width, height, depth),
      self.all_empty_space_behind(width, height, depth),
    ],
    [
      self.empty_space_directly_right(width, height, depth),
      self.all_empty_space_above(width, height, depth),
      self.all_empty_space_behind_excluding_above(width, height, depth),
    ],
    [
      self.empty_space_directly_right(width, height, depth),
      self.all_empty_space_above_excluding_behind(width, height, depth),
      self.all_empty_space_behind(width, height, depth),
    ],
  ]
  combinations.sort_by(texture_atlas_pack_compare_container_sets)
  Some(({ x: self.x, y: self.y }, combinations[5]))
}

///|
fn texture_atlas_pack_remove_section(
  sections : Array[TextureAtlasPackSection],
  index : Int,
) -> Unit {
  if index < 0 || index >= sections.length() {
    return
  }
  sections.remove(index) |> ignore
}

///|
fn texture_atlas_pack_place(
  sections : Array[TextureAtlasPackSection],
  width : Int,
  height : Int,
) -> TextureAtlasPackedLocation? {
  if sections.length() == 0 {
    return None
  }
  let candidates : Array[TextureAtlasPackSection] = []
  for section in sections {
    candidates.push(section)
  }
  let last_section_index = candidates.length() - 1
  let mut sections_tried = 0
  while candidates.length() > 0 {
    let section = candidates.pop().unwrap()
    match section.try_place(width, height, 1) {
      Some((location, new_sections)) => {
        new_sections.sort_by(fn(left, right) {
          texture_atlas_pack_section_volume(right) -
          texture_atlas_pack_section_volume(left)
        })
        texture_atlas_pack_remove_section(
          sections,
          last_section_index - sections_tried,
        )
        for new_section in new_sections {
          if texture_atlas_pack_section_volume(new_section) > 0 {
            sections.push(new_section)
          }
        }
        return Some(location)
      }
      None => sections_tried = sections_tried + 1
    }
  }
  None
}

///|
fn texture_atlas_pack_texture_rects(
  textures : Array[Handle[Image]],
  atlas_size : @math.UVec2,
  padding : @math.UVec2,
) -> Array[@math.URect?]? {
  let texture_count = textures.length()
  let rects : Array[@math.URect?] = []
  let placement_order : Array[Int] = []
  for i in 0..<texture_count {
    rects.push(None)
    placement_order.push(i)
  }
  placement_order.sort_by(fn(left, right) {
    let left_width = asset_texture_width(textures[left]) + padding.x
    let left_height = asset_texture_height(textures[left]) + padding.y
    let right_width = asset_texture_width(textures[right]) + padding.x
    let right_height = asset_texture_height(textures[right]) + padding.y
    let area_cmp = right_width * right_height - left_width * left_height
    if area_cmp != 0 {
      return area_cmp
    }
    left - right
  })
  let sections = [
    texture_atlas_pack_section(0, 0, 0, atlas_size.x, atlas_size.y, 1),
  ]
  for order_index in 0..<texture_count {
    let texture_index = placement_order[order_index]
    let texture = textures[texture_index]
    let width = asset_texture_width(texture)
    let height = asset_texture_height(texture)
    if width <= 0 || height <= 0 {
      return None
    }
    let packed_width = width + padding.x
    let packed_height = height + padding.y
    let location = match
      texture_atlas_pack_place(sections, packed_width, packed_height) {
      Some(value) => value
      None => return None
    }
    rects[texture_index] = Some(
      @math.URect::new(
        @math.UVec2::new(location.x, location.y),
        @math.UVec2::new(location.x + width, location.y + height),
      ),
    )
  }
  Some(rects)
}

///|
fn texture_atlas_layout_assets_mut_or_abort() -> @ecs.ResourceMut[
  Assets[TextureAtlasLayout],
] {
  let key : @ecs.ResourceKey[Assets[TextureAtlasLayout]] = registered_assets_resource_key()
  match asset_current_world() {
    Some(world) =>
      match world.get_resource_mut(key) {
        Some(assets) => assets
        None =>
          abort(
            "TextureAtlasLayout assets resource is missing; add AssetPlugin before mutating texture atlas layouts",
          )
      }
    None =>
      abort(
        "TextureAtlasLayout asset mutations require an active app world; use the world-owned Assets<TextureAtlasLayout> resource directly outside scheduled systems",
      )
  }
}

///|
fn texture_atlas_layout_assets_or_abort() -> Assets[TextureAtlasLayout] {
  let key : @ecs.ResourceKey[Assets[TextureAtlasLayout]] = registered_assets_resource_key()
  match asset_current_world() {
    Some(world) =>
      match world.get_resource(key) {
        Some(assets) => assets
        None =>
          abort(
            "TextureAtlasLayout assets resource is missing; add AssetPlugin before reading texture atlas layouts",
          )
      }
    None =>
      abort(
        "TextureAtlasLayout asset lookups require an active app world; use the world-owned Assets<TextureAtlasLayout> resource directly outside scheduled systems",
      )
  }
}

///|
pub fn asset_add_texture_atlas_layout(
  layout : TextureAtlasLayout,
) -> Handle[TextureAtlasLayout] {
  texture_atlas_layout_assets_mut_or_abort().modify(fn(assets) {
    assets.add(layout)
  })
}

///|
pub fn asset_get_texture_atlas_layout(
  handle : Handle[TextureAtlasLayout],
) -> TextureAtlasLayout? {
  texture_atlas_layout_assets_or_abort().get(handle)
}

///|
pub fn asset_set_texture_atlas_layout(
  handle : Handle[TextureAtlasLayout],
  layout : TextureAtlasLayout,
) -> Bool {
  texture_atlas_layout_assets_mut_or_abort().modify(fn(assets) {
    assets.set(handle, layout)
  })
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
    let layout = TextureAtlasLayout::new_empty(current_size)
    let sources = TextureAtlasSources::{ texture_ids: [] }
    let packed_rects = texture_atlas_pack_texture_rects(
      self.textures,
      current_size,
      self.padding,
    )
    if packed_rects is Some(rects) {
      let mut ok = true
      let atlas_texture = asset_create_dynamic_texture(
        current_size,
        self.nearest,
      )
      for i in 0..<texture_count {
        let rect = match rects[i] {
          Some(value) => value
          None => {
            ok = false
            break
          }
        }
        let index = layout.add_texture(rect)
        sources.texture_ids.push((self.textures[i], index))
        asset_copy_texture_to_texture(atlas_texture, rect.min, self.textures[i])
      }
      if ok {
        return Some((layout, sources, atlas_texture))
      }
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
    abort("TextureAtlasBuilder failed to build a texture atlas")
  }
}
