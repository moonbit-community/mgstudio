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
/// Baseline parity: Bevy's native `Skybox` and `EnvironmentMapLight` components
/// are not currently exposed in mgstudio. This port preserves startup topology
/// and per-frame synchronized rotation by mapping environment rotation to a
/// rotating skybox proxy mesh plus a coupled point-light orbit.

///|
const PI : Float = 3.141592653589793F

///|
const TWO_PI : Float = 6.283185307179586F

///|
priv struct RotateEnvState {
  mut skybox : @core.Entity?
  mut light : @core.Entity?
}

///|
let rotate_env_state : Ref[RotateEnvState] = Ref::new({
  skybox: None,
  light: None,
})

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

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  rotate_env_state.val.skybox = None
  rotate_env_state.val.light = None

  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let sphere_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.843F, 0.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.3F)
    .with_clearcoat_normal_texture(
      Some(asset_server.load("textures/ScratchedGold-Normal.png")),
    )
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.1F),
  )
  @render3d.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 24, 40),
    @render3d.MeshMaterial3d::new(sphere_material),
    @math.Transform::identity().with_scale(@math.Vec3::splat(1.25F)),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      100_000.0F,
      30.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(0.0F, 0.0F, 2.0F), tick)
  rotate_env_state.val.light = Some(light)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 0.0F, 10.0F),
  ).spawn(world)
  |> ignore

  let sky_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_base_color_texture(
      Some(asset_server.load("textures/Ryfjallet_cubemap.png")),
    )
    .with_unlit(true)
    .with_emissive(@render2d.Color::new(2.0F, 2.0F, 2.0F, 1.0F))
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )
  let skybox = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(200.0F, 200.0F, 200.0F),
    @render3d.MeshMaterial3d::new(sky_material),
    @math.Transform::identity(),
  ).spawn(world)
  rotate_env_state.val.skybox = Some(skybox)
}

///|
fn rotate_skybox_and_environment_proxy(world : @ecs_world.World) -> Unit {
  let now = @time.time_elapsed_seconds()
  let angle = 0.2F * now
  let tick = world.read_change_tick()

  if rotate_env_state.val.skybox is Some(skybox_entity) {
    world
    .get_transform_store()
    .set(
      skybox_entity,
      @math.Transform::identity().with_rotation(
        @math.Quat::from_rotation_y(angle),
      ),
      tick,
    )
    |> ignore
  }

  if rotate_env_state.val.light is Some(light_entity) {
    let light_pos = @math.Vec3::new(
      @math.sin(angle) * 2.0F,
      0.0F,
      @math.cos(angle) * 2.0F,
    )
    world
    .get_transform_store()
    .set(
      light_entity,
      @math.Transform::from_xyz(light_pos.x, light_pos.y, light_pos.z),
      tick,
    )
    |> ignore
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(rotate_skybox_and_environment_proxy)
  .run()
}
