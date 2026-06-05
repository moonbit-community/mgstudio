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
pub fn apply_scale_sprite_image_mode(
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
    -0.5F * local_offset_target.x * draw_sign_x,
    -0.5F * local_offset_target.y * draw_sign_y,
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
pub fn apply_sprite_image_mode(
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
  draw_scale : @math.Vec2,
  region_size : @math.Vec2,
  image_mode : SpriteImageMode,
  has_custom_size : Bool,
) -> (@math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2, Bool) {
  if has_custom_size {
    match image_mode.scale() {
      Some(scaling_mode) => {
        let (scaled_uv_min, scaled_uv_max, scaled_draw_scale, local_offset) = apply_scale_sprite_image_mode(
          uv_min, uv_max, draw_scale, region_size, scaling_mode,
        )
        (scaled_uv_min, scaled_uv_max, scaled_draw_scale, local_offset, false)
      }
      None => (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F), false)
    }
  } else {
    (uv_min, uv_max, draw_scale, @math.Vec2::new(0.0F, 0.0F), false)
  }
}

///|
pub struct ComputedTextureSlices {
  slices : Array[TextureSlice]
}

///|
pub let ecs_key_computed_texture_slices : @ecs.ComponentKey[
  ComputedTextureSlices,
] = @ecs.register_component(
  debug_name="mgstudio.sprite_render.ComputedTextureSlices",
)

///|
impl @ecs.Component for ComputedTextureSlices with fn component() {
  ecs_key_computed_texture_slices
}

///|
pub fn ComputedTextureSlices::extract_slices(
  self : ComputedTextureSlices,
  sprite : Sprite,
  anchor : Anchor,
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
  let anchor_size = match sprite.custom_size {
    Some(size) => size
    None =>
      match sprite.rect {
        Some(rect) => rect.size()
        None => @math.Vec2::zero()
      }
  }
  let anchor_offset = @math.Vec2::new(
    anchor.as_vec().x * anchor_size.x,
    anchor.as_vec().y * anchor_size.y,
  )
  let extracted : Array[TextureSlice] = []
  for slice in self.slices {
    extracted.push(TextureSlice::{
      texture_rect: slice.texture_rect,
      draw_size: slice.draw_size,
      offset: @math.Vec2::new(
        slice.offset.x * flip.x - anchor_offset.x,
        slice.offset.y * flip.y - anchor_offset.y,
      ),
    })
  }
  extracted
}

///|
fn compute_sprite_slices(
  sprite : Sprite,
  images : @asset.Assets[@asset.Image],
  texture_atlas_layouts : @asset.Assets[@asset.TextureAtlasLayout],
) -> ComputedTextureSlices? {
  let (image_size, texture_rect) = match sprite.texture_atlas {
    Some(atlas) =>
      match texture_atlas_layouts.get(atlas.layout()) {
        Some(layout) =>
          match atlas.texture_rect(texture_atlas_layouts) {
            Some(rect) => (layout.size().to_vec2(), rect.as_rect())
            None => return None
          }
        None => return None
      }
    None =>
      match images.get(sprite.image) {
        Some(image) => {
          let size = @math.Vec2::new(
            Float::from_int(image.width()),
            Float::from_int(image.height()),
          )
          let rect = match sprite.rect {
            Some(rect) => rect
            None => sprite_rect_from_size(size)
          }
          (size, rect)
        }
        None => return None
      }
  }
  compute_sprite_slices_from_rect(sprite, image_size, texture_rect)
}

