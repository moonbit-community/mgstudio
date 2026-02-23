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
/// Port of `bevy/examples/3d/transmission.rs`.
///
/// Baseline parity: control flow and material field updates follow Bevy's
/// transmission example. Runtime resolve quality is tracked separately in the
/// parity matrix.

///|
const PI : Float = 3.141592653589793F

///|
const LCG_MOD : Int = 2147483647

///|
const CAMERA_HEIGHT : Float = 1.8F

///|
const CAMERA_MIN_RADIUS : Float = 2.0F

///|
const CAMERA_MAX_RADIUS : Float = 25.0F

///|
const CAMERA_ROTATE_SPEED : Float = 1.0F

///|
const CAMERA_ZOOM_SPEED : Float = 4.0F

///|
const AUTO_CAMERA_SPEED : Float = 0.25F

///|
priv struct TransmissionState {
  mut diffuse_transmission : Float
  mut specular_transmission : Float
  mut thickness : Float
  mut ior : Float
  mut perceptual_roughness : Float
  mut reflectance : Float
  mut auto_camera : Bool
  mut camera_angle : Float
  mut camera_radius : Float
  mut camera : @core.Entity?
  mut flame_mesh : @core.Entity?
  mut flame_light : @core.Entity?
  mut display_text : @text.TextHandle?
  specular_materials : Array[@asset.Handle[@render3d.StandardMaterial]]
  diffuse_materials : Array[@asset.Handle[@render3d.StandardMaterial]]
  color_materials : Array[@asset.Handle[@render3d.StandardMaterial]]
  mut random_seed : Int
}

///|
let transmission_state : Ref[TransmissionState] = Ref::new({
  diffuse_transmission: 0.5F,
  specular_transmission: 0.9F,
  thickness: 1.8F,
  ior: 1.5F,
  perceptual_roughness: 0.12F,
  reflectance: 0.5F,
  auto_camera: true,
  camera_angle: 0.1418970546F,
  camera_radius: 7.0710678119F,
  camera: None,
  flame_mesh: None,
  flame_light: None,
  display_text: None,
  specular_materials: [],
  diffuse_materials: [],
  color_materials: [],
  random_seed: 1367130551,
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
fn lcg_next(seed : Int) -> Int {
  let mut next = (seed * 1103515245 + 12345) % LCG_MOD
  if next < 0 {
    next = next + LCG_MOD
  }
  next
}

///|
fn next_random_unit() -> Float {
  transmission_state.val.random_seed = lcg_next(
    transmission_state.val.random_seed,
  )
  float_from_int(transmission_state.val.random_seed) / float_from_int(LCG_MOD)
}

///|
fn quality_label(quality : @render3d.ScreenSpaceTransmissionQuality) -> String {
  match quality {
    Low => "Low"
    Medium => "Medium"
    High => "High"
    Ultra => "Ultra"
  }
}

///|
fn camera_screen_space_transmission(
  world : @ecs_world.World,
) -> @render3d.ScreenSpaceTransmission {
  if transmission_state.val.camera is Some(camera_entity) {
    match world.get_screen_space_transmission_store().get(camera_entity) {
      Some(value) => value
      None => @render3d.ScreenSpaceTransmission::default()
    }
  } else {
    @render3d.ScreenSpaceTransmission::default()
  }
}

///|
fn camera_set_screen_space_transmission(
  world : @ecs_world.World,
  value : @render3d.ScreenSpaceTransmission,
) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let store = world.get_screen_space_transmission_store()
    if store.contains(camera_entity) {
      store.set(camera_entity, value, tick) |> ignore
    } else {
      store.insert(camera_entity, value, tick)
    }
  }
}

///|
fn camera_hdr_enabled(world : @ecs_world.World) -> Bool {
  if transmission_state.val.camera is Some(camera_entity) {
    world.get_hdr_store().contains(camera_entity)
  } else {
    false
  }
}

///|
fn camera_depth_prepass_enabled(world : @ecs_world.World) -> Bool {
  if transmission_state.val.camera is Some(camera_entity) {
    world.get_depth_prepass_store().contains(camera_entity)
  } else {
    false
  }
}

