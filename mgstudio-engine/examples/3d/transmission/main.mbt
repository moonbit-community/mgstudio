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
priv struct TransmissionState {
  mut diffuse_transmission : Float
  mut specular_transmission : Float
  mut thickness : Float
  mut ior : Float
  mut perceptual_roughness : Float
  mut reflectance : Float
  mut auto_camera : Bool
  mut camera_translation : @math.Vec3
  mut camera : @core.Entity?
  mut flame_mesh : @core.Entity?
  mut flame_light : @core.Entity?
  mut display_text : @text.TextHandle?
  specular_materials : Array[@asset.Handle[@pbr.StandardMaterial]]
  diffuse_materials : Array[@asset.Handle[@pbr.StandardMaterial]]
  color_materials : Array[@asset.Handle[@pbr.StandardMaterial]]
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
  camera_translation: @math.Vec3::new(
    CAMERA_INITIAL_X,
    CAMERA_INITIAL_Y,
    CAMERA_INITIAL_Z,
  ),
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
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn expf(value : Float) -> Float {
  @math.pow(E, value)
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
fn quality_label(
  quality : @post_process.ScreenSpaceTransmissionQuality,
) -> String {
  match quality {
    Low => "Low"
    Medium => "Medium"
    High => "High"
    Ultra => "Ultra"
  }
}

///|
fn camera_screen_space_transmission(
  world : @ecs.World,
) -> @post_process.ScreenSpaceTransmission {
  if transmission_state.val.camera is Some(camera_entity) {
    match
      world
      .component(@post_process.ecs_key_screen_space_transmission)
      .get(camera_entity) {
      Some(value) => value
      None => @post_process.ScreenSpaceTransmission::default()
    }
  } else {
    @post_process.ScreenSpaceTransmission::default()
  }
}

///|
fn camera_set_screen_space_transmission(
  world : @ecs.World,
  value : @post_process.ScreenSpaceTransmission,
) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let store = world.component(@post_process.ecs_key_screen_space_transmission)
    if store.contains(camera_entity) {
      store.set(camera_entity, value, tick) |> ignore
    } else {
      store.insert(camera_entity, value, tick)
    }
  }
}

///|
fn camera_hdr_enabled(world : @ecs.World) -> Bool {
  if transmission_state.val.camera is Some(camera_entity) {
    world.component(@pbr.ecs_key_hdr).contains(camera_entity)
  } else {
    false
  }
}

///|
fn camera_depth_prepass_enabled(world : @ecs.World) -> Bool {
  if transmission_state.val.camera is Some(camera_entity) {
    world.component(@pbr.ecs_key_depth_prepass).contains(camera_entity)
  } else {
    false
  }
}

///|
fn camera_taa_enabled(world : @ecs.World) -> Bool {
  if transmission_state.val.camera is Some(camera_entity) {
    world
    .component(@post_process.ecs_key_temporal_jitter)
    .contains(camera_entity)
  } else {
    false
  }
}

///|
fn camera_toggle_hdr(world : @ecs.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let store = world.component(@pbr.ecs_key_hdr)
    if store.contains(camera_entity) {
      store.remove(camera_entity) |> ignore
    } else {
      store.insert(camera_entity, @pbr.Hdr::default(), tick)
    }
  }
}

///|
fn camera_toggle_depth_prepass(world : @ecs.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let store = world.component(@pbr.ecs_key_depth_prepass)
    if store.contains(camera_entity) {
      store.remove(camera_entity) |> ignore
    } else {
      store.insert(camera_entity, @pbr.DepthPrepass::default(), tick)
    }
  }
}

///|
fn camera_toggle_taa(world : @ecs.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let tick = world.read_change_tick()
    let jitter_store = world.component(@post_process.ecs_key_temporal_jitter)
    let taa_store = world.component(
      @post_process.ecs_key_temporal_anti_aliasing,
    )
    if jitter_store.contains(camera_entity) {
      jitter_store.remove(camera_entity) |> ignore
      taa_store.remove(camera_entity) |> ignore
    } else {
      jitter_store.insert(
        camera_entity,
        @post_process.TemporalJitter::default(),
        tick,
      )
      taa_store.insert(
        camera_entity,
        @post_process.TemporalAntiAliasing::default(),
        tick,
      )
    }
  }
}

