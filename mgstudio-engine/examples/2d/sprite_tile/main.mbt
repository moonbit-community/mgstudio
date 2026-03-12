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
  mut texture : @asset.Handle[@asset.Image]?
  min : Float
  max : Float
  mut current : Float
  mut speed : Float
}

///|
let sprite_tile_animation_state : Ref[SpriteTileAnimationState] = Ref::new(SpriteTileAnimationState::{
  sprite: None,
  texture: None,
  min: 128.0F,
  max: 512.0F,
  current: 128.0F,
  speed: 50.0F,
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(sprite_tile_setup))
  .add_systems(@app.Update, @app.system(sprite_tile_animate))
  .run()
}

///|
fn sprite_tile_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let sprite = @sprite.Sprite::from_image(texture)
    .with_image_mode(
      @sprite.SpriteImageMode::tiled(
        tile_x=true,
        tile_y=true,
        stretch_value=0.5F,
      ),
    )
    .with_custom_size(Some(@math.Vec2::new(128.0F, 128.0F)))
  let entity = @sprite.SpriteBundle::new(sprite, @math.Transform::identity()).spawn(
    world,
  )
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(world)
  |> ignore
  sprite_tile_animation_state.val.sprite = Some(entity)
  sprite_tile_animation_state.val.texture = Some(texture)
  sprite_tile_animation_state.val.current = 128.0F
  sprite_tile_animation_state.val.speed = 50.0F
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in sprite_tile example")
  }
}

///|
fn sprite_tile_animate(world : @ecs.World) -> Unit {
  if sprite_tile_animation_state.val.sprite is None ||
    sprite_tile_animation_state.val.texture is None {
    return
  }
  if sprite_tile_animation_state.val.current >=
    sprite_tile_animation_state.val.max ||
    sprite_tile_animation_state.val.current <=
    sprite_tile_animation_state.val.min {
    sprite_tile_animation_state.val.speed = -sprite_tile_animation_state.val.speed
  }
  sprite_tile_animation_state.val.current = sprite_tile_animation_state.val.current +
    sprite_tile_animation_state.val.speed * world_time(world).delta_seconds()
  if sprite_tile_animation_state.val.sprite is Some(entity) &&
    sprite_tile_animation_state.val.texture is Some(texture) {
    try! world.despawn(entity)
    let sprite = @sprite.Sprite::from_image(texture)
      .with_image_mode(
        @sprite.SpriteImageMode::tiled(
          tile_x=true,
          tile_y=true,
          stretch_value=0.5F,
        ),
      )
      .with_custom_size(
        Some(
          @math.Vec2::new(
            sprite_tile_animation_state.val.current,
            sprite_tile_animation_state.val.current,
          ),
        ),
      )
    let new_entity = @sprite.SpriteBundle::new(
      sprite,
      @math.Transform::identity(),
    ).spawn(world)
    sprite_tile_animation_state.val.sprite = Some(new_entity)
  }
}