///|
fn camera_taa_enabled(world : @ecs_world.World) -> Bool {
  if transmission_state.val.camera is Some(camera_entity) {
    world.get_temporal_jitter_store().contains(camera_entity)
  } else {
    false
  }
}

///|
fn camera_toggle_hdr(world : @ecs_world.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let store = world.get_hdr_store()
    if store.contains(camera_entity) {
      store.remove(camera_entity) |> ignore
    } else {
      store.insert(camera_entity, @render3d.Hdr::default(), tick)
    }
  }
}

///|
fn camera_toggle_depth_prepass(world : @ecs_world.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let store = world.get_depth_prepass_store()
    if store.contains(camera_entity) {
      store.remove(camera_entity) |> ignore
    } else {
      store.insert(camera_entity, @render3d.DepthPrepass::default(), tick)
    }
  }
}

///|
fn camera_toggle_taa(world : @ecs_world.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let jitter_store = world.get_temporal_jitter_store()
    let taa_store = world.get_temporal_anti_aliasing_store()
    if jitter_store.contains(camera_entity) {
      jitter_store.remove(camera_entity) |> ignore
      taa_store.remove(camera_entity) |> ignore
    } else {
      jitter_store.insert(
        camera_entity,
        @render3d.TemporalJitter::default(),
        tick,
      )
      taa_store.insert(
        camera_entity,
        @render3d.TemporalAntiAliasing::default(),
        tick,
      )
    }
  }
}

///|
fn transmission_hud_text(world : @ecs_world.World) -> String {
  let transmission = camera_screen_space_transmission(world)
  let hdr_text = if camera_hdr_enabled(world) { "ON " } else { "OFF" }
  let depth_text = if camera_depth_prepass_enabled(world) {
    "ON "
  } else {
    "OFF"
  }
  let taa_text = if camera_taa_enabled(world) {
    if camera_depth_prepass_enabled(world) {
      "ON "
    } else {
      "N/A (Needs Depth Prepass)"
    }
  } else {
    "OFF"
  }

  " J / K / L / ;  Screen Space Specular Transmissive Quality: \{quality_label(transmission.quality)}\n" +
  "         O / P  Screen Space Specular Transmissive Steps: \{transmission.steps}\n" +
  "         1 / 2  Diffuse Transmission: \{transmission_state.val.diffuse_transmission}\n" +
  "         Q / W  Specular Transmission: \{transmission_state.val.specular_transmission}\n" +
  "         A / S  Thickness: \{transmission_state.val.thickness}\n" +
  "         Z / X  IOR: \{transmission_state.val.ior}\n" +
  "         E / R  Perceptual Roughness: \{transmission_state.val.perceptual_roughness}\n" +
  "         U / I  Reflectance: \{transmission_state.val.reflectance}\n" +
  "    Arrow Keys  Control Camera\n" +
  "             C  Randomize Colors\n" +
  "             H  HDR + Bloom: \{hdr_text}\n" +
  "             D  Depth Prepass: \{depth_text}\n" +
  "             T  TAA: \{taa_text}\n"
}

