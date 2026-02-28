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
/// Port of `bevy/examples/3d/atmosphere.rs`.
///
/// Baseline parity: camera controls, sun motion, exposure control, tonemapping,
/// bloom, TAA, SSR and fog response are aligned where the engine API permits.
///
/// Engine blockers for exact parity:
/// - Missing runtime pipeline and ECS wiring for
///   `Atmosphere` / `ScatteringMedium` / `AtmosphereSettings`.
/// - Missing runtime pipeline and ECS wiring for
///   `FogVolume` / `VolumetricFog` / `VolumetricLight`.
/// - Missing `ExtendedMaterial` custom deferred shader extension path used by
///   Bevy's animated water material.

///|
const SUN_ROTATION_SPEED : Float = 0.3141592653589793F

///|
const SCENE_FOCUS_X : Float = -1.0F

///|
const SCENE_FOCUS_Y : Float = 0.1F

///|
const SCENE_FOCUS_Z : Float = -0.5F

///|
const BASE_EXPOSURE_EV100 : Float = 13.0F

///|
const TERRAIN_ROWS : Int = 36

///|
priv struct AtmosphereState {
  mut paused : Bool
  mut mode : Int
  mut exposure_ev100 : Float
  mut sun_pitch : Float
  atmosphere_stub : @render3d.Atmosphere
  mut atmosphere_settings_stub : @render3d.AtmosphereSettings
  volumetric_fog_stub : @render3d.VolumetricFog
  fog_volume_stub : @render3d.FogVolume
  mut camera : @core.Entity?
  mut sun : @core.Entity?
  mut water_material : @asset.Handle[@render3d.StandardMaterial]?
  mut help_text : @text.TextHandle?
}

///|
let atmosphere_state : Ref[AtmosphereState] = Ref::new({
  paused: false,
  mode: 0,
  exposure_ev100: BASE_EXPOSURE_EV100,
  sun_pitch: 0.0F,
  atmosphere_stub: @render3d.Atmosphere::earthlike(
    @render3d.ScatteringMedium::earthlike().with_density_multiplier(1.0F),
  ),
  atmosphere_settings_stub: @render3d.AtmosphereSettings::default(),
  volumetric_fog_stub: @render3d.VolumetricFog::default()
  .with_ambient_intensity(0.0F),
  fog_volume_stub: @render3d.FogVolume::default()
  .with_density_factor(0.1F)
  .with_scattering(0.3F)
  .with_absorption(0.3F),
  camera: None,
  sun: None,
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
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn transform_forward(transform : @math.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn scene_focus() -> @math.Vec3 {
  @math.Vec3::new(SCENE_FOCUS_X, SCENE_FOCUS_Y, SCENE_FOCUS_Z)
}

///|
fn atmosphere_mode_name(mode : Int) -> String {
  if mode == 0 {
    "LookupTexture"
  } else {
    "Raymarched"
  }
}

///|
fn atmosphere_instruction_text() -> String {
  let paused = if atmosphere_state.val.paused { "yes" } else { "no" }
  "Atmosphere Example Controls\n1 - LookupTexture\n2 - Raymarched\nEnter - Pause/Resume Sun Motion\nArrowUp/ArrowDown - Adjust Exposure\n\nMode: \{atmosphere_mode_name(atmosphere_state.val.mode)}\nPaused: \{paused}\nExposure ev100: \{atmosphere_state.val.exposure_ev100}"
}

///|
fn print_controls() -> Unit {
  println("Atmosphere Example Controls:")
  println("    1          - Switch to lookup texture rendering method")
  println("    2          - Switch to raymarched rendering method")
  println("    Enter      - Pause/Resume sun motion")
  println("    Up/Down    - Increase/Decrease exposure")
}

///|
fn apply_atmosphere(world : @ecs_world.World) -> Unit {
  let state = atmosphere_state.val
  let medium_density = clampf(
    state.atmosphere_stub.medium.density_multiplier,
    0.1F,
    10.0F,
  )
  let scene_units_to_m = clampf(
    state.atmosphere_settings_stub.scene_units_to_m,
    0.1F,
    10.0F,
  )
  let fog_density_factor = clampf(state.fog_volume_stub.density_factor, 0.0F, 2.0F)
  let ambient_intensity = clampf(
    state.volumetric_fog_stub.ambient_intensity,
    0.0F,
    2.0F,
  )

  let (
    base_r,
    base_g,
    base_b,
    sun_r,
    sun_g,
    sun_b,
    extinction_r,
    extinction_g,
    extinction_b,
    inscattering_r,
    inscattering_g,
    inscattering_b,
    base_visibility,
    directional_exponent,
  ) = if state.mode == 0 {
    (
      0.35F,
      0.48F,
      0.66F,
      0.80F,
      0.84F,
      1.00F,
      0.35F,
      0.50F,
      0.66F,
      0.80F,
      0.844F,
      1.00F,
      18.0F,
      5.0F,
    )
  } else {
    (
      0.30F,
      0.42F,
      0.60F,
      1.00F,
      0.92F,
      0.80F,
      0.30F,
      0.45F,
      0.62F,
      1.00F,
      0.92F,
      0.80F,
      12.0F,
      8.0F,
    )
  }

  let mut sun_mix = 0.0F
  if state.camera is Some(camera_entity) {
    if state.sun is Some(sun_entity) {
      if world.get_transform_store().get(camera_entity)
        is Some(camera_transform) {
        if world.get_transform_store().get(sun_entity) is Some(sun_transform) {
          let light_dir = transform_forward(sun_transform).neg()
          let view_dir = scene_focus()
            .sub(camera_transform.translation)
            .normalize_or_zero()
          let phase = clamp01(light_dir.dot(view_dir) * 0.5F + 0.5F)
          sun_mix = clamp01(@math.pow(phase, directional_exponent) * 0.55F)
        }
      }
    }
  }

  // Lower ev100 means brighter scene (roughly).
  let exposure_scale = clampf(
    @math.pow(2.0F, (BASE_EXPOSURE_EV100 - state.exposure_ev100) / 6.0F),
    0.45F,
    1.85F,
  )

  let fog_r = clamp01(
    (base_r * (1.0F - sun_mix) + sun_r * sun_mix) * exposure_scale,
  )
  let fog_g = clamp01(
    (base_g * (1.0F - sun_mix) + sun_g * sun_mix) * exposure_scale,
  )
  let fog_b = clamp01(
    (base_b * (1.0F - sun_mix) + sun_b * sun_mix) * exposure_scale,
  )
  let ambient_lift = clampf(ambient_intensity * 0.2F, 0.0F, 0.2F)
  let visibility = clampf(
    base_visibility /
    clampf(exposure_scale, 0.55F, 1.8F) /
    clampf(medium_density * scene_units_to_m * (1.0F + fog_density_factor), 0.2F, 12.0F),
    6.0F,
    40.0F,
  )
  let directional_alpha = clampf(0.3F + sun_mix * 0.45F, 0.2F, 0.75F)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::default()
    .with_color(
      @render2d.Color::new(
        clamp01(fog_r + ambient_lift),
        clamp01(fog_g + ambient_lift),
        clamp01(fog_b + ambient_lift),
        1.0F,
      ),
    )
    .with_directional_light_color(
      @render2d.Color::new(sun_r, sun_g, sun_b, directional_alpha),
    )
    .with_directional_light_exponent(directional_exponent)
    .with_falloff(
      @render3d.FogFalloff3d::from_visibility_colors(
        visibility,
        @render2d.Color::srgb(extinction_r, extinction_g, extinction_b),
        @render2d.Color::srgb(inscattering_r, inscattering_g, inscattering_b),
      ),
    ),
  )

  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      clampf(0.03F * exposure_scale, 0.01F, 0.06F),
    )
  }
}

