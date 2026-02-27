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
}

///|
let sprite_sheet_state : Ref[SpriteSheetState] = Ref::new(SpriteSheetState::{
  timer_seconds: 0.0F,
})

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_sheet_setup)
  .add_system(sprite_sheet_animate)
  .run()
}

///|
fn sprite_sheet_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(GABE_FRAME_SIZE, GABE_FRAME_SIZE),
    GABE_FRAME_COLUMNS,
    GABE_FRAME_ROWS,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
  let atlas = @asset.TextureAtlas::new(layout_handle, GABE_FIRST_FRAME)
  let sprite = @render2d.Sprite::from_atlas_image(texture, atlas)
  let transform = @math.Transform::identity().with_scale(
    @math.Vec3::splat(GABE_SCALE),
  )

  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore

  @render2d.SpriteBundle::new(sprite, transform).spawn(world) |> ignore
  sprite_sheet_state.val.timer_seconds = 0.0F
}

///|
fn sprite_sheet_animate(world : @ecs_world.World) -> Unit {
  sprite_sheet_state.val.timer_seconds = sprite_sheet_state.val.timer_seconds +
    @time.time_delta_seconds()

  if sprite_sheet_state.val.timer_seconds >= GABE_ANIMATION_STEP_SECONDS {
    sprite_sheet_state.val.timer_seconds = 0.0F
    let tick = world.read_change_tick()
    let sprite_store = world.get_sprite_store()
    let transform_store = world.get_transform_store()
    let updates : Array[(@core.Entity, @render2d.Sprite)] = []

    @core.query2(sprite_store, transform_store, fn(entity, sprite, _transform) {
      if sprite.texture_atlas is Some(atlas) {
        let next_index = if atlas.index == GABE_LAST_FRAME {
          GABE_FIRST_FRAME
        } else {
          atlas.index + 1
        }
        let next_sprite = sprite.with_texture_atlas(
          Some(atlas.with_index(next_index)),
        )
        updates.push((entity, next_sprite))
      }
    })

    for entry in updates {
      sprite_store.set(entry.0, entry.1, tick) |> ignore
    }
  }
}
