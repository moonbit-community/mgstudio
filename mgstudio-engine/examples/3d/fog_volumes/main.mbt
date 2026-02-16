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
/// Baseline parity: Bevy's voxel fog volume pipeline (`FogVolume`,
/// `VolumetricFog`, `VolumetricLight`) is approximated here using mgstudio's
/// current distance-fog interface and a proxy volume mesh setup.

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
}

///|
let fog_volumes_state : Ref[FogVolumesState] = Ref::new({
  camera: None,
  light: None,
})

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
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
fn spawn_volume_proxy(world : @ecs_world.World) -> Unit {
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
  world.get_parent_store().insert(ear_left, @hierarchy.Parent::new(head), tick)

  let ear_right = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(0.16F, 0.8F, 0.16F),
    @render3d.MeshMaterial3d::new(fog_material),
    @math.Transform::from_xyz(
      fog_center().x + 0.16F,
      fog_center().y + 0.7F,
      fog_center().z,
    ),
  ).spawn(world)
  world.get_parent_store().insert(ear_right, @hierarchy.Parent::new(head), tick)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  fog_volumes_state.val.camera = None
  fog_volumes_state.val.light = None

  let tick = world.read_change_tick()

  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(0.45F, 0.5F, 0.56F, 0.9F),
      @render3d.FogFalloff3d::exponential_squared(0.32F),
    ),
  )

  spawn_volume_proxy(world)

  let light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    light,
    @math.Transform::from_xyz(1.0F, 1.0F, -0.3F).looking_at(
      fog_center(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
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
  fog_volumes_state.val.camera = Some(camera)
}

///|
fn rotate_camera(world : @ecs_world.World) -> Unit {
  guard fog_volumes_state.val.camera is Some(camera_entity) else { return }

  let elapsed = @time.time_elapsed_seconds()
  let angle = elapsed * CAMERA_SPEED
  let camera_pos = @math.Vec3::new(
    @math.cos(angle) * CAMERA_RADIUS,
    CAMERA_HEIGHT,
    @math.sin(angle) * CAMERA_RADIUS,
  )

  let tick = world.read_change_tick()
  world
  .get_transform_store()
  .set(
    camera_entity,
    @math.Transform::from_xyz(camera_pos.x, camera_pos.y, camera_pos.z).looking_at(
      fog_center(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  |> ignore

  let light_dir = if fog_volumes_state.val.light is Some(light_entity) {
    if world.get_transform_store().get(light_entity) is Some(light_transform) {
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
  let brightness = 0.55F + 0.45F * phase
  let density = 0.18F + 0.22F * (1.0F - phase)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(
        clamp01(0.45F * brightness),
        clamp01(0.5F * brightness),
        clamp01(0.56F * brightness),
        0.9F,
      ),
      @render3d.FogFalloff3d::exponential_squared(density),
    ),
  )
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotate_camera)
  .run()
}
