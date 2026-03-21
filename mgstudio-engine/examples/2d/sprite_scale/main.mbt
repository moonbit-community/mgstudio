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
const LABEL_FONT_SIZE : Float = 15.0F

///|
const LABEL_VERTICAL_GAP : Float = 10.0F

///|
const ATLAS_FIRST_FRAME : Int = 0

///|
const ATLAS_LAST_FRAME : Int = 6

///|
struct Rect {
  size : @math.Vec2
  text : String
  translation : @math.Vec3
  texture : @asset.Handle[@asset.Image]
  image_mode : @sprite.SpriteImageMode
}

///|
struct SpriteSheet {
  size : @math.Vec2
  text : String
  translation : @math.Vec3
  texture : @asset.Handle[@asset.Image]
  image_mode : @sprite.SpriteImageMode
  atlas : @asset.TextureAtlas
  indices : AnimationIndices
  timer : AnimationTimer
}

///|
struct AnimationIndices {
  first : Int
  last : Int
}

///|
let animation_indices_key : @ecs.ComponentKey[AnimationIndices] = @ecs.register_component(
  debug_name="examples.2d.sprite_scale.AnimationIndices",
)

///|
pub impl @ecs.Component for AnimationIndices with component() {
  animation_indices_key
}

///|
struct AnimationTimer {
  mut timer : @time.Timer
}

///|
let animation_timer_key : @ecs.ComponentKey[AnimationTimer] = @ecs.register_component(
  debug_name="examples.2d.sprite_scale.AnimationTimer",
)

///|
pub impl @ecs.Component for AnimationTimer with component() {
  animation_timer_key
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup_sprites)))
  .add_systems(
    @app.Startup,
    @app.system(@app.system_param3(setup_texture_atlas)),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param(setup_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_sprite)))
  .run()
}

///|
fn setup_camera(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
}

///|
fn setup_sprites(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let square = asset_server.get().load("textures/slice_square_2.png")
  let banner = asset_server.get().load("branding/banner.png")
  let text_style = @text.TextFont::from_font_size(LABEL_FONT_SIZE).with_font(
    asset_server.get().load_font("fonts/FiraSans-Bold.ttf"),
  )

  let rects : Array[Rect] = [
    Rect::{
      size: @math.Vec2::new(100.0F, 225.0F),
      text: "Stretched",
      translation: @math.Vec3::new(-570.0F, 230.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Auto,
    },
    Rect::{
      size: @math.Vec2::new(100.0F, 225.0F),
      text: "Fill Center",
      translation: @math.Vec3::new(-450.0F, 230.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillCenter,
      ),
    },
    Rect::{
      size: @math.Vec2::new(100.0F, 225.0F),
      text: "Fill Start",
      translation: @math.Vec3::new(-330.0F, 230.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillStart,
      ),
    },
    Rect::{
      size: @math.Vec2::new(100.0F, 225.0F),
      text: "Fill End",
      translation: @math.Vec3::new(-210.0F, 230.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillEnd,
      ),
    },
    Rect::{
      size: @math.Vec2::new(300.0F, 100.0F),
      text: "Fill Start Horizontal",
      translation: @math.Vec3::new(10.0F, 290.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillStart,
      ),
    },
    Rect::{
      size: @math.Vec2::new(300.0F, 100.0F),
      text: "Fill End Horizontal",
      translation: @math.Vec3::new(10.0F, 155.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillEnd,
      ),
    },
    Rect::{
      size: @math.Vec2::new(200.0F, 200.0F),
      text: "Fill Center",
      translation: @math.Vec3::new(280.0F, 230.0F, 0.0F),
      texture: banner,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillCenter,
      ),
    },
    Rect::{
      size: @math.Vec2::new(200.0F, 100.0F),
      text: "Fill Center",
      translation: @math.Vec3::new(500.0F, 230.0F, 0.0F),
      texture: square,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillCenter,
      ),
    },
    Rect::{
      size: @math.Vec2::new(100.0F, 100.0F),
      text: "Stretched",
      translation: @math.Vec3::new(-570.0F, -40.0F, 0.0F),
      texture: banner,
      image_mode: @sprite.SpriteImageMode::Auto,
    },
    Rect::{
      size: @math.Vec2::new(200.0F, 200.0F),
      text: "Fit Center",
      translation: @math.Vec3::new(-400.0F, -40.0F, 0.0F),
      texture: banner,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitCenter,
      ),
    },
    Rect::{
      size: @math.Vec2::new(200.0F, 200.0F),
      text: "Fit Start",
      translation: @math.Vec3::new(-180.0F, -40.0F, 0.0F),
      texture: banner,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitStart,
      ),
    },
    Rect::{
      size: @math.Vec2::new(200.0F, 200.0F),
      text: "Fit End",
      translation: @math.Vec3::new(40.0F, -40.0F, 0.0F),
      texture: banner,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitEnd,
      ),
    },
    Rect::{
      size: @math.Vec2::new(100.0F, 200.0F),
      text: "Fit Center",
      translation: @math.Vec3::new(210.0F, -40.0F, 0.0F),
      texture: banner,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitCenter,
      ),
    },
  ]

  for rect in rects {
    spawn_rect(commands, rect, text_style)
  }
}

