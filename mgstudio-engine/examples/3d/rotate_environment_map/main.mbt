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
/// Port of `bevy/examples/3d/rotate_environment_map.rs`.
///
/// Exact parity target: rotate `Skybox` and `EnvironmentMapLight` together.
/// Tracking note: parity patch pass.

///|
const PI : Float = 3.141592653589793F

///|
const TWO_PI : Float = 6.283185307179586F

///|
priv struct RotateEnvState {
  mut camera : @core.Entity?
}

///|
let rotate_env_state : Ref[RotateEnvState] = Ref::new({ camera: None })

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = TWO_PI / sectors_f

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

  let geometry = @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices))
  geometry.generate_tangents() |> ignore
  @pbr.Mesh3d::from_geometry(geometry)
}

///|
fn setup(world : @ecs.World) -> Unit {
  rotate_env_state.val.camera = None

  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let sphere_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.843F, 0.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.3F)
    .with_clearcoat_normal_texture(
      Some(
        asset_server.load_with_settings("textures/ScratchedGold-Normal.png", fn(
          settings,
        ) {
          settings.is_srgb = false
        }),
      ),
    )
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.1F),
  )
  @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 24, 40),
    @pbr.MeshMaterial3d::new(sphere_material),
    @math.Transform::identity().with_scale(@math.Vec3::splat(1.25F)),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(light, @pbr.PointLight::default().with_intensity(100_000.0F), tick)
  let camera = @pbr.Camera3dBundle::new_with_projection(
    @sprite.Camera::default(),
    @pbr.Projection::Perspective(@pbr.PerspectiveProjection3d::{
      ..@pbr.PerspectiveProjection3d::default(),
      fov: 27.0F * PI / 180.0F,
    }),
    @math.Transform::from_xyz(0.0F, 0.0F, 10.0F),
  ).spawn(world)
  rotate_env_state.val.camera = Some(camera)
  world.component(@pbr.ecs_key_hdr).insert(camera, @pbr.Hdr::default(), tick)
  world
  .component(@pbr.ecs_key_tonemapping)
  .insert(camera, @pbr.Tonemapping::AcesFitted, tick)
  world
  .component(@pbr.ecs_key_skybox)
  .insert(
    camera,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      5000.0F,
    ),
    tick,
  )
  world
  .component(@pbr.ecs_key_environment_map_light)
  .insert(
    camera,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2000.0F,
    ),
    tick,
  )
}

///|
fn rotate_skybox_and_environment_map(world : @ecs.World) -> Unit {
  let now = @time.time_elapsed_seconds()
  let angle = 0.2F * now
  let rotation = @math.Quat::from_rotation_y(angle)
  let tick = world.read_change_tick()

  if rotate_env_state.val.camera is Some(camera_entity) {
    if world.component(@pbr.ecs_key_skybox).get(camera_entity) is Some(skybox) {
      world
      .component(@pbr.ecs_key_skybox)
      .set(camera_entity, skybox.with_rotation(rotation), tick)
      |> ignore
    }
    if world.component(@pbr.ecs_key_environment_map_light).get(camera_entity)
      is Some(environment_map_light) {
      world
      .component(@pbr.ecs_key_environment_map_light)
      .set(camera_entity, environment_map_light.with_rotation(rotation), tick)
      |> ignore
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate_skybox_and_environment_map))
  .run()
}
