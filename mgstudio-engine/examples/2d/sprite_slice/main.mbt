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
const LABEL_FONT_SIZE : Float = 20.0F

///|
const LABEL_VERTICAL_GAP : Float = 10.0F

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_slice_setup)
  .run()
}

///|
fn sprite_slice_setup(world : @ecs.World) -> Unit {
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn_ecs(
    world,
  )
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let handle_1 = asset_server.load("textures/slice_square.png")
  let handle_2 = asset_server.load("textures/slice_square_2.png")
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  spawn_sprite_row(
    world,
    handle_1,
    font,
    @math.Vec2::new(-600.0F, 150.0F),
    200.0F,
    ROW_GAP,
  )
  spawn_sprite_row(
    world,
    handle_2,
    font,
    @math.Vec2::new(-600.0F, -150.0F),
    80.0F,
    ROW_GAP,
  )
}

///|
fn spawn_sprite_row(
  world : @ecs.World,
  texture_handle : @asset.Handle[@asset.Image],
  font : @asset.Handle[@asset.Font],
  start_position : @math.Vec2,
  slice_border : Float,
  gap : Float,
) -> Unit {
  let border = @render2d.BorderRect::square(slice_border)
  let cases : Array[(String, @math.Vec2, @render2d.SpriteImageMode)] = [
    (
      "Original",
      @math.Vec2::new(100.0F, 100.0F),
      @render2d.SpriteImageMode::Auto,
    ),
    (
      "Stretched",
      @math.Vec2::new(100.0F, 200.0F),
      @render2d.SpriteImageMode::Auto,
    ),
    (
      "With Slicing",
      @math.Vec2::new(100.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(@render2d.TextureSlicer::new(border)),
    ),
    (
      "With Tiling",
      @math.Vec2::new(100.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(
        @render2d.TextureSlicer::new(border)
        .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.5F))
        .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.2F)),
      ),
    ),
    (
      "With Tiling",
      @math.Vec2::new(300.0F, 200.0F),
      @render2d.SpriteImageMode::Sliced(
        @render2d.TextureSlicer::new(border)
        .with_center_scale_mode(@render2d.SliceScaleMode::Tile(0.2F))
        .with_sides_scale_mode(@render2d.SliceScaleMode::Tile(0.3F)),
      ),
    ),
    (
      "With Corners Constrained",
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
    let label = item.0
    let size = item.1
    let image_mode = item.2
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
    @render2d.SpriteBundle::new(sprite, transform).spawn_ecs(world) |> ignore
    spawn_slice_label(label, font, position, size)
    cursor_x = cursor_x + 0.5F * size.x + gap
  }
}

///|
fn spawn_slice_label(
  label : String,
  font : @asset.Handle[@asset.Font],
  sprite_position : @math.Vec2,
  sprite_size : @math.Vec2,
) -> Unit {
  let label_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(
      sprite_position.x,
      sprite_position.y - 0.5F * sprite_size.y - LABEL_VERTICAL_GAP,
    ),
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @text.Text2dBundle::new(
    @text.Text2d::new(label),
    @text.TextFont::default().with_font(font).with_font_size(LABEL_FONT_SIZE),
    label_transform,
  )
  .with_color(@text.TextColor::new(@render2d.Color::white()))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_anchor(@render2d.Anchor::top_center())
  .spawn()
  |> ignore
}
