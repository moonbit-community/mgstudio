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
///
/// Baseline parity: control flow and material field updates follow the upstream
/// transmission example. Runtime resolve quality is tracked separately in the
/// parity matrix.

///|
const PI : Float = 3.141592653589793F

///|
const E : Float = 2.718281828459045F

///|
const AUTO_CAMERA_SPEED : Float = 0.25F

///|
const CAMERA_INITIAL_X : Float = 1.0F

///|
const CAMERA_INITIAL_Y : Float = 1.8F

///|
const CAMERA_INITIAL_Z : Float = 7.0F

///|
struct Flicker {}

///|
let flicker_key : @ecs.ComponentKey[Flicker] = @ecs.register_component(
  debug_name="examples.3d.transmission.Flicker",
)

///|
pub impl @ecs.Component for Flicker with fn component() {
  flicker_key
}

///|
struct ExampleControls {
  diffuse_transmission : Bool
  specular_transmission : Bool
  color : Bool
}

///|
let example_controls_key : @ecs.ComponentKey[ExampleControls] = @ecs.register_component(
  debug_name="examples.3d.transmission.ExampleControls",
)

///|
pub impl @ecs.Component for ExampleControls with fn component() {
  example_controls_key
}

///|
struct ExampleDisplay {}

///|
let example_display_key : @ecs.ComponentKey[ExampleDisplay] = @ecs.register_component(
  debug_name="examples.3d.transmission.ExampleDisplay",
)

///|
pub impl @ecs.Component for ExampleDisplay with fn component() {
  example_display_key
}

///|
fn ExampleControls::ExampleControls(
  diffuse_transmission~ : Bool,
  specular_transmission~ : Bool,
  color~ : Bool,
) -> ExampleControls {
  { diffuse_transmission, specular_transmission, color }
}

///|
priv struct ExampleState {
  mut diffuse_transmission : Float
  mut specular_transmission : Float
  mut thickness : Float
  mut ior : Float
  mut perceptual_roughness : Float
  mut reflectance : Float
  mut auto_camera : Bool
}

///|
fn ExampleState::ExampleState() -> ExampleState {
  {
    diffuse_transmission: 0.5F,
    specular_transmission: 0.9F,
    thickness: 1.8F,
    ior: 1.5F,
    perceptual_roughness: 0.12F,
    reflectance: 0.5F,
    auto_camera: true,
  }
}

///|
impl @app.FromWorld for ExampleState with fn from_world(_world) {
  ExampleState()
}

///|
priv struct ExampleRandom {
  rng : @random.Rand
}

///|
fn ExampleRandom::ExampleRandom() -> ExampleRandom {
  { rng: @random.Rand::new() }
}

///|
impl @app.FromWorld for ExampleRandom with fn from_world(_world) {
  ExampleRandom()
}

