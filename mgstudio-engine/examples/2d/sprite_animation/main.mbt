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
const FIRST_SPRITE_INDEX : Int = 1

///|
const LAST_SPRITE_INDEX : Int = 6

///|
const LEFT_FPS : Int = 10

///|
const RIGHT_FPS : Int = 20

///|
const SPRITE_SCALE : Float = 6.0F

///|
const LEFT_SPRITE_X : Float = -70.0F

///|
const RIGHT_SPRITE_X : Float = 70.0F

///|
struct AnimationConfig {
  first_sprite_index : Int
  last_sprite_index : Int
  fps : Int
  mut frame_timer : @time.Timer
}

///|
let animation_config_key : @ecs.ComponentKey[AnimationConfig] = @ecs.register_component(
  debug_name="examples.2d.sprite_animation.AnimationConfig",
)

///|
pub impl @ecs.Component for AnimationConfig with component() {
  animation_config_key
}

///|
fn AnimationConfig::new(
  first_sprite_index : Int,
  last_sprite_index : Int,
  fps : Int,
) -> AnimationConfig {
  AnimationConfig::{
    first_sprite_index,
    last_sprite_index,
    fps,
    frame_timer: AnimationConfig::timer_from_fps(fps),
  }
}

///|
fn AnimationConfig::timer_from_fps(fps : Int) -> @time.Timer {
  @time.Timer::from_seconds(
    1.0F / Float::from_double(fps.to_double()),
    @time.TimerMode::Once,
  )
}

///|
struct LeftSprite {}

///|
let left_sprite_key : @ecs.ComponentKey[LeftSprite] = @ecs.register_component(
  debug_name="examples.2d.sprite_animation.LeftSprite",
)

///|
pub impl @ecs.Component for LeftSprite with component() {
  left_sprite_key
}

///|
struct RightSprite {}

///|
let right_sprite_key : @ecs.ComponentKey[RightSprite] = @ecs.register_component(
  debug_name="examples.2d.sprite_animation.RightSprite",
)

///|
pub impl @ecs.Component for RightSprite with component() {
  right_sprite_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest())
  })
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(execute_animations)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(trigger_left_animation)).run_if(
      @input.input_just_pressed(@window.KeyCode::ArrowLeft),
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(trigger_right_animation)).run_if(
      @input.input_just_pressed(@window.KeyCode::ArrowRight),
    ),
  )
  .run()
}

///|
fn spawn_help_overlay(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new(
          "Left Arrow: Animate Left Sprite\nRight Arrow: Animate Right Sprite",
        ),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  spawn_help_overlay(commands, asset_server)

  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(24, 24),
    7,
    1,
  )
  let texture_atlas_layout = texture_atlas_layouts.get_ref().val.add(layout)

  let animation_config_1 = AnimationConfig::new(
    FIRST_SPRITE_INDEX,
    LAST_SPRITE_INDEX,
    LEFT_FPS,
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_atlas_image(
          texture,
          @asset.TextureAtlas::new(
            texture_atlas_layout,
            animation_config_1.first_sprite_index,
          ),
        ),
        @transform.Transform::identity()
        .with_scale(@math.Vec3::splat(SPRITE_SCALE))
        .with_translation(@math.Vec3::new(LEFT_SPRITE_X, 0.0F, 0.0F)),
        LeftSprite::{  },
        animation_config_1,
      ),
    ),
  )

  let animation_config_2 = AnimationConfig::new(
    FIRST_SPRITE_INDEX,
    LAST_SPRITE_INDEX,
    RIGHT_FPS,
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_atlas_image(
          asset_server.get().load("textures/rpg/chars/gabe/gabe-idle-run.png"),
          @asset.TextureAtlas::new(
            texture_atlas_layout,
            animation_config_2.first_sprite_index,
          ),
        ),
        @transform.Transform::identity()
        .with_scale(@math.Vec3::splat(SPRITE_SCALE))
        .with_translation(@math.Vec3::new(RIGHT_SPRITE_X, 0.0F, 0.0F)),
        RightSprite::{  },
        animation_config_2,
      ),
    ),
  )
}

///|
fn trigger_left_animation(
  animation : @ecs.Query1Filtered[AnimationConfig, @ecs.With[LeftSprite]],
) -> Unit {
  try! animation.for_each(fn(_entity, config) {
    config.frame_timer = AnimationConfig::timer_from_fps(config.fps)
  })
}

///|
fn trigger_right_animation(
  animation : @ecs.Query1Filtered[AnimationConfig, @ecs.With[RightSprite]],
) -> Unit {
  try! animation.for_each(fn(_entity, config) {
    config.frame_timer = AnimationConfig::timer_from_fps(config.fps)
  })
}

///|
fn execute_animations(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query2[AnimationConfig, @sprite.Sprite],
) -> Unit {
  try! query.for_each(fn(_entity, config, sprite) {
    config.frame_timer = config.frame_timer.tick(time.get().delta())
    guard config.frame_timer.just_finished() else { return }
    guard sprite.texture_atlas is Some(atlas) else { return }

    if atlas.index == config.last_sprite_index {
      sprite.texture_atlas = Some(atlas.with_index(config.first_sprite_index))
    } else {
      sprite.texture_atlas = Some(atlas.with_index(atlas.index + 1))
      config.frame_timer = AnimationConfig::timer_from_fps(config.fps)
    }
  })
}
