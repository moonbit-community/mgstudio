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
const SUN_ROTATION_SPEED : Float = 0.3141592653589793F

///|
const PI : Float = 3.141592653589793F

///|
const SCENE_FOCUS_X : Float = 0.0F

///|
const SCENE_FOCUS_Y : Float = 0.1F

///|
const SCENE_FOCUS_Z : Float = 0.0F

///|
const BASE_EXPOSURE_EV100 : Float = 13.0F

///|
priv struct AtmosphereState {
  mut paused : Bool
  mut mode : Int
  mut exposure_ev100 : Float
  mut sun_pitch : Float
  atmosphere : @pbr.Atmosphere
  mut atmosphere_settings : @pbr.AtmosphereSettings
  volumetric_fog : @pbr.VolumetricFog
  fog_volume : @pbr.FogVolume
  mut camera : @core.Entity?
  mut sun : @core.Entity?
  mut fog_volume_entity : @core.Entity?
  mut water_material : @asset.Handle[@pbr.StandardMaterial]?
  mut help_text : @text.TextHandle?
}

///|
let atmosphere_state : Ref[AtmosphereState] = Ref::new({
  paused: false,
  mode: 0,
  exposure_ev100: BASE_EXPOSURE_EV100,
  sun_pitch: 0.0F,
  atmosphere: @pbr.Atmosphere::earthlike(
    @pbr.ScatteringMedium::earthlike().with_density_multiplier(1.0F),
  ),
  atmosphere_settings: @pbr.AtmosphereSettings::default(),
  volumetric_fog: @pbr.VolumetricFog::default().with_ambient_intensity(0.0F),
  fog_volume: @pbr.FogVolume::default()
  .with_density_factor(0.1F)
  .with_scattering(0.3F)
  .with_absorption(0.3F),
  camera: None,
  sun: None,
  fog_volume_entity: None,
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
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in atmosphere example")
  }
}

///|
fn apply_atmosphere(world : @ecs.World) -> Unit {
  let state = atmosphere_state.val
  if state.camera is Some(camera_entity) {
    if (try! world.get_by_key(camera_entity, @pbr.ecs_key_camera3d))
      is Some(camera3d) {
      try! (world.replace(
        camera_entity,
        @pbr.ecs_key_camera3d,
        camera3d
        .with_atmosphere(Some(state.atmosphere))
        .with_atmosphere_settings(Some(state.atmosphere_settings))
        .with_volumetric_fog(Some(state.volumetric_fog)),
      )
      |> ignore)
    }
    try! world.set_by_key(
      camera_entity,
      @pbr.ecs_key_atmosphere_environment_map_light,
      @pbr.AtmosphereEnvironmentMapLight::default(),
    )
  }
  if state.fog_volume_entity is Some(fog_volume_entity) {
    try! (world.replace(
      fog_volume_entity,
      @pbr.ecs_key_fog_volume,
      state.fog_volume,
    )
    |> ignore)
  }
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 0.0F),
  )
}

