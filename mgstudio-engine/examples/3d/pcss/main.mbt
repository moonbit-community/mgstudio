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
/// Port of `bevy/examples/3d/pcss.rs`.
///
/// Parity note:
/// - Bevy widget radio-buttons are mapped to keyboard controls.
/// - Camera/light component wiring follows Bevy, with runtime rendering quality
///   still bounded by the current backend.

///|
const LIGHT_RADIUS : Float = 10.0F

///|
const POINT_LIGHT_INTENSITY : Float = 1_000_000_000.0F

///|
const POINT_LIGHT_RANGE : Float = 110.0F

///|
const DIRECTIONAL_SHADOW_DEPTH_BIAS : Float = 0.20F

///|
const POINT_SHADOW_DEPTH_BIAS : Float = 0.35F

///|
const SHADOW_MAP_NEAR_Z : Float = 50.0F

///|
pub(all) enum LightType {
  Directional
  Point
  Spot
} derive(Eq, Show)

///|
pub(all) enum ShadowFilter {
  NonTemporal
  Temporal
} derive(Eq, Show)

///|
priv struct PcssState {
  mut camera : @core.Entity?
  mut light : @core.Entity?
  mut help_text : @text.TextHandle?
  mut light_type : LightType
  mut shadow_filter : ShadowFilter
  mut soft_shadows : Bool
}

///|
let pcss_state : Ref[PcssState] = Ref::new({
  camera: None,
  light: None,
  help_text: None,
  light_type: LightType::Directional,
  shadow_filter: ShadowFilter::NonTemporal,
  soft_shadows: true,
})

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@render3d.ecs_key_global_ambient_light, ambient)
}

///|
fn light_type_text(light_type : LightType) -> String {
  match light_type {
    LightType::Directional => "Directional"
    LightType::Point => "Point"
    LightType::Spot => "Spot"
  }
}

///|
fn shadow_filter_text(shadow_filter : ShadowFilter) -> String {
  match shadow_filter {
    ShadowFilter::NonTemporal => "Non-Temporal"
    ShadowFilter::Temporal => "Temporal"
  }
}

///|
fn on_off_text(enabled : Bool) -> String {
  if enabled {
    "On"
  } else {
    "Off"
  }
}

///|
fn help_text_content() -> String {
  let state = pcss_state.val
  "PCSS (Bevy-aligned controls)\n" +
  "Q/W/E: Light Type " +
  light_type_text(state.light_type) +
  "\n" +
  "A/S: Shadow Filter " +
  shadow_filter_text(state.shadow_filter) +
  "\n" +
  "D/F: Soft Shadows " +
  on_off_text(state.soft_shadows) +
  "\n"
}

///|
fn update_help_text() -> Unit {
  if pcss_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, help_text_content())
  }
}

///|
fn create_directional_light() -> @render3d.DirectionalLight {
  @render3d.DirectionalLight::new(@sprite.Color::white(), 10_000.0F, true)
  .with_shadow_depth_bias(DIRECTIONAL_SHADOW_DEPTH_BIAS)
  .with_soft_shadow_size(
    if pcss_state.val.soft_shadows {
      Some(LIGHT_RADIUS)
    } else {
      None
    },
  )
}

///|
fn create_point_light() -> @render3d.PointLight {
  @render3d.PointLight::new(
    @sprite.Color::white(),
    POINT_LIGHT_INTENSITY,
    POINT_LIGHT_RANGE,
    true,
  )
  .with_radius(LIGHT_RADIUS)
  .with_soft_shadows_enabled(pcss_state.val.soft_shadows)
  .with_shadow_depth_bias(POINT_SHADOW_DEPTH_BIAS)
  .with_shadow_map_near_z(SHADOW_MAP_NEAR_Z)
}

///|
fn create_spot_light() -> @render3d.SpotLight {
  @render3d.SpotLight::new(
    @sprite.Color::white(),
    POINT_LIGHT_INTENSITY,
    POINT_LIGHT_RANGE,
    0.0F,
    0.7853981633974483F,
    true,
  )
  .with_radius(LIGHT_RADIUS)
  .with_soft_shadows_enabled(pcss_state.val.soft_shadows)
  .with_shadow_depth_bias(DIRECTIONAL_SHADOW_DEPTH_BIAS)
  .with_shadow_map_near_z(SHADOW_MAP_NEAR_Z)
}

