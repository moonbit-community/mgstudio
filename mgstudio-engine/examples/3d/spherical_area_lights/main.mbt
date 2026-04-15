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
/// Parity target: preserve Bevy's `PointLight.radius` sweep and scene topology.
/// Current runtime keeps the real `radius` knob and also applies
/// intensity/range fallback mapping for visible differentiation until full
/// spherical-light shading parity lands in the renderer.

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
fn mapped_point_light_range(radius : Float) -> Float {
  let ratio = clamp01(radius / RADIUS_MAX)
  4.0F + ratio * 12.0F
}

///|
fn mapped_point_light_intensity(radius : Float) -> Float {
  let ratio = clamp01(radius / RADIUS_MAX)
  50_000.0F + ratio * 150_000.0F
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

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn setup(world : @ecs.World) -> Unit {
  set_global_ambient_light(world, @sprite.Color::white(), 60.0F)

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.2F, 1.5F, 2.5F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  camera |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(100.0F, 100.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.2F, 0.2F, 0.2F, 1.0F),
        ).with_perceptual_roughness(0.08F),
      ),
    ),
    @transform.Transform::identity(),
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

    let sphere = @pbr.MeshMaterial3dBundle::new(
      sphere_mesh,
      @pbr.MeshMaterial3d::new(
        @pbr.standard_material_add(
          @pbr.StandardMaterial::from_color(
            @sprite.Color::new(0.5F, 0.5F, 1.0F, 1.0F),
          ).with_unlit(true),
        ),
      ),
      @transform.Transform::from_xyz(position.x, position.y, position.z).with_scale(
        @math.Vec3::splat(radius),
      ),
    ).spawn(world)

    let point_light = world.spawn_empty()
    try! world.set_by_key(
      point_light,
      @pbr.ecs_key_point_light,
      @pbr.PointLight::default()
      .with_color(@sprite.Color::new(0.2F, 0.2F, 1.0F, 1.0F))
      .with_radius(radius)
      .with_range(mapped_point_light_range(radius))
      .with_intensity(mapped_point_light_intensity(radius))
      .with_shadow_maps_enabled(false),
    )
    try! world.set_by_key(
      point_light,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(sphere),
    )
    try! world.set_by_key(
      point_light,
      @pbr.ecs_key_point_light,
      @pbr.PointLight::default()
      .with_color(@sprite.Color::new(0.2F, 0.2F, 1.0F, 1.0F))
      .with_radius(radius)
      .with_range(mapped_point_light_range(radius))
      .with_intensity(mapped_point_light_intensity(radius))
      .with_shadow_maps_enabled(false),
    )
    try! world.set_by_key(
      point_light,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(sphere),
    )
    try! world.set_by_key(
      point_light,
      @transform.ecs_key_transform,
      @transform.Transform::identity(),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
