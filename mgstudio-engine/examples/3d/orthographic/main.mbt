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
  let projection = @pbr.Projection::Orthographic(@pbr.OrthographicProjection3d::{
    ..@pbr.OrthographicProjection3d::default_3d(),
    scaling_mode: @pbr.OrthographicScalingMode3d::FixedVertical(
      FIXED_VIEWPORT_HEIGHT,
    ),
  })

  @pbr.Camera3dBundle::new_with_projection(
    @sprite.Camera::default(),
    projection,
    @math.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_plane(5.0F, 5.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
    ),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @pbr.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(-1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(light, @pbr.PointLight::default(), tick)
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
