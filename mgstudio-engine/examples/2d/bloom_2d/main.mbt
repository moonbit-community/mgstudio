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
  mut camera : @core.Entity
  mut help_text : @text.TextHandle?
  mut bloom_enabled : Bool
  mut bloom : @render2d.Bloom2dSettings
  mut tonemapping : @render3d.Tonemapping
}

///|
let bloom_example_state : Ref[BloomExampleState] = Ref::new(BloomExampleState::{
  camera: @core.Entity::placeholder(),
  help_text: None,
  bloom_enabled: true,
  bloom: @render2d.Bloom2dSettings::default(),
  tonemapping: @render3d.Tonemapping::TonyMcMapface,
})

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
fn float_text_2(value : Float) -> String {
  let rounded = (value * 100.0F).round() / 100.0F
  "\{rounded}"
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn bloom_mode_text(mode : @render2d.BloomCompositeMode) -> String {
  match mode {
    EnergyConserving => "Energy-conserving"
    Additive => "Additive"
  }
}

///|
fn tonemapping_text(mode : @render3d.Tonemapping) -> String {
  match mode {
    None => "None"
    AcesFitted => "AcesFitted"
    AgX => "AgX"
    BlenderFilmic => "BlenderFilmic"
    Reinhard => "Reinhard"
    ReinhardLuminance => "ReinhardLuminance"
    SomewhatBoringDisplayTransform => "SomewhatBoringDisplayTransform"
    TonyMcMapface => "TonyMcMapface"
  }
}

///|
fn next_tonemap(mode : @render3d.Tonemapping) -> @render3d.Tonemapping {
  match mode {
    None => AcesFitted
    AcesFitted => AgX
    AgX => BlenderFilmic
    BlenderFilmic => Reinhard
    Reinhard => ReinhardLuminance
    ReinhardLuminance => SomewhatBoringDisplayTransform
    SomewhatBoringDisplayTransform => TonyMcMapface
    TonyMcMapface => None
  }
}

///|
fn bloom_help_text() -> String {
  let bloom = bloom_example_state.val.bloom
  let mut text = if bloom_example_state.val.bloom_enabled {
    "Bloom (Toggle: Space)\n" +
    "(Q/A) Intensity: " +
    float_text_2(bloom.intensity) +
    "\n" +
    "(W/S) Low-frequency boost: " +
    float_text_2(bloom.low_frequency_boost) +
    "\n" +
    "(E/D) Low-frequency boost curvature: " +
    float_text_2(bloom.low_frequency_boost_curvature) +
    "\n" +
    "(R/F) High-pass frequency: " +
    float_text_2(bloom.high_pass_frequency) +
    "\n" +
    "(T/G) Mode: " +
    bloom_mode_text(bloom.composite_mode) +
    "\n" +
    "(Y/H) Threshold: " +
    float_text_2(bloom.prefilter.threshold) +
    "\n" +
    "(U/J) Threshold softness: " +
    float_text_2(bloom.prefilter.threshold_softness) +
    "\n" +
    "(I/K) Horizontal Scale: " +
    float_text_2(bloom.scale.x) +
    "\n"
  } else {
    "Bloom: Off (Toggle: Space)\n"
  }
  text = text +
    "(O) Tonemapping: " +
    tonemapping_text(bloom_example_state.val.tonemapping) +
    "\n"
  text
}

///|
fn update_help_text() -> Unit {
  if bloom_example_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, bloom_help_text())
  }
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @render2d.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_help_overlay(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    "",
    font,
    20.0F,
    @render2d.Color::white(),
  )
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.get_ui_root_store().insert(root, @ui.UiRoot::default(), tick)
  world
  .get_node_store()
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
  bloom_example_state.val.help_text = Some(text_handle)
  update_help_text()
}

