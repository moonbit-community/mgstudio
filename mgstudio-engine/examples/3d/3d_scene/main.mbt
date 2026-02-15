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
/// Port of `bevy/examples/3d/3d_scene.rs`.

///|
const PI : Float = 3.141592653589793F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn disk_mesh(radius : Float, segments : Int) -> @render3d.Mesh3d {
  let count = if segments < 3 { 3 } else { segments }
  let positions : Array[@math.Vec3] = [@math.Vec3::new(0.0F, 0.0F, 0.0F)]
  let uvs : Array[@math.Vec2] = [@math.Vec2::new(0.5F, 0.5F)]
  let indices : Array[Int] = []

  let count_f = float_from_int(count)
  for i in 0..<count {
    let t = float_from_int(i) / count_f
    let angle = t * PI * 2.0F
    let x = @math.cos(angle) * radius
    let y = @math.sin(angle) * radius
    positions.push(@math.Vec3::new(x, y, 0.0F))
    uvs.push(
      @math.Vec2::new(x / (radius * 2.0F) + 0.5F, y / (radius * 2.0F) + 0.5F),
    )
  }

  for i in 0..<count {
    let next = if i + 1 < count { i + 1 } else { 0 }
    indices.push(0)
    indices.push(1 + i)
    indices.push(1 + next)
  }

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  @render3d.MeshMaterial3dBundle::new(
    disk_mesh(4.0F, 64),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::white()),
      ),
    ),
    @math.Transform::identity().with_rotation(
      @math.Quat::from_rotation_x(-@math.pi_half()),
    ),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(124.0F / 255.0F, 144.0F / 255.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      1_000_000.0F,
      20.0F,
      true,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .run()
}
