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
const LABEL_VERTICAL_GAP : Float = 10.0F

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let style = @text.TextFont::default().with_font(font)
  let handle_1 = asset_server.get().load("textures/slice_square.png")
  let handle_2 = asset_server.get().load("textures/slice_square_2.png")

  spawn_sprites(
    commands,
    handle_1,
    @math.Vec3::new(-600.0F, 150.0F, 0.0F),
    200.0F,
    style,
    ROW_GAP,
  )
  spawn_sprites(
    commands,
    handle_2,
    @math.Vec3::new(-600.0F, -150.0F, 0.0F),
    80.0F,
    style,
    ROW_GAP,
  )
}

///|
fn spawn_sprites(
  commands : @app.Commands,
  texture_handle : @asset.Handle[@asset.Image],
  position : @math.Vec3,
  slice_border : Float,
  style : @text.TextFont,
  gap : Float,
) -> Unit {
  let cursor = position
  let border = @sprite.BorderRect::square(slice_border)
  let cases : Array[(String, @math.Vec2, @sprite.SpriteImageMode)] = [
    ("Original", @math.Vec2::new(100.0F, 100.0F), @sprite.SpriteImageMode::Auto),
    (
      "Stretched",
      @math.Vec2::new(100.0F, 200.0F),
      @sprite.SpriteImageMode::Auto,
    ),
    (
      "With Slicing",
      @math.Vec2::new(100.0F, 200.0F),
      @sprite.SpriteImageMode::Sliced(@sprite.TextureSlicer::new(border)),
    ),
    (
      "With Tiling",
      @math.Vec2::new(100.0F, 200.0F),
      @sprite.SpriteImageMode::Sliced(
        @sprite.TextureSlicer::new(border)
        .with_center_scale_mode(@sprite.SliceScaleMode::Tile(0.5F))
        .with_sides_scale_mode(@sprite.SliceScaleMode::Tile(0.2F)),
      ),
    ),
    (
      "With Tiling",
      @math.Vec2::new(300.0F, 200.0F),
      @sprite.SpriteImageMode::Sliced(
        @sprite.TextureSlicer::new(border)
        .with_center_scale_mode(@sprite.SliceScaleMode::Tile(0.2F))
        .with_sides_scale_mode(@sprite.SliceScaleMode::Tile(0.3F)),
      ),
    ),
    (
      "With Corners Constrained",
      @math.Vec2::new(300.0F, 200.0F),
      @sprite.SpriteImageMode::Sliced(
        @sprite.TextureSlicer::new(border)
        .with_center_scale_mode(@sprite.SliceScaleMode::Tile(0.1F))
        .with_sides_scale_mode(@sprite.SliceScaleMode::Tile(0.2F))
        .with_max_corner_scale(0.2F),
      ),
    ),
  ]

  for item in cases {
    let label = item.0
    let size = item.1
    let image_mode = item.2
    cursor.x = cursor.x + 0.5F * size.x
    let translation = @math.Vec3::new(cursor.x, cursor.y, cursor.z)
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::from_image(texture_handle)
          .with_custom_size(Some(size))
          .with_image_mode(image_mode),
          @transform.Transform::from_translation(translation),
        ),
      ),
    )
    spawn_slice_label(label, style, translation, size)
    cursor.x = cursor.x + 0.5F * size.x + gap
  }
}

///|
fn spawn_slice_label(
  label : String,
  style : @text.TextFont,
  sprite_translation : @math.Vec3,
  sprite_size : @math.Vec2,
) -> Unit {
  @text.Text2dBundle::new(
    @text.Text2d::new(label),
    style,
    @transform.Transform::from_xyz(
      sprite_translation.x,
      sprite_translation.y - 0.5F * sprite_size.y - LABEL_VERTICAL_GAP,
      sprite_translation.z,
    ),
  )
  .with_color(@text.TextColor::new(@sprite.Color::white()))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_anchor(@sprite.Anchor::top_center())
  .spawn()
  |> ignore
}
