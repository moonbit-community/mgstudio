// Copyright 2026 International Digital Economy Academy
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
/// Port of `bevy/examples/3d/post_processing.rs`.
///
/// Baseline parity: mgstudio now exposes camera-attached
/// `ChromaticAberration` and `Vignette`, but the current renderer evaluates
/// them in the object draw phase (approximation) instead of Bevy's full-screen
/// post-process graph.

///|
const PI : Float = 3.141592653589793F

///|
const ADJUSTMENT_SPEED : Float = 0.005F

///|
const MAX_CHROMATIC_ABERRATION_INTENSITY : Float = 0.4F

///|
const SETTING_COUNT : Int = 6

///|
priv struct AppSettings {
  mut selected : Int
  mut chromatic_aberration_intensity : Float
  mut vignette_intensity : Float
  mut vignette_radius : Float
  mut vignette_smoothness : Float
  mut vignette_roundness : Float
  mut vignette_edge_compensation : Float
}

///|
priv struct PostProcessingState {
  mut settings : AppSettings
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
fn default_settings() -> AppSettings {
  let chromatic_aberration = @render3d.ChromaticAberration::default()
  let vignette = @render3d.Vignette::default()
  {
    selected: 0,
    chromatic_aberration_intensity: chromatic_aberration.intensity,
    vignette_intensity: vignette.intensity,
    vignette_radius: vignette.radius,
    vignette_smoothness: vignette.smoothness,
    vignette_roundness: vignette.roundness,
    vignette_edge_compensation: vignette.edge_compensation,
  }
}

///|
let post_processing_state : Ref[PostProcessingState] = Ref::new({
  settings: default_settings(),
  camera: None,
  help_text: None,
})

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
fn float_text(value : Float) -> String {
  let rounded = (value * 100.0F).round() / 100.0F
  "\{rounded}"
}

///|
fn apply_post_process_settings(world : @ecs_world.World) -> Unit {
  guard post_processing_state.val.camera is Some(camera_entity) else { return }
  let tick = world.read_change_tick()
  let settings = post_processing_state.val.settings

  let intensity = settings.chromatic_aberration_intensity
  let max_samples_f = ((intensity - 0.02F) / (0.20F - 0.02F) * 56.0F + 8.0F).round()
  let max_samples = clampf(max_samples_f, 8.0F, 64.0F).to_int()
  let chromatic_aberration = @render3d.ChromaticAberration::default()
    .with_intensity(intensity)
    .with_max_samples(max_samples)

  let vignette = @render3d.Vignette::default()
    .with_intensity(settings.vignette_intensity)
    .with_radius(settings.vignette_radius)
    .with_smoothness(settings.vignette_smoothness)
    .with_roundness(settings.vignette_roundness)
    .with_edge_compensation(settings.vignette_edge_compensation)

  let chromatic_aberration_store = world.get_chromatic_aberration_store()
  if chromatic_aberration_store.contains(camera_entity) {
    chromatic_aberration_store.set(camera_entity, chromatic_aberration, tick)
    |> ignore
  } else {
    chromatic_aberration_store.insert(camera_entity, chromatic_aberration, tick)
  }
  let vignette_store = world.get_vignette_store()
  if vignette_store.contains(camera_entity) {
    vignette_store.set(camera_entity, vignette, tick) |> ignore
  } else {
    vignette_store.insert(camera_entity, vignette, tick)
  }
}

///|
fn help_text_content() -> String {
  let settings = post_processing_state.val.settings
  let lines = [
    "Chromatic aberration intensity: " +
    float_text(settings.chromatic_aberration_intensity),
    "Vignette intensity: " + float_text(settings.vignette_intensity),
    "Vignette radius: " + float_text(settings.vignette_radius),
    "Vignette smoothness: " + float_text(settings.vignette_smoothness),
    "Vignette roundness: " + float_text(settings.vignette_roundness),
    "Vignette edge compensation: " +
    float_text(settings.vignette_edge_compensation),
  ]
  let text = StringBuilder::new()
  for i in 0..<SETTING_COUNT {
    if i == settings.selected {
      text.write_string("> ")
    }
    text.write_string(lines[i])
    text.write_string("\n")
  }
  text.write_string("\n(Press Up or Down to select)\n")
  text.write_string("(Press Left or Right to change)")
  text.to_string()
}

///|
fn update_help_text() -> Unit {
  guard post_processing_state.val.help_text is Some(help_text) else { return }
  @text.text_set_content(help_text, help_text_content())
}

///|
fn spawn_camera(world : @ecs_world.World) -> Unit {
  let camera = @render3d.Camera3dBundle::new(
      @render2d.Camera::default(),
      @math.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
        @math.Vec3::new(0.0F, 0.3F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_chromatic_aberration(Some(@render3d.ChromaticAberration::default()))
    .with_vignette(Some(@render3d.Vignette::default()))
    .spawn(world)
  post_processing_state.val.camera = Some(camera)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F, 1.0F),
      @render3d.FogFalloff3d::linear(1.0F, 8.0F),
    ),
  )
}

