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
pub fn SpriteScalingMode::default() -> SpriteScalingMode {
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
pub fn SpriteTiling::default() -> SpriteTiling {
  SpriteTiling::new(true, true, 1.0F)
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
pub fn SpriteImageMode::default() -> SpriteImageMode {
  SpriteImageMode::Auto
}

///|
pub fn SpriteImageMode::scale(
  scaling_mode? : SpriteScalingMode = SpriteScalingMode::FillCenter,
) -> SpriteImageMode {
  SpriteImageMode::Scale(scaling_mode)
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
