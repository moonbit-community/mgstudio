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
/// Port of `bevy/examples/3d/spherical_area_lights.rs`.
///
/// Baseline parity: Bevy's `PointLight.radius` area-light shading model is not
/// exposed in mgstudio. This port preserves scene topology and radius sweep by
/// scaling visible light proxies and mapping light effect to available point
/// light intensity/range.

///|
const TWO_PI : Float = 6.283185307179586F

///|
const PI : Float = 3.141592653589793F

///|
const LIGHT_COUNT : Int = 6

///|
const POSITION_MIN : Float = -2.0F

///|
const POSITION_MAX : Float = 2.0F

///|
const RADIUS_MIN : Float = 0.0F

///|
const RADIUS_MAX : Float = 0.4F

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
fn set_global_ambient_light(
  world : @ecs_world.World,
  color : @render2d.Color,
  brightness : Float,
) -> Unit {
  let tick = world.read_change_tick()
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  if world.get_global_ambient_light_resource().get_ref_mut(tick)
    is Some(current) {
    current.val = ambient
  } else {
    world.get_global_ambient_light_resource().insert(ambient, tick)
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  set_global_ambient_light(world, @render2d.Color::white(), 60.0F)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.2F, 1.5F, 2.5F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  camera |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(100.0F, 100.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.2F, 0.2F, 0.2F, 1.0F),
        ).with_perceptual_roughness(0.08F),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let position_len = POSITION_MAX - POSITION_MIN
  let radius_len = RADIUS_MAX - RADIUS_MIN
  let sphere_mesh = uv_sphere_mesh(1.0F, 40, 72)

  for i in 0..<LIGHT_COUNT {
    let percent = float_from_int(i) / float_from_int(LIGHT_COUNT)
    let radius = RADIUS_MIN + percent * radius_len
    let x = POSITION_MIN + percent * position_len
    let position = @math.Vec3::new(x, 0.3F, 0.0F)

    @render3d.MeshMaterial3dBundle::new(
      sphere_mesh,
      @render3d.MeshMaterial3d::new(
        @render3d.standard_material_add(
          @render3d.StandardMaterial::from_color(
            @render2d.Color::new(0.5F, 0.5F, 1.0F, 1.0F),
          ).with_unlit(true),
        ),
      ),
      @math.Transform::from_xyz(position.x, position.y, position.z).with_scale(
        @math.Vec3::splat(radius),
      ),
    ).spawn(world)
    |> ignore

    let point_light = world.spawn_empty()
    world
    .get_point_light_store()
    .insert(
      point_light,
      @render3d.PointLight::new(
        @render2d.Color::new(0.2F, 0.2F, 1.0F, 1.0F),
        100_000.0F,
        8.0F,
        false,
      ),
      tick,
    )
    world
    .get_transform_store()
    .insert(
      point_light,
      @math.Transform::from_xyz(position.x, position.y, position.z),
      tick,
    )
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .run()
}
