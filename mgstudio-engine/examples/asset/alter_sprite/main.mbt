// Copyright 2026 International Digital Economy Academy
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
pub(all) enum BirdVariant {
  Normal
  Logo
}

///|
pub struct Bird {
  mut variant : BirdVariant
}

///|
pub fn Bird::normal() -> Bird {
  Bird::{ variant: BirdVariant::Normal }
}

///|
pub fn Bird::get_texture_path(self : Bird) -> String {
  match self.variant {
    Normal => "branding/bevy_bird_dark.png"
    Logo => "branding/bevy_logo_dark.png"
  }
}

///|
pub fn Bird::set_next_variant(self : Bird) -> Unit {
  self.variant = match self.variant {
    Normal => BirdVariant::Logo
    Logo => BirdVariant::Normal
  }
}

///|
struct Left {}

///|
let left_key : @ecs.ComponentKey[Left] = @ecs.register_component(
  debug_name="examples.asset.alter_sprite.Left",
)

///|
pub impl @ecs.Component for Left with component() {
  left_key
}

///|
let bird_key : @ecs.ComponentKey[Bird] = @ecs.register_component(
  debug_name="examples.asset.alter_sprite.Bird",
)

///|
pub impl @ecs.Component for Bird with component() {
  bird_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let bird_left = Bird::normal()
  let bird_right = Bird::normal()
  let texture_left : @asset.Handle[@asset.Image] = asset_server
    .get()
    .load_with_settings(bird_left.get_texture_path(), fn(settings) {
      settings.asset_usage = @asset.RenderAssetUsages::all()
    })

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Bird Left"),
        Left::{  },
        @sprite.Sprite::from_image(texture_left),
        @transform.Transform::from_xyz(-200.0F, 0.0F, 0.0F),
        bird_left,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Bird Right"),
        @sprite.Sprite::from_image(
          asset_server.get().load(bird_right.get_texture_path()),
        ),
        @transform.Transform::from_xyz(200.0F, 0.0F, 0.0F),
        bird_right,
      ),
    ),
  )
}

///|
fn spawn_text(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Instructions"),
        @text.Text::new(
          "Space: swap the right sprite's image handle\nEnter: modify the left sprite image asset",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(12.0F),
          left: @ui.Val::Px(12.0F),
        },
      ),
    ),
  )
}

///|
fn alter_handle(
  asset_server : @app.Res[@asset.AssetServer],
  right_bird : @ecs.Query[
    (@ecs.Mut[Bird], @ecs.Mut[@sprite.Sprite]),
    @ecs.Without[Left],
  ],
) -> Unit {
  try! right_bird.view(fn(_entity, data) {
    let (bird, sprite) = data
    let bird_ref = bird.get_ref()
    bird_ref.val.set_next_variant()
    sprite.get_ref().val.image = asset_server
      .get()
      .load(bird_ref.val.get_texture_path())
  })
}

///|
fn invert_pixels(pixels : Bytes) -> Bytes {
  Bytes::makei(pixels.length(), i => {
    let value = match pixels.get(i) {
      Some(byte) => byte.to_int() & 0xFF
      None => 0
    }
    (255 - value).to_byte()
  })
}

///|
fn alter_asset(
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  left_bird : @ecs.Query[@ecs.Comp[@sprite.Sprite], @ecs.With[Left]],
) -> Unit {
  guard (left_bird.single() catch { _ => None }) is Some(sprite_comp) else {
    return
  }
  let sprite = sprite_comp.value()
  guard images.get_ref().val.get_mut(sprite.image) is Some(image) else {
    return
  }
  image.pixels = invert_pixels(image.pixels)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Startup, @app.system(@app.system_param(spawn_text)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(alter_handle)).run_if(
      @input.input_just_pressed(@window.KeyCode::Space),
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(alter_asset)).run_if(
      @input.input_just_pressed(@window.KeyCode::Enter),
    ),
  )
  .run()
}
