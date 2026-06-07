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
const SHADER_PATH : String = "shaders/custom_material.wgsl"

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let plane_mesh = meshes.peek()
    |> @pbr.add_mesh(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
        @math.Vec2::new(8.0F, 8.0F),
      ).build(),
    )
  let torus_mesh = meshes.modify(fn(meshes) {
    meshes |> @pbr.add_mesh(@math.Sphere::new(1.0F))
  })
  let floor_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::srgb(0.15F, 0.18F, 0.22F)),
    )
  let torus_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::white())
      .with_base_color_texture(
        Some(asset_server.get().load_image("branding/banner.png")),
      )
      .with_reflectance(0.5F),
    )

  commands.spawn(
    (
      @mesh.Mesh3d::new(plane_mesh),
      @pbr.MeshMaterial3d::new(floor_material),
      @transform.Transform::identity(),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @mesh.Mesh3d::new(torus_mesh),
      @pbr.MeshMaterial3d::new(torus_material).with_extension_fragment_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(0.0F, 1.2F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::new(@color.Color::white(), 1_100_000.0F, 25.0F, false),
      @transform.Transform::from_xyz(4.0F, 5.0F, 4.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @transform.Transform::from_xyz(-3.0F, 3.2F, 7.0F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(@app.Startup, setup)
  .run()
}
