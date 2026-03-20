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
pub(all) enum SliceScaleMode {
  Stretch
  Tile(Float)
}

///|
pub fn SliceScaleMode::default() -> SliceScaleMode {
  SliceScaleMode::Stretch
}

///|
pub struct TextureSlicer {
  border : BorderRect
  center_scale_mode : SliceScaleMode
  sides_scale_mode : SliceScaleMode
  max_corner_scale : Float
}

///|
pub fn TextureSlicer::new(border : BorderRect) -> TextureSlicer {
  TextureSlicer::{
    border,
    center_scale_mode: SliceScaleMode::Stretch,
    sides_scale_mode: SliceScaleMode::Stretch,
    max_corner_scale: 1.0F,
  }
}

///|
pub fn TextureSlicer::default() -> TextureSlicer {
  TextureSlicer::new(BorderRect::default())
}

///|
pub fn TextureSlicer::with_center_scale_mode(
  self : TextureSlicer,
  center_scale_mode : SliceScaleMode,
) -> TextureSlicer {
  TextureSlicer::{ ..self, center_scale_mode, }
}

///|
pub fn TextureSlicer::with_sides_scale_mode(
  self : TextureSlicer,
  sides_scale_mode : SliceScaleMode,
) -> TextureSlicer {
  TextureSlicer::{ ..self, sides_scale_mode, }
}

///|
pub fn TextureSlicer::with_max_corner_scale(
  self : TextureSlicer,
  max_corner_scale : Float,
) -> TextureSlicer {
  TextureSlicer::{ ..self, max_corner_scale, }
}

///|
fn texture_slice_rect_size(rect : @math.Rect) -> @math.Vec2 {
  @math.Vec2::new(rect.max.x - rect.min.x, rect.max.y - rect.min.y)
}

///|
fn texture_slice_rect_min(rect : @math.Rect) -> @math.Vec2 {
  rect.min
}

///|
fn texture_slice_rect_max(rect : @math.Rect) -> @math.Vec2 {
  rect.max
}

///|
fn texture_slice_vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn texture_slice_vec2_sub(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x - b.x, a.y - b.y)
}

///|
fn texture_slice_vec2_mul_scalar(v : @math.Vec2, scalar : Float) -> @math.Vec2 {
  @math.Vec2::new(v.x * scalar, v.y * scalar)
}

///|
fn texture_slice_corner_scale(
  base_size : @math.Vec2,
  render_size : @math.Vec2,
  max_corner_scale : Float,
) -> Float {
  let scale_x = if base_size.x == 0.0F {
    1.0F
  } else {
    render_size.x / base_size.x
  }
  let scale_y = if base_size.y == 0.0F {
    1.0F
  } else {
    render_size.y / base_size.y
  }
  let min_scale = if scale_x < scale_y { scale_x } else { scale_y }
  if min_scale < max_corner_scale {
    min_scale
  } else {
    max_corner_scale
  }
}