///|
fn ExampleRandom::random_unit(self : ExampleRandom) -> Float {
  self.rng.float()
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
fn clamp01(value : Float) -> Float {
  clampf(value, 0.0F, 1.0F)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn expf(value : Float) -> Float {
  @math.pow(E, value)
}

///|
fn quality_label(quality : @pbr.ScreenSpaceTransmissionQuality) -> String {
  match quality {
    Low => "Low"
    Medium => "Medium"
    High => "High"
    Ultra => "Ultra"
  }
}

///|
fn transmission_hud_text_with_camera(
  transmission : @pbr.ScreenSpaceTransmission,
  state : ExampleState,
  hdr_enabled : Bool,
  depth_prepass_enabled : Bool,
  taa_enabled : Bool,
) -> String {
  let hdr_text = if hdr_enabled { "ON " } else { "OFF" }
  let depth_text = if depth_prepass_enabled { "ON " } else { "OFF" }
  let taa_text = if taa_enabled {
    if depth_prepass_enabled {
      "ON "
    } else {
      "N/A (Needs Depth Prepass)"
    }
  } else {
    "OFF"
  }

  " J / K / L / ;  Screen Space Specular Transmissive Quality: \{quality_label(transmission.quality)}\n         O / P  Screen Space Specular Transmissive Steps: \{transmission.steps}\n         1 / 2  Diffuse Transmission: \{state.diffuse_transmission}\n         Q / W  Specular Transmission: \{state.specular_transmission}\n         A / S  Thickness: \{state.thickness}\n         Z / X  IOR: \{state.ior}\n         E / R  Perceptual Roughness: \{state.perceptual_roughness}\n         U / I  Reflectance: \{state.reflectance}\n    Arrow Keys  Control Camera\n             C  Randomize Colors\n             H  HDR + Bloom: \{hdr_text}\n             D  Depth Prepass: \{depth_text}\n             T  TAA: \{taa_text}\n"
}

///|
fn spawn_controlled_mesh(
  commands : @app.Commands,
  mesh : @mesh.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
  controls : ExampleControls,
) -> Unit {
  ignore(
    commands.spawn(
      (mesh, @pbr.MeshMaterial3dTyped::new(material), transform, controls),
    ),
  )
}

///|
fn setup_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cube_mesh = @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets |> @pbr.add_mesh(@math.Cuboid::new(0.7F, 0.7F, 0.7F))
    }),
  )
  let sphere_geometry = @mesh_primitives_dim3.SphereMeshBuilder::new(
    0.9F,
    @mesh_primitives_dim3.SphereKind::ico(7),
  ).ico(7) catch {
    _ => abort("transmission icosphere subdivisions should be valid")
  }
  let sphere_mesh = @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets.add(@mesh.Mesh::from_3d_geometry(sphere_geometry))
    }),
  )
  let plane_mesh = @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets
      |> @pbr.add_mesh(
        @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
          @math.Vec2::new(2.0F, 2.0F),
        ).build(),
      )
    }),
  )
  let candle_geometry = @mesh_primitives_dim3.CylinderMeshBuilder::from_cylinder(
      @math.Cylinder::new(0.5F, 2.0F),
    )
    .resolution(50)
    .build()
  let candle_mesh = @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets.add(@mesh.Mesh::from_3d_geometry(candle_geometry))
    }),
  )

  let cube_1_material = materials.modify(fn(assets) {
    assets |> @pbr.add_material(@pbr.StandardMaterial::StandardMaterial())
  })
  spawn_controlled_mesh(
    commands,
    cube_mesh,
    cube_1_material,
    @transform.Transform::from_xyz(0.25F, 0.5F, -2.0F).with_rotation(
      @math.Quat::from_rotation_x(1.4F)
      .mul(@math.Quat::from_rotation_y(3.7F))
      .mul(@math.Quat::from_rotation_z(21.3F))
      .normalize(),
    ),
    ExampleControls(
      color=true,
      specular_transmission=false,
      diffuse_transmission=false,
    ),
  )

  let cube_2_material = materials.modify(fn(assets) {
    assets |> @pbr.add_material(@pbr.StandardMaterial::StandardMaterial())
  })
  spawn_controlled_mesh(
    commands,
    cube_mesh,
    cube_2_material,
    @transform.Transform::from_xyz(-0.75F, 0.7F, -2.0F).with_rotation(
      @math.Quat::from_rotation_x(0.4F)
      .mul(@math.Quat::from_rotation_y(2.3F))
      .mul(@math.Quat::from_rotation_z(4.7F))
      .normalize(),
    ),
    ExampleControls(
      color=true,
      specular_transmission=false,
      diffuse_transmission=false,
    ),
  )

  let candle_material = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(0.9F, 0.2F, 0.3F, 1.0F),
      )
      .with_diffuse_transmission(0.7F)
      .with_perceptual_roughness(0.32F)
      .with_thickness(0.2F),
    )
  })
  spawn_controlled_mesh(
    commands,
    candle_mesh,
    candle_material,
    @transform.Transform::from_xyz(-1.0F, 0.0F, 0.0F),
    ExampleControls(
      color=true,
      specular_transmission=false,
      diffuse_transmission=true,
    ),
  )

  let flame_material = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      )
      .with_emissive(@color.Color::new(23.6F, 19.48F, 16.8F, 1.0F))
      .with_diffuse_transmission(1.0F),
    )
  })
  ignore(
    commands.spawn(
      (
        sphere_mesh,
        @pbr.MeshMaterial3dTyped::new(flame_material),
        @transform.Transform::from_xyz(-1.0F, 1.15F, 0.0F).with_scale(
          @math.Vec3::new(0.1F, 0.2F, 0.1F),
        ),
        Flicker::{  },
        @pbr.NotShadowCaster::NotShadowCaster(),
      ),
    ),
  )

  let white_glass = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
      )
      .with_specular_transmission(0.9F)
      .with_diffuse_transmission(1.0F)
      .with_thickness(1.8F)
      .with_ior(1.5F)
      .with_perceptual_roughness(0.12F),
    )
  })
  spawn_controlled_mesh(
    commands,
    sphere_mesh,
    white_glass,
    @transform.Transform::from_xyz(1.0F, 0.0F, 0.0F),
    ExampleControls(
      color=true,
      specular_transmission=true,
      diffuse_transmission=false,
    ),
  )

  let red_glass = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
      )
      .with_specular_transmission(0.9F)
      .with_diffuse_transmission(1.0F)
      .with_thickness(1.8F)
      .with_ior(1.5F)
      .with_perceptual_roughness(0.12F),
    )
  })
  spawn_controlled_mesh(
    commands,
    sphere_mesh,
    red_glass,
    @transform.Transform::from_xyz(1.0F, -0.5F, 2.0F).with_scale(
      @math.Vec3::splat(0.5F),
    ),
    ExampleControls(
      color=true,
      specular_transmission=true,
      diffuse_transmission=false,
    ),
  )

  let green_glass = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
      )
      .with_specular_transmission(0.9F)
      .with_diffuse_transmission(1.0F)
      .with_thickness(1.8F)
      .with_ior(1.5F)
      .with_perceptual_roughness(0.12F),
    )
  })
  spawn_controlled_mesh(
    commands,
    sphere_mesh,
    green_glass,
    @transform.Transform::from_xyz(0.0F, -0.5F, 2.0F).with_scale(
      @math.Vec3::splat(0.5F),
    ),
    ExampleControls(
      color=true,
      specular_transmission=true,
      diffuse_transmission=false,
    ),
  )

  let blue_glass = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @color.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
      )
      .with_specular_transmission(0.9F)
      .with_diffuse_transmission(1.0F)
      .with_thickness(1.8F)
      .with_ior(1.5F)
      .with_perceptual_roughness(0.12F),
    )
  })
  spawn_controlled_mesh(
    commands,
    sphere_mesh,
    blue_glass,
    @transform.Transform::from_xyz(-1.0F, -0.5F, 2.0F).with_scale(
      @math.Vec3::splat(0.5F),
    ),
    ExampleControls(
      color=true,
      specular_transmission=true,
      diffuse_transmission=false,
    ),
  )

  let black_tile = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(@color.Color::black())
      .with_reflectance(0.3F)
      .with_perceptual_roughness(0.8F),
    )
  })
  let white_tile = materials.modify(fn(assets) {
    assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(@color.Color::white())
      .with_reflectance(0.3F)
      .with_perceptual_roughness(0.8F),
    )
  })
  for x in -3..<4 {
    for z in -3..<4 {
      let use_black = (x + z) % 2 == 0
      spawn_controlled_mesh(
        commands,
        plane_mesh,
        if use_black {
          black_tile
        } else {
          white_tile
        },
        @transform.Transform::from_xyz(
          float_from_int(x) * 2.0F,
          -1.0F,
          float_from_int(z) * 2.0F,
        ),
        ExampleControls(
          color=true,
          specular_transmission=false,
          diffuse_transmission=false,
        ),
      )
    }
  }

  let paper_material_base = @pbr.StandardMaterial::from_color(
      @color.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_diffuse_transmission(0.6F)
    .with_perceptual_roughness(0.8F)
    .with_reflectance(1.0F)
    .with_double_sided(true)
    .with_cull_mode(None)
  let paper_material = materials.modify(fn(assets) {
    assets |> @pbr.add_material(paper_material_base)
  })
  ignore(
    commands.spawn(
      (
        plane_mesh,
        @pbr.MeshMaterial3dTyped::new(paper_material),
        @transform.Transform::from_xyz(0.0F, 0.5F, -3.0F)
        .with_scale(@math.Vec3::new(2.0F, 1.0F, 1.0F))
        .with_rotation(@math.Quat::from_rotation_x(PI / 2.0F)),
        @pbr.TransmittedShadowReceiver::TransmittedShadowReceiver(),
        ExampleControls::ExampleControls(
          color=false,
          specular_transmission=false,
          diffuse_transmission=true,
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(-1.0F, 1.7F, 0.0F),
        @pbr.PointLight::new(
          @color.Color::new(0.987F, 0.792F, 0.674F, 1.0F),
          4_000.0F,
          5.0F,
          true,
        ).with_radius(0.2F),
        Flicker::{  },
      ),
    ),
  )
}

///|
fn setup_camera(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let color_grading = @post_process.ColorGrading::ColorGrading()
  color_grading.global.post_saturation = 1.2F
  let camera = commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @transform.Transform::from_xyz(
        CAMERA_INITIAL_X,
        CAMERA_INITIAL_Y,
        CAMERA_INITIAL_Z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
      color_grading,
      @post_process.Tonemapping::TonyMcMapface,
      @pbr.Exposure::new(6.0F),
      @pbr.Msaa::Off,
      @post_process.TemporalJitter::TemporalJitter(),
      @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
    ),
  )
  commands.entity(camera).insert_component(@pbr.Hdr::Hdr())
  commands.entity(camera).insert_component(@post_process.Bloom::Bloom())
  commands
  .entity(camera)
  .insert_component(
    @pbr.EnvironmentMapLight::new(
      Some(
        asset_server
        .get()
        .load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
      ),
      Some(
        asset_server
        .get()
        .load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      ),
      25.0F,
    ),
  )
}

