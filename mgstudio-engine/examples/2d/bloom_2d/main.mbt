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
struct BloomCamera {}

///|
let bloom_camera_key : @ecs.ComponentKey[BloomCamera] = @ecs.register_component(
  debug_name="examples.2d.bloom_2d.BloomCamera",
)

///|
pub impl @ecs.Component for BloomCamera with component() {
  bloom_camera_key
}

///|
struct BloomHelpText {}

///|
let bloom_help_text_key : @ecs.ComponentKey[BloomHelpText] = @ecs.register_component(
  debug_name="examples.2d.bloom_2d.BloomHelpText",
)

///|
pub impl @ecs.Component for BloomHelpText with component() {
  bloom_help_text_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param6(update_bloom_settings)),
  )
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
    "0\{fraction.to_string()}"
  } else {
    fraction.to_string()
  }
  "\{sign}\{whole.to_string()}.\{fraction_text}"
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
  bloom : @sprite.Bloom?,
  tonemapping : @sprite.Tonemapping,
) -> String {
  let mut text = match bloom {
    Some(bloom) =>
      "Bloom (Toggle: Space)\n(Q/A) Intensity: \{float_text_2(bloom.intensity)}\n(W/S) Low-frequency boost: \{float_text_2(bloom.low_frequency_boost)}\n(E/D) Low-frequency boost curvature: \{float_text_2(bloom.low_frequency_boost_curvature)}\n(R/F) High-pass frequency: \{float_text_2(bloom.high_pass_frequency)}\n(T/G) Mode: \{bloom_mode_text(bloom.composite_mode)}\n(Y/H) Threshold: \{float_text_2(bloom.prefilter.threshold)}\n(U/J) Threshold softness: \{float_text_2(bloom.prefilter.threshold_softness)}\n(I/K) Horizontal Scale: \{float_text_2(bloom.scale.x)}\n"
    None => "Bloom: Off (Toggle: Space)\n"
  }
  text = "\{text}(O) Tonemapping: \{tonemapping_text(tonemapping)}\n"
  text
}

