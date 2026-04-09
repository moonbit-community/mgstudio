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
// Bevy source: `bevy/crates/bevy_ui_render/src/ui_texture_slice_pipeline.rs`.
fn clamp_stretch_value(v : Float) -> Float {
  if v < 0.001F {
    0.001F
  } else {
    v
  }
}

///|
fn min3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a < b { a } else { b }
  if ab < c {
    ab
  } else {
    c
  }
}

///|
fn compute_tiled_axis(
  tile : Bool,
  image_extent : Float,
  target_extent : Float,
  stretch_value : Float,
) -> Float {
  if tile {
    let denom = image_extent * clamp_stretch_value(stretch_value)
    if denom == 0.0F {
      1.0F
    } else {
      target_extent / denom
    }
  } else {
    1.0F
  }
}

///|
fn compute_tiled_subaxis(
  image_extent : Float,
  target_extent : Float,
  mode : @ui.SliceScaleMode,
) -> Float {
  match mode {
    @ui.SliceScaleMode::Stretch => 1.0F
    @ui.SliceScaleMode::Tile(stretch_value) => {
      let denom = image_extent * clamp_stretch_value(stretch_value)
      if denom == 0.0F {
        1.0F
      } else {
        target_extent / denom
      }
    }
  }
}

///|
fn compute_texture_slices(
  image_size : @math.Vec2,
  target_size : @math.Vec2,
  mode : @ui.NodeImageMode,
) -> (@math.Vec4, @math.Vec4, @math.Vec4) {
  match mode {
    @ui.NodeImageMode::Sliced(slicer) => {
      let denom_x = if image_size.x == 0.0F { 1.0F } else { image_size.x }
      let denom_y = if image_size.y == 0.0F { 1.0F } else { image_size.y }
      let tdenom_x = if target_size.x == 0.0F { 1.0F } else { target_size.x }
      let tdenom_y = if target_size.y == 0.0F { 1.0F } else { target_size.y }
      let min_coeff = min3(
        target_size.x / denom_x,
        target_size.y / denom_y,
        slicer.max_corner_scale,
      )
      let slices = @math.Vec4::new(
        slicer.border.left / denom_x,
        slicer.border.top / denom_y,
        1.0F - slicer.border.right / denom_x,
        1.0F - slicer.border.bottom / denom_y,
      )
      let border = @math.Vec4::new(
        slicer.border.left / tdenom_x * min_coeff,
        slicer.border.top / tdenom_y * min_coeff,
        1.0F - slicer.border.right / tdenom_x * min_coeff,
        1.0F - slicer.border.bottom / tdenom_y * min_coeff,
      )
      let image_side_width = denom_x * (slices.z - slices.x)
      let image_side_height = denom_y * (slices.w - slices.y)
      let target_side_width = tdenom_x * (border.z - border.x)
      let target_side_height = tdenom_y * (border.w - border.y)
      let repeat_side_x = compute_tiled_subaxis(
        image_side_width,
        target_side_width,
        slicer.sides_scale_mode,
      )
      let repeat_side_y = compute_tiled_subaxis(
        image_side_height,
        target_side_height,
        slicer.sides_scale_mode,
      )
      let repeat_center_x = compute_tiled_subaxis(
        image_side_width,
        target_side_width,
        slicer.center_scale_mode,
      )
      let repeat_center_y = compute_tiled_subaxis(
        image_side_height,
        target_side_height,
        slicer.center_scale_mode,
      )
      (
        slices,
        border,
        @math.Vec4::new(
          repeat_side_x, repeat_side_y, repeat_center_x, repeat_center_y,
        ),
      )
    }
    @ui.NodeImageMode::Tiled(tile_x, tile_y, stretch_value) => {
      let rx = compute_tiled_axis(
        tile_x,
        image_size.x,
        target_size.x,
        stretch_value,
      )
      let ry = compute_tiled_axis(
        tile_y,
        image_size.y,
        target_size.y,
        stretch_value,
      )
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, rx, ry),
      )
    }
    _ =>
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
      )
  }
}

///|
fn vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn ui_uv_from_image_rects(
  image_size : @math.Vec2,
  atlas_rect : @math.Rect?,
  rect : @math.Rect?,
  flip_x : Bool,
  flip_y : Bool,
) -> (@math.Vec2, @math.Vec2) {
  let denom_x = image_size.x
  let denom_y = image_size.y
  if denom_x <= 0.0F || denom_y <= 0.0F {
    return (@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F))
  }
  let image_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(denom_x, denom_y),
  )
  let texture_rect = match (atlas_rect, rect) {
    (None, None) => image_rect
    (None, Some(r)) => r
    (Some(ar), None) => ar
    (Some(ar), Some(r)) => {
      let min = vec2_add(r.min, ar.min)
      let max = vec2_add(r.max, ar.min)
      @math.Rect::new(min, max)
    }
  }
  let mut uv_min = @math.Vec2::new(
    texture_rect.min.x / denom_x,
    texture_rect.min.y / denom_y,
  )
  let mut uv_max = @math.Vec2::new(
    texture_rect.max.x / denom_x,
    texture_rect.max.y / denom_y,
  )
  if flip_x {
    let tmp = uv_min.x
    uv_min = @math.Vec2::new(uv_max.x, uv_min.y)
    uv_max = @math.Vec2::new(tmp, uv_max.y)
  }
  if flip_y {
    let tmp = uv_min.y
    uv_min = @math.Vec2::new(uv_min.x, uv_max.y)
    uv_max = @math.Vec2::new(uv_max.x, tmp)
  }
  (uv_min, uv_max)
}
