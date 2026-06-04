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
pub(all) struct Sprite {
  mut image : @asset.Handle[@asset.Image]
  mut texture_atlas : @asset.TextureAtlas?
  mut color : Color
  mut flip_x : Bool
  mut flip_y : Bool
  mut custom_size : @math.Vec2?
  mut rect : @math.Rect?
  mut image_mode : SpriteImageMode
}

///|
pub(all) enum SpriteScalingMode {
  FillCenter
  FillStart
  FillEnd
  FitCenter
  FitStart
  FitEnd
}

///|
pub impl Default for SpriteScalingMode with fn default() {
  SpriteScalingMode::FillCenter
}

///|
pub struct SpriteTiling {
  tile_x : Bool
  tile_y : Bool
  stretch_value : Float
}

///|
pub fn SpriteTiling::new(
  tile_x : Bool,
  tile_y : Bool,
  stretch_value : Float,
) -> SpriteTiling {
  SpriteTiling::{ tile_x, tile_y, stretch_value }
}

///|
pub fn SpriteTiling::SpriteTiling() -> SpriteTiling {
  SpriteTiling::new(true, true, 1.0F)
}

///|
pub impl Default for SpriteTiling with fn default() {
  SpriteTiling::SpriteTiling()
}

///|
pub fn SpriteTiling::with_tile_x(
  self : SpriteTiling,
  tile_x : Bool,
) -> SpriteTiling {
  SpriteTiling::{ ..self, tile_x, }
}

///|
pub fn SpriteTiling::with_tile_y(
  self : SpriteTiling,
  tile_y : Bool,
) -> SpriteTiling {
  SpriteTiling::{ ..self, tile_y, }
}

///|
pub fn SpriteTiling::with_stretch_value(
  self : SpriteTiling,
  stretch_value : Float,
) -> SpriteTiling {
  SpriteTiling::{ ..self, stretch_value, }
}

///|
pub(all) enum SpriteImageMode {
  Auto
  Scale(SpriteScalingMode)
  Sliced(TextureSlicer)
  Tiled(SpriteTiling)
}

///|
pub impl Default for SpriteImageMode with fn default() {
  SpriteImageMode::Auto
}

///|
pub struct Anchor {
  value : @math.Vec2
}

///|
pub fn Anchor::new(value : @math.Vec2) -> Anchor {
  Anchor::{ value, }
}

///|
pub fn Anchor::as_vec(self : Anchor) -> @math.Vec2 {
  self.value
}

///|
pub fn Anchor::bottom_left() -> Anchor {
  Anchor::new(@math.Vec2::new(-0.5F, -0.5F))
}

///|
pub fn Anchor::bottom_center() -> Anchor {
  Anchor::new(@math.Vec2::new(0.0F, -0.5F))
}

///|
pub fn Anchor::bottom_right() -> Anchor {
  Anchor::new(@math.Vec2::new(0.5F, -0.5F))
}

///|
pub fn Anchor::center_left() -> Anchor {
  Anchor::new(@math.Vec2::new(-0.5F, 0.0F))
}

///|
pub fn Anchor::center() -> Anchor {
  Anchor::new(@math.Vec2::new(0.0F, 0.0F))
}

///|
pub fn Anchor::center_right() -> Anchor {
  Anchor::new(@math.Vec2::new(0.5F, 0.0F))
}

///|
pub fn Anchor::top_left() -> Anchor {
  Anchor::new(@math.Vec2::new(-0.5F, 0.5F))
}

///|
pub fn Anchor::top_center() -> Anchor {
  Anchor::new(@math.Vec2::new(0.0F, 0.5F))
}

///|
pub fn Anchor::top_right() -> Anchor {
  Anchor::new(@math.Vec2::new(0.5F, 0.5F))
}

///|
pub fn Anchor::Anchor() -> Anchor {
  Anchor::center()
}

///|
pub impl Default for Anchor with fn default() {
  Anchor::Anchor()
}

///|
pub fn SpriteImageMode::scale(self : SpriteImageMode) -> SpriteScalingMode? {
  match self {
    SpriteImageMode::Scale(mode) => Some(mode)
    _ => None
  }
}

///|
pub fn SpriteImageMode::uses_slices(self : SpriteImageMode) -> Bool {
  match self {
    SpriteImageMode::Sliced(_) => true
    SpriteImageMode::Tiled(_) => true
    _ => false
  }
}

///|
pub fn SpriteImageMode::tiled(
  tile_x? : Bool = true,
  tile_y? : Bool = true,
  stretch_value? : Float = 1.0F,
) -> SpriteImageMode {
  SpriteImageMode::Tiled(SpriteTiling::new(tile_x, tile_y, stretch_value))
}

///|
pub fn Sprite::Sprite() -> Sprite {
  Sprite::from_image(@asset.Handle::new(0))
}

///|
pub impl Default for Sprite with fn default() {
  Sprite::Sprite()
}

///|
pub fn Sprite::from_image(image : @asset.Handle[@asset.Image]) -> Sprite {
  Sprite::{
    image,
    texture_atlas: None,
    color: Color::white(),
    flip_x: false,
    flip_y: false,
    custom_size: None,
    rect: None,
    image_mode: SpriteImageMode::Auto,
  }
}

///|
pub fn Sprite::sized(size : @math.Vec2) -> Sprite {
  Sprite::from_image(@asset.asset_white_texture()).with_custom_size(Some(size))
}

///|
pub fn Sprite::from_color(color : Color, size : @math.Vec2) -> Sprite {
  Sprite::{ ..Sprite(), color, custom_size: Some(size) }
}

