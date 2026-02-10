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
priv struct BloomExampleState {
  mut scene_target : @asset.Handle[@asset.Image]?
  mut bloom : @render2d.Bloom2dSettings
}

///|
let bloom_example_state : Ref[BloomExampleState] = Ref::new(BloomExampleState::{
  scene_target: None,
  bloom: @render2d.Bloom2dSettings::default(),
})

///|
fn scene_layers() -> @render2d.RenderLayers {
  @render2d.RenderLayers::layer(0)
}

///|
fn compose_layers() -> @render2d.RenderLayers {
  @render2d.RenderLayers::layer(1)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(bloom_setup)
  .add_system(bloom_update)
  .run()
}

///|
fn bloom_setup(world : @ecs_world.World) -> Unit {
  let width = safe_positive_int(@window.window_width(), 1280)
  let height = safe_positive_int(@window.window_height(), 720)
  let scene_target = @render2d.render2d_create_render_target(
    world, width, height, false,
  )

  @render2d.Camera2dBundle::new_with_layers(
    @render2d.Camera::new(@render2d.Color::black()).with_order(0),
    @math.Transform::identity(),
    @render2d.RenderTarget::Image(scene_target),
    scene_layers(),
  ).spawn(world)
  |> ignore

  @render2d.Camera2dBundle::new_with_layers(
    @render2d.Camera::new(@render2d.Color::black()).with_order(1),
    @math.Transform::identity(),
    @render2d.RenderTarget::Screen,
    compose_layers(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let bird = asset_server.load("branding/bevy_bird_dark.png")
  @render2d.SpriteBundle::new_with_layers(
    @render2d.Sprite::from_image(bird)
    .with_custom_size(Some(@math.Vec2::new(160.0F, 160.0F)))
    .with_color(@render2d.Color::new(5.0F, 5.0F, 5.0F, 1.0F)),
    @math.Transform::identity(),
    scene_layers(),
  ).spawn(world)
  |> ignore

  @render2d.Mesh2dBundle::new_with_layers(
    @render2d.Mesh2d::from_circle(@render2d.Circle::new(100.0F)),
    @render2d.ColorMaterial::new(@render2d.Color::new(7.5F, 0.0F, 7.5F, 1.0F)),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-220.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    scene_layers(),
  ).spawn(world)
  |> ignore

  @render2d.Mesh2dBundle::new_with_layers(
    @render2d.Mesh2d::from_regular_polygon(
      @render2d.RegularPolygon::new(100.0F, 6),
    ),
    @render2d.ColorMaterial::new(@render2d.Color::new(6.25F, 9.4F, 9.1F, 1.0F)),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(220.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
    scene_layers(),
  ).spawn(world)
  |> ignore

  bloom_example_state.val.scene_target = Some(scene_target)
  bloom_example_state.val.bloom = @render2d.Bloom2dSettings::default()
}

///|
fn bloom_update(world : @ecs_world.World) -> Unit {
  guard bloom_example_state.val.scene_target is Some(scene_target) else {
    return
  }
  handle_input_settings()
  let width = safe_positive_int(@window.window_width(), 1280)
  let height = safe_positive_int(@window.window_height(), 720)
  let compose_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, 0.0F),
    0.0F,
    @math.Vec2::new(
      Float::from_double(width.to_double()),
      Float::from_double(height.to_double()),
    ),
  )

  @render2d.render2d_push_sprite_uv(
    world,
    scene_target,
    compose_transform,
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @render2d.Color::white(),
    compose_layers(),
  )

  @render2d.render2d_draw_bloom_overlay(
    world,
    scene_target,
    compose_transform,
    bloom_example_state.val.bloom,
    compose_layers(),
  )
}

///|
fn handle_input_settings() -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    bloom_example_state.val.bloom = @render2d.Bloom2dSettings::{
      enabled: !bloom_example_state.val.bloom.enabled,
      intensity: bloom_example_state.val.bloom.intensity,
      spread: bloom_example_state.val.bloom.spread,
      pass_count: bloom_example_state.val.bloom.pass_count,
      tint: bloom_example_state.val.bloom.tint,
    }
  }

  let dt = @time.time_delta_seconds()
  let mut intensity = bloom_example_state.val.bloom.intensity
  if @input.key_pressed(@window.KeyCode::KeyA) {
    intensity = intensity - dt * 0.4F
  }
  if @input.key_pressed(@window.KeyCode::KeyQ) {
    intensity = intensity + dt * 0.4F
  }
  if intensity < 0.0F {
    intensity = 0.0F
  }
  if intensity > 2.0F {
    intensity = 2.0F
  }

  let mut spread = bloom_example_state.val.bloom.spread
  if @input.key_pressed(@window.KeyCode::KeyS) {
    spread = spread - dt * 0.15F
  }
  if @input.key_pressed(@window.KeyCode::KeyW) {
    spread = spread + dt * 0.15F
  }
  if spread < 0.0F {
    spread = 0.0F
  }
  if spread > 0.4F {
    spread = 0.4F
  }

  let mut pass_count = bloom_example_state.val.bloom.pass_count
  if @input.key_just_pressed(@window.KeyCode::KeyD) {
    pass_count = pass_count - 1
  }
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    pass_count = pass_count + 1
  }
  if pass_count < 1 {
    pass_count = 1
  }
  if pass_count > 24 {
    pass_count = 24
  }

  bloom_example_state.val.bloom = @render2d.Bloom2dSettings::{
    enabled: bloom_example_state.val.bloom.enabled,
    intensity,
    spread,
    pass_count,
    tint: bloom_example_state.val.bloom.tint,
  }
}

///|
fn safe_positive_int(value : Int, fallback : Int) -> Int {
  if value <= 0 {
    fallback
  } else {
    value
  }
}
