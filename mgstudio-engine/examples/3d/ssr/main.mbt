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
/// Port of `bevy/examples/3d/ssr.rs`.
///
/// Baseline parity: deferred SSR controls and Bevy scene interaction flow are
/// mapped to mgstudio APIs. Bevy's custom deferred water material extension is
/// still represented with closest available standard-material behavior.

///|
const PI : Float = 3.141592653589793F

///|
const CAMERA_HEIGHT : Float = 2.25F

///|
const CAMERA_KEYBOARD_ZOOM_SPEED : Float = 0.1F

///|
const CAMERA_KEYBOARD_ORBIT_SPEED : Float = 0.02F

///|
const CAMERA_MOUSE_WHEEL_ZOOM_SPEED : Float = 0.25F

///|
const CAMERA_MIN_RADIUS : Float = 2.0F

///|
const CAMERA_MAX_RADIUS : Float = 12.0F

///|
const RANGE_STEP_ROUGHNESS : Float = 0.005F

///|
const RANGE_STEP_EDGE : Float = 0.001F

///|
pub(all) enum DisplayedModel {
  Cube
  FlightHelmet
  Capsules
}

///|
pub(all) enum DisplayedBase {
  Water
  Metallic
  RedPlane
}

///|
priv struct SsrState {
  mut ssr_on : Bool
  mut displayed_model : DisplayedModel
  mut displayed_base : DisplayedBase
  mut min_roughness_start : Float
  mut min_roughness_end : Float
  mut max_roughness_start : Float
  mut max_roughness_end : Float
  mut edge_fadeout_start : Float
  mut edge_fadeout_end : Float
  mut thickness : Float
  mut linear_steps : Int
  mut bisection_steps : Int
  mut linear_march_exponent : Float
  mut use_secant : Bool
  mut camera_radius : Float
  mut camera_theta : Float
  mut camera : @core.Entity?
  mut cube_model : @core.Entity?
  mut flight_helmet_model : @core.Entity?
  capsule_models : Array[@core.Entity]
  mut metallic_base : @core.Entity?
  mut red_plane_base : @core.Entity?
  mut water_base : @core.Entity?
  mut water_material : @asset.Handle[@render3d.StandardMaterial]?
  mut help_text : @text.TextHandle?
}