///|
fn transmission_hud_text(world : @ecs.World) -> String {
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
  material : @asset.Handle[@pbr.StandardMaterial],
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
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
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

  @pbr.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn cylinder_mesh(
  radius : Float,
  height : Float,
  resolution : Int,
) -> @pbr.Mesh3d {
  let safe_radius = if radius <= 0.0F { 0.5F } else { radius }
  let safe_height = if height <= 0.0F { 1.0F } else { height }
  let safe_resolution = if resolution < 3 { 3 } else { resolution }
  let half_height = safe_height / 2.0F
  let inv_diameter = 0.5F / safe_radius
  let resolution_f = float_from_int(safe_resolution)

  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []

  for i in 0..<safe_resolution {
    let i0 = float_from_int(i)
    let i1 = float_from_int(i + 1)
    let theta0 = i0 * 2.0F * PI / resolution_f
    let theta1 = i1 * 2.0F * PI / resolution_f
    let x0 = safe_radius * @math.cos(theta0)
    let z0 = safe_radius * @math.sin(theta0)
    let x1 = safe_radius * @math.cos(theta1)
    let z1 = safe_radius * @math.sin(theta1)
    let u0 = i0 / resolution_f
    let u1 = i1 / resolution_f

    positions.push(@math.Vec3::new(x0, half_height, z0))
    uvs.push(@math.Vec2::new(u0, 0.0F))
    positions.push(@math.Vec3::new(x0, -half_height, z0))
    uvs.push(@math.Vec2::new(u0, 1.0F))
    positions.push(@math.Vec3::new(x1, half_height, z1))
    uvs.push(@math.Vec2::new(u1, 0.0F))

    positions.push(@math.Vec3::new(x1, half_height, z1))
    uvs.push(@math.Vec2::new(u1, 0.0F))
    positions.push(@math.Vec3::new(x0, -half_height, z0))
    uvs.push(@math.Vec2::new(u0, 1.0F))
    positions.push(@math.Vec3::new(x1, -half_height, z1))
    uvs.push(@math.Vec2::new(u1, 1.0F))

    positions.push(@math.Vec3::new(0.0F, half_height, 0.0F))
    uvs.push(@math.Vec2::new(0.5F, 0.5F))
    positions.push(@math.Vec3::new(x1, half_height, z1))
    uvs.push(
      @math.Vec2::new(0.5F + x1 * inv_diameter, 0.5F + z1 * inv_diameter),
    )
    positions.push(@math.Vec3::new(x0, half_height, z0))
    uvs.push(
      @math.Vec2::new(0.5F + x0 * inv_diameter, 0.5F + z0 * inv_diameter),
    )

    positions.push(@math.Vec3::new(0.0F, -half_height, 0.0F))
    uvs.push(@math.Vec2::new(0.5F, 0.5F))
    positions.push(@math.Vec3::new(x0, -half_height, z0))
    uvs.push(
      @math.Vec2::new(0.5F + x0 * inv_diameter, 0.5F + z0 * inv_diameter),
    )
    positions.push(@math.Vec3::new(x1, -half_height, z1))
    uvs.push(
      @math.Vec2::new(0.5F + x1 * inv_diameter, 0.5F + z1 * inv_diameter),
    )
  }

  @pbr.Mesh3d::from_geometry(@mesh.Mesh3dGeometry::new(positions, uvs, None))
}

///|
fn spawn_mesh(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  world.insert_resource(
    @pbr.ecs_key_point_light_shadow_map,
    @pbr.PointLightShadowMap::new(2048),
  )
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 0.0F),
  )

  let cube_mesh = @pbr.Mesh3d::from_cuboid(0.7F, 0.7F, 0.7F)
  let sphere_mesh = uv_sphere_mesh(0.9F, 24, 40)
  let plane_mesh = @pbr.Mesh3d::from_plane(2.0F, 2.0F)
  let candle_mesh = cylinder_mesh(0.5F, 2.0F, 50)

  let cube_1_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::default(),
  )
  register_material(cube_1_material, true, false, false)
  spawn_mesh(
    world,
    cube_mesh,
    cube_1_material,
    @math.Transform::from_xyz(0.25F, 0.5F, -2.0F).with_rotation(
      @math.Quat::from_rotation_x(1.4F)
      .mul(@math.Quat::from_rotation_y(3.7F))
      .mul(@math.Quat::from_rotation_z(21.3F))
      .normalize(),
    ),
  )

  let cube_2_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::default(),
  )
  register_material(cube_2_material, true, false, false)
  spawn_mesh(
    world,
    cube_mesh,
    cube_2_material,
    @math.Transform::from_xyz(-0.75F, 0.7F, -2.0F).with_rotation(
      @math.Quat::from_rotation_x(0.4F)
      .mul(@math.Quat::from_rotation_y(2.3F))
      .mul(@math.Quat::from_rotation_z(4.7F))
      .normalize(),
    ),
  )

  let candle_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.9F, 0.2F, 0.3F, 1.0F),
    )
    .with_diffuse_transmission(0.7F)
    .with_perceptual_roughness(0.32F)
    .with_thickness(0.2F),
  )
  register_material(candle_material, true, false, true)
  spawn_mesh(
    world,
    candle_mesh,
    candle_material,
    @math.Transform::from_xyz(-1.0F, 0.0F, 0.0F),
  )

  let flame_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_emissive(@sprite.Color::new(23.6F, 19.48F, 16.8F, 1.0F))
    .with_diffuse_transmission(1.0F),
  )
  let flame_mesh_entity = @pbr.MeshMaterial3dBundle::new(
    sphere_mesh,
    @pbr.MeshMaterial3d::new(flame_material),
    @math.Transform::from_xyz(-1.0F, 1.15F, 0.0F).with_scale(
      @math.Vec3::new(0.1F, 0.2F, 0.1F),
    ),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_not_shadow_caster)
  .insert(flame_mesh_entity, @pbr.NotShadowCaster::default(), tick)
  transmission_state.val.flame_mesh = Some(flame_mesh_entity)

  let white_glass = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
    .with_perceptual_roughness(0.12F),
  )
  register_material(white_glass, true, true, false)
  spawn_mesh(
    world,
    sphere_mesh,
    white_glass,
    @math.Transform::from_xyz(1.0F, 0.0F, 0.0F),
  )

  let red_glass = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
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

  let green_glass = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
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

  let blue_glass = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    )
    .with_specular_transmission(0.9F)
    .with_diffuse_transmission(1.0F)
    .with_thickness(1.8F)
    .with_ior(1.5F)
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

  let black_tile = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black())
    .with_reflectance(0.3F)
    .with_perceptual_roughness(0.8F),
  )
  let white_tile = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
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

  let paper_material_base = @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    )
    .with_diffuse_transmission(0.6F)
    .with_perceptual_roughness(0.8F)
    .with_reflectance(1.0F)
    .with_double_sided(true)
    .with_cull_mode(None)
  let paper_material = @pbr.standard_material_add(paper_material_base)
  register_material(paper_material, false, false, true)
  let paper_entity = @pbr.MeshMaterial3dBundle::new(
    plane_mesh,
    @pbr.MeshMaterial3d::new(paper_material),
    @math.Transform::from_xyz(0.0F, 0.5F, -3.0F)
    .with_scale(@math.Vec3::new(2.0F, 1.0F, 1.0F))
    .with_rotation(@math.Quat::from_rotation_x(PI / 2.0F)),
  ).spawn(world)
  world
  .component(@pbr.ecs_key_transmitted_shadow_receiver)
  .insert(paper_entity, @pbr.TransmittedShadowReceiver::default(), tick)

  let flame_light = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(flame_light, @math.Transform::from_xyz(-1.0F, 1.7F, 0.0F), tick)
  world
  .component(@pbr.ecs_key_point_light)
  .insert(
    flame_light,
    @pbr.PointLight::new(
      @sprite.Color::new(0.987F, 0.792F, 0.674F, 1.0F),
      4_000.0F,
      5.0F,
      true,
    ).with_radius(0.2F),
    tick,
  )
  transmission_state.val.flame_light = Some(flame_light)
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let color_grading = @post_process.ColorGrading::default()
  color_grading.global.post_saturation = 1.2F
  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default().with_clear_color(@sprite.Color::black()),
      @math.Transform::from_xyz(
        CAMERA_INITIAL_X,
        CAMERA_INITIAL_Y,
        CAMERA_INITIAL_Z,
      ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    )
    .with_screen_space_transmission(
      Some(@post_process.ScreenSpaceTransmission::default()),
    )
    .spawn(world)
  let tick = world.read_change_tick()
  world.component(@pbr.ecs_key_hdr).insert(camera, @pbr.Hdr::default(), tick)
  world
  .component(@post_process.ecs_key_bloom)
  .insert(camera, @post_process.Bloom::default(), tick)
  world.component(@pbr.ecs_key_msaa).insert(camera, @pbr.Msaa::Off, tick)
  world
  .component(@post_process.ecs_key_temporal_jitter)
  .insert(camera, @post_process.TemporalJitter::default(), tick)
  world
  .component(@post_process.ecs_key_temporal_anti_aliasing)
  .insert(camera, @post_process.TemporalAntiAliasing::default(), tick)
  world
  .component(@pbr.ecs_key_exposure)
  .insert(camera, @pbr.Exposure::new(6.0F), tick)
  world
  .component(@post_process.ecs_key_color_grading)
  .insert(camera, color_grading, tick)
  world
  .component(@post_process.ecs_key_tonemapping)
  .insert(camera, @post_process.Tonemapping::TonyMcMapface, tick)
  world
  .component(@pbr.ecs_key_environment_map_light)
  .insert(
    camera,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      25.0F,
    ),
    tick,
  )
  transmission_state.val.camera = Some(camera)
}

