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
/// Port of `bevy/examples/3d/depth_of_field.rs`.
///
/// Baseline parity: Bevy `DepthOfField` post-process modes are not exposed in
/// current mgstudio APIs. This port preserves Bevy's control model
/// (focus/aperture/mode cycling and help text semantics), keeps real camera
/// `Hdr`/`Tonemapping`/`Bloom` setup, and maps DOF adjustments onto camera
/// projection and distance-fog proxies.

///|
const FOCAL_DISTANCE_SPEED : Float = 0.05F

///|
const APERTURE_F_STOP_SPEED : Float = 0.01F

///|
const MIN_FOCAL_DISTANCE : Float = 0.01F

///|
const MIN_APERTURE_F_STOPS : Float = 0.05F

///|
const SENSOR_HEIGHT_METERS : Float = 0.024F

///|
const BASE_FOV : Float = 0.47123889803846897F

///|
pub(all) enum DofMode {
  Bokeh
  Gaussian
  Off
}

///|
priv struct DofState {
  mut focal_distance : Float
  mut aperture_f_stops : Float
  mut mode : DofMode
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let dof_state : Ref[DofState] = Ref::new({
  focal_distance: 7.0F,
  aperture_f_stops: 0.125F,
  mode: DofMode::Bokeh,
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
fn mode_name(mode : DofMode) -> String {
  match mode {
    Bokeh => "Bokeh".to_string()
    Gaussian => "Gaussian".to_string()
    Off => "Off".to_string()
  }
}

///|
fn compute_proxy_fov() -> Float {
  let aperture_term = (dof_state.val.aperture_f_stops - 0.125F) * 0.4F
  clampf(BASE_FOV + aperture_term, 0.22F, 1.20F)
}

///|
fn compute_focal_length_meters(fov : Float) -> Float {
  let half = fov / 2.0F
  let tan_half = @math.sin(half) / @math.cos(half)
  SENSOR_HEIGHT_METERS / (2.0F * tan_half)
}

///|
fn set_camera_projection(world : @ecs.World, fov : Float) -> Unit {
  guard dof_state.val.camera is Some(camera) else { return }
  let perspective = @pbr.PerspectiveProjection3d::{
    ..@pbr.PerspectiveProjection3d::default(),
    fov,
  }
  world
  .component(@pbr.ecs_key_projection)
  .set(
    camera,
    @pbr.Projection::Perspective(perspective),
    world.read_change_tick(),
  )
  |> ignore
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn apply_dof_proxy(world : @ecs.World) -> Unit {
  let mode = dof_state.val.mode
  let focal = dof_state.val.focal_distance
  let aperture = dof_state.val.aperture_f_stops
  let fov = compute_proxy_fov()
  set_camera_projection(world, fov)

  if mode is Off {
    @pbr.render3d_set_distance_fog(
      @pbr.DistanceFog::new(
        @sprite.Color::new(0.12F, 0.13F, 0.14F, 1.0F),
        @pbr.FogFalloff3d::linear(20.0F, 200.0F),
      ),
    )
    set_global_ambient_light(world, @sprite.Color::white(), 0.85F)
    return
  }

  let blur_span = if mode is Bokeh { 1.2F } else { 2.0F }
  let start = clampf(focal - blur_span * (0.6F + aperture * 0.6F), 0.1F, 500.0F)
  let end = clampf(
    focal + blur_span * (1.4F + aperture * 0.8F),
    start + 0.1F,
    500.0F,
  )
  @pbr.render3d_set_distance_fog(
    @pbr.DistanceFog::new(
      @sprite.Color::new(0.11F, 0.12F, 0.13F, 1.0F),
      @pbr.FogFalloff3d::linear(start, end),
    ),
  )
  let ambient = if mode is Bokeh { 0.70F } else { 0.77F }
  set_global_ambient_light(world, @sprite.Color::white(), ambient)
}

///|
fn help_text() -> String {
  let fov = compute_proxy_fov()
  let focal_length_mm = compute_focal_length_meters(fov) * 1000.0F
  let sensor_mm = SENSOR_HEIGHT_METERS * 1000.0F
  if dof_state.val.mode is Off {
    return "Mode: Off (Press Space to change)\n\n" +
      "Focal distance: " +
      dof_state.val.focal_distance.to_string() +
      " m (Press Up/Down to change)\n" +
      "Aperture F-stops: f/" +
      dof_state.val.aperture_f_stops.to_string() +
      " (Press Left/Right to change)\n" +
      "Sensor height: " +
      sensor_mm.to_string() +
      " mm\n" +
      "Focal length: " +
      focal_length_mm.to_string() +
      " mm"
  }
  "Focal distance: " +
  dof_state.val.focal_distance.to_string() +
  " m (Press Up/Down to change)\n" +
  "Aperture F-stops: f/" +
  dof_state.val.aperture_f_stops.to_string() +
  " (Press Left/Right to change)\n" +
  "Sensor height: " +
  sensor_mm.to_string() +
  " mm\n" +
  "Focal length: " +
  focal_length_mm.to_string() +
  " mm\n" +
  "Mode: " +
  mode_name(dof_state.val.mode) +
  " (Press Space to change)\n\n" +
  "Adapted runtime note: DOF post-process is represented via projection/fog proxies."
}

///|
fn update_text() -> Unit {
  if dof_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, help_text())
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  dof_state.val = {
    focal_distance: 7.0F,
    aperture_f_stops: 0.125F,
    mode: DofMode::Bokeh,
    camera: None,
    help_text: None,
  }
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 4.5F, 8.25F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world.component(@pbr.ecs_key_hdr).insert(camera, @pbr.Hdr::default(), tick)
  world
  .component(@post_process.ecs_key_tonemapping)
  .insert(camera, @post_process.Tonemapping::TonyMcMapface, tick)
  world
  .component(@post_process.ecs_key_bloom)
  .insert(camera, @post_process.Bloom::default(), tick)
  dof_state.val.camera = Some(camera)

  let scene_entity = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    scene_entity,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/DepthOfFieldExample/DepthOfFieldExample.glb",
        ),
      ),
    ),
    tick,
  )

  let floor_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.24F, 0.24F, 0.26F, 1.0F),
    ).with_perceptual_roughness(0.85F),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_plane(50.0F, 50.0F),
    @pbr.MeshMaterial3d::new(floor_material),
    @math.Transform::from_xyz(0.0F, -1.0F, -6.0F),
  ).spawn(world)
  |> ignore

  for i in 0..<9 {
    let i_f = Float::from_double(i.to_double())
    let z = -2.0F - i_f * 2.0F
    let x = if i % 2 == 0 { -1.8F } else { 1.8F }
    let hue = i_f / 8.0F
    let material = @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(
          0.25F + hue * 0.55F,
          0.2F + (1.0F - hue) * 0.6F,
          0.45F,
          1.0F,
        ),
      )
      .with_metallic(0.15F + hue * 0.6F)
      .with_perceptual_roughness(0.2F + hue * 0.5F),
    )
    @pbr.MeshMaterial3dBundle::new(
      @pbr.Mesh3d::from_cuboid(0.9F, 0.9F, 0.9F),
      @pbr.MeshMaterial3d::new(material),
      @math.Transform::from_xyz(x, 0.0F, z),
    ).spawn(world)
    |> ignore
  }

  let directional = world.spawn_empty()
  world
  .component(@pbr.ecs_key_directional_light)
  .insert(
    directional,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 25_000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional,
    @math.Transform::from_xyz(0.0F, 8.0F, 3.0F).looking_at(
      @math.Vec3::new(0.0F, -1.5F, -8.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let point = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    point,
    @pbr.PointLight::new(@sprite.Color::white(), 120_000.0F, 40.0F, false),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(point, @math.Transform::from_xyz(0.0F, 4.5F, 6.0F), tick)

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
  dof_state.val.help_text = Some(help_text)

  apply_dof_proxy(world)
  update_text()
}

///|
fn adjust_focus_and_mode(world : @ecs.World) -> Unit {
  let mut changed = false

  let distance_delta = if @input.key_pressed(@window.KeyCode::ArrowDown) {
    -FOCAL_DISTANCE_SPEED
  } else if @input.key_pressed(@window.KeyCode::ArrowUp) {
    FOCAL_DISTANCE_SPEED
  } else {
    0.0F
  }
  let f_stop_delta = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    -APERTURE_F_STOP_SPEED
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    APERTURE_F_STOP_SPEED
  } else {
    0.0F
  }

  if distance_delta != 0.0F || f_stop_delta != 0.0F {
    dof_state.val.focal_distance = clampf(
      dof_state.val.focal_distance + distance_delta,
      MIN_FOCAL_DISTANCE,
      500.0F,
    )
    dof_state.val.aperture_f_stops = clampf(
      dof_state.val.aperture_f_stops + f_stop_delta,
      MIN_APERTURE_F_STOPS,
      16.0F,
    )
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Space) {
    dof_state.val.mode = match dof_state.val.mode {
      Bokeh => DofMode::Gaussian
      Gaussian => DofMode::Off
      Off => DofMode::Bokeh
    }
    changed = true
  }

  if changed {
    apply_dof_proxy(world)
    update_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(adjust_focus_and_mode))
  .run()
}