///|
fn bloom_setup(world : @ecs_world.World) -> Unit {
  bloom_example_state.val.camera = @core.Entity::placeholder()
  bloom_example_state.val.help_text = None
  bloom_example_state.val.bloom_enabled = true
  bloom_example_state.val.bloom = @render2d.Bloom2dSettings::default()
  bloom_example_state.val.tonemapping = @render3d.Tonemapping::TonyMcMapface

  let camera = @render2d.Camera2dBundle::new(
      @render2d.Camera::new(@render2d.Color::black()),
      @math.Transform::identity(),
    )
    .with_bloom2d(
      @render2d.Bloom2d::new().with_settings(bloom_example_state.val.bloom),
    )
    .spawn(world)
  bloom_example_state.val.camera = camera
  let tick = world.read_change_tick()
  world
  .get_tonemapping_store()
  .insert(camera, bloom_example_state.val.tonemapping, tick)
  world
  .get_deband_dither_store()
  .insert(camera, @render3d.DebandDither::Enabled, tick)

  let asset_server = @asset.AssetServer::new()
  let bird = asset_server.load("branding/bevy_bird_dark.png")
  @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(bird)
    .with_custom_size(Some(@math.Vec2::new(160.0F, 160.0F)))
    .with_color(@render2d.Color::new(5.0F, 5.0F, 5.0F, 1.0F)),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_circle(@render2d.Circle::new(100.0F)),
    @render2d.ColorMaterial::new(@render2d.Color::new(7.5F, 0.0F, 7.5F, 1.0F)),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-200.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

  @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_regular_polygon(
      @render2d.RegularPolygon::new(100.0F, 6),
    ),
    @render2d.ColorMaterial::new(@render2d.Color::new(6.25F, 9.4F, 9.1F, 1.0F)),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(200.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

  spawn_help_overlay(world)
}

///|
fn bloom_update(world : @ecs_world.World) -> Unit {
  if bloom_example_state.val.camera.is_placeholder() {
    return
  }

  let mut bloom = bloom_example_state.val.bloom
  let mut bloom_enabled = bloom_example_state.val.bloom_enabled
  let mut tonemapping = bloom_example_state.val.tonemapping
  let dt = @time.time_delta_seconds()
  let tick = world.read_change_tick()

  if bloom_enabled {
    if @input.key_just_pressed(@window.KeyCode::Space) {
      bloom_enabled = false
    } else {
      let mut intensity = bloom.intensity
      if @input.key_pressed(@window.KeyCode::KeyA) {
        intensity = intensity - dt / 10.0F
      }
      if @input.key_pressed(@window.KeyCode::KeyQ) {
        intensity = intensity + dt / 10.0F
      }
      intensity = clampf(intensity, 0.0F, 1.0F)

      let mut low_frequency_boost = bloom.low_frequency_boost
      if @input.key_pressed(@window.KeyCode::KeyS) {
        low_frequency_boost = low_frequency_boost - dt / 10.0F
      }
      if @input.key_pressed(@window.KeyCode::KeyW) {
        low_frequency_boost = low_frequency_boost + dt / 10.0F
      }
      low_frequency_boost = clampf(low_frequency_boost, 0.0F, 1.0F)

      let mut low_frequency_boost_curvature = bloom.low_frequency_boost_curvature
      if @input.key_pressed(@window.KeyCode::KeyD) {
        low_frequency_boost_curvature = low_frequency_boost_curvature -
          dt / 10.0F
      }
      if @input.key_pressed(@window.KeyCode::KeyE) {
        low_frequency_boost_curvature = low_frequency_boost_curvature +
          dt / 10.0F
      }
      low_frequency_boost_curvature = clampf(
        low_frequency_boost_curvature, 0.0F, 1.0F,
      )

      let mut high_pass_frequency = bloom.high_pass_frequency
      if @input.key_pressed(@window.KeyCode::KeyF) {
        high_pass_frequency = high_pass_frequency - dt / 10.0F
      }
      if @input.key_pressed(@window.KeyCode::KeyR) {
        high_pass_frequency = high_pass_frequency + dt / 10.0F
      }
      high_pass_frequency = clampf(high_pass_frequency, 0.0F, 1.0F)

      let mut composite_mode = bloom.composite_mode
      if @input.key_pressed(@window.KeyCode::KeyG) {
        composite_mode = Additive
      }
      if @input.key_pressed(@window.KeyCode::KeyT) {
        composite_mode = EnergyConserving
      }

      let mut threshold = bloom.prefilter.threshold
      if @input.key_pressed(@window.KeyCode::KeyH) {
        threshold = threshold - dt
      }
      if @input.key_pressed(@window.KeyCode::KeyY) {
        threshold = threshold + dt
      }
      if threshold < 0.0F {
        threshold = 0.0F
      }

      let mut threshold_softness = bloom.prefilter.threshold_softness
      if @input.key_pressed(@window.KeyCode::KeyJ) {
        threshold_softness = threshold_softness - dt / 10.0F
      }
      if @input.key_pressed(@window.KeyCode::KeyU) {
        threshold_softness = threshold_softness + dt / 10.0F
      }
      threshold_softness = clampf(threshold_softness, 0.0F, 1.0F)

      let mut scale_x = bloom.scale.x
      if @input.key_pressed(@window.KeyCode::KeyK) {
        scale_x = scale_x - dt * 2.0F
      }
      if @input.key_pressed(@window.KeyCode::KeyI) {
        scale_x = scale_x + dt * 2.0F
      }
      scale_x = clampf(scale_x, 0.0F, 16.0F)

      bloom = @render2d.Bloom2dSettings::{
        intensity,
        low_frequency_boost,
        low_frequency_boost_curvature,
        high_pass_frequency,
        prefilter: @render2d.BloomPrefilter::{ threshold, threshold_softness },
        composite_mode,
        max_mip_dimension: bloom.max_mip_dimension,
        scale: @math.Vec2::new(scale_x, bloom.scale.y),
      }
    }
  } else if @input.key_just_pressed(@window.KeyCode::Space) {
    bloom_enabled = true
    bloom = @render2d.Bloom2dSettings::default()
  }

  if @input.key_just_pressed(@window.KeyCode::KeyO) {
    tonemapping = next_tonemap(tonemapping)
    world
    .get_tonemapping_store()
    .set(bloom_example_state.val.camera, tonemapping, tick)
    |> ignore
  }

  bloom_example_state.val.bloom = bloom
  bloom_example_state.val.bloom_enabled = bloom_enabled
  bloom_example_state.val.tonemapping = tonemapping

  let bloom_store = world.get_bloom2d_store()
  let camera = bloom_example_state.val.camera
  if bloom_store.get(camera) is Some(current) {
    let next = current.with_settings(bloom).with_enabled(bloom_enabled)
    bloom_store.set(camera, next, tick) |> ignore
  }

  update_help_text()
}