///|
fn spawn_help_overlay(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @text.Text::new(""),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
        BloomHelpText::{  },
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::new(@sprite.Color::black()),
        @sprite.Tonemapping::TonyMcMapface,
        @sprite.Bloom::default(),
        @sprite.DebandDither::Enabled,
        BloomCamera::{  },
      ),
    ),
  )

  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(
        asset_server.get().load("branding/bevy_bird_dark.png"),
      )
      .with_color(@sprite.Color::srgb(5.0F, 5.0F, 5.0F))
      .with_custom_size(Some(@math.Vec2::new(160.0F, 160.0F))),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes
          .peek()
          .add(
            @sprite.mesh2d_geometry_circle(@sprite.Circle::new(100.0F)).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite.ColorMaterialAsset::from_color(
              @sprite.Color::srgb(7.5F, 0.0F, 7.5F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(-200.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes
          .peek()
          .add(
            @sprite.mesh2d_geometry_regular_polygon(
              @sprite.RegularPolygon::new(100.0F, 6),
            ).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite.ColorMaterialAsset::from_color(
              @sprite.Color::srgb(6.25F, 9.4F, 9.1F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(200.0F, 0.0F, 0.0F),
      ),
    ),
  )

  spawn_help_overlay(commands, asset_server)
}

///|
fn bloom_camera_entity(
  camera_query : @ecs.Query[@ecs.Comp[BloomCamera], @ecs.All],
) -> @core.Entity? {
  let camera_ref : Ref[@core.Entity?] = Ref::new(None)
  try! camera_query.view(fn(entity, _camera) {
    if camera_ref.val is None {
      camera_ref.val = Some(entity)
    }
  })
  camera_ref.val
}

///|
fn update_bloom_settings(
  commands : @app.Commands,
  time : @app.Res[@time.Time[Unit]],
  camera_query : @ecs.Query[@ecs.Comp[BloomCamera], @ecs.All],
  tonemapping_query : @ecs.Query[@ecs.Comp[@sprite.Tonemapping], @ecs.All],
  bloom_query : @ecs.Query[@ecs.Comp[@sprite.Bloom], @ecs.All],
  help_query : @ecs.Query[
    (@ecs.Comp[BloomHelpText], @ecs.Mut[@text.Text]),
    @ecs.All,
  ],
) -> Unit {
  guard bloom_camera_entity(camera_query) is Some(camera_entity) else { return }

  let tonemapping = match
    (tonemapping_query.get(camera_entity) catch { _ => None }) {
    Some(mode) => mode.value()
    None => @sprite.Tonemapping::TonyMcMapface
  }
  let current_bloom = match
    (bloom_query.get(camera_entity) catch { _ => None }) {
    Some(value) => Some(value.value())
    None => None
  }

  try! help_query.for_each(fn(_entity, data) {
    let (_help_text, help_text) = data
    help_text.modify(fn(value) {
      value.content = bloom_help_text(current_bloom, tonemapping)
    })
  })

  let dt = time.get().delta_seconds()

  match current_bloom {
    Some(current_bloom) =>
      if @input.key_just_pressed(@window.KeyCode::Space) {
        commands.entity(camera_entity).remove_component(@sprite.ecs_key_bloom)
      } else {
        let mut intensity = current_bloom.intensity
        if @input.key_pressed(@window.KeyCode::KeyA) {
          intensity = intensity - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyQ) {
          intensity = intensity + dt / 10.0F
        }
        intensity = clampf(intensity, 0.0F, 1.0F)

        let mut low_frequency_boost = current_bloom.low_frequency_boost
        if @input.key_pressed(@window.KeyCode::KeyS) {
          low_frequency_boost = low_frequency_boost - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyW) {
          low_frequency_boost = low_frequency_boost + dt / 10.0F
        }
        low_frequency_boost = clampf(low_frequency_boost, 0.0F, 1.0F)

        let mut low_frequency_boost_curvature = current_bloom.low_frequency_boost_curvature
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

        let mut high_pass_frequency = current_bloom.high_pass_frequency
        if @input.key_pressed(@window.KeyCode::KeyF) {
          high_pass_frequency = high_pass_frequency - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyR) {
          high_pass_frequency = high_pass_frequency + dt / 10.0F
        }
        high_pass_frequency = clampf(high_pass_frequency, 0.0F, 1.0F)

        let mut composite_mode = current_bloom.composite_mode
        if @input.key_pressed(@window.KeyCode::KeyG) {
          composite_mode = Additive
        }
        if @input.key_pressed(@window.KeyCode::KeyT) {
          composite_mode = EnergyConserving
        }

        let mut threshold = current_bloom.prefilter.threshold
        if @input.key_pressed(@window.KeyCode::KeyH) {
          threshold = threshold - dt
        }
        if @input.key_pressed(@window.KeyCode::KeyY) {
          threshold = threshold + dt
        }
        if threshold < 0.0F {
          threshold = 0.0F
        }

        let mut threshold_softness = current_bloom.prefilter.threshold_softness
        if @input.key_pressed(@window.KeyCode::KeyJ) {
          threshold_softness = threshold_softness - dt / 10.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyU) {
          threshold_softness = threshold_softness + dt / 10.0F
        }
        threshold_softness = clampf(threshold_softness, 0.0F, 1.0F)

        let mut scale_x = current_bloom.scale.x
        if @input.key_pressed(@window.KeyCode::KeyK) {
          scale_x = scale_x - dt * 2.0F
        }
        if @input.key_pressed(@window.KeyCode::KeyI) {
          scale_x = scale_x + dt * 2.0F
        }
        scale_x = clampf(scale_x, 0.0F, 16.0F)

        commands
        .entity(camera_entity)
        .insert_component(
          current_bloom
          .with_intensity(intensity)
          .with_low_frequency_boost(low_frequency_boost)
          .with_low_frequency_boost_curvature(low_frequency_boost_curvature)
          .with_high_pass_frequency(high_pass_frequency)
          .with_prefilter(threshold, threshold_softness)
          .with_composite_mode(composite_mode)
          .with_scale(@math.Vec2::new(scale_x, current_bloom.scale.y)),
        )
      }
    None =>
      if @input.key_just_pressed(@window.KeyCode::Space) {
        commands
        .entity(camera_entity)
        .insert_component(@sprite.Bloom::default())
      }
  }

  if @input.key_just_pressed(@window.KeyCode::KeyO) {
    commands.entity(camera_entity).insert_component(next_tonemap(tonemapping))
  }
}