///|
fn spawn_scene(
  world : @ecs_world.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let tick = world.read_change_tick()

  let tonemapping_test = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(
    tonemapping_test,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/TonemappingTest/TonemappingTest.gltf",
        ),
      ),
    ),
    tick,
  )

  let flight_helmet = world.spawn_empty()
  world
  .get_scene_root_store()
  .insert(
    flight_helmet,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    flight_helmet,
    @math.Transform::from_xyz(0.5F, 0.0F, -0.5F).with_rotation(
      @math.Quat::from_rotation_y(-0.15F * PI),
    ),
    tick,
  )

  let directional_light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 15_000.0F, true),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(0.0F, 4.0F, 4.0F).with_rotation(
      @math.Quat::from_rotation_y(-0.15F * PI).mul(
        @math.Quat::from_rotation_x(-0.15F * PI),
      ),
    ),
    tick,
  )
}

///|
fn spawn_text(asset_server : @asset.AssetServer) -> Unit {
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  post_processing_state.val.help_text = Some(handle)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  post_processing_state.val.settings = default_settings()
  post_processing_state.val.camera = None
  post_processing_state.val.help_text = None

  let asset_server = @asset.AssetServer::new()
  spawn_camera(world)
  spawn_scene(world, asset_server)
  spawn_text(asset_server)
  apply_post_process_settings(world)
  update_help_text()
}

///|
fn handle_keyboard_input(world : @ecs_world.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::ArrowUp) &&
    post_processing_state.val.settings.selected > 0 {
    post_processing_state.val.settings.selected = post_processing_state.val.settings.selected -
      1
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::ArrowDown) &&
    post_processing_state.val.settings.selected < SETTING_COUNT - 1 {
    post_processing_state.val.settings.selected = post_processing_state.val.settings.selected +
      1
    changed = true
  }

  let mut delta = 0.0F
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta = delta - ADJUSTMENT_SPEED
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    delta = delta + ADJUSTMENT_SPEED
  }
  if delta != 0.0F {
    let selected = post_processing_state.val.settings.selected
    if selected == 0 {
      post_processing_state.val.settings.chromatic_aberration_intensity = clampf(
        post_processing_state.val.settings.chromatic_aberration_intensity +
        delta,
        0.0F,
        MAX_CHROMATIC_ABERRATION_INTENSITY,
      )
    } else if selected == 1 {
      post_processing_state.val.settings.vignette_intensity = clampf(
        post_processing_state.val.settings.vignette_intensity + delta,
        0.0F,
        1.0F,
      )
    } else if selected == 2 {
      post_processing_state.val.settings.vignette_radius = clampf(
        post_processing_state.val.settings.vignette_radius + delta,
        0.0F,
        2.0F,
      )
    } else if selected == 3 {
      let smoothness = post_processing_state.val.settings.vignette_smoothness +
        delta
      post_processing_state.val.settings.vignette_smoothness = if smoothness <=
        0.01F {
        0.01F
      } else {
        smoothness
      }
    } else if selected == 4 {
      let roundness = post_processing_state.val.settings.vignette_roundness +
        delta
      post_processing_state.val.settings.vignette_roundness = if roundness <=
        0.01F {
        0.01F
      } else {
        roundness
      }
    } else if selected == 5 {
      post_processing_state.val.settings.vignette_edge_compensation = clampf(
        post_processing_state.val.settings.vignette_edge_compensation + delta,
        0.0F,
        1.0F,
      )
    }
    changed = true
  }

  if changed {
    apply_post_process_settings(world)
    update_help_text()
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(handle_keyboard_input)
  .run()
}
