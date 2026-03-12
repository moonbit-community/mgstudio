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
const GABE_FRAME_SIZE : Int = 24

///|
const GABE_FRAME_COLUMNS : Int = 7

///|
const GABE_FRAME_ROWS : Int = 1

///|
const GABE_FIRST_FRAME : Int = 1

///|
const GABE_LAST_FRAME : Int = 6

///|
const GABE_ANIMATION_STEP_SECONDS : Float = 0.1F

///|
const GABE_SCALE : Float = 6.0F

///|
priv struct SpriteSheetState {
  mut timer_seconds : Float
  mut sprite : @core.Entity?
  mut texture : @asset.Handle[@asset.Image]?
  mut layout : @asset.Handle[@asset.TextureAtlasLayout]?
  mut frame : Int
}

///|
let sprite_sheet_state : Ref[SpriteSheetState] = Ref::new(SpriteSheetState::{
  timer_seconds: 0.0F,
  sprite: None,
  texture: None,
  layout: None,
  frame: GABE_FIRST_FRAME,
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(sprite_sheet_setup))
  .add_systems(@app.Update, @app.system(sprite_sheet_animate))
  .run()
}

///|
fn sprite_sheet_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(GABE_FRAME_SIZE, GABE_FRAME_SIZE),
    GABE_FRAME_COLUMNS,
    GABE_FRAME_ROWS,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
  let atlas = @asset.TextureAtlas::new(layout_handle, GABE_FIRST_FRAME)
  let sprite = @sprite.Sprite::from_atlas_image(texture, atlas)
  let transform = @math.Transform::identity().with_scale(
    @math.Vec3::splat(GABE_SCALE),
  )

  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(world)
  |> ignore

  let entity = @sprite.SpriteBundle::new(sprite, transform).spawn(world)
  sprite_sheet_state.val.timer_seconds = 0.0F
  sprite_sheet_state.val.sprite = Some(entity)
  sprite_sheet_state.val.texture = Some(texture)
  sprite_sheet_state.val.layout = Some(layout_handle)
  sprite_sheet_state.val.frame = GABE_FIRST_FRAME
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in sprite_sheet example")
  }
}

///|
fn sprite_sheet_animate(world : @ecs.World) -> Unit {
  sprite_sheet_state.val.timer_seconds = sprite_sheet_state.val.timer_seconds +
    world_time(world).delta_seconds()

  if sprite_sheet_state.val.timer_seconds >= GABE_ANIMATION_STEP_SECONDS {
    sprite_sheet_state.val.timer_seconds = 0.0F
    if sprite_sheet_state.val.texture is Some(texture) &&
      sprite_sheet_state.val.layout is Some(layout_handle) {
      let next_frame = if sprite_sheet_state.val.frame == GABE_LAST_FRAME {
        GABE_FIRST_FRAME
      } else {
        sprite_sheet_state.val.frame + 1
      }
      if sprite_sheet_state.val.sprite is Some(entity) {
        try! world.despawn(entity)
      }
      let atlas = @asset.TextureAtlas::new(layout_handle, next_frame)
      let sprite = @sprite.Sprite::from_atlas_image(texture, atlas)
      let transform = @math.Transform::identity().with_scale(
        @math.Vec3::splat(GABE_SCALE),
      )
      let entity = @sprite.SpriteBundle::new(sprite, transform).spawn(world)
      sprite_sheet_state.val.sprite = Some(entity)
      sprite_sheet_state.val.frame = next_frame
    }
  }
}