///|
let ssr_state : Ref[SsrState] = Ref::new({
  ssr_on: true,
  displayed_model: DisplayedModel::Cube,
  displayed_base: DisplayedBase::Water,
  min_roughness_start: 0.0F,
  min_roughness_end: 0.01F,
  max_roughness_start: 0.99F,
  max_roughness_end: 1.0F,
  edge_fadeout_start: 0.0F,
  edge_fadeout_end: 0.0F,
  thickness: 0.25F,
  linear_steps: 10,
  bisection_steps: 5,
  linear_march_exponent: 1.0F,
  use_secant: true,
  camera_radius: 4.67F,
  camera_theta: -0.2709468503F,
  camera: None,
  cube_model: None,
  flight_helmet_model: None,
  capsule_models: [],
  metallic_base: None,
  red_plane_base: None,
  water_base: None,
  water_material: None,
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
fn clamp01(value : Float) -> Float {
  clampf(value, 0.0F, 1.0F)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn ordered_unit_range(start : Float, end_ : Float) -> (Float, Float) {
  let safe_start = clamp01(start)
  let safe_end = clamp01(end_)
  if safe_start <= safe_end {
    (safe_start, safe_end)
  } else {
    (safe_end, safe_start)
  }
}

///|
fn model_name(model : DisplayedModel) -> String {
  match model {
    Cube => "Cube"
    FlightHelmet => "Flight Helmet"
    Capsules => "Capsules"
  }
}

///|
fn base_name(base : DisplayedBase) -> String {
  match base {
    Water => "Water"
    Metallic => "Metallic"
    RedPlane => "Red Plane"
  }
}

///|
fn on_off_label(value : Bool) -> String {
  if value {
    "On"
  } else {
    "Off"
  }
}

///|
fn ssr_ui_text() -> String {
  let state = ssr_state.val
  "SSR Example (Bevy-aligned scene flow, adapted render path)\n" +
  "\n" +
  "SSR: 1=On 2=Off | Current: " +
  on_off_label(state.ssr_on) +
  "\n" +
  "Model: 3=Cube 4=FlightHelmet 5=Capsules | Current: " +
  model_name(state.displayed_model) +
  "\n" +
  "Base: 6=Water Q=Metallic E=RedPlane | Current: " +
  base_name(state.displayed_base) +
  "\n" +
  "\n" +
  "Camera: W/S zoom, A/D orbit, Mouse Wheel zoom\n" +
  "\n" +
  "Min Roughness Start: J-/U+ = " +
  "\{state.min_roughness_start}" +
  "\n" +
  "Min Roughness End:   K-/I+ = " +
  "\{state.min_roughness_end}" +
  "\n" +
  "Max Roughness Start: N-/M+ = " +
  "\{state.max_roughness_start}" +
  "\n" +
  "Max Roughness End: ,-/ .+ = " +
  "\{state.max_roughness_end}" +
  "\n" +
  "Edge Fadeout Start: R-/T+ = " +
  "\{state.edge_fadeout_start}" +
  "\n" +
  "Edge Fadeout End:   F-/G+ = " +
  "\{state.edge_fadeout_end}" +
  "\n"
}

///|
fn update_help_text() -> Unit {
  if ssr_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, ssr_ui_text())
  }
}

///|
fn uv_sphere_mesh(
  radius : Float,
  stacks : Int,
  sectors : Int,
) -> @render3d.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn set_entity_visibility(
  world : @ecs.World,
  entity : @core.Entity?,
  visible : Bool,
  tick : @core.Tick,
) -> Unit {
  if entity is Some(value) {
    world
    .component(@visibility.ecs_key_visibility)
    .set(
      value,
      if visible {
        @visibility.Visibility::Inherited
      } else {
        @visibility.Visibility::Hidden
      },
      tick,
    )
    |> ignore
  }
}

///|
fn apply_model_and_base_visibility(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let model = ssr_state.val.displayed_model
  let base = ssr_state.val.displayed_base

  set_entity_visibility(world, ssr_state.val.cube_model, model is Cube, tick)
  set_entity_visibility(
    world,
    ssr_state.val.flight_helmet_model,
    model is FlightHelmet,
    tick,
  )
  for capsule in ssr_state.val.capsule_models {
    set_entity_visibility(world, Some(capsule), model is Capsules, tick)
  }

  set_entity_visibility(world, ssr_state.val.water_base, base is Water, tick)
  set_entity_visibility(
    world,
    ssr_state.val.metallic_base,
    base is Metallic,
    tick,
  )
  set_entity_visibility(
    world,
    ssr_state.val.red_plane_base,
    base is RedPlane,
    tick,
  )
}

///|
fn apply_camera_transform(world : @ecs.World) -> Unit {
  if ssr_state.val.camera is Some(camera) {
    let x = @math.sin(ssr_state.val.camera_theta) * ssr_state.val.camera_radius
    let z = @math.cos(ssr_state.val.camera_theta) * ssr_state.val.camera_radius
    let tick = world.read_change_tick()
    world
    .component(@math.ecs_key_transform)
    .set(
      camera,
      @math.Transform::from_xyz(x, CAMERA_HEIGHT, z).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn sanitize_ssr_ranges() -> Unit {
  let (min_start, min_end) = ordered_unit_range(
    ssr_state.val.min_roughness_start,
    ssr_state.val.min_roughness_end,
  )
  ssr_state.val.min_roughness_start = min_start
  ssr_state.val.min_roughness_end = min_end

  let (max_start, max_end) = ordered_unit_range(
    ssr_state.val.max_roughness_start,
    ssr_state.val.max_roughness_end,
  )
  ssr_state.val.max_roughness_start = max_start
  ssr_state.val.max_roughness_end = max_end

  let (edge_start, edge_end) = ordered_unit_range(
    ssr_state.val.edge_fadeout_start,
    ssr_state.val.edge_fadeout_end,
  )
  ssr_state.val.edge_fadeout_start = edge_start
  ssr_state.val.edge_fadeout_end = edge_end

  ssr_state.val.thickness = clampf(ssr_state.val.thickness, 0.0F, 5.0F)
  ssr_state.val.linear_steps = if ssr_state.val.linear_steps <= 0 {
    1
  } else {
    ssr_state.val.linear_steps
  }
  ssr_state.val.bisection_steps = if ssr_state.val.bisection_steps < 0 {
    0
  } else {
    ssr_state.val.bisection_steps
  }
  ssr_state.val.linear_march_exponent = clampf(
    ssr_state.val.linear_march_exponent,
    0.1F,
    4.0F,
  )
}

///|
fn build_ssr_settings() -> @render3d.ScreenSpaceReflections {
  @render3d.ScreenSpaceReflections::default()
  .with_min_perceptual_roughness(
    ssr_state.val.min_roughness_start,
    ssr_state.val.min_roughness_end,
  )
  .with_max_perceptual_roughness(
    ssr_state.val.max_roughness_start,
    ssr_state.val.max_roughness_end,
  )
  .with_edge_fadeout(
    ssr_state.val.edge_fadeout_start,
    ssr_state.val.edge_fadeout_end,
  )
  .with_thickness(ssr_state.val.thickness)
  .with_linear_steps(ssr_state.val.linear_steps)
  .with_bisection_steps(ssr_state.val.bisection_steps)
  .with_linear_march_exponent(ssr_state.val.linear_march_exponent)
  .with_use_secant(ssr_state.val.use_secant)
}

///|
fn apply_ssr_settings(world : @ecs.World) -> Unit {
  sanitize_ssr_ranges()
  if ssr_state.val.camera is Some(camera) {
    let tick = world.read_change_tick()
    let store = world.component(@render3d.ecs_key_screen_space_reflections)
    if ssr_state.val.ssr_on {
      if !store.set(camera, build_ssr_settings(), tick) {
        store.insert(camera, build_ssr_settings(), tick)
      }
    } else {
      store.remove(camera) |> ignore
    }
  }
}

///|
fn spawn_cube(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_base_color_texture(Some(asset_server.load("branding/icon.png")))
    .with_perceptual_roughness(0.08F)
    .with_metallic(0.0F),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  ssr_state.val.cube_model = Some(cube)
}

///|
fn spawn_flight_helmet(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let tick = world.read_change_tick()
  let entity = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    entity,
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
  .component(@math.ecs_key_transform)
  .insert(
    entity,
    @math.Transform::identity().with_scale(@math.Vec3::splat(2.5F)),
    tick,
  )
  world
  .component(@visibility.ecs_key_visibility)
  .insert(entity, @visibility.Visibility::Hidden, tick)
  ssr_state.val.flight_helmet_model = Some(entity)
}

///|
fn spawn_capsules(world : @ecs.World) -> Unit {
  ssr_state.val.capsule_models.clear()
  for i in 0..<5 {
    let roughness = clampf(float_from_int(i) * 0.25F, 0.08F, 1.0F)
    let material = @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(@render2d.Color::black())
      .with_perceptual_roughness(roughness)
      .with_metallic(0.0F),
    )
    let entity = @render3d.MeshMaterial3dBundle::new(
      uv_sphere_mesh(0.4F, 20, 28),
      @render3d.MeshMaterial3d::new(material),
      @math.Transform::from_xyz(float_from_int(i) * 1.1F - 2.2F, 0.5F, 0.0F),
    ).spawn(world)

    let tick = world.read_change_tick()
    world
    .component(@visibility.ecs_key_visibility)
    .set(entity, @visibility.Visibility::Hidden, tick)
    |> ignore
    ssr_state.val.capsule_models.push(entity)
  }
}

///|
fn spawn_bases(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let tick = world.read_change_tick()

  let metallic_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.25F, 0.25F, 0.25F, 1.0F),
    )
    .with_metallic(1.0F)
    .with_perceptual_roughness(0.3F),
  )
  let metallic = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(100.0F, 100.0F),
    @render3d.MeshMaterial3d::new(metallic_material),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@visibility.ecs_key_visibility)
  .set(metallic, @visibility.Visibility::Hidden, tick)
  |> ignore
  ssr_state.val.metallic_base = Some(metallic)

  let red_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.85F, 0.12F, 0.12F, 1.0F),
    )
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.2F),
  )
  let red = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(100.0F, 100.0F),
    @render3d.MeshMaterial3d::new(red_material),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@visibility.ecs_key_visibility)
  .set(red, @visibility.Visibility::Hidden, tick)
  |> ignore
  ssr_state.val.red_plane_base = Some(red)

  let water_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black())
    .with_normal_map_texture(
      Some(
        asset_server.load_with_settings(
          "textures/water_normals.png",
          @asset.ImageLoaderSettings::default()
          .with_is_srgb(false)
          .with_sampler(@asset.ImageSampler::LinearRepeat),
        ),
      ),
    )
    .with_perceptual_roughness(0.09F)
    .with_reflectance(0.6F)
    .with_metallic(0.0F),
  )
  let water = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(100.0F, 100.0F),
    @render3d.MeshMaterial3d::new(water_material),
    @math.Transform::identity(),
  ).spawn(world)
  ssr_state.val.water_base = Some(water)
  ssr_state.val.water_material = Some(water_material)
}