///|
fn setup_texture_atlas(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  let gabe = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let text_style = @text.TextFont::from_font_size(LABEL_FONT_SIZE).with_font(
    asset_server.get().load_font("fonts/FiraSans-Bold.ttf"),
  )
  let animation_indices = AnimationIndices::{
    first: ATLAS_FIRST_FRAME,
    last: ATLAS_LAST_FRAME,
  }
  let gabe_atlas = @asset.TextureAtlas::new(
    texture_atlas_layouts.get_ref().val.add(
      @asset.TextureAtlasLayout::from_grid(@math.UVec2::new(24, 24), 7, 1),
    ),
    animation_indices.first,
  )

  let sprite_sheets : Array[SpriteSheet] = [
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Stretched",
      translation: @math.Vec3::new(-570.0F, -200.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Auto,
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Fill Center",
      translation: @math.Vec3::new(-570.0F, -300.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillCenter,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Fill Start",
      translation: @math.Vec3::new(-430.0F, -200.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillStart,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Fill End",
      translation: @math.Vec3::new(-430.0F, -300.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillEnd,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(50.0F, 120.0F),
      text: "Fill Center",
      translation: @math.Vec3::new(-300.0F, -250.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillCenter,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(50.0F, 120.0F),
      text: "Fill Start",
      translation: @math.Vec3::new(-190.0F, -250.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillStart,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(50.0F, 120.0F),
      text: "Fill End",
      translation: @math.Vec3::new(-90.0F, -250.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FillEnd,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Fit Center",
      translation: @math.Vec3::new(20.0F, -200.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitCenter,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Fit Start",
      translation: @math.Vec3::new(20.0F, -300.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitStart,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
    SpriteSheet::{
      size: @math.Vec2::new(120.0F, 50.0F),
      text: "Fit End",
      translation: @math.Vec3::new(160.0F, -200.0F, 0.0F),
      texture: gabe,
      image_mode: @sprite.SpriteImageMode::Scale(
        @sprite.SpriteScalingMode::FitEnd,
      ),
      atlas: gabe_atlas,
      indices: animation_indices,
      timer: AnimationTimer::{
        timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
      },
    },
  ]

  for sprite_sheet in sprite_sheets {
    spawn_sprite_sheet(commands, sprite_sheet, text_style)
  }
}

///|
fn spawn_rect(
  commands : @app.Commands,
  rect : Rect,
  text_style : @text.TextFont,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(rect.texture)
        .with_custom_size(Some(rect.size))
        .with_image_mode(rect.image_mode),
        @transform.Transform::from_translation(rect.translation),
      ),
    ),
  )
  spawn_scale_label(rect.text, text_style, rect.translation, rect.size)
}

///|
fn spawn_sprite_sheet(
  commands : @app.Commands,
  sprite_sheet : SpriteSheet,
  text_style : @text.TextFont,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_atlas_image(
          sprite_sheet.texture,
          sprite_sheet.atlas,
        )
        .with_custom_size(Some(sprite_sheet.size))
        .with_image_mode(sprite_sheet.image_mode),
        sprite_sheet.indices,
        sprite_sheet.timer,
        @transform.Transform::from_translation(sprite_sheet.translation),
      ),
    ),
  )
  spawn_scale_label(
    sprite_sheet.text,
    text_style,
    sprite_sheet.translation,
    sprite_sheet.size,
  )
}

///|
fn spawn_scale_label(
  label : String,
  text_style : @text.TextFont,
  sprite_translation : @math.Vec3,
  sprite_size : @math.Vec2,
) -> Unit {
  @text.Text2dBundle::new(
    @text.Text2d::new(label),
    text_style,
    @transform.Transform::from_xyz(
      sprite_translation.x,
      sprite_translation.y - 0.5F * sprite_size.y - LABEL_VERTICAL_GAP,
      sprite_translation.z,
    ),
  )
  .with_color(@text.TextColor::new(@sprite.Color::white()))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_anchor(@sprite.Anchor::top_center())
  .spawn()
  |> ignore
}

///|
fn animate_sprite(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query3[AnimationIndices, AnimationTimer, @sprite.Sprite],
) -> Unit {
  try! query.for_each(fn(_entity, indices, timer, sprite) {
    timer.timer = timer.timer.tick(time.get().delta())
    guard timer.timer.just_finished() else { return }
    guard sprite.texture_atlas is Some(atlas) else { return }

    sprite.texture_atlas = Some(
      atlas.with_index(
        if atlas.index == indices.last {
          indices.first
        } else {
          atlas.index + 1
        },
      ),
    )
  })
}