///|
fn setup_text(world : @ecs.World) -> Unit {
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
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .spawn()

  transmission_state.val.display_text = Some(handle)
}

///|
fn set_hud_text(world : @ecs.World) -> Unit {
  if transmission_state.val.display_text is Some(handle) {
    @text.text_set_content(handle, transmission_hud_text(world))
  }
}

///|
fn apply_camera_transform(world : @ecs.World) -> Unit {
  if transmission_state.val.camera is Some(camera_entity) {
    let camera_pos = transmission_state.val.camera_translation
    let tick = world.read_change_tick()
    world
    .component(@math.ecs_key_transform)
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
      if @pbr.standard_material_get(handle) is Some(material) {
        let alpha = material.base_color.a
        let random_color = @sprite.Color::new(
          next_random_unit(),
          next_random_unit(),
          next_random_unit(),
          alpha,
        )
        @pbr.standard_material_set(
          handle,
          material.with_base_color(random_color),
        )
        |> ignore
      }
    }
  }

  for handle in transmission_state.val.specular_materials {
    if @pbr.standard_material_get(handle) is Some(material) {
      let updated = material
        .with_specular_transmission(
          transmission_state.val.specular_transmission,
        )
        .with_thickness(transmission_state.val.thickness)
        .with_ior(transmission_state.val.ior)
        .with_perceptual_roughness(transmission_state.val.perceptual_roughness)
        .with_reflectance(transmission_state.val.reflectance)

      @pbr.standard_material_set(handle, updated) |> ignore
    }
  }

  for handle in transmission_state.val.diffuse_materials {
    if @pbr.standard_material_get(handle) is Some(material) {
      let updated = material.with_diffuse_transmission(
        transmission_state.val.diffuse_transmission,
      )

      @pbr.standard_material_set(handle, updated) |> ignore
    }
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in transmission example")
  }
}