///|
fn setup_camera_and_lights(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @render3d.Camera3dBundle::new(
      @render2d.Camera::default(),
      @math.Transform::from_xyz(-1.25F, CAMERA_HEIGHT, 4.5F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_screen_space_reflections(Some(build_ssr_settings()))
    .spawn(world)
  ssr_state.val.camera = Some(camera)

  let tick = world.read_change_tick()
  world
  .component(@render3d.ecs_key_hdr)
  .insert(camera, @render3d.Hdr::default(), tick)
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera, @render3d.Msaa::Off, tick)
  world
  .component(@render3d.ecs_key_temporal_anti_aliasing)
  .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)
  world
  .component(@render3d.ecs_key_screen_space_ambient_occlusion)
  .insert(camera, @render3d.ScreenSpaceAmbientOcclusion::default(), tick)
  world
  .component(@render3d.ecs_key_environment_map_light)
  .insert(
    camera,
    @render3d.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      5000.0F,
    ),
    tick,
  )
  world
  .component(@render3d.ecs_key_skybox)
  .insert(
    camera,
    @render3d.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      5000.0F,
    ),
    tick,
  )

  let directional = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 15_000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional,
    @math.Transform::from_xyz(2.5F, 5.5F, 2.8F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let point = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    point,
    @render3d.PointLight::new(
      @render2d.Color::new(1.0F, 0.98F, 0.96F, 1.0F),
      200_000.0F,
      30.0F,
      true,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(point, @math.Transform::from_xyz(-3.0F, 3.5F, 2.0F), tick)

  world.insert_resource(
    @render3d.ecs_key_global_ambient_light,
    @render3d.GlobalAmbientLight::new(@render2d.Color::white(), 0.03F),
  )
}

///|
fn setup_text(_world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(ssr_ui_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(790.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .spawn()

  ssr_state.val.help_text = Some(handle)
}

///|
fn rotate_models(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let rotation = @math.Quat::from_rotation_y(@time.time_elapsed_seconds())

  if ssr_state.val.cube_model is Some(cube) {
    if world.component(@math.ecs_key_transform).get(cube) is Some(transform) {
      world
      .component(@math.ecs_key_transform)
      .set(cube, transform.with_rotation(rotation), tick)
      |> ignore
    }
  }

  if ssr_state.val.flight_helmet_model is Some(helmet) {
    if world.component(@math.ecs_key_transform).get(helmet) is Some(transform) {
      world
      .component(@math.ecs_key_transform)
      .set(helmet, transform.with_rotation(rotation), tick)
      |> ignore
    }
  }
}

///|
fn animate_water_material(_world : @ecs.World) -> Unit {
  if ssr_state.val.water_material is Some(handle) {
    if @render3d.standard_material_get(handle) is Some(material) {
      let t = @time.time_elapsed_seconds()
      let offset = @math.Vec2::new(
        @math.sin(t * 0.31F) * 0.04F,
        @math.cos(t * 0.27F) * 0.04F,
      )
      @render3d.standard_material_set(
        handle,
        material
        .with_uv_offset(offset)
        .with_emissive(
          @render2d.Color::new(
            0.01F + @math.sin(t * 0.4F) * 0.005F,
            0.02F,
            0.025F,
            1.0F,
          ),
        ),
      )
      |> ignore
    }
  }
}

///|
fn adjust_camera_controls(world : @ecs.World) -> Bool {
  let mut changed = false

  if @input.key_pressed(@window.KeyCode::KeyW) {
    ssr_state.val.camera_radius = clampf(
      ssr_state.val.camera_radius - CAMERA_KEYBOARD_ZOOM_SPEED,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    ssr_state.val.camera_radius = clampf(
      ssr_state.val.camera_radius + CAMERA_KEYBOARD_ZOOM_SPEED,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyA) {
    ssr_state.val.camera_theta = ssr_state.val.camera_theta +
      CAMERA_KEYBOARD_ORBIT_SPEED
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    ssr_state.val.camera_theta = ssr_state.val.camera_theta -
      CAMERA_KEYBOARD_ORBIT_SPEED
    changed = true
  }

  if @input.mouse_wheel_delta_opt() is Some(wheel) {
    ssr_state.val.camera_radius = clampf(
      ssr_state.val.camera_radius - wheel.y * CAMERA_MOUSE_WHEEL_ZOOM_SPEED,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    changed = true
  }

  if changed {
    apply_camera_transform(world)
  }
  changed
}

///|
fn control_system(world : @ecs.World) -> Unit {
  let mut settings_changed = false
  let mut visibility_changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    ssr_state.val.ssr_on = true
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    ssr_state.val.ssr_on = false
    settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    ssr_state.val.displayed_model = DisplayedModel::Cube
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    ssr_state.val.displayed_model = DisplayedModel::FlightHelmet
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    ssr_state.val.displayed_model = DisplayedModel::Capsules
    visibility_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    ssr_state.val.displayed_base = DisplayedBase::Water
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    ssr_state.val.displayed_base = DisplayedBase::Metallic
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    ssr_state.val.displayed_base = DisplayedBase::RedPlane
    visibility_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyU) {
    ssr_state.val.min_roughness_start = ssr_state.val.min_roughness_start +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyJ) {
    ssr_state.val.min_roughness_start = ssr_state.val.min_roughness_start -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyI) {
    ssr_state.val.min_roughness_end = ssr_state.val.min_roughness_end +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyK) {
    ssr_state.val.min_roughness_end = ssr_state.val.min_roughness_end -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyM) {
    ssr_state.val.max_roughness_start = ssr_state.val.max_roughness_start +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyN) {
    ssr_state.val.max_roughness_start = ssr_state.val.max_roughness_start -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::Period) {
    ssr_state.val.max_roughness_end = ssr_state.val.max_roughness_end +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::Comma) {
    ssr_state.val.max_roughness_end = ssr_state.val.max_roughness_end -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyT) {
    ssr_state.val.edge_fadeout_start = ssr_state.val.edge_fadeout_start +
      RANGE_STEP_EDGE
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyR) {
    ssr_state.val.edge_fadeout_start = ssr_state.val.edge_fadeout_start -
      RANGE_STEP_EDGE
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyG) {
    ssr_state.val.edge_fadeout_end = ssr_state.val.edge_fadeout_end +
      RANGE_STEP_EDGE
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyF) {
    ssr_state.val.edge_fadeout_end = ssr_state.val.edge_fadeout_end -
      RANGE_STEP_EDGE
    settings_changed = true
  }

  let camera_changed = adjust_camera_controls(world)

  if settings_changed {
    apply_ssr_settings(world)
  }
  if visibility_changed {
    apply_model_and_base_visibility(world)
  }

  if settings_changed || visibility_changed || camera_changed {
    update_help_text()
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @render3d.ecs_key_default_opaque_renderer_method,
    @render3d.DefaultOpaqueRendererMethod::deferred(),
  )

  ssr_state.val.ssr_on = true
  ssr_state.val.displayed_model = DisplayedModel::Cube
  ssr_state.val.displayed_base = DisplayedBase::Water
  ssr_state.val.min_roughness_start = 0.0F
  ssr_state.val.min_roughness_end = 0.01F
  ssr_state.val.max_roughness_start = 0.99F
  ssr_state.val.max_roughness_end = 1.0F
  ssr_state.val.edge_fadeout_start = 0.0F
  ssr_state.val.edge_fadeout_end = 0.0F
  ssr_state.val.thickness = 0.25F
  ssr_state.val.linear_steps = 10
  ssr_state.val.bisection_steps = 5
  ssr_state.val.linear_march_exponent = 1.0F
  ssr_state.val.use_secant = true
  ssr_state.val.camera_radius = 4.67F
  ssr_state.val.camera_theta = -0.2709468503F
  ssr_state.val.camera = None
  ssr_state.val.cube_model = None
  ssr_state.val.flight_helmet_model = None
  ssr_state.val.capsule_models.clear()
  ssr_state.val.metallic_base = None
  ssr_state.val.red_plane_base = None
  ssr_state.val.water_base = None
  ssr_state.val.water_material = None
  ssr_state.val.help_text = None

  let asset_server = @asset.AssetServer::new()

  spawn_cube(world, asset_server)
  spawn_flight_helmet(world, asset_server)
  spawn_capsules(world)
  spawn_bases(world, asset_server)
  setup_camera_and_lights(world)
  setup_text(world)

  apply_ssr_settings(world)
  apply_model_and_base_visibility(world)
  apply_camera_transform(world)
  update_help_text()
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(control_system)
  .add_system(rotate_models)
  .add_system(animate_water_material)
  .run()
}
