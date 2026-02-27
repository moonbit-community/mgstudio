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
const ROW_GAP : Float = 40.0F

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_slice_setup)
  .run()
}

///|
fn sprite_slice_setup(world : @ecs_world.World) -> Unit {
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let handle_1 = asset_server.load("textures/slice_square.png")
  let handle_2 = asset_server.load("textures/slice_square_2.png")

  // BLOCKER: render2d has no Text2d equivalent yet, so labels are omitted.
  spawn_sprite_row(
    world,
    handle_1,
    @math.Vec2::new(-600.0F, 150.0F),
    200.0F,
    ROW_GAP,
  )
  spawn_sprite_row(
    world,
    handle_2,
    @math.Vec2::new(-600.0F, -150.0F),
    80.0F,
    ROW_GAP,
  )
}

///|
fn spawn_sprite_row(
  world : @ecs_world.World,
  texture_handle : @asset.Handle[@asset.Image],
  start_position : @math.Vec2,
  slice_border : Float,
  gap : Float,
) -> Unit {
  let border = @render2d.BorderRect::square(slice_border)
  let cases : Array[(@math.Vec2, @render2d.SpriteImageMode)] = [
    (@math.Vec2::new(100.0F, 100.0F), @render2d.SpriteImageMode::Auto),
    (@math.Vec2::new(100.0F, 200.0F), @render2d.SpriteImageMode::Auto),
    (
      @math.Vec2::new(100.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(@render2d.TextureSlicer::new(border)),
    ),
    (
      @math.Vec2::new(100.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(
        @render2d.TextureSlicer::new(border)
        .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.5F))
        .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.2F)),
      ),
    ),
    (
      @math.Vec2::new(300.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(
        @render2d.TextureSlicer::new(border)
        .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.2F))
        .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.3F)),
      ),
    ),
    (
      @math.Vec2::new(300.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(
        @render2d.TextureSlicer::new(border)
        .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.1F))
        .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.2F))
        .with_max_corner_scale(0.2F),
      ),
    ),
  ]

  let mut cursor_x = start_position.x
  for item in cases {
    let size = item.0
    let image_mode = item.1
    cursor_x = cursor_x + 0.5F * size.x
    let position = @math.Vec2::new(cursor_x, start_position.y)
    let transform = @math.Transform::from_xy_rotation_scale(
      position,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    )
    let sprite = @render2d.Sprite::from_image(texture_handle)
      .with_custom_size(Some(size))
      .with_image_mode(image_mode)
    @render2d.SpriteBundle::new(sprite, transform).spawn(world) |> ignore
    cursor_x = cursor_x + 0.5F * size.x + gap
  }
}