///|
fn setup_text(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::Text(),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_top(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
        ExampleDisplay::{  },
      ),
    ),
  )
}

///|
fn apply_material_controls_to_assets(
  assets : @asset.Assets[@pbr.StandardMaterial],
  controllable : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[ExampleControls]),
    @ecs.All,
  ],
  state : ExampleState,
  color_random : ExampleRandom,
  randomize_colors : Bool,
) -> Unit {
  try! controllable.view(fn(_entity, data) {
    let (mesh_material, controls) = data
    guard assets.get(mesh_material.value().material) is Some(material) else {
      return
    }
    let controls = controls.value()
    let mut updated = material
    if controls.specular_transmission {
      updated = updated
        .with_specular_transmission(state.specular_transmission)
        .with_thickness(state.thickness)
        .with_ior(state.ior)
        .with_perceptual_roughness(state.perceptual_roughness)
        .with_reflectance(state.reflectance)
    }
    if controls.diffuse_transmission {
      updated = updated.with_diffuse_transmission(state.diffuse_transmission)
    }
    if controls.color && randomize_colors {
      updated = updated.with_base_color(
        @color.Color::new(
          color_random.random_unit(),
          color_random.random_unit(),
          color_random.random_unit(),
          updated.base_color.a,
        ),
      )
    }
    ignore(assets.insert(mesh_material.value().material, updated))
  })
}

