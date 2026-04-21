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
const GABE_FIRST_FRAME : Int = 1

///|
const GABE_LAST_FRAME : Int = 6

///|
struct AnimationIndices {
  first : Int
  last : Int
}

///|
let animation_indices_key : @ecs.ComponentKey[AnimationIndices] = @ecs.register_component(
  debug_name="examples.2d.sprite_sheet.AnimationIndices",
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
  debug_name="examples.2d.sprite_sheet.AnimationTimer",
)

///|
pub impl @ecs.Component for AnimationTimer with component() {
  animation_timer_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest()),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_sprite)))
  .run()
}

///|
fn animate_sprite(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (
      @ecs.Comp[AnimationIndices],
      @ecs.Mut[AnimationTimer],
      @ecs.Mut[@sprite.Sprite],
    ),
    @ecs.All,
  ],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (indices, timer, sprite) = data
    let indices = indices.value()
    let mut next_atlas = None
    timer.modify(fn(value) {
      value.timer = value.timer.tick(time.get().delta())
      guard value.timer.just_finished() else { return }
      guard sprite.value().texture_atlas is Some(atlas) else { return }
      next_atlas = Some(
        atlas.with_index(
          if atlas.index == indices.last {
            indices.first
          } else {
            atlas.index + 1
          },
        ),
      )
    })
    if next_atlas is Some(next_atlas) {
      sprite.set(sprite.value().with_texture_atlas(Some(next_atlas)))
    }
  })
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
) -> Unit {
  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let texture_atlas_layout = texture_atlas_layouts
    .peek()
    .add(@asset.TextureAtlasLayout::from_grid(@math.UVec2::splat(24), 7, 1))
  let animation_indices = AnimationIndices::{
    first: GABE_FIRST_FRAME,
    last: GABE_LAST_FRAME,
  }

  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_atlas_image(
          texture,
          @asset.TextureAtlas::new(
            texture_atlas_layout,
            animation_indices.first,
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_scale(
          @math.Vec3::splat(6.0F),
        ),
        animation_indices,
        AnimationTimer::{
          timer: @time.Timer::from_seconds(0.1F, @time.TimerMode::Repeating),
        },
      ),
    ),
  )
}