///|
fn TextureSlicer::corner_slices(
  self : TextureSlicer,
  base_rect : @math.Rect,
  render_size : @math.Vec2,
) -> (TextureSlice, TextureSlice, TextureSlice, TextureSlice) {
  let scale = texture_slice_corner_scale(
    texture_slice_rect_size(base_rect),
    render_size,
    self.max_corner_scale,
  )
  let left = self.border.left
  let right = self.border.right
  let top = self.border.top
  let bottom = self.border.bottom
  let min = texture_slice_rect_min(base_rect)
  let max = texture_slice_rect_max(base_rect)
  (
    TextureSlice::{
      texture_rect: @math.Rect::new(
        min,
        texture_slice_vec2_add(min, @math.Vec2::new(left, top)),
      ),
      draw_size: texture_slice_vec2_mul_scalar(
        @math.Vec2::new(left, top),
        scale,
      ),
      offset: @math.Vec2::new(
        (-render_size.x + left * scale) / 2.0F,
        (render_size.y - top * scale) / 2.0F,
      ),
    },
    TextureSlice::{
      texture_rect: @math.Rect::new(
        @math.Vec2::new(max.x - right, min.y),
        @math.Vec2::new(max.x, min.y + top),
      ),
      draw_size: texture_slice_vec2_mul_scalar(
        @math.Vec2::new(right, top),
        scale,
      ),
      offset: @math.Vec2::new(
        (render_size.x - right * scale) / 2.0F,
        (render_size.y - top * scale) / 2.0F,
      ),
    },
    TextureSlice::{
      texture_rect: @math.Rect::new(
        @math.Vec2::new(min.x, max.y - bottom),
        @math.Vec2::new(min.x + left, max.y),
      ),
      draw_size: texture_slice_vec2_mul_scalar(
        @math.Vec2::new(left, bottom),
        scale,
      ),
      offset: @math.Vec2::new(
        (-render_size.x + left * scale) / 2.0F,
        (-render_size.y + bottom * scale) / 2.0F,
      ),
    },
    TextureSlice::{
      texture_rect: @math.Rect::new(
        @math.Vec2::new(max.x - right, max.y - bottom),
        max,
      ),
      draw_size: texture_slice_vec2_mul_scalar(
        @math.Vec2::new(right, bottom),
        scale,
      ),
      offset: @math.Vec2::new(
        (render_size.x - right * scale) / 2.0F,
        (-render_size.y + bottom * scale) / 2.0F,
      ),
    },
  )
}

///|
fn TextureSlicer::horizontal_side_slices(
  self : TextureSlicer,
  corners : (TextureSlice, TextureSlice, TextureSlice, TextureSlice),
  base_rect : @math.Rect,
  render_size : @math.Vec2,
) -> (TextureSlice, TextureSlice) {
  let left = corners.0
  let right = corners.1
  let bottom_left = corners.2
  let bottom_right = corners.3
  let min = texture_slice_rect_min(base_rect)
  let max = texture_slice_rect_max(base_rect)
  (
    TextureSlice::{
      texture_rect: @math.Rect::new(
        texture_slice_vec2_add(min, @math.Vec2::new(0.0F, self.border.top)),
        @math.Vec2::new(min.x + self.border.left, max.y - self.border.bottom),
      ),
      draw_size: @math.Vec2::new(
        left.draw_size.x,
        render_size.y - (left.draw_size.y + bottom_left.draw_size.y),
      ),
      offset: @math.Vec2::new(
        (left.draw_size.x - render_size.x) / 2.0F,
        (bottom_left.draw_size.y - left.draw_size.y) / 2.0F,
      ),
    },
    TextureSlice::{
      texture_rect: @math.Rect::new(
        @math.Vec2::new(max.x - self.border.right, min.y + self.border.top),
        texture_slice_vec2_sub(max, @math.Vec2::new(0.0F, self.border.bottom)),
      ),
      draw_size: @math.Vec2::new(
        right.draw_size.x,
        render_size.y - (right.draw_size.y + bottom_right.draw_size.y),
      ),
      offset: @math.Vec2::new(
        (render_size.x - right.draw_size.x) / 2.0F,
        (bottom_right.draw_size.y - right.draw_size.y) / 2.0F,
      ),
    },
  )
}