///|
fn apply_material_controls(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  controllable : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[ExampleControls]),
    @ecs.All,
  ],
  state : ExampleState,
  color_random : ExampleRandom,
  randomize_colors : Bool,
) -> Unit {
  materials.modify(fn(assets) {
    apply_material_controls_to_assets(
      assets, controllable, state, color_random, randomize_colors,
    )
  })
}

///|
fn example_control_system(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  controllable : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[ExampleControls]),
    @ecs.All,
  ],
  camera : @ecs.Query[
    (
      @core.Entity,
      @ecs.Write[@pbr.ScreenSpaceTransmission],
      @ecs.Write[@transform.Transform],
      @ecs.Optional[@pbr.DepthPrepass],
      @ecs.Optional[@post_process.TemporalJitter],
      @ecs.Has[@pbr.Hdr],
    ),
    @ecs.With[@pbr.Camera3d],
  ],
  display : @ecs.Query[@ecs.Write[@text.Text], @ecs.With[ExampleDisplay]],
  state_param : @app.Local[ExampleState],
  color_random_param : @app.Local[ExampleRandom],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_seconds()
  let state = state_param.get()
  let color_random = color_random_param.get()
  let mut materials_changed = false
  let mut randomize_colors = false
  guard (camera.single() catch { _ => None }) is Some(camera_data) else {
    return
  }
  let (
    camera_entity,
    transmission,
    camera_transform,
    depth_prepass,
    temporal_jitter,
    hdr,
  ) = camera_data
  let hdr_enabled = hdr.present()
  let depth_prepass_enabled = depth_prepass.value() is Some(_)
  let taa_enabled = temporal_jitter.value() is Some(_)
  let mut transmission_settings = transmission.value()
  let mut transmission_settings_changed = false
  let toggle_hdr = @input.key_just_pressed(KeyH)
  let toggle_depth_prepass = @input.key_just_pressed(KeyD)
  let toggle_taa = @input.key_just_pressed(KeyT)

  if @input.key_pressed(Digit2) {
    state.diffuse_transmission = clamp01(state.diffuse_transmission + delta)
    materials_changed = true
  } else if @input.key_pressed(Digit1) {
    state.diffuse_transmission = clamp01(state.diffuse_transmission - delta)
    materials_changed = true
  }

  if @input.key_pressed(KeyW) {
    state.specular_transmission = clamp01(state.specular_transmission + delta)
    materials_changed = true
  } else if @input.key_pressed(KeyQ) {
    state.specular_transmission = clamp01(state.specular_transmission - delta)
    materials_changed = true
  }

  if @input.key_pressed(KeyS) {
    state.thickness = clampf(state.thickness + delta, 0.0F, 5.0F)
    materials_changed = true
  } else if @input.key_pressed(KeyA) {
    state.thickness = clampf(state.thickness - delta, 0.0F, 5.0F)
    materials_changed = true
  }

  if @input.key_pressed(KeyX) {
    state.ior = clampf(state.ior + delta, 1.0F, 3.0F)
    materials_changed = true
  } else if @input.key_pressed(KeyZ) {
    state.ior = clampf(state.ior - delta, 1.0F, 3.0F)
    materials_changed = true
  }

  if @input.key_pressed(KeyI) {
    state.reflectance = clamp01(state.reflectance + delta)
    materials_changed = true
  } else if @input.key_pressed(KeyU) {
    state.reflectance = clamp01(state.reflectance - delta)
    materials_changed = true
  }

  if @input.key_pressed(KeyR) {
    state.perceptual_roughness = clamp01(state.perceptual_roughness + delta)
    materials_changed = true
  } else if @input.key_pressed(KeyE) {
    state.perceptual_roughness = clamp01(state.perceptual_roughness - delta)
    materials_changed = true
  }

  if @input.key_just_pressed(KeyO) && transmission_settings.steps > 0 {
    transmission_settings = transmission_settings.with_steps(
      transmission_settings.steps - 1,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(KeyP) && transmission_settings.steps < 4 {
    transmission_settings = transmission_settings.with_steps(
      transmission_settings.steps + 1,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(KeyJ) {
    transmission_settings = transmission_settings.with_quality(Low)
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(KeyK) {
    transmission_settings = transmission_settings.with_quality(Medium)
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(KeyL) {
    transmission_settings = transmission_settings.with_quality(High)
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(Semicolon) {
    transmission_settings = transmission_settings.with_quality(Ultra)
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(KeyC) {
    randomize_colors = true
    materials_changed = true
  }

  if toggle_hdr {
    if hdr_enabled {
      commands.entity(camera_entity).remove(@pbr.ecs_key_hdr)
    } else {
      commands.entity(camera_entity).insert_component(@pbr.Hdr::Hdr())
    }
  }

  if toggle_depth_prepass {
    if depth_prepass_enabled {
      commands.entity(camera_entity).remove(@pbr.ecs_key_depth_prepass)
    } else {
      commands
      .entity(camera_entity)
      .insert_component(@pbr.DepthPrepass::DepthPrepass())
    }
  }

  if toggle_taa {
    if taa_enabled {
      commands
      .entity(camera_entity)
      .remove(@post_process.ecs_key_temporal_jitter)
      commands
      .entity(camera_entity)
      .remove(@post_process.ecs_key_temporal_anti_aliasing)
    } else {
      commands
      .entity(camera_entity)
      .insert_component(@post_process.TemporalJitter::TemporalJitter())
      commands
      .entity(camera_entity)
      .insert_component(
        @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
      )
    }
  }

  let rotation = if @input.key_pressed(ArrowRight) {
    state.auto_camera = false
    delta
  } else if @input.key_pressed(ArrowLeft) {
    state.auto_camera = false
    -delta
  } else if state.auto_camera {
    delta * AUTO_CAMERA_SPEED
  } else {
    0.0F
  }

  let camera_distance = camera_transform.value().translation.length()
  let distance_change = if @input.key_pressed(ArrowDown) &&
    camera_distance < 25.0F {
    delta
  } else if @input.key_pressed(ArrowUp) && camera_distance > 2.0F {
    -delta
  } else {
    0.0F
  }

  let mut camera_changed = false
  if distance_change != 0.0F || rotation != 0.0F {
    camera_changed = true
  }

  if camera_changed {
    camera_transform.modify(fn(value) {
      value.translation = value.translation.mul_scalar(expf(distance_change))
      value.rotate_around(
        @math.Vec3::zero(),
        @math.Quat::from_rotation_y(rotation),
      )
    })
  }

  if materials_changed {
    apply_material_controls(
      materials, controllable, state, color_random, randomize_colors,
    )
  }

  if transmission_settings_changed {
    transmission.set(transmission_settings)
  }

  guard (display.single() catch { _ => None }) is Some(display_text) else {
    state_param.set(state)
    color_random_param.set(color_random)
    return
  }
  display_text.set(
    @text.Text::new(
      transmission_hud_text_with_camera(
        transmission_settings,
        state,
        if toggle_hdr {
          !hdr_enabled
        } else {
          hdr_enabled
        },
        if toggle_depth_prepass {
          !depth_prepass_enabled
        } else {
          depth_prepass_enabled
        },
        if toggle_taa {
          !taa_enabled
        } else {
          taa_enabled
        },
      ),
    ),
  )
  state_param.set(state)
  color_random_param.set(color_random)
}

///|
fn flicker_system(
  flame : @ecs.Query[
    @ecs.Write[@transform.Transform],
    (@ecs.With[Flicker], @ecs.With[@mesh.Mesh3d]),
  ],
  light : @ecs.Query[
    (@ecs.Write[@pbr.PointLight], @ecs.Write[@transform.Transform]),
    (@ecs.With[Flicker], @ecs.Without[@mesh.Mesh3d]),
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let s = time.get().elapsed_seconds()
  let a = @math.cos(s * 6.0F) * 0.0125F + @math.cos(s * 4.0F) * 0.025F
  let b = @math.cos(s * 5.0F) * 0.0125F + @math.cos(s * 3.0F) * 0.025F
  let c = @math.cos(s * 7.0F) * 0.0125F + @math.cos(s * 2.0F) * 0.025F

  guard (light.single() catch { _ => None }) is Some(light_data) else { return }
  let (point_light, light_transform) = light_data
  point_light.set(
    point_light.value().with_intensity(4_000.0F + 3_000.0F * (a + b + c)),
  )
  light_transform.modify(fn(value) {
    value.translation = @math.Vec3::new(-1.0F - c, 1.7F, -a)
  })

  guard (flame.single() catch { _ => None }) is Some(flame_transform) else {
    return
  }
  let base_transform = @transform.Transform::from_xyz(-1.0F - c, 1.23F, -a).looking_at(
    @math.Vec3::new(-1.0F - c, 1.7F - b, -a),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  flame_transform.set(
    base_transform
    .with_rotation(
      base_transform.rotation
      .mul(@math.Quat::from_rotation_z(PI / 2.0F))
      .normalize(),
    )
    .with_scale(@math.Vec3::new(0.1F, 0.2F, 0.1F)),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  setup_scene(commands, meshes, materials)
  setup_camera(commands, asset_server)
  setup_text(commands)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(@camera.ClearColor::new(@color.Color::black()))
  .insert_resource(@pbr.PointLightShadowMap::new(2048))
  .insert_resource(@pbr.GlobalAmbientLight::new(@color.Color::white(), 0.0F))
  .add_systems_param4(Startup, setup)
  .add_systems_param8(Update, example_control_system)
  .add_systems_param3(Update, flicker_system)
  .run()
}