///|
pub fn compute_sprite_slices_from_rect(
  sprite : Sprite,
  image_size : @math.Vec2,
  texture_rect : @math.Rect,
) -> ComputedTextureSlices? {
  match sprite.image_mode {
    SpriteImageMode::Sliced(slicer) =>
      Some(ComputedTextureSlices::{
        slices: slicer.compute_slices(texture_rect, sprite.custom_size),
      })
    SpriteImageMode::Tiled(tiling) => {
      let slice = TextureSlice::{
        texture_rect,
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

///|
pub let sprite_systems_compute_slices : @app.SystemSet = @app.system_set(
  "mgstudio.sprite_render.SpriteSystems.ComputeSlices",
)

///|
fn insert_computed_texture_slices_for_sprite(
  commands : @app.Commands,
  entity : @core.Entity,
  sprite : Sprite,
  images : @asset.Assets[@asset.Image],
  texture_atlas_layouts : @asset.Assets[@asset.TextureAtlasLayout],
) -> Unit {
  match compute_sprite_slices(sprite, images, texture_atlas_layouts) {
    Some(slices) => commands.entity(entity).insert_component(slices)
    None => ()
  }
}

///|
pub type ComputedSlicesAssetParams = @app.ParamSet2[
  @app.Res[@asset.Assets[@asset.Image]],
  @app.Res[@asset.Assets[@asset.TextureAtlasLayout]],
]

///|
pub type ComputedSlicesChangedSpritesQuery = @ecs.Query[
  @ecs.Comp[Sprite],
  @ecs.Changed[Sprite],
]

///|
pub type ComputedSlicesAllSpritesQuery = @ecs.Query[@ecs.Comp[Sprite], @ecs.All]

///|
pub type ComputedSlicesAssetEventParams = @app.ParamSet2[
  @ecs.MessageReader[@asset.AssetEvent[@asset.Image]],
  ComputedSlicesAllSpritesQuery,
]

///|
pub fn compute_slices_on_sprite_change_system(
  commands : @app.Commands,
  assets : ComputedSlicesAssetParams,
  changed_sprites : ComputedSlicesChangedSpritesQuery,
) -> Unit {
  let images = assets.p0().get()
  let texture_atlas_layouts = assets.p1().get()
  try! changed_sprites.view(fn(entity, sprite_comp) {
    let sprite = sprite_comp.value()
    if !sprite.image_mode.uses_slices() {
      return
    }
    insert_computed_texture_slices_for_sprite(
      commands, entity, sprite, images, texture_atlas_layouts,
    )
  })
}

///|
pub fn compute_slices_on_asset_event_system(
  commands : @app.Commands,
  assets : ComputedSlicesAssetParams,
  params : ComputedSlicesAssetEventParams,
) -> Unit {
  let changed_handles : @hashset.HashSet[Int] = @hashset.HashSet([])
  for event in params.p0().read() {
    match event {
      Added(handle) | Modified(handle) => changed_handles.add(handle.id())
      _ => ()
    }
  }
  if changed_handles.is_empty() {
    return
  }
  let images = assets.p0().get()
  let texture_atlas_layouts = assets.p1().get()
  let sprites = params.p1()
  try! sprites.view(fn(entity, sprite_comp) {
    let sprite = sprite_comp.value()
    if !sprite.image_mode.uses_slices() {
      return
    }
    if !changed_handles.contains(sprite.image.id()) {
      return
    }
    insert_computed_texture_slices_for_sprite(
      commands, entity, sprite, images, texture_atlas_layouts,
    )
  })
}

///|
test "sprite: computed texture slice insertion is deferred until after sprite query" {
  let spawned : Ref[@core.Entity?] = Ref(None)
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_startup_system_param2(fn(
      commands : @app.Commands,
      images : @app.ResMut[@asset.Assets[@asset.Image]],
    ) {
      let image = images.modify(fn(value) {
        value.add(@asset.Image::new(32, 32, Bytes::new(32 * 32 * 4)))
      })
      let sprite = Sprite::from_image(image)
        .with_custom_size(Some(@math.Vec2::new(96.0F, 64.0F)))
        .with_image_mode(
          SpriteImageMode::Sliced(TextureSlicer::new(BorderRect::square(8.0F))),
        )
      spawned.val = Some(commands.spawn_component(sprite))
    })
    .add_system_param3(compute_slices_on_sprite_change_system)
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected sliced sprite entity")
  }
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_computed_texture_slices))
    is Some(_),
    content="true",
  )
}
