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
priv struct SpriteTileAnimationState {
  mut sprite : @core.Entity?
  min : Float
  max : Float
  mut current : Float
  mut speed : Float
}

///|
let sprite_tile_animation_state : Ref[SpriteTileAnimationState] = Ref::new(SpriteTileAnimationState::{
  sprite: None,
  min: 128.0F,
  max: 512.0F,
  current: 128.0F,
  speed: 50.0F,
})

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_tile_setup)
  .add_system(sprite_tile_animate)
  .run()
}

///|
fn sprite_tile_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::from_image(texture)
    .with_image_mode(@render2d.SpriteImageMode::tiled(stretch_value=0.5F))
    .with_custom_size(Some(@math.Vec2::new(128.0F, 128.0F)))
  let entity = @render2d.SpriteBundle::new(sprite, @math.Transform::identity()).spawn(
    world,
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  sprite_tile_animation_state.val.sprite = Some(entity)
  sprite_tile_animation_state.val.current = 128.0F
  sprite_tile_animation_state.val.speed = 50.0F
}

///|
fn sprite_tile_animate(world : @ecs_world.World) -> Unit {
  guard sprite_tile_animation_state.val.sprite is Some(entity) else { return }
  if sprite_tile_animation_state.val.current >=
    sprite_tile_animation_state.val.max ||
    sprite_tile_animation_state.val.current <=
    sprite_tile_animation_state.val.min {
    sprite_tile_animation_state.val.speed = -sprite_tile_animation_state.val.speed
  }
  sprite_tile_animation_state.val.current = sprite_tile_animation_state.val.current +
    sprite_tile_animation_state.val.speed * @time.time_delta_seconds()
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  if sprite_store.get(entity) is Some(sprite) {
    sprite_store.set(
      entity,
      sprite.with_custom_size(
        Some(
          @math.Vec2::new(
            sprite_tile_animation_state.val.current,
            sprite_tile_animation_state.val.current,
          ),
        ),
      ),
      tick,
    )
    |> ignore
  }
}