///|
fn apply_camera_shadow_filter(world : @ecs.World) -> Unit {
  guard pcss_state.val.camera is Some(camera) else { return }
  let tick = world.read_change_tick()
  let filter_mode = match pcss_state.val.shadow_filter {
    ShadowFilter::NonTemporal => @render3d.ShadowFilteringMethod::Gaussian
    ShadowFilter::Temporal => @render3d.ShadowFilteringMethod::Temporal
  }
  world
  .component(@render3d.ecs_key_shadow_filtering_method)
  .insert(camera, filter_mode, tick)
  if pcss_state.val.shadow_filter == ShadowFilter::Temporal {
    world
    .component(@render3d.ecs_key_temporal_anti_aliasing)
    .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)
  } else {
    world.component(@render3d.ecs_key_temporal_anti_aliasing).remove(camera)
    |> ignore
  }
}

///|
fn apply_light_type(world : @ecs.World) -> Unit {
  guard pcss_state.val.light is Some(light) else { return }
  let tick = world.read_change_tick()
  world.component(@render3d.ecs_key_directional_light).remove(light) |> ignore
  world.component(@render3d.ecs_key_point_light).remove(light) |> ignore
  world.component(@render3d.ecs_key_spot_light).remove(light) |> ignore

  match pcss_state.val.light_type {
    LightType::Directional =>
      world
      .component(@render3d.ecs_key_directional_light)
      .insert(light, create_directional_light(), tick)
    LightType::Point =>
      world
      .component(@render3d.ecs_key_point_light)
      .insert(light, create_point_light(), tick)
    LightType::Spot =>
      world
      .component(@render3d.ecs_key_spot_light)
      .insert(light, create_spot_light(), tick)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  pcss_state.val = {
    camera: None,
    light: None,
    help_text: None,
    light_type: LightType::Directional,
    shadow_filter: ShadowFilter::NonTemporal,
    soft_shadows: true,
  }

  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let camera = @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(-12.912F * 0.7F, 4.466F * 0.7F, -10.624F * 0.7F).looking_at(
      @math.Vec3::new(0.0F, 3.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  pcss_state.val.camera = Some(camera)

  world
  .component(@render3d.ecs_key_shadow_filtering_method)
  .insert(camera, @render3d.ShadowFilteringMethod::Gaussian, tick)
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera, @render3d.Msaa::Off, tick)
  world
  .component(@render3d.ecs_key_temporal_jitter)
  .insert(camera, @render3d.TemporalJitter::default(), tick)
  world
  .component(@render3d.ecs_key_depth_prepass)
  .insert(camera, @render3d.DepthPrepass::default(), tick)
  world
  .component(@render3d.ecs_key_motion_vector_prepass)
  .insert(camera, @render3d.MotionVectorPrepass::default(), tick)
  world
  .component(@render3d.ecs_key_skybox)
  .insert(
    camera,
    @render3d.Skybox::new(
      asset_server.load("environment_maps/sky_skybox.ktx2"),
      500.0F,
    ),
    tick,
  )

  let light = world.spawn_empty()
  pcss_state.val.light = Some(light)
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::from_xyz(57.693F, 34.334F, -6.422F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  apply_light_type(world)

  let scene_entity = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    scene_entity,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server, "models/PalmTree/PalmTree.gltf#Scene0",
      ),
    ),
    tick,
  )

  let help_text = @text.Text2dBundle::new(
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
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  pcss_state.val.help_text = Some(help_text)

  set_global_ambient_light(world, @sprite.Color::white(), 0.0F)
  apply_camera_shadow_filter(world)
  update_help_text()
}

///|
fn controls(world : @ecs.World) -> Unit {
  let mut update_light = false
  let mut update_camera = false

  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    pcss_state.val.light_type = LightType::Directional
    update_light = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyW) {
    pcss_state.val.light_type = LightType::Point
    update_light = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    pcss_state.val.light_type = LightType::Spot
    update_light = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyA) {
    pcss_state.val.shadow_filter = ShadowFilter::Temporal
    update_camera = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyS) {
    pcss_state.val.shadow_filter = ShadowFilter::NonTemporal
    update_camera = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyD) {
    pcss_state.val.soft_shadows = true
    update_light = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyF) {
    pcss_state.val.soft_shadows = false
    update_light = true
  }

  if update_light {
    apply_light_type(world)
  }
  if update_camera {
    apply_camera_shadow_filter(world)
  }
  if update_light || update_camera {
    update_help_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(controls))
  .run()
}