///|
fn register_material(
  material : @asset.Handle[@render3d.StandardMaterial],
  color : Bool,
  specular : Bool,
  diffuse : Bool,
) -> Unit {
  if color {
    transmission_state.val.color_materials.push(material)
  }
  if specular {
    transmission_state.val.specular_materials.push(material)
  }
  if diffuse {
    transmission_state.val.diffuse_materials.push(material)
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
fn setup_scene(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  let cube_mesh = @render3d.Mesh3d::from_cuboid(0.7F, 0.7F, 0.7F)
  let sphere_mesh = uv_sphere_mesh(0.9F, 24, 40)
  let plane_mesh = @render3d.Mesh3d::from_plane(2.0F, 2.0F)

  let cube_1_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.7F, 0.7F, 0.78F, 1.0F),
    )
    .with_perceptual_roughness(0.45F)
    .with_reflectance(0.3F),
  )
  register_material(cube_1_material, true, false, false)
  spawn_mesh(
    world,
    cube_mesh,
    cube_1_material,
    @math.Transform::from_xyz(0.25F, 0.5F, -2.0F).with_rotation(
      @math.Quat::from_rotation_x(1.4F)
      .mul(@math.Quat::from_rotation_y(3.7F))
      .mul(@math.Quat::from_rotation_z(2.13F))
      .normalize(),
    ),
  )

  let cube_2_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.74F, 0.72F, 0.70F, 1.0F),
    )
    .with_perceptual_roughness(0.5F)
    .with_reflectance(0.3F),
  )
  register_material(cube_2_material, true, false, false)
  spawn_mesh(
    world,
    cube_mesh,
    cube_2_material,
    @math.Transform::from_xyz(-0.75F, 0.7F, -2.0F).with_rotation(
      @math.Quat::from_rotation_x(0.4F)
      .mul(@math.Quat::from_rotation_y(2.3F))
      .mul(@math.Quat::from_rotation_z(0.47F))
      .normalize(),
    ),
  )

  let candle_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.9F, 0.2F, 0.3F, 1.0F),
    )
    .with_diffuse_transmission(0.7F)
    .with_perceptual_roughness(0.32F)
    .with_thickness(0.2F)
    .with_reflectance(0.35F),
  )
  register_material(candle_material, true, false, true)
  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(1.0F, 2.0F, 1.0F),
    candle_material,
    @math.Transform::from_xyz(-1.0F, 0.0F, 0.0F).with_scale(
      @math.Vec3::new(0.5F, 1.0F, 0.5F),
    ),
  )

  let flame_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_emissive(@render2d.Color::new(2.2F, 1.2F, 0.1F, 1.0F))
    .with_diffuse_transmission(1.0F)
    .with_perceptual_roughness(0.15F),
  )
  let flame_mesh_entity = @render3d.MeshMaterial3dBundle::new(
    sphere_mesh,
    @render3d.MeshMaterial3d::new(flame_material),
    @math.Transform::from_xyz(-1.0F, 1.23F, 0.0F).with_scale(
      @math.Vec3::new(0.1F, 0.2F, 0.1F),
    ),
  ).spawn(world)
  transmission_state.val.flame_mesh = Some(flame_mesh_entity)

  let white_glass = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
    .with_reflectance(0.6F)
    .with_perceptual_roughness(0.12F),
  )
  register_material(white_glass, true, true, false)
  spawn_mesh(
    world,
    sphere_mesh,
    white_glass,
    @math.Transform::from_xyz(1.0F, 0.0F, 0.0F),
  )

  let red_glass = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
    .with_reflectance(0.6F)
    .with_perceptual_roughness(0.12F),
  )
  register_material(red_glass, true, true, false)
  spawn_mesh(
    world,
    sphere_mesh,
    red_glass,
    @math.Transform::from_xyz(1.0F, -0.5F, 2.0F).with_scale(
      @math.Vec3::splat(0.5F),
    ),
  )

  let green_glass = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
    .with_reflectance(0.6F)
    .with_perceptual_roughness(0.12F),
  )
  register_material(green_glass, true, true, false)
  spawn_mesh(
    world,
    sphere_mesh,
    green_glass,
    @math.Transform::from_xyz(0.0F, -0.5F, 2.0F).with_scale(
      @math.Vec3::splat(0.5F),
    ),
  )

  let blue_glass = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
    .with_reflectance(0.6F)
    .with_perceptual_roughness(0.12F),
  )
  register_material(blue_glass, true, true, false)
  spawn_mesh(
    world,
    sphere_mesh,
    blue_glass,
    @math.Transform::from_xyz(-1.0F, -0.5F, 2.0F).with_scale(
      @math.Vec3::splat(0.5F),
    ),
  )

  let black_tile = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black())
    .with_reflectance(0.3F)
    .with_perceptual_roughness(0.8F),
  )
  let white_tile = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_reflectance(0.3F)
    .with_perceptual_roughness(0.8F),
  )
  register_material(black_tile, true, false, false)
  register_material(white_tile, true, false, false)

  for x in -3..<4 {
    for z in -3..<4 {
      let use_black = (x + z) % 2 == 0
      spawn_mesh(
        world,
        plane_mesh,
        if use_black {
          black_tile
        } else {
          white_tile
        },
        @math.Transform::from_xyz(
          float_from_int(x) * 2.0F,
          -1.0F,
          float_from_int(z) * 2.0F,
        ),
      )
    }
  }

  let paper_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_diffuse_transmission(0.6F)
    .with_perceptual_roughness(0.8F)
    .with_reflectance(1.0F),
  )
  register_material(paper_material, false, false, true)
  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(4.0F, 2.0F, 0.04F),
    paper_material,
    @math.Transform::from_xyz(0.0F, 0.5F, -3.0F),
  )

  let directional_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(1.8F, 3.2F, 3.8F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 12_000.0F, true),
    tick,
  )

  let flame_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(flame_light, @math.Transform::from_xyz(-1.0F, 1.7F, 0.0F), tick)
  world
  .get_point_light_store()
  .insert(
    flame_light,
    @render3d.PointLight::new(
      @render2d.Color::new(1.0F, 0.86F, 0.74F, 1.0F),
      4_000.0F,
      5.0F,
      true,
    ),
    tick,
  )
  transmission_state.val.flame_light = Some(flame_light)
}

