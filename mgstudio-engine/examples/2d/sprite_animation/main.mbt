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
pub impl @ecs.Component for AnimationConfig with fn component() {
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
pub impl @ecs.Component for LeftSprite with fn component() {
  left_sprite_key
}

///|
struct RightSprite {}

///|
let right_sprite_key : @ecs.ComponentKey[RightSprite] = @ecs.register_component(
  debug_name="examples.2d.sprite_animation.RightSprite",
)

///|
pub impl @ecs.Component for RightSprite with fn component() {
  right_sprite_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::set(@asset.AssetPlugin::nearest()))
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
fn spawn_help_overlay(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Left Arrow: Animate Left Sprite\nRight Arrow: Animate Right Sprite",
        ),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
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
  ignore(commands.spawn_component(@sprite.Camera2d::Camera2d()))
  spawn_help_overlay(commands)

  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(24, 24),
    7,
    1,
  )
  let texture_atlas_layout = texture_atlas_layouts.modify(fn(layouts) {
    layouts.add(layout)
  })

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
          texture,
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
  animation : @ecs.Query[@ecs.Mut[AnimationConfig], @ecs.With[LeftSprite]],
) -> Unit {
  try! animation.for_each(fn(_entity, config) {
    config.modify(fn(value) {
      value.frame_timer = AnimationConfig::timer_from_fps(value.fps)
    })
  })
}

///|
fn trigger_right_animation(
  animation : @ecs.Query[@ecs.Mut[AnimationConfig], @ecs.With[RightSprite]],
) -> Unit {
  try! animation.for_each(fn(_entity, config) {
    config.modify(fn(value) {
      value.frame_timer = AnimationConfig::timer_from_fps(value.fps)
    })
  })
}

///|
fn execute_animations(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Mut[AnimationConfig], @ecs.Mut[@sprite.Sprite]),
    @ecs.All,
  ],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (config, sprite) = data
    let mut next_atlas = None
    config.modify(fn(value) {
      value.frame_timer = value.frame_timer.tick(time.get().delta())
      guard value.frame_timer.just_finished() else { return }
      guard sprite.value().texture_atlas is Some(atlas) else { return }

      if atlas.index == value.last_sprite_index {
        next_atlas = Some(atlas.with_index(value.first_sprite_index))
      } else {
        next_atlas = Some(atlas.with_index(atlas.index + 1))
        value.frame_timer = AnimationConfig::timer_from_fps(value.fps)
      }
    })
    if next_atlas is Some(next_atlas) {
      sprite.set(sprite.value().with_texture_atlas(Some(next_atlas)))
    }
  })
}
