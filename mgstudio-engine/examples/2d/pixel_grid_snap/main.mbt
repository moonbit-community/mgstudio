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
const RES_WIDTH : Int = 160

///|
const RES_HEIGHT : Int = 90

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins_nearest()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(pixel_grid_snap_setup)
  .add_system(pixel_grid_snap_update)
  .run()
}

///|
priv struct PixelGridState {
  mut pixel_sprite : @core.Entity
  mut high_sprite : @core.Entity
  mut pixel_mesh : @core.Entity
  mut outer_camera : @core.Entity
  mut rotation : Float
}

///|
let pixel_state : Ref[PixelGridState] = Ref::new(PixelGridState::{
  pixel_sprite: @core.Entity::placeholder(),
  high_sprite: @core.Entity::placeholder(),
  pixel_mesh: @core.Entity::placeholder(),
  outer_camera: @core.Entity::placeholder(),
  rotation: 0.0F,
})

///|
fn pixel_grid_snap_setup(world : @ecs_world.World) -> Unit {
  let pixel_layers = @render2d.RenderLayers::layer(0)
  let high_layers = @render2d.RenderLayers::layer(1)
  let asset_server = @asset.AssetServer::new()
  let pixel_dark = asset_server.load("pixel/bevy_pixel_dark.png")
  let pixel_light = asset_server.load("pixel/bevy_pixel_light.png")
  let canvas = @render2d.render2d_create_render_target(
    world,
    RES_WIDTH,
    RES_HEIGHT,
    true,
  )
  let canvas_sprite = @render2d.SpriteBundle::new_with_layers(
    @render2d.Sprite::new(@render2d.Color::white()),
    @math.Transform::identity(),
    canvas,
    high_layers,
  )
  canvas_sprite.spawn(world) |> ignore
  let pixel_sprite = @render2d.SpriteBundle::new_with_layers(
    @render2d.Sprite::new(@render2d.Color::white()),
    @math.Transform::new(
      @math.Vec2::new(-45.0F, 20.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    pixel_dark,
    pixel_layers,
  ).spawn(world)
  let high_sprite = @render2d.SpriteBundle::new_with_layers(
    @render2d.Sprite::new(@render2d.Color::white()),
    @math.Transform::new(
      @math.Vec2::new(-45.0F, -20.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    pixel_light,
    high_layers,
  ).spawn(world)
  let capsule = @render2d.Capsule2d::default()
  let mesh = @render2d.Mesh2d::from_capsule(capsule)
  let material = @render2d.ColorMaterial::new(@render2d.Color::black())
  let mesh_handle = @render2d.Mesh2dBundle::new_with_layers(
    mesh,
    material,
    @math.Transform::new(
      @math.Vec2::new(25.0F, 0.0F),
      0.0F,
      @math.Vec2::new(32.0F, 32.0F),
    ),
    pixel_layers,
  ).spawn(world)
  let in_game_camera = @render2d.Camera::default().with_order(-1)
  @render2d.Camera2dBundle::new_with_layers(
    in_game_camera,
    @math.Transform::identity(),
    @render2d.RenderTarget::Image(canvas),
    pixel_layers,
  ).spawn(world)
  |> ignore
  let outer_camera = @render2d.Camera::default()
  let outer_handle = @render2d.Camera2dBundle::new_with_layers(
    outer_camera,
    @math.Transform::identity(),
    @render2d.RenderTarget::Screen,
    high_layers,
  ).spawn(world)
  pixel_state.val.pixel_sprite = pixel_sprite
  pixel_state.val.high_sprite = high_sprite
  pixel_state.val.pixel_mesh = mesh_handle
  pixel_state.val.outer_camera = outer_handle
  pixel_state.val.rotation = 0.0F
}

///|
fn pixel_grid_snap_update(world : @ecs_world.World) -> Unit {
  if pixel_state.val.outer_camera.is_placeholder() ||
    pixel_state.val.pixel_sprite.is_placeholder() ||
    pixel_state.val.high_sprite.is_placeholder() ||
    pixel_state.val.pixel_mesh.is_placeholder() {
    return
  }
  let delta = @time.time_delta_seconds()
  let next_rotation = pixel_state.val.rotation + delta
  pixel_state.val.rotation = next_rotation
  let pixel_transform = @math.Transform::new(
    @math.Vec2::new(-45.0F, 20.0F),
    next_rotation,
    @math.Vec2::new(1.0F, 1.0F),
  )
  let high_transform = @math.Transform::new(
    @math.Vec2::new(-45.0F, -20.0F),
    next_rotation,
    @math.Vec2::new(1.0F, 1.0F),
  )
  let mesh_transform = @math.Transform::new(
    @math.Vec2::new(25.0F, 0.0F),
    next_rotation,
    @math.Vec2::new(32.0F, 32.0F),
  )
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  transform_store.set(pixel_state.val.pixel_sprite, pixel_transform, tick)
  |> ignore
  transform_store.set(pixel_state.val.high_sprite, high_transform, tick)
  |> ignore
  transform_store.set(pixel_state.val.pixel_mesh, mesh_transform, tick)
  |> ignore
  let width = @window.window_width()
  let height = @window.window_height()
  if width <= 0 || height <= 0 {
    return
  }
  let scale_factor = @window.window_scale_factor()
  let safe_scale = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let width_f = Float::from_double(width.to_double()) / safe_scale
  let height_f = Float::from_double(height.to_double()) / safe_scale
  let h_scale = width_f / Float::from_double(RES_WIDTH.to_double())
  let v_scale = height_f / Float::from_double(RES_HEIGHT.to_double())
  let min_scale = if h_scale < v_scale { h_scale } else { v_scale }
  let rounded = pixel_grid_round_scale(min_scale)
  let scale_int = if rounded < 1 { 1 } else { rounded }
  let scale = 1.0F / Float::from_double(scale_int.to_double())
  let projection_store = @render2d.Has_Projection::get_projection_store(world)
  projection_store.set(
    pixel_state.val.outer_camera,
    @render2d.Projection::Orthographic(
      @render2d.OrthographicProjection::new(scale),
    ),
    tick,
  )
  |> ignore
}

///|
fn pixel_grid_round_scale(value : Float) -> Int {
  let base = value.to_int()
  let fraction = value - Float::from_double(base.to_double())
  if fraction >= 0.5F {
    base + 1
  } else {
    base
  }
}