///|
fn setup_camera(world : @ecs_world.World) -> Unit {
  let camera = @render3d.Camera3dBundle::new(
      @render2d.Camera::default().with_clear_color(@render2d.Color::black()),
      @math.Transform::from_xyz(1.0F, CAMERA_HEIGHT, 7.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_screen_space_transmission(
      Some(@render3d.ScreenSpaceTransmission::default()),
    )
    .spawn(world)
  let tick = world.read_change_tick()
  world.get_hdr_store().insert(camera, @render3d.Hdr::default(), tick)
  world.get_bloom_store().insert(camera, @render3d.Bloom::default(), tick)
  world
  .get_temporal_jitter_store()
  .insert(camera, @render3d.TemporalJitter::default(), tick)
  world
  .get_temporal_anti_aliasing_store()
  .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)
  transmission_state.val.camera = Some(camera)
}

///|
fn setup_text(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(transmission_hud_text(world)),
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
    .spawn()

  transmission_state.val.display_text = Some(handle)
}

///|
fn set_hud_text(world : @ecs_world.World) -> Unit {
  if transmission_state.val.display_text is Some(handle) {
    @text.text_set_content(handle, transmission_hud_text(world))
  }
}

///|
fn apply_camera_transform(world : @ecs_world.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let camera_pos = @math.Vec3::new(
      @math.sin(transmission_state.val.camera_angle) *
      transmission_state.val.camera_radius,
      CAMERA_HEIGHT,
      @math.cos(transmission_state.val.camera_angle) *
      transmission_state.val.camera_radius,
    )

    let tick = world.read_change_tick()
    world
    .get_transform_store()
    .set(
      camera_entity,
      @math.Transform::from_xyz(camera_pos.x, camera_pos.y, camera_pos.z).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn apply_material_controls(randomize_colors : Bool) -> Unit {
  if randomize_colors {
    for handle in transmission_state.val.color_materials {
      if @render3d.standard_material_get(handle) is Some(material) {
        let alpha = material.base_color.a
        let random_color = @render2d.Color::new(
          next_random_unit(),
          next_random_unit(),
          next_random_unit(),
          alpha,
        )
        @render3d.standard_material_set(
          handle,
          material.with_base_color(random_color),
        )
        |> ignore
      }
    }
  }

  for handle in transmission_state.val.specular_materials {
    if @render3d.standard_material_get(handle) is Some(material) {
      let updated = material
        .with_specular_transmission(
          transmission_state.val.specular_transmission,
        )
        .with_thickness(transmission_state.val.thickness)
        .with_ior(transmission_state.val.ior)
        .with_perceptual_roughness(transmission_state.val.perceptual_roughness)
        .with_reflectance(transmission_state.val.reflectance)

      @render3d.standard_material_set(handle, updated) |> ignore
    }
  }

  for handle in transmission_state.val.diffuse_materials {
    if @render3d.standard_material_get(handle) is Some(material) {
      let updated = material.with_diffuse_transmission(
        transmission_state.val.diffuse_transmission,
      )

      @render3d.standard_material_set(handle, updated) |> ignore
    }
  }
}

///|
fn example_control_system(world : @ecs_world.World) -> Unit {
  let delta = @time.time_delta_seconds()
  let mut materials_changed = false
  let mut randomize_colors = false
  let mut transmission_settings = camera_screen_space_transmission(world)
  let mut transmission_settings_changed = false
  let toggle_hdr = @input.key_just_pressed(@window.KeyCode::KeyH)
  let toggle_depth_prepass = @input.key_just_pressed(@window.KeyCode::KeyD)
  let toggle_taa = @input.key_just_pressed(@window.KeyCode::KeyT)

  if @input.key_pressed(@window.KeyCode::Digit2) {
    transmission_state.val.diffuse_transmission = clamp01(
      transmission_state.val.diffuse_transmission + delta,
    )
    materials_changed = true
  } else if @input.key_pressed(@window.KeyCode::Digit1) {
    transmission_state.val.diffuse_transmission = clamp01(
      transmission_state.val.diffuse_transmission - delta,
    )
    materials_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyW) {
    transmission_state.val.specular_transmission = clamp01(
      transmission_state.val.specular_transmission + delta,
    )
    materials_changed = true
  } else if @input.key_pressed(@window.KeyCode::KeyQ) {
    transmission_state.val.specular_transmission = clamp01(
      transmission_state.val.specular_transmission - delta,
    )
    materials_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyS) {
    transmission_state.val.thickness = clampf(
      transmission_state.val.thickness + delta,
      0.0F,
      5.0F,
    )
    materials_changed = true
  } else if @input.key_pressed(@window.KeyCode::KeyA) {
    transmission_state.val.thickness = clampf(
      transmission_state.val.thickness - delta,
      0.0F,
      5.0F,
    )
    materials_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyX) {
    transmission_state.val.ior = clampf(
      transmission_state.val.ior + delta,
      1.0F,
      3.0F,
    )
    materials_changed = true
  } else if @input.key_pressed(@window.KeyCode::KeyZ) {
    transmission_state.val.ior = clampf(
      transmission_state.val.ior - delta,
      1.0F,
      3.0F,
    )
    materials_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyI) {
    transmission_state.val.reflectance = clamp01(
      transmission_state.val.reflectance + delta,
    )
    materials_changed = true
  } else if @input.key_pressed(@window.KeyCode::KeyU) {
    transmission_state.val.reflectance = clamp01(
      transmission_state.val.reflectance - delta,
    )
    materials_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyR) {
    transmission_state.val.perceptual_roughness = clamp01(
      transmission_state.val.perceptual_roughness + delta,
    )
    materials_changed = true
  } else if @input.key_pressed(@window.KeyCode::KeyE) {
    transmission_state.val.perceptual_roughness = clamp01(
      transmission_state.val.perceptual_roughness - delta,
    )
    materials_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyO) {
    transmission_settings = transmission_settings.with_steps(
      transmission_settings.steps - 1,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyP) {
    transmission_settings = transmission_settings.with_steps(
      transmission_settings.steps + 1,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyJ) {
    transmission_settings = transmission_settings.with_quality(
      @render3d.ScreenSpaceTransmissionQuality::Low,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyK) {
    transmission_settings = transmission_settings.with_quality(
      @render3d.ScreenSpaceTransmissionQuality::Medium,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    transmission_settings = transmission_settings.with_quality(
      @render3d.ScreenSpaceTransmissionQuality::High,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Semicolon) {
    transmission_settings = transmission_settings.with_quality(
      @render3d.ScreenSpaceTransmissionQuality::Ultra,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    randomize_colors = true
    materials_changed = true
  }

  if toggle_hdr {
    camera_toggle_hdr(world)
  }

  if toggle_depth_prepass {
    camera_toggle_depth_prepass(world)
  }

  if toggle_taa {
    camera_toggle_taa(world)
  }

  let mut rotation_delta = 0.0F
  if @input.key_pressed(@window.KeyCode::ArrowRight) {
    transmission_state.val.auto_camera = false
    rotation_delta = rotation_delta + delta * CAMERA_ROTATE_SPEED
  }
  if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    transmission_state.val.auto_camera = false
    rotation_delta = rotation_delta - delta * CAMERA_ROTATE_SPEED
  }
  if rotation_delta == 0.0F && transmission_state.val.auto_camera {
    rotation_delta = rotation_delta + delta * AUTO_CAMERA_SPEED
  }

  let mut zoom_delta = 0.0F
  if @input.key_pressed(@window.KeyCode::ArrowDown) {
    zoom_delta = zoom_delta + delta * CAMERA_ZOOM_SPEED
    transmission_state.val.auto_camera = false
  }
  if @input.key_pressed(@window.KeyCode::ArrowUp) {
    zoom_delta = zoom_delta - delta * CAMERA_ZOOM_SPEED
    transmission_state.val.auto_camera = false
  }

  if rotation_delta != 0.0F || zoom_delta != 0.0F {
    transmission_state.val.camera_angle = transmission_state.val.camera_angle +
      rotation_delta
    transmission_state.val.camera_radius = clampf(
      transmission_state.val.camera_radius + zoom_delta,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    apply_camera_transform(world)
  }

  if materials_changed {
    apply_material_controls(randomize_colors)
  }

  if transmission_settings_changed {
    camera_set_screen_space_transmission(world, transmission_settings)
  }

  if materials_changed ||
    randomize_colors ||
    toggle_hdr ||
    toggle_depth_prepass ||
    toggle_taa {
    set_hud_text(world)
  }
}

///|
fn flicker_system(world : @ecs_world.World) -> Unit {
  let s = @time.time_elapsed_seconds()
  let a = @math.cos(s * 6.0F) * 0.0125F + @math.cos(s * 4.0F) * 0.025F
  let b = @math.cos(s * 5.0F) * 0.0125F + @math.cos(s * 3.0F) * 0.025F
  let c = @math.cos(s * 7.0F) * 0.0125F + @math.cos(s * 2.0F) * 0.025F

  let tick = world.read_change_tick()

  if transmission_state.val.flame_light is Some(light_entity) {
    if world.get_point_light_store().get(light_entity) is Some(point_light) {
      world
      .get_point_light_store()
      .set(
        light_entity,
        @render3d.PointLight::new(
          point_light.color,
          clampf(4_000.0F + 3_000.0F * (a + b + c), 500.0F, 8_000.0F),
          point_light.range,
          point_light.shadow_maps_enabled,
        ),
        tick,
      )
      |> ignore
    }

    if world.get_transform_store().get(light_entity) is Some(light_transform) {
      world
      .get_transform_store()
      .set(
        light_entity,
        light_transform.with_translation(@math.Vec3::new(-1.0F - c, 1.7F, -a)),
        tick,
      )
      |> ignore
    }
  }

  if transmission_state.val.flame_mesh is Some(flame_entity) {
    if world.get_transform_store().get(flame_entity) is Some(flame_transform) {
      world
      .get_transform_store()
      .set(
        flame_entity,
        flame_transform
        .with_translation(@math.Vec3::new(-1.0F - c, 1.23F, -a))
        .with_scale(
          @math.Vec3::new(
            0.1F + clamp01(b * 2.0F) * 0.03F,
            0.2F + clamp01(a * 2.0F) * 0.06F,
            0.1F + clamp01(c * 2.0F) * 0.03F,
          ),
        ),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  transmission_state.val = {
    diffuse_transmission: 0.5F,
    specular_transmission: 0.9F,
    thickness: 1.8F,
    ior: 1.5F,
    perceptual_roughness: 0.12F,
    reflectance: 0.5F,
    auto_camera: true,
    camera_angle: 0.1418970546F,
    camera_radius: 7.0710678119F,
    camera: None,
    flame_mesh: None,
    flame_light: None,
    display_text: None,
    specular_materials: [],
    diffuse_materials: [],
    color_materials: [],
    random_seed: 1367130551,
  }

  setup_scene(world)
  setup_camera(world)
  setup_text(world)
  apply_camera_transform(world)
  apply_material_controls(false)
  set_hud_text(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(example_control_system)
  .add_system(flicker_system)
  .run()
}
