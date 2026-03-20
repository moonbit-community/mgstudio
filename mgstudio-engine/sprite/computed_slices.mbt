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
fn sprite_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn sprite_rect_from_size(size : @math.Vec2) -> @math.Rect {
  @math.Rect::new(@math.Vec2::new(0.0F, 0.0F), size)
}

///|
fn apply_scale_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  scaling_mode : SpriteScalingMode,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2) {
  let region_w = sprite_abs_float(region_size.x)
  let region_h = sprite_abs_float(region_size.y)
  if region_w <= 0.0F || region_h <= 0.0F {
    return (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F))
  }
  let draw_sign_x = if draw_scale.x < 0.0F { -1.0F } else { 1.0F }
  let draw_sign_y = if draw_scale.y < 0.0F { -1.0F } else { 1.0F }
  let mut target_size = @math.Vec2::new(
    sprite_abs_float(draw_scale.x) * region_w,
    sprite_abs_float(draw_scale.y) * region_h,
  )
  if target_size.x <= 0.0F || target_size.y <= 0.0F {
    return (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F))
  }

  let texture_ratio = region_w / region_h
  let quad_ratio = target_size.x / target_size.y
  if texture_ratio <= 0.0F || quad_ratio <= 0.0F {
    return (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F))
  }

  let tex_quad_scale = texture_ratio / quad_ratio
  let quad_tex_scale = quad_ratio / texture_ratio
  let mut uv_offset_scale = @math.Vec4::new(
    uv_min.x,
    uv_min.y,
    uv_max.x - uv_min.x,
    uv_max.y - uv_min.y,
  )
  let mut local_offset_target = @math.Vec2::new(0.0F, 0.0F)

  match scaling_mode {
    FillCenter =>
      if quad_ratio > texture_ratio {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y +
          (uv_offset_scale.w - uv_offset_scale.w * tex_quad_scale) * 0.5F,
          uv_offset_scale.z,
          uv_offset_scale.w * tex_quad_scale,
        )
      } else {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x +
          (uv_offset_scale.z - uv_offset_scale.z * quad_tex_scale) * 0.5F,
          uv_offset_scale.y,
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.w,
        )
      }
    FillStart =>
      if quad_ratio > texture_ratio {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y +
          uv_offset_scale.w -
          uv_offset_scale.w * tex_quad_scale,
          uv_offset_scale.z,
          uv_offset_scale.w * tex_quad_scale,
        )
      } else {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y,
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.w,
        )
      }
    FillEnd =>
      if quad_ratio > texture_ratio {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x,
          uv_offset_scale.y,
          uv_offset_scale.z,
          uv_offset_scale.w * tex_quad_scale,
        )
      } else {
        uv_offset_scale = @math.Vec4::new(
          uv_offset_scale.x +
          uv_offset_scale.z -
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.y,
          uv_offset_scale.z * quad_tex_scale,
          uv_offset_scale.w,
        )
      }
    FitCenter =>
      if texture_ratio > quad_ratio {
        target_size = @math.Vec2::new(
          target_size.x,
          target_size.x / texture_ratio,
        )
      } else {
        target_size = @math.Vec2::new(
          target_size.y * texture_ratio,
          target_size.y,
        )
      }
    FitStart =>
      if texture_ratio > quad_ratio {
        let new_quad = @math.Vec2::new(
          target_size.x,
          target_size.x / texture_ratio,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(0.0F, -offset.y)
        target_size = new_quad
      } else {
        let new_quad = @math.Vec2::new(
          target_size.y * texture_ratio,
          target_size.y,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(offset.x, 0.0F)
        target_size = new_quad
      }
    FitEnd =>
      if texture_ratio > quad_ratio {
        let new_quad = @math.Vec2::new(
          target_size.x,
          target_size.x / texture_ratio,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(0.0F, offset.y)
        target_size = new_quad
      } else {
        let new_quad = @math.Vec2::new(
          target_size.y * texture_ratio,
          target_size.y,
        )
        let offset = @math.Vec2::new(
          target_size.x - new_quad.x,
          target_size.y - new_quad.y,
        )
        local_offset_target = @math.Vec2::new(-offset.x, 0.0F)
        target_size = new_quad
      }
  }

  let next_draw_scale = @math.Vec2::new(
    draw_sign_x * target_size.x / region_w,
    draw_sign_y * target_size.y / region_h,
  )
  let local_offset = @math.Vec2::new(
    local_offset_target.x / region_w,
    local_offset_target.y / region_h,
  )
  (
    @math.Vec2::new(uv_offset_scale.x, uv_offset_scale.y),
    @math.Vec2::new(
      uv_offset_scale.x + uv_offset_scale.z,
      uv_offset_scale.y + uv_offset_scale.w,
    ),
    next_draw_scale,
    local_offset,
  )
}

///|
fn apply_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  image_mode : SpriteImageMode,
  has_custom_size : Bool,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2, Bool) {
  match image_mode {
    SpriteImageMode::Scale(scaling_mode) =>
      if has_custom_size {
        let (scaled_uv_min, scaled_uv_max, scaled_draw_scale, local_offset) = apply_scale_sprite_image_mode(
          uv_min, uv_max, draw_scale, region_size, scaling_mode,
        )
        (scaled_uv_min, scaled_uv_max, scaled_draw_scale, local_offset, false)
      } else {
        (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F), false)
      }
    _ => (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F), false)
  }
}