///|
fn TextureSlicer::vertical_side_slices(
  self : TextureSlicer,
  corners : (TextureSlice, TextureSlice, TextureSlice, TextureSlice),
  base_rect : @math.Rect,
  render_size : @math.Vec2,
) -> (TextureSlice, TextureSlice) {
  let top_left = corners.0
  let top_right = corners.1
  let bottom_left = corners.2
  let bottom_right = corners.3
  let min = texture_slice_rect_min(base_rect)
  let max = texture_slice_rect_max(base_rect)
  (
    TextureSlice::{
      texture_rect: @math.Rect::new(
        texture_slice_vec2_add(min, @math.Vec2::new(self.border.left, 0.0F)),
        @math.Vec2::new(max.x - self.border.right, min.y + self.border.top),
      ),
      draw_size: @math.Vec2::new(
        render_size.x - (top_left.draw_size.x + top_right.draw_size.x),
        top_left.draw_size.y,
      ),
      offset: @math.Vec2::new(
        (top_left.draw_size.x - top_right.draw_size.x) / 2.0F,
        (render_size.y - top_left.draw_size.y) / 2.0F,
      ),
    },
    TextureSlice::{
      texture_rect: @math.Rect::new(
        @math.Vec2::new(min.x + self.border.left, max.y - self.border.bottom),
        texture_slice_vec2_sub(max, @math.Vec2::new(self.border.right, 0.0F)),
      ),
      draw_size: @math.Vec2::new(
        render_size.x - (bottom_left.draw_size.x + bottom_right.draw_size.x),
        bottom_left.draw_size.y,
      ),
      offset: @math.Vec2::new(
        (bottom_left.draw_size.x - bottom_right.draw_size.x) / 2.0F,
        (bottom_left.draw_size.y - render_size.y) / 2.0F,
      ),
    },
  )
}

///|
pub fn TextureSlicer::compute_slices(
  self : TextureSlicer,
  rect : @math.Rect,
  render_size : @math.Vec2?,
) -> Array[TextureSlice] {
  let target_size = match render_size {
    Some(size) => size
    None => texture_slice_rect_size(rect)
  }
  let border_total = @math.Vec2::new(
    self.border.left + self.border.right,
    self.border.top + self.border.bottom,
  )
  let rect_size = texture_slice_rect_size(rect)
  if border_total.x >= rect_size.x || border_total.y >= rect_size.y {
    return [
      TextureSlice::{
        texture_rect: rect,
        draw_size: target_size,
        offset: @math.Vec2::new(0.0F, 0.0F),
      },
    ]
  }
  let corners = self.corner_slices(rect, target_size)
  let vertical_sides = self.vertical_side_slices(corners, rect, target_size)
  let horizontal_sides = self.horizontal_side_slices(corners, rect, target_size)
  let center = TextureSlice::{
    texture_rect: @math.Rect::new(
      texture_slice_vec2_add(
        texture_slice_rect_min(rect),
        @math.Vec2::new(self.border.left, self.border.top),
      ),
      texture_slice_vec2_sub(
        texture_slice_rect_max(rect),
        @math.Vec2::new(self.border.right, self.border.bottom),
      ),
    ),
    draw_size: @math.Vec2::new(
      target_size.x - (corners.0.draw_size.x + corners.1.draw_size.x),
      target_size.y - (corners.0.draw_size.y + corners.2.draw_size.y),
    ),
    offset: @math.Vec2::new(
      vertical_sides.0.offset.x,
      horizontal_sides.0.offset.y,
    ),
  }
  let slices : Array[TextureSlice] = [
    corners.0,
    corners.1,
    corners.2,
    corners.3,
  ]
  match self.center_scale_mode {
    SliceScaleMode::Stretch => slices.push(center)
    SliceScaleMode::Tile(stretch_value) =>
      for slice in center.tiled(stretch_value, (true, true)) {
        slices.push(slice)
      }
  }
  match self.sides_scale_mode {
    SliceScaleMode::Stretch => {
      slices.push(vertical_sides.0)
      slices.push(vertical_sides.1)
      slices.push(horizontal_sides.0)
      slices.push(horizontal_sides.1)
    }
    SliceScaleMode::Tile(stretch_value) => {
      for slice in vertical_sides.0.tiled(stretch_value, (true, false)) {
        slices.push(slice)
      }
      for slice in vertical_sides.1.tiled(stretch_value, (true, false)) {
        slices.push(slice)
      }
      for slice in horizontal_sides.0.tiled(stretch_value, (false, true)) {
        slices.push(slice)
      }
      for slice in horizontal_sides.1.tiled(stretch_value, (false, true)) {
        slices.push(slice)
      }
    }
  }
  slices
}