///|
fn spawn_mesh(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
) -> Unit {
  @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default().with_clear_color(@sprite.Color::black()),
      @transform.Transform::from_xyz(-2.4F, 0.04F, 0.0F).looking_at(
        scene_focus(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_atmosphere(Some(atmosphere_state.val.atmosphere))
    .with_atmosphere_settings(Some(atmosphere_state.val.atmosphere_settings))
    .with_volumetric_fog(Some(atmosphere_state.val.volumetric_fog))
    .with_exposure(Some(@pbr.Exposure::new(BASE_EXPOSURE_EV100)))
    .with_screen_space_reflections(
      Some(@post_process.ScreenSpaceReflections::default()),
    )
    .spawn(world)

  try! world.set_by_key(
    camera,
    @post_process.ecs_key_tonemapping,
    @post_process.Tonemapping::AcesFitted,
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_bloom,
    @post_process.Bloom::natural(),
  )
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::default(),
  )

  atmosphere_state.val.camera = Some(camera)
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let cascade_shadow_config = @pbr.CascadeShadowConfigBuilder::default()
    .with_first_cascade_far_bound(0.3F)
    .with_maximum_distance(15.0F)
    .build()

  let sun = world.spawn_empty()
  try! world.set_by_key(
    sun,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 0.4F, 0.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    sun,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(
      @sprite.Color::new(0.98F, 0.95F, 0.82F, 1.0F),
      130_000.0F,
      true,
    ).with_cascade_shadow_config(Some(cascade_shadow_config)),
  )
  atmosphere_state.val.sun = Some(sun)
  try! world.set_by_key(
    sun,
    @pbr.ecs_key_volumetric_light,
    @pbr.VolumetricLight::default(),
  )

  let terrain = world.spawn_empty()
  try! world.set_by_key(
    terrain,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset("models/terrain/terrain.glb"),
      ),
    ),
  )
  try! world.set_by_key(
    terrain,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-1.0F, 0.0F, -0.5F)
    .with_scale(@math.Vec3::splat(0.5F))
    .with_rotation(@math.Quat::from_rotation_y(PI / 2.0F)),
  )

  let probe_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_sphere(1.0F)),
    ),
  )
  let probe_metal = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_metallic(1.0F)
    .with_perceptual_roughness(0.0F),
  )
  spawn_mesh(
    world,
    probe_mesh,
    probe_metal,
    @transform.Transform::from_xyz(-1.0F, 0.1F, -0.1F).with_scale(
      @math.Vec3::splat(0.05F),
    ),
  )

  let probe_rough = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_metallic(0.0F)
    .with_perceptual_roughness(1.0F),
  )
  spawn_mesh(
    world,
    probe_mesh,
    probe_rough,
    @transform.Transform::from_xyz(-1.0F, 0.1F, 0.1F).with_scale(
      @math.Vec3::splat(0.05F),
    ),
  )

  let fog_volume_entity = world.spawn_empty()
  atmosphere_state.val.fog_volume_entity = Some(fog_volume_entity)
  try! world.set_by_key(
    fog_volume_entity,
    @pbr.ecs_key_fog_volume,
    atmosphere_state.val.fog_volume,
  )
  try! world.set_by_key(
    fog_volume_entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F).with_scale(
      @math.Vec3::new(10.0F, 1.0F, 10.0F),
    ),
  )

  let water_normals = asset_server.load_with_settings(
    "textures/water_normals.png",
    fn(settings) {
      settings.is_srgb = false
      settings.sampler = @asset.ImageSampler::Descriptor(
        @asset.ImageSamplerDescriptor::linear().set_address_mode(
          @asset.ImageAddressMode::Repeat,
        ),
      )
    },
  )
  let water_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    )
    .with_perceptual_roughness(0.0F)
    .with_normal_map_texture(Some(water_normals))
    .with_uv_transform(
      @transform.Affine2::from_scale(@math.Vec2::new(500.0F, 500.0F)),
    ),
  )
  atmosphere_state.val.water_material = Some(water_material)
  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(100.0F, 100.0F)),
      ),
    ),
    water_material,
    @transform.Transform::identity(),
  )
}