///|
priv struct ComputedTextureSlices {
  slices : Array[TextureSlice]
}

///|
fn ComputedTextureSlices::extract_slices(
  self : ComputedTextureSlices,
  sprite : Sprite,
  anchor : Anchor,
  transform_scale : @math.Vec2,
  base_size : @math.Vec2,
) -> Array[TextureSlice] {
  let flip = @math.Vec2::new(
    if sprite.flip_x {
      -1.0F
    } else {
      1.0F
    },
    if sprite.flip_y {
      -1.0F
    } else {
      1.0F
    },
  )
  let scaled_size = @math.Vec2::new(
    base_size.x * sprite_abs_float(transform_scale.x),
    base_size.y * sprite_abs_float(transform_scale.y),
  )
  let anchor_offset = @math.Vec2::new(
    anchor.as_vec().x * scaled_size.x,
    anchor.as_vec().y * scaled_size.y,
  )
  let extracted : Array[TextureSlice] = []
  for slice in self.slices {
    extracted.push(TextureSlice::{
      texture_rect: slice.texture_rect,
      draw_size: @math.Vec2::new(
        slice.draw_size.x * sprite_abs_float(transform_scale.x),
        slice.draw_size.y * sprite_abs_float(transform_scale.y),
      ),
      offset: @math.Vec2::new(
        slice.offset.x * flip.x * sprite_abs_float(transform_scale.x) -
        anchor_offset.x,
        slice.offset.y * flip.y * sprite_abs_float(transform_scale.y) -
        anchor_offset.y,
      ),
    })
  }
  extracted
}

///|
fn compute_sprite_slices(
  sprite : Sprite,
  image_size : @math.Vec2,
) -> ComputedTextureSlices? {
  match sprite.image_mode {
    SpriteImageMode::Sliced(slicer) =>
      Some(ComputedTextureSlices::{
        slices: slicer.compute_slices(
          sprite_rect_from_size(image_size),
          sprite.custom_size,
        ),
      })
    SpriteImageMode::Tiled(tiling) => {
      let slice = TextureSlice::{
        texture_rect: sprite_rect_from_size(image_size),
        draw_size: match sprite.custom_size {
          Some(size) => size
          None => image_size
        },
        offset: @math.Vec2::new(0.0F, 0.0F),
      }
      Some(ComputedTextureSlices::{
        slices: slice.tiled(
          tiling.stretch_value,
          (tiling.tile_x, tiling.tile_y),
        ),
      })
    }
    _ => None
  }
}
