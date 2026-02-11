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
pub fn game_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_slice_setup)
  .run()
}

///|
fn sprite_slice_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/rpg/ui/generic-rpg-ui-text-box.png")
  let border = @render2d.BorderRect::square(8.0F)
  let border_large = @render2d.BorderRect::square(12.0F)
  let sliced_stretch = @render2d.SpriteImageMode::Sliced(
    @render2d.TextureSlicer::new(border),
  )
  let sliced_tile = @render2d.SpriteImageMode::Sliced(
    @render2d.TextureSlicer::new(border)
    .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.45F))
    .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.30F)),
  )
  let sliced_tile_wide = @render2d.SpriteImageMode::Sliced(
    @render2d.TextureSlicer::new(border)
    .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.25F))
    .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.20F)),
  )
  let sliced_corner_limited = @render2d.SpriteImageMode::Sliced(
    @render2d.TextureSlicer::new(border_large)
    .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.25F))
    .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.20F))
    .with_max_corner_scale(0.65F),
  )
  spawn_slice_sprite(
    world,
    texture,
    @math.Vec2::new(-430.0F, 130.0F),
    None,
    @render2d.SpriteImageMode::Auto,
    @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
  )
  spawn_slice_sprite(
    world,
    texture,
    @math.Vec2::new(-120.0F, 130.0F),
    Some(@math.Vec2::new(260.0F, 96.0F)),
    @render2d.SpriteImageMode::Auto,
    @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
  )
  spawn_slice_sprite(
    world,
    texture,
    @math.Vec2::new(220.0F, 130.0F),
    Some(@math.Vec2::new(260.0F, 96.0F)),
    sliced_stretch,
    @render2d.Color::new(0.80F, 0.95F, 1.0F, 1.0F),
  )
  spawn_slice_sprite(
    world,
    texture,
    @math.Vec2::new(-280.0F, -120.0F),
    Some(@math.Vec2::new(260.0F, 96.0F)),
    sliced_tile,
    @render2d.Color::new(0.85F, 1.0F, 0.85F, 1.0F),
  )
  spawn_slice_sprite(
    world,
    texture,
    @math.Vec2::new(80.0F, -120.0F),
    Some(@math.Vec2::new(260.0F, 96.0F)),
    sliced_tile_wide,
    @render2d.Color::new(1.0F, 0.90F, 0.75F, 1.0F),
  )
  spawn_slice_sprite(
    world,
    texture,
    @math.Vec2::new(420.0F, -120.0F),
    Some(@math.Vec2::new(360.0F, 96.0F)),
    sliced_corner_limited,
    @render2d.Color::new(1.0F, 0.82F, 0.90F, 1.0F),
  )
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn spawn_slice_sprite(
  world : @ecs_world.World,
  texture : @asset.Handle[@asset.Image],
  position : @math.Vec2,
  custom_size : @math.Vec2?,
  image_mode : @render2d.SpriteImageMode,
  color : @render2d.Color,
) -> Unit {
  let base_sprite = @render2d.Sprite::from_image(texture)
    .with_color(color)
    .with_image_mode(image_mode)
  let sprite = match custom_size {
    Some(size) => base_sprite.with_custom_size(Some(size))
    None => base_sprite
  }
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @render2d.SpriteBundle::new(sprite, transform).spawn(world) |> ignore
}

///|
fn main {
  game_main()
}
