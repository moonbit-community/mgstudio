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
/// Port of `bevy/examples/3d/orthographic.rs`.

///|
const FIXED_VIEWPORT_HEIGHT : Float = 6.0F

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let projection = @render3d.Projection::Orthographic(@render3d.OrthographicProjection3d::{
    ..@render3d.OrthographicProjection3d::default_3d(),
    scaling_mode: @render3d.OrthographicScalingMode3d::FixedVertical(
      FIXED_VIEWPORT_HEIGHT,
    ),
  })

  @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::default(),
    projection,
    @math.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

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

  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
    ),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(light, @math.Transform::from_xyz(3.0F, 8.0F, 5.0F), tick)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