///|
fn example_control_system(world : @ecs.World) -> Unit {
  let delta = world_time(world).delta_seconds()
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

  if @input.key_just_pressed(@window.KeyCode::KeyO) &&
    transmission_settings.steps > 0 {
    transmission_settings = transmission_settings.with_steps(
      transmission_settings.steps - 1,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyP) &&
    transmission_settings.steps < 4 {
    transmission_settings = transmission_settings.with_steps(
      transmission_settings.steps + 1,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyJ) {
    transmission_settings = transmission_settings.with_quality(
      @post_process.ScreenSpaceTransmissionQuality::Low,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyK) {
    transmission_settings = transmission_settings.with_quality(
      @post_process.ScreenSpaceTransmissionQuality::Medium,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    transmission_settings = transmission_settings.with_quality(
      @post_process.ScreenSpaceTransmissionQuality::High,
    )
    transmission_settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Semicolon) {
    transmission_settings = transmission_settings.with_quality(
      @post_process.ScreenSpaceTransmissionQuality::Ultra,
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

  let rotation = if @input.key_pressed(@window.KeyCode::ArrowRight) {
    transmission_state.val.auto_camera = false
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    transmission_state.val.auto_camera = false
    -delta
  } else if transmission_state.val.auto_camera {
    delta * AUTO_CAMERA_SPEED
  } else {
    0.0F
  }

  let camera_distance = transmission_state.val.camera_translation.length()
  let distance_change = if @input.key_pressed(@window.KeyCode::ArrowDown) &&
    camera_distance < 25.0F {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowUp) &&
    camera_distance > 2.0F {
    -delta
  } else {
    0.0F
  }

  let mut camera_changed = false
  if distance_change != 0.0F {
    transmission_state.val.camera_translation = transmission_state.val.camera_translation.mul_scalar(
      expf(distance_change),
    )
    camera_changed = true
  }

  if rotation != 0.0F {
    transmission_state.val.camera_translation = quat_rotate_vec3(
      @math.Quat::from_rotation_y(rotation),
      transmission_state.val.camera_translation,
    )
    camera_changed = true
  }

  if camera_changed {
    apply_camera_transform(world)
  }

  if materials_changed {
    apply_material_controls(randomize_colors)
  }

  if transmission_settings_changed {
    camera_set_screen_space_transmission(world, transmission_settings)
  }

  set_hud_text(world)
}

///|
fn flicker_system(world : @ecs.World) -> Unit {
  let s = world_time(world).elapsed_seconds()
  let a = @math.cos(s * 6.0F) * 0.0125F + @math.cos(s * 4.0F) * 0.025F
  let b = @math.cos(s * 5.0F) * 0.0125F + @math.cos(s * 3.0F) * 0.025F
  let c = @math.cos(s * 7.0F) * 0.0125F + @math.cos(s * 2.0F) * 0.025F

  let tick = world.read_change_tick()

  if transmission_state.val.flame_light is Some(light_entity) {
    if world.component(@pbr.ecs_key_point_light).get(light_entity)
      is Some(point_light) {
      world
      .component(@pbr.ecs_key_point_light)
      .set(
        light_entity,
        point_light.with_intensity(4_000.0F + 3_000.0F * (a + b + c)),
        tick,
      )
      |> ignore
    }

    if world.component(@math.ecs_key_transform).get(light_entity)
      is Some(light_transform) {
      world
      .component(@math.ecs_key_transform)
      .set(
        light_entity,
        light_transform.with_translation(@math.Vec3::new(-1.0F - c, 1.7F, -a)),
        tick,
      )
      |> ignore
    }
  }

  if transmission_state.val.flame_mesh is Some(flame_entity) {
    if world.component(@math.ecs_key_transform).contains(flame_entity) {
      let base_transform = @math.Transform::from_xyz(-1.0F - c, 1.23F, -a).looking_at(
        @math.Vec3::new(-1.0F - c, 1.7F - b, -a),
        @math.Vec3::new(1.0F, 0.0F, 0.0F),
      )
      let rotated_flame = base_transform.with_rotation(
        base_transform.rotation
        .mul(@math.Quat::from_rotation_z(PI / 2.0F))
        .normalize(),
      )
      world
      .component(@math.ecs_key_transform)
      .set(
        flame_entity,
        rotated_flame.with_scale(@math.Vec3::new(0.1F, 0.2F, 0.1F)),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  transmission_state.val = {
    diffuse_transmission: 0.5F,
    specular_transmission: 0.9F,
    thickness: 1.8F,
    ior: 1.5F,
    perceptual_roughness: 0.12F,
    reflectance: 0.5F,
    auto_camera: true,
    camera_translation: @math.Vec3::new(
      CAMERA_INITIAL_X,
      CAMERA_INITIAL_Y,
      CAMERA_INITIAL_Z,
    ),
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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(example_control_system))
  .add_systems(@app.Update, @app.system(flicker_system))
  .run()
}