///|
fn spawn_mesh(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup_camera(world : @ecs_world.World) -> Unit {
  let camera = @render3d.Camera3dBundle::new(
      @render2d.Camera::default().with_clear_color(@render2d.Color::black()),
      @math.Transform::from_xyz(-2.4F, 0.04F, 0.0F).looking_at(
        scene_focus(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_screen_space_reflections(
      Some(@render3d.ScreenSpaceReflections::default()),
    )
    .spawn(world)

  let tick = world.read_change_tick()
  world
  .get_deferred_prepass_store()
  .insert(camera, @render3d.DeferredPrepass::default(), tick)
  world
  .get_tonemapping_store()
  .insert(camera, @render3d.Tonemapping::AcesFitted, tick)
  world.get_bloom_store().insert(camera, @render3d.Bloom::default(), tick)
  world.get_msaa_store().insert(camera, @render3d.Msaa::Off, tick)
  world
  .get_temporal_anti_aliasing_store()
  .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)

  atmosphere_state.val.camera = Some(camera)
}

///|
fn setup_scene(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let sun = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    sun,
    @math.Transform::from_xyz(1.0F, 0.4F, 0.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    sun,
    @render3d.DirectionalLight::new(
      @render2d.Color::new(0.98F, 0.95F, 0.82F, 1.0F),
      100_000.0F,
      true,
    ),
    tick,
  )
  atmosphere_state.val.sun = Some(sun)

  let terrain_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.36F, 0.33F, 0.29F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  for i in 0..<TERRAIN_ROWS {
    let i_f = float_from_int(i)
    let depth = i_f * 0.28F
    let width = 0.9F + i_f * 0.35F
    let height = 0.05F + i_f * 0.008F
    let x_shift = @math.sin(i_f * 0.35F) * 0.25F
    spawn_mesh(
      world,
      @render3d.Mesh3d::from_cuboid(width, height, 0.25F),
      terrain_material,
      @math.Transform::from_xyz(
        -1.0F + x_shift,
        height / 2.0F - 0.06F,
        -0.5F - depth,
      ),
    )
  }

  let probe_mesh = @render3d.Mesh3d::from_tetrahedron(0.06F)
  let probe_metal = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_metallic(1.0F)
    .with_perceptual_roughness(0.0F),
  )
  spawn_mesh(
    world,
    probe_mesh,
    probe_metal,
    @math.Transform::from_xyz(-1.0F, 0.1F, -0.1F),
  )

  let probe_rough = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_metallic(0.0F)
    .with_perceptual_roughness(1.0F),
  )
  spawn_mesh(
    world,
    probe_mesh,
    probe_rough,
    @math.Transform::from_xyz(-1.0F, 0.1F, 0.1F),
  )

  let water_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    )
    .with_perceptual_roughness(0.0F)
    .with_metallic(0.0F)
    .with_reflectance(1.0F),
  )
  atmosphere_state.val.water_material = Some(water_material)
  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(100.0F, 0.02F, 100.0F),
    water_material,
    @math.Transform::from_xyz(-1.0F, 0.0F, -0.5F),
  )
}

