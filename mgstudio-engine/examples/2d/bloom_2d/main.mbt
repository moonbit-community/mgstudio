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
/// Port of `bevy/examples/2d/bloom_2d.rs`.

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(bloom_setup))
  .add_systems(@app.Update, @app.system(bloom_update))
  .run()
}

///|
fn float_text_2(value : Float) -> String {
  let scaled = (value * 100.0F).round().to_int()
  let sign = if scaled < 0 { "-" } else { "" }
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let whole = abs_scaled / 100
  let fraction = abs_scaled % 100
  let fraction_text = if fraction < 10 {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  sign + whole.to_string() + "." + fraction_text
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
fn bloom_mode_text(mode : @sprite.BloomCompositeMode) -> String {
  match mode {
    EnergyConserving => "Energy-conserving"
    Additive => "Additive"
  }
}

///|
fn tonemapping_text(mode : @sprite.Tonemapping) -> String {
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
fn next_tonemap(mode : @sprite.Tonemapping) -> @sprite.Tonemapping {
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
fn bloom_help_text(
  bloom : @sprite.Bloom2d?,
  tonemapping : @sprite.Tonemapping,
) -> String {
  let mut text = match bloom {
    Some(bloom) => {
      let settings = bloom.settings
      "Bloom (Toggle: Space)\n" +
      "(Q/A) Intensity: " +
      float_text_2(settings.intensity) +
      "\n" +
      "(W/S) Low-frequency boost: " +
      float_text_2(settings.low_frequency_boost) +
      "\n" +
      "(E/D) Low-frequency boost curvature: " +
      float_text_2(settings.low_frequency_boost_curvature) +
      "\n" +
      "(R/F) High-pass frequency: " +
      float_text_2(settings.high_pass_frequency) +
      "\n" +
      "(T/G) Mode: " +
      bloom_mode_text(settings.composite_mode) +
      "\n" +
      "(Y/H) Threshold: " +
      float_text_2(settings.prefilter.threshold) +
      "\n" +
      "(U/J) Threshold softness: " +
      float_text_2(settings.prefilter.threshold_softness) +
      "\n" +
      "(I/K) Horizontal Scale: " +
      float_text_2(settings.scale.x) +
      "\n"
    }
    None => "Bloom: Off (Toggle: Space)\n"
  }
  text = text + "(O) Tonemapping: " + tonemapping_text(tonemapping) + "\n"
  text
}

///|
fn single_camera_entity(world : @ecs.World) -> @core.Entity? {
  let entity_ref = Ref::new(None)
  let query = world.query1_filtered(@sprite.ecs_key_camera2d, @ecs.All::new())
  try! query.view(fn(entity, _camera2d) {
    if entity_ref.val is None {
      entity_ref.val = Some(entity)
    }
  })
  entity_ref.val
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in bloom_2d example")
  }
}

///|
fn single_help_text_handle(world : @ecs.World) -> @text.TextHandle? {
  let handle_ref = Ref::new(None)
  let query = world.query1_filtered(@ui.ecs_key_ui_text, @ecs.All::new())
  try! query.view(fn(_entity, ui_text) {
    if handle_ref.val is None {
      handle_ref.val = Some(ui_text.handle)
    }
  })
  handle_ref.val
}

///|
fn set_help_text(world : @ecs.World, content : String) -> Unit {
  if single_help_text_handle(world) is Some(handle) {
    @text.text_set_content(handle, content)
  }
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 220.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_help_overlay(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    "",
    font,
    20.0F,
    @sprite.Color::white(),
  )
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn bloom_setup(world : @ecs.World) -> Unit {
  let asset_server = match
    (try! world.get_resource(@asset.asset_server_resource_key())) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "bloom_2d requires the world-owned AssetServer resource; add AssetPlugin before the example startup system runs",
      )
  }
  let camera = @sprite.Camera2dBundle::new(
      @sprite.Camera::new(@sprite.Color::black()),
      @math.Transform::identity(),
    )
    .with_bloom2d(@sprite.Bloom2d::new())
    .spawn(world)
  let tick = world.read_change_tick()
  world
  .component(@sprite.ecs_key_tonemapping)
  .insert(camera, @sprite.Tonemapping::TonyMcMapface, tick)
  world
  .component(@sprite.ecs_key_deband_dither)
  .insert(camera, @sprite.DebandDither::Enabled, tick)

  let bird = asset_server.load("branding/bevy_bird_dark.png")
  @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(bird)
    .with_color(@sprite.Color::srgb(5.0F, 5.0F, 5.0F))
    .with_custom_size(Some(@math.Vec2::new(160.0F, 160.0F))),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_circle(@sprite.Circle::new(100.0F)),
    @sprite.ColorMaterial::new(@sprite.Color::srgb(7.5F, 0.0F, 7.5F)),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-200.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

  @sprite.Mesh2dBundle::new(
    @sprite.Mesh2d::from_regular_polygon(@sprite.RegularPolygon::new(100.0F, 6)),
    @sprite.ColorMaterial::new(@sprite.Color::srgb(6.25F, 9.4F, 9.1F)),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(200.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  ).spawn(world)
  |> ignore

  spawn_help_overlay(world, asset_server)
}

///|
fn bloom_update(world : @ecs.World) -> Unit {
  guard single_camera_entity(world) is Some(camera_entity) else { return }

  let bloom_store = world.component(@sprite.ecs_key_bloom2d)
  let tonemapping_store = world.component(@sprite.ecs_key_tonemapping)
  let tick = world.read_change_tick()
  let dt = world_time(world).delta_seconds()
  let tonemapping = tonemapping_store
    .get(camera_entity)
    .unwrap_or(@sprite.Tonemapping::TonyMcMapface)
  let current_bloom = bloom_store.get(camera_entity)

  set_help_text(world, bloom_help_text(current_bloom, tonemapping))

  match current_bloom {
    Some(current_bloom) =>
      if @input.key_just_pressed(@window.KeyCode::Space) {
        bloom_store.remove(camera_entity) |> ignore
      } else {
        let mut intensity = current_bloom.settings.intensity
        if @input.key_pressed(@window.KeyCode::KeyA) {
          intensity = intensity - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyQ) {
          intensity = intensity + dt / 10.0F
        }
        intensity = clampf(intensity, 0.0F, 1.0F)

        let mut low_frequency_boost = current_bloom.settings.low_frequency_boost
        if @input.key_pressed(@window.KeyCode::KeyS) {
          low_frequency_boost = low_frequency_boost - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyW) {
          low_frequency_boost = low_frequency_boost + dt / 10.0F
        }
        low_frequency_boost = clampf(low_frequency_boost, 0.0F, 1.0F)

        let mut low_frequency_boost_curvature = current_bloom.settings.low_frequency_boost_curvature
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

        let mut high_pass_frequency = current_bloom.settings.high_pass_frequency
        if @input.key_pressed(@window.KeyCode::KeyF) {
          high_pass_frequency = high_pass_frequency - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyR) {
          high_pass_frequency = high_pass_frequency + dt / 10.0F
        }
        high_pass_frequency = clampf(high_pass_frequency, 0.0F, 1.0F)

        let mut composite_mode = current_bloom.settings.composite_mode
        if @input.key_pressed(@window.KeyCode::KeyG) {
          composite_mode = Additive
        }
        if @input.key_pressed(@window.KeyCode::KeyT) {
          composite_mode = EnergyConserving
        }

        let mut threshold = current_bloom.settings.prefilter.threshold
        if @input.key_pressed(@window.KeyCode::KeyH) {
          threshold = threshold - dt
        }
        if @input.key_pressed(@window.KeyCode::KeyY) {
          threshold = threshold + dt
        }
        if threshold < 0.0F {
          threshold = 0.0F
        }

        let mut threshold_softness = current_bloom.settings.prefilter.threshold_softness
        if @input.key_pressed(@window.KeyCode::KeyJ) {
          threshold_softness = threshold_softness - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyU) {
          threshold_softness = threshold_softness + dt / 10.0F
        }
        threshold_softness = clampf(threshold_softness, 0.0F, 1.0F)

        let mut scale_x = current_bloom.settings.scale.x
        if @input.key_pressed(@window.KeyCode::KeyK) {
          scale_x = scale_x - dt * 2.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyI) {
          scale_x = scale_x + dt * 2.0F
        }
        scale_x = clampf(scale_x, 0.0F, 16.0F)

        let next_settings = @sprite.Bloom2dSettings::{
          intensity,
          low_frequency_boost,
          low_frequency_boost_curvature,
          high_pass_frequency,
          prefilter: @sprite.BloomPrefilter::{ threshold, threshold_softness },
          composite_mode,
          max_mip_dimension: current_bloom.settings.max_mip_dimension,
          scale: @math.Vec2::new(scale_x, current_bloom.settings.scale.y),
        }
        bloom_store.set(
          camera_entity,
          current_bloom.with_settings(next_settings).with_enabled(true),
          tick,
        )
        |> ignore
      }
    None =>
      if @input.key_just_pressed(@window.KeyCode::Space) {
        bloom_store.insert(camera_entity, @sprite.Bloom2d::new(), tick)
      }
  }

  if @input.key_just_pressed(@window.KeyCode::KeyO) {
    tonemapping_store.set(camera_entity, next_tonemap(tonemapping), tick)
    |> ignore
  }
}
