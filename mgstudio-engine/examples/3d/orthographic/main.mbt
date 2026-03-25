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

///|
const FIXED_VIEWPORT_HEIGHT : Float = 6.0F

///|
fn setup(world : @ecs.World) -> Unit {
  let projection = @pbr.Projection::Orthographic(@pbr.OrthographicProjection3d::{
    ..@pbr.OrthographicProjection3d::default_3d(),
    scaling_mode: @pbr.OrthographicScalingMode3d::FixedVertical(
      FIXED_VIEWPORT_HEIGHT,
    ),
  })

  @pbr.Camera3dBundle::new_with_projection(
    @sprite.Camera::default(),
    projection,
    @transform.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.3F, 0.5F, 0.3F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
    ),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(cube_material),
    @transform.Transform::from_xyz(1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(cube_material),
    @transform.Transform::from_xyz(1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(cube_material),
    @transform.Transform::from_xyz(-1.5F, 0.5F, 1.5F),
  ).spawn(world)
  |> ignore

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(cube_material),
    @transform.Transform::from_xyz(-1.5F, 0.5F, -1.5F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(3.0F, 8.0F, 5.0F),
  )
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
