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
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.peek()
  let material_assets = materials.peek()

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets |> @pbr.add_mesh(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets
          |> @pbr.add_material(@sprite.Color::new(0.3F, 0.5F, 0.3F, 1.0F)),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F)),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets
          |> @pbr.add_material(@sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F)),
        ),
        @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default().with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @sprite.Camera::default()
        .with_order(1)
        .with_clear_color_config(@sprite.ClearColorConfig::None),
        @transform.Transform::from_xyz(10.0F, 10.0F, -5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .run()
}
