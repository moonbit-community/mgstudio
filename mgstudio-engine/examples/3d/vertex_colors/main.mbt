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
/// Port of `bevy/examples/3d/vertex_colors.rs`.

///|
fn colorful_cube_mesh() -> @render3d.Mesh3d {
  let positions = [
    // Top (+y)
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    // Bottom (-y)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    // Right (+x)
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    // Left (-x)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    // Back (+z)
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    // Forward (-z)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  ]
  let indices = [
    0, 3, 1, 1, 3, 2, 4, 5, 7, 5, 6, 7, 8, 11, 9, 9, 11, 10, 12, 13, 15, 13, 14,
    15, 16, 19, 17, 17, 19, 18, 20, 21, 23, 21, 22, 23,
  ]
  let colors : Array[@math.Vec4] = []
  for position in positions {
    colors.push(
      @math.Vec4::new(
        (1.0F - position.x) / 2.0F,
        (1.0F - position.y) / 2.0F,
        (1.0F - position.z) / 2.0F,
        1.0F,
      ),
    )
  }
  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new_with_colors(positions, uvs, colors, Some(indices)),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    colorful_cube_mesh(),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(@render2d.Color::white()),
      ),
    ),
    @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let light_entity = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(
    light_entity,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      1_000_000.0F,
      20.0F,
      true,
    ),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    light_entity,
    @math.Transform::from_xyz(4.0F, 5.0F, 4.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .run()
}
