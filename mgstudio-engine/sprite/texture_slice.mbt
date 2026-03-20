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
pub struct TextureSlice {
  texture_rect : @math.Rect
  draw_size : @math.Vec2
  offset : @math.Vec2
}

///|
fn texture_slice_module_rect_size(rect : @math.Rect) -> @math.Vec2 {
  @math.Vec2::new(rect.max.x - rect.min.x, rect.max.y - rect.min.y)
}

///|
fn texture_slice_expected_axis(
  texture_extent : Float,
  draw_extent : Float,
  tile : Bool,
  stretch_value : Float,
) -> Float {
  if !tile {
    draw_extent
  } else {
    let stretch = if stretch_value < 0.001F { 0.001F } else { stretch_value }
    let expected = texture_extent * stretch
    if expected < 1.0F {
      1.0F
    } else if expected > draw_extent {
      draw_extent
    } else {
      expected
    }
  }
}

///|
pub fn TextureSlice::tiled(
  self : TextureSlice,
  stretch_value : Float,
  tile : (Bool, Bool),
) -> Array[TextureSlice] {
  let tile_x = tile.0
  let tile_y = tile.1
  if !tile_x && !tile_y {
    return [self]
  }
  let rect_size = texture_slice_module_rect_size(self.texture_rect)
  let expected_size = @math.Vec2::new(
    texture_slice_expected_axis(
      rect_size.x,
      self.draw_size.x,
      tile_x,
      stretch_value,
    ),
    texture_slice_expected_axis(
      rect_size.y,
      self.draw_size.y,
      tile_y,
      stretch_value,
    ),
  )
  let base_offset = @math.Vec2::new(
    -self.draw_size.x / 2.0F,
    self.draw_size.y / 2.0F,
  )
  let slices : Array[TextureSlice] = []
  let mut offset_y = base_offset.y
  let mut remaining_columns = self.draw_size.y
  while remaining_columns > 0.0F {
    let size_y = if expected_size.y < remaining_columns {
      expected_size.y
    } else {
      remaining_columns
    }
    let mut offset_x = base_offset.x
    offset_y = offset_y - size_y / 2.0F
    let mut remaining_rows = self.draw_size.x
    while remaining_rows > 0.0F {
      let size_x = if expected_size.x < remaining_rows {
        expected_size.x
      } else {
        remaining_rows
      }
      offset_x = offset_x + size_x / 2.0F
      let draw_size = @math.Vec2::new(size_x, size_y)
      let delta = @math.Vec2::new(
        if expected_size.x == 0.0F {
          0.0F
        } else {
          draw_size.x / expected_size.x
        },
        if expected_size.y == 0.0F {
          0.0F
        } else {
          draw_size.y / expected_size.y
        },
      )
      let texture_size = texture_slice_module_rect_size(self.texture_rect)
      slices.push(TextureSlice::{
        texture_rect: @math.Rect::new(
          self.texture_rect.min,
          @math.Vec2::new(
            self.texture_rect.min.x + texture_size.x * delta.x,
            self.texture_rect.min.y + texture_size.y * delta.y,
          ),
        ),
        draw_size,
        offset: @math.Vec2::new(
          self.offset.x + offset_x,
          self.offset.y + offset_y,
        ),
      })
      offset_x = offset_x + size_x / 2.0F
      remaining_rows = remaining_rows - size_x
    }
    offset_y = offset_y - size_y / 2.0F
    remaining_columns = remaining_columns - size_y
  }
  slices
}