///|
fn setup_instructions(_world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(atmosphere_instruction_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
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
  atmosphere_state.val.help_text = Some(handle)
}

///|
fn atmosphere_controls(world : @ecs.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    atmosphere_state.val.mode = 0
    atmosphere_state.val.atmosphere_settings = atmosphere_state.val.atmosphere_settings.with_rendering_method(
      @pbr.AtmosphereMode::LookupTexture,
    )
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    atmosphere_state.val.mode = 1
    atmosphere_state.val.atmosphere_settings = atmosphere_state.val.atmosphere_settings.with_rendering_method(
      @pbr.AtmosphereMode::Raymarched,
    )
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Enter) {
    atmosphere_state.val.paused = !atmosphere_state.val.paused
    changed = true
  }

  let delta = world_time(world).delta_seconds()
  let mut exposure_changed = false
  let exposure_delta = if @input.key_pressed(@window.KeyCode::ArrowUp) {
    -delta * 2.0F
  } else if @input.key_pressed(@window.KeyCode::ArrowDown) {
    delta * 2.0F
  } else {
    0.0F
  }
  if exposure_delta != 0.0F {
    if atmosphere_state.val.camera is Some(camera_entity) {
      if (try! world.get_by_key(camera_entity, @pbr.ecs_key_exposure))
        is Some(exposure) {
        let next = clampf(exposure.ev100 + exposure_delta, 6.0F, 20.0F)
        if next != exposure.ev100 {
          try! (world.replace(
            camera_entity,
            @pbr.ecs_key_exposure,
            exposure.with_ev100(next),
          )
          |> ignore)
          atmosphere_state.val.exposure_ev100 = next
          exposure_changed = true
        }
      }
    } else {
      atmosphere_state.val.exposure_ev100 = clampf(
        atmosphere_state.val.exposure_ev100 + exposure_delta,
        6.0F,
        20.0F,
      )
      exposure_changed = true
    }
  }
  changed = changed || exposure_changed

  if changed {
    if atmosphere_state.val.help_text is Some(handle) {
      @text.text_set_content(handle, atmosphere_instruction_text())
    }
    apply_atmosphere(world)
  }
}

///|
fn dynamic_scene(world : @ecs.World) -> Unit {
  if !atmosphere_state.val.paused {
    atmosphere_state.val.sun_pitch = atmosphere_state.val.sun_pitch -
      world_time(world).delta_seconds() * SUN_ROTATION_SPEED
  }

  if atmosphere_state.val.sun is Some(sun_entity) {
    let sun_pos = @math.Vec3::new(
      1.0F,
      0.4F * @math.cos(atmosphere_state.val.sun_pitch),
      0.4F * @math.sin(atmosphere_state.val.sun_pitch),
    )
    try! (world.replace(
      sun_entity,
      @transform.ecs_key_transform,
      @transform.Transform::from_xyz(sun_pos.x, sun_pos.y, sun_pos.z).looking_at(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    |> ignore)
  }

  if atmosphere_state.val.water_material is Some(material_handle) {
    if @pbr.standard_material_get(material_handle) is Some(material) {
      let t = world_time(world).elapsed_seconds()
      let offset = @math.Vec2::new(t * 0.012F, -t * 0.009F)
      let updated = material.with_uv_transform(
        @transform.Affine2::from_translation(offset).mul(
          @transform.Affine2::from_scale(@math.Vec2::new(500.0F, 500.0F)),
        ),
      )
      @pbr.standard_material_set(material_handle, updated) |> ignore
    }
  }

  apply_atmosphere(world)
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_default_opaque_renderer_method,
    @pbr.DefaultOpaqueRendererMethod::deferred(),
  )

  atmosphere_state.val = {
    paused: false,
    mode: 0,
    exposure_ev100: BASE_EXPOSURE_EV100,
    sun_pitch: 0.0F,
    atmosphere: @pbr.Atmosphere::earthlike(
      @pbr.ScatteringMedium::earthlike().with_density_multiplier(1.0F),
    ),
    atmosphere_settings: @pbr.AtmosphereSettings::default()
    .with_scene_units_to_m(1.0F)
    .with_rendering_method(@pbr.AtmosphereMode::LookupTexture),
    volumetric_fog: @pbr.VolumetricFog::default().with_ambient_intensity(0.0F),
    fog_volume: @pbr.FogVolume::default()
    .with_density_factor(0.1F)
    .with_scattering(0.3F)
    .with_absorption(0.3F),
    camera: None,
    sun: None,
    fog_volume_entity: None,
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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(atmosphere_controls))
  .add_systems(@app.Update, @app.system(dynamic_scene))
  .run()
}