///|
fn setup_instructions(_world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(atmosphere_instruction_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
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
  atmosphere_state.val.help_text = Some(handle)
}

///|
fn atmosphere_controls(world : @ecs_world.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    atmosphere_state.val.mode = 0
    atmosphere_state.val.atmosphere_settings_stub = atmosphere_state.val.atmosphere_settings_stub
    .with_rendering_method(@render3d.AtmosphereMode::LookupTexture)
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    atmosphere_state.val.mode = 1
    atmosphere_state.val.atmosphere_settings_stub = atmosphere_state.val.atmosphere_settings_stub
    .with_rendering_method(@render3d.AtmosphereMode::Raymarched)
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Enter) {
    atmosphere_state.val.paused = !atmosphere_state.val.paused
    changed = true
  }

  let delta = @time.time_delta_seconds()
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    atmosphere_state.val.exposure_ev100 = atmosphere_state.val.exposure_ev100 -
      delta * 2.0F
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::ArrowDown) {
    atmosphere_state.val.exposure_ev100 = atmosphere_state.val.exposure_ev100 +
      delta * 2.0F
    changed = true
  }
  atmosphere_state.val.exposure_ev100 = clampf(
    atmosphere_state.val.exposure_ev100,
    6.0F,
    20.0F,
  )

  if changed {
    if atmosphere_state.val.help_text is Some(handle) {
      @text.text_set_content(handle, atmosphere_instruction_text())
    }
    apply_atmosphere(world)
  }
}

///|
fn dynamic_scene(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  if !atmosphere_state.val.paused {
    atmosphere_state.val.sun_pitch = atmosphere_state.val.sun_pitch -
      @time.time_delta_seconds() * SUN_ROTATION_SPEED
  }

  if atmosphere_state.val.sun is Some(sun_entity) {
    let sun_pos = @math.Vec3::new(
      1.0F,
      0.4F * @math.cos(atmosphere_state.val.sun_pitch),
      0.4F * @math.sin(atmosphere_state.val.sun_pitch),
    )
    world
    .get_transform_store()
    .set(
      sun_entity,
      @math.Transform::from_xyz(sun_pos.x, sun_pos.y, sun_pos.z).looking_at(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      tick,
    )
    |> ignore
  }

  if atmosphere_state.val.water_material is Some(material_handle) {
    if @render3d.standard_material_get(material_handle) is Some(material) {
      let t = @time.time_elapsed_seconds()
      let wave = (@math.sin(t * 0.8F) + 1.0F) * 0.5F
      let base_blue = 0.10F + wave * 0.10F
      let updated = material
        .with_base_color(@render2d.Color::new(0.0F, 0.0F, base_blue, 1.0F))
        .with_emissive(
          @render2d.Color::new(0.0F, 0.0F, base_blue * 0.35F, 1.0F),
        )
      @render3d.standard_material_set(material_handle, updated) |> ignore
    }
  }

  apply_atmosphere(world)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  atmosphere_state.val = {
    paused: false,
    mode: 0,
    exposure_ev100: BASE_EXPOSURE_EV100,
    sun_pitch: 0.0F,
    atmosphere_stub: @render3d.Atmosphere::earthlike(
      @render3d.ScatteringMedium::earthlike().with_density_multiplier(1.0F),
    ),
    atmosphere_settings_stub: @render3d.AtmosphereSettings::default()
    .with_scene_units_to_m(1.0F)
    .with_rendering_method(@render3d.AtmosphereMode::LookupTexture),
    volumetric_fog_stub: @render3d.VolumetricFog::default()
    .with_ambient_intensity(0.0F),
    fog_volume_stub: @render3d.FogVolume::default()
    .with_density_factor(0.1F)
    .with_scattering(0.3F)
    .with_absorption(0.3F),
    camera: None,
    sun: None,
    water_material: None,
    help_text: None,
  }

  setup_camera(world)
  setup_scene(world)
  setup_instructions(world)
  apply_atmosphere(world)
  print_controls()
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(atmosphere_controls)
  .add_system(dynamic_scene)
  .run()
}
