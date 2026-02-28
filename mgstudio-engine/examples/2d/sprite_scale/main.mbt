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
const ATLAS_FRAME_SIZE : Int = 24

///|
const ATLAS_COLUMNS : Int = 7

///|
const ATLAS_ROWS : Int = 1

///|
const ATLAS_FIRST_FRAME : Int = 0

///|
const ATLAS_LAST_FRAME : Int = 6

///|
const ANIMATION_STEP_SECONDS : Float = 0.1F

///|
const LABEL_FONT_SIZE : Float = 14.0F

///|
const LABEL_VERTICAL_GAP : Float = 10.0F

///|
priv struct SpriteScaleState {
  mut timer_seconds : Float
}

///|
let sprite_scale_state : Ref[SpriteScaleState] = Ref::new(SpriteScaleState::{
  timer_seconds: 0.0F,
})

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_scale_setup_sprites)
  .add_startup_system(sprite_scale_setup_texture_atlas)
  .add_startup_system(sprite_scale_setup_camera)
  .add_system(
    @app.system_query2(
      fn(world) { world.get_sprite_store() },
      fn(world) { world.get_transform_store() },
      sprite_scale_update,
    ),
  )
  .run()
}

///|
fn sprite_scale_setup_camera(world : @ecs_world.World) -> Unit {
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn sprite_scale_setup_sprites(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let square = asset_server.load("textures/slice_square_2.png")
  let banner = asset_server.load("branding/banner.png")
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(-570.0F, 230.0F),
    @math.Vec2::new(100.0F, 225.0F),
    "Auto",
  )
  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(-450.0F, 230.0F),
    @math.Vec2::new(100.0F, 225.0F),
    "FillCenter",
  )
  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(-330.0F, 230.0F),
    @math.Vec2::new(100.0F, 225.0F),
    "FillStart",
  )
  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(-210.0F, 230.0F),
    @math.Vec2::new(100.0F, 225.0F),
    "FillEnd",
  )
  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(10.0F, 290.0F),
    @math.Vec2::new(300.0F, 100.0F),
    "FillStart",
  )
  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(10.0F, 155.0F),
    @math.Vec2::new(300.0F, 100.0F),
    "FillEnd",
  )
  spawn_scaled_sprite(
    world,
    banner,
    font,
    @math.Vec2::new(280.0F, 230.0F),
    @math.Vec2::new(200.0F, 200.0F),
    "FillCenter",
  )
  spawn_scaled_sprite(
    world,
    square,
    font,
    @math.Vec2::new(500.0F, 230.0F),
    @math.Vec2::new(200.0F, 100.0F),
    "FillCenter",
  )
  spawn_scaled_sprite(
    world,
    banner,
    font,
    @math.Vec2::new(-570.0F, -40.0F),
    @math.Vec2::new(100.0F, 100.0F),
    "Auto",
  )
  spawn_scaled_sprite(
    world,
    banner,
    font,
    @math.Vec2::new(-400.0F, -40.0F),
    @math.Vec2::new(200.0F, 200.0F),
    "FitCenter",
  )
  spawn_scaled_sprite(
    world,
    banner,
    font,
    @math.Vec2::new(-180.0F, -40.0F),
    @math.Vec2::new(200.0F, 200.0F),
    "FitStart",
  )
  spawn_scaled_sprite(
    world,
    banner,
    font,
    @math.Vec2::new(40.0F, -40.0F),
    @math.Vec2::new(200.0F, 200.0F),
    "FitEnd",
  )
  spawn_scaled_sprite(
    world,
    banner,
    font,
    @math.Vec2::new(210.0F, -40.0F),
    @math.Vec2::new(100.0F, 200.0F),
    "FitCenter",
  )
}

///|
fn sprite_scale_setup_texture_atlas(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let gabe = asset_server.load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(ATLAS_FRAME_SIZE, ATLAS_FRAME_SIZE),
    ATLAS_COLUMNS,
    ATLAS_ROWS,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)

  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-570.0F, -200.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "Auto",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-570.0F, -300.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "FillCenter",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-430.0F, -200.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "FillStart",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-430.0F, -300.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "FillEnd",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-300.0F, -250.0F),
    @math.Vec2::new(50.0F, 120.0F),
    "FillCenter",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-190.0F, -250.0F),
    @math.Vec2::new(50.0F, 120.0F),
    "FillStart",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(-90.0F, -250.0F),
    @math.Vec2::new(50.0F, 120.0F),
    "FillEnd",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(20.0F, -200.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "FitCenter",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(20.0F, -300.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "FitStart",
  )
  spawn_scaled_atlas_sprite(
    world,
    gabe,
    font,
    layout_handle,
    @math.Vec2::new(160.0F, -200.0F),
    @math.Vec2::new(120.0F, 50.0F),
    "FitEnd",
  )
  sprite_scale_state.val.timer_seconds = 0.0F
}