///|
fn sprite_texture_rect_for_pixel_space(
  image : @asset.Handle[@asset.Image],
  texture_atlas : @asset.TextureAtlas?,
  rect : @math.Rect?,
  texture_atlases : @asset.Assets[@asset.TextureAtlasLayout],
) -> @math.Rect {
  let image_size = @math.Vec2::new(
    Float::from_int(@asset.asset_texture_width(image).max(1)),
    Float::from_int(@asset.asset_texture_height(image).max(1)),
  )
  let atlas_rect = match texture_atlas {
    Some(atlas) =>
      atlas.texture_rect(texture_atlases).map(fn(value) { value.as_rect() })
    None => None
  }
  match (atlas_rect, rect) {
    (None, None) => @math.Rect::new(@math.Vec2::zero(), image_size)
    (None, Some(sprite_rect)) => sprite_rect
    (Some(atlas), None) => atlas
    (Some(atlas), Some(sprite_rect)) => sprite_rect.translate(atlas.min())
  }
}

///|
pub(all) enum SpritePixelSpacePoint {
  Inside(@math.Vec2)
  Outside(@math.Vec2)
}

///|
pub fn SpritePixelSpacePoint::point(self : SpritePixelSpacePoint) -> @math.Vec2 {
  match self {
    Inside(point) => point
    Outside(point) => point
  }
}

///|
pub fn SpritePixelSpacePoint::is_inside(self : SpritePixelSpacePoint) -> Bool {
  match self {
    Inside(_) => true
    Outside(_) => false
  }
}

///|
fn sprite_compute_pixel_space_point(
  image : @asset.Handle[@asset.Image],
  texture_atlas : @asset.TextureAtlas?,
  rect : @math.Rect?,
  custom_size : @math.Vec2?,
  flip_x : Bool,
  flip_y : Bool,
  point_relative_to_sprite : @math.Vec2,
  anchor : Anchor,
  texture_atlases : @asset.Assets[@asset.TextureAtlasLayout],
) -> SpritePixelSpacePoint {
  let texture_rect = sprite_texture_rect_for_pixel_space(
    image, texture_atlas, rect, texture_atlases,
  )
  let sprite_size = custom_size.unwrap_or(texture_rect.size())
  let sprite_center = @math.Vec2::new(
    -anchor.as_vec().x * sprite_size.x,
    -anchor.as_vec().y * sprite_size.y,
  )
  let point_relative_to_sprite_center = point_relative_to_sprite.sub(
    sprite_center,
  )
  if flip_x {
    point_relative_to_sprite_center.x = -point_relative_to_sprite_center.x
  }
  if !flip_y {
    point_relative_to_sprite_center.y = -point_relative_to_sprite_center.y
  }
  if sprite_size.x == 0.0F || sprite_size.y == 0.0F {
    return Outside(point_relative_to_sprite_center)
  }
  let texture_size = texture_rect.size()
  let sprite_to_texture_ratio = @math.Vec2::new(
    texture_size.x / sprite_size.x,
    texture_size.y / sprite_size.y,
  )
  let point_relative_to_texture = @math.Vec2::new(
    point_relative_to_sprite_center.x * sprite_to_texture_ratio.x,
    point_relative_to_sprite_center.y * sprite_to_texture_ratio.y,
  ).add(texture_rect.center())
  if texture_rect.contains(point_relative_to_texture) {
    Inside(point_relative_to_texture)
  } else {
    Outside(point_relative_to_texture)
  }
}

///|
pub fn Sprite::compute_pixel_space_point(
  self : Sprite,
  point_relative_to_sprite : @math.Vec2,
  anchor : Anchor,
  _images : @asset.Assets[@asset.Image],
  texture_atlases : @asset.Assets[@asset.TextureAtlasLayout],
) -> SpritePixelSpacePoint {
  sprite_compute_pixel_space_point(
    self.image,
    self.texture_atlas,
    self.rect,
    self.custom_size,
    self.flip_x,
    self.flip_y,
    point_relative_to_sprite,
    anchor,
    texture_atlases,
  )
}

///|
pub fn Sprite::from_atlas_image(
  image : @asset.Handle[@asset.Image],
  atlas : @asset.TextureAtlas,
) -> Sprite {
  Sprite::{ ..Sprite::from_image(image), texture_atlas: Some(atlas) }
}

///|
pub fn Sprite::with_texture_atlas(
  self : Sprite,
  texture_atlas : @asset.TextureAtlas?,
) -> Sprite {
  Sprite::{ ..self, texture_atlas, }
}

///|
pub fn Sprite::with_color(self : Sprite, color : Color) -> Sprite {
  Sprite::{ ..self, color, }
}

///|
pub fn Sprite::with_flip_x(self : Sprite, flip_x : Bool) -> Sprite {
  Sprite::{ ..self, flip_x, }
}

///|
pub fn Sprite::with_flip_y(self : Sprite, flip_y : Bool) -> Sprite {
  Sprite::{ ..self, flip_y, }
}

///|
pub fn Sprite::with_custom_size(
  self : Sprite,
  custom_size : @math.Vec2?,
) -> Sprite {
  Sprite::{ ..self, custom_size, }
}

///|
pub fn Sprite::with_rect(self : Sprite, rect : @math.Rect?) -> Sprite {
  Sprite::{ ..self, rect, }
}

///|
pub fn Sprite::with_image_mode(
  self : Sprite,
  image_mode : SpriteImageMode,
) -> Sprite {
  Sprite::{ ..self, image_mode, }
}
