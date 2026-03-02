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
/// Port of `bevy/examples/3d/fog_volumes.rs`.
///
/// Parity notes:
/// - Uses Bevy-like proxy volume geometry and camera/light motion.
/// - Uses `VolumetricFog` / `FogVolume` data-model stubs for scene parameters.
/// - Backend still approximates voxel fog-volume rendering through distance fog.

///|
const PI : Float = 3.141592653589793F

///|
const CAMERA_RADIUS : Float = 2.2F

///|
const CAMERA_HEIGHT : Float = 1.0F

///|
const CAMERA_SPEED : Float = 0.75F

///|
fn fog_center() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.5F, 0.0F)
}

///|
priv struct FogVolumesState {
  mut camera : @core.Entity?
  mut light : @core.Entity?
  mut volumetric_fog_stub : @render3d.VolumetricFog
  mut fog_volume_stub : @render3d.FogVolume
}

///|
let fog_volumes_state : Ref[FogVolumesState] = Ref::new({
  camera: None,
  light: None,
  volumetric_fog_stub: @render3d.VolumetricFog::default(),
  fog_volume_stub: @render3d.FogVolume::default(),
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
fn apply_distance_fog_from_stub(world : @ecs.World, phase : Float) -> Unit {
  let fog_volume_stub = fog_volumes_state.val.fog_volume_stub
  let volumetric_fog_stub = fog_volumes_state.val.volumetric_fog_stub
  let visibility = clampf(
    12.0F / (1.0F + fog_volume_stub.density_factor * 2.5F),
    2.5F,
    20.0F,
  )
  let brightness = 0.55F + 0.45F * phase
  let ambient_lift = clampf(
    volumetric_fog_stub.ambient_intensity * 0.4F,
    0.0F,
    0.2F,
  )
  let directional_alpha = clampf(0.25F + phase * 0.55F, 0.2F, 0.9F)
  let fog_color = fog_volume_stub.fog_color

  let fog = @render3d.DistanceFog::default()
    .with_color(
      @render2d.Color::new(
        clamp01(fog_color.r * brightness + ambient_lift),
        clamp01(fog_color.g * brightness + ambient_lift),
        clamp01(fog_color.b * brightness + ambient_lift),
        0.9F,
      ),
    )
    .with_directional_light_color(
      @render2d.Color::new(1.0F, 1.0F, 1.0F, directional_alpha),
    )
    .with_directional_light_exponent(24.0F)
    .with_falloff(@render3d.FogFalloff3d::from_visibility_squared(visibility))
  guard fog_volumes_state.val.camera is Some(camera) else { return }
  let tick = world.read_change_tick()
  let camera3d_store = @render3d.query_get_camera3d_store(world)
  let camera3d = match camera3d_store.get(camera) {
    Some(value) => value
    None => @render3d.Camera3d::default()
  }
  camera3d_store.set(camera, camera3d.with_distance_fog(Some(fog)), tick)
  |> ignore
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn spawn_volume_proxy(world : @ecs.World) -> Unit {
  let fog_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.88F, 0.92F, 0.97F, 0.25F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F)
    .with_emissive(@render2d.Color::new(0.22F, 0.24F, 0.3F, 1.0F)),
  )

  let head = @render3d.MeshMaterial3dBundle::new(
    uv_sphere_mesh(0.45F, 18, 32),
    @render3d.MeshMaterial3d::new(fog_material),
    @math.Transform::from_xyz(fog_center().x, fog_center().y, fog_center().z),
  ).spawn(world)

  let tick = world.read_change_tick()

  // Two elongated cubes approximate bunny ears for a fog-volume silhouette.
  let ear_left = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.16F, 0.8F, 0.16F),
    @render3d.MeshMaterial3d::new(fog_material),
    @math.Transform::from_xyz(
      fog_center().x - 0.16F,
      fog_center().y + 0.7F,
      fog_center().z,
    ),
  ).spawn(world)
  @hierarchy.query_get_parent_store(world).insert(
    ear_left,
    @hierarchy.Parent::new(head),
    tick,
  )

  let ear_right = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.16F, 0.8F, 0.16F),
    @render3d.MeshMaterial3d::new(fog_material),
    @math.Transform::from_xyz(
      fog_center().x + 0.16F,
      fog_center().y + 0.7F,
      fog_center().z,
    ),
  ).spawn(world)
  @hierarchy.query_get_parent_store(world).insert(
    ear_right,
    @hierarchy.Parent::new(head),
    tick,
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  fog_volumes_state.val.camera = None
  fog_volumes_state.val.light = None
  fog_volumes_state.val.volumetric_fog_stub = @render3d.VolumetricFog::default()
    .with_step_count(64)
    .with_ambient_intensity(0.0F)
  fog_volumes_state.val.fog_volume_stub = @render3d.FogVolume::default()
    .with_density_factor(1.0F)
    .with_scattering(1.0F)
    .with_absorption(0.3F)
    .with_fog_color(@render2d.Color::new(0.45F, 0.5F, 0.56F, 1.0F))

  let tick = world.read_change_tick()

  let ambient = @render3d.query_get_global_ambient_light_resource(world)
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  spawn_volume_proxy(world)

  let light = world.spawn_empty()
  @math.query_get_transform_store(world).insert(
    light,
    @math.Transform::from_xyz(1.0F, 1.0F, -0.3F).looking_at(
      fog_center(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  @render3d.query_get_directional_light_store(world).insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 32_000.0F, true),
    tick,
  )
  fog_volumes_state.val.light = Some(light)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-0.75F, 1.0F, 2.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  @render3d.query_get_hdr_store(world).insert(
    camera,
    @render3d.Hdr::default(),
    tick,
  )
  fog_volumes_state.val.camera = Some(camera)
  apply_distance_fog_from_stub(world, 1.0F)
}

///|
fn rotate_camera(world : @ecs.World) -> Unit {
  guard fog_volumes_state.val.camera is Some(camera_entity) else { return }

  let elapsed = @time.time_elapsed_seconds()
  let angle = elapsed * CAMERA_SPEED
  let camera_pos = @math.Vec3::new(
    @math.cos(angle) * CAMERA_RADIUS,
    CAMERA_HEIGHT,
    @math.sin(angle) * CAMERA_RADIUS,
  )

  let tick = world.read_change_tick()
  @math.query_get_transform_store(world).set(
    camera_entity,
    @math.Transform::from_xyz(camera_pos.x, camera_pos.y, camera_pos.z).looking_at(
      fog_center(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  |> ignore

  let light_dir = if fog_volumes_state.val.light is Some(light_entity) {
    if @math.query_get_transform_store(world).get(light_entity)
      is Some(light_transform) {
      transform_forward(light_transform)
    } else {
      @math.Vec3::new(0.0F, -1.0F, 0.0F)
    }
  } else {
    @math.Vec3::new(0.0F, -1.0F, 0.0F)
  }
  let view_dir = fog_center().sub(camera_pos).normalize_or_zero()
  let phase = clamp01(light_dir.neg().dot(view_dir) * 0.5F + 0.5F)

  // Approximate volumetric scattering with dynamic fog color and density.
  let density = 0.18F + 0.22F * (1.0F - phase)
  fog_volumes_state.val.fog_volume_stub = fog_volumes_state.val.fog_volume_stub
    .with_density_factor(density)
    .with_scattering(1.0F)
  apply_distance_fog_from_stub(world, phase)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotate_camera)
  .run()
}