///|
fn spawn_scaled_sprite(
  world : @ecs_world.World,
  texture : @asset.Handle[@asset.Image],
  font : @asset.Handle[@asset.Font],
  translation : @math.Vec2,
  size : @math.Vec2,
  intended_mode : String,
) -> Unit {
  let sprite = @render2d.Sprite::from_image(texture)
    .with_custom_size(Some(size))
    .with_image_mode(resolve_scale_mode(intended_mode))
  let transform = @math.Transform::from_xy_rotation_scale(
    translation,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @render2d.SpriteBundle::new(sprite, transform).spawn(world) |> ignore
  spawn_scale_label(intended_mode, font, translation, size)
}

///|
fn spawn_scaled_atlas_sprite(
  world : @ecs_world.World,
  texture : @asset.Handle[@asset.Image],
  font : @asset.Handle[@asset.Font],
  layout_handle : @asset.Handle[@asset.TextureAtlasLayout],
  translation : @math.Vec2,
  size : @math.Vec2,
  intended_mode : String,
) -> Unit {
  let atlas = @asset.TextureAtlas::new(layout_handle, ATLAS_FIRST_FRAME)
  let sprite = @render2d.Sprite::from_atlas_image(texture, atlas)
    .with_custom_size(Some(size))
    .with_image_mode(resolve_scale_mode(intended_mode))
  let transform = @math.Transform::from_xy_rotation_scale(
    translation,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @render2d.SpriteBundle::new(sprite, transform).spawn(world) |> ignore
  spawn_scale_label(intended_mode, font, translation, size)
}

///|
fn spawn_scale_label(
  label : String,
  font : @asset.Handle[@asset.Font],
  sprite_translation : @math.Vec2,
  sprite_size : @math.Vec2,
) -> Unit {
  let label_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(
      sprite_translation.x,
      sprite_translation.y - 0.5F * sprite_size.y - LABEL_VERTICAL_GAP,
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

///|
fn resolve_scale_mode(_intended_mode : String) -> @render2d.SpriteImageMode {
  match _intended_mode {
    "FillCenter" =>
      @render2d.SpriteImageMode::Scale(@render2d.SpriteScalingMode::FillCenter)
    "FillStart" =>
      @render2d.SpriteImageMode::Scale(@render2d.SpriteScalingMode::FillStart)
    "FillEnd" =>
      @render2d.SpriteImageMode::Scale(@render2d.SpriteScalingMode::FillEnd)
    "FitCenter" =>
      @render2d.SpriteImageMode::Scale(@render2d.SpriteScalingMode::FitCenter)
    "FitStart" =>
      @render2d.SpriteImageMode::Scale(@render2d.SpriteScalingMode::FitStart)
    "FitEnd" =>
      @render2d.SpriteImageMode::Scale(@render2d.SpriteScalingMode::FitEnd)
    _ => @render2d.SpriteImageMode::Auto
  }
}

///|
fn sprite_scale_update(
  query : @core.Query2[@render2d.Sprite, @math.Transform],
  world : @ecs_world.World,
) -> Unit {
  sprite_scale_state.val.timer_seconds = sprite_scale_state.val.timer_seconds +
    @time.time_delta_seconds()

  if sprite_scale_state.val.timer_seconds >= ANIMATION_STEP_SECONDS {
    sprite_scale_state.val.timer_seconds = 0.0F
    let tick = world.read_change_tick()
    query.update_a(tick, fn(_entity, sprite, _transform) {
      if sprite.texture_atlas is Some(atlas) {
        let next_index = if atlas.index == ATLAS_LAST_FRAME {
          ATLAS_FIRST_FRAME
        } else {
          atlas.index + 1
        }
        sprite.with_texture_atlas(Some(atlas.with_index(next_index)))
      } else {
        sprite
      }
    })
  }
}
