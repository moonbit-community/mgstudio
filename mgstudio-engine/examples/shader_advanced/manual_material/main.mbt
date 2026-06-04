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
const SHADER_ASSET_PATH : String = "shaders/manual_material.wgsl"

///|
const IMAGE_ASSET_PATH : String = "branding/icon.png"

///|
fn setup(
  commands : @app.Commands,
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let plane_mesh = mesh_assets.peek()
    |> @pbr.add_mesh(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
        @math.Vec2::new(8.0F, 8.0F),
      ).build(),
    )
  let cube_mesh = mesh_assets.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(2.0F, 2.0F, 2.0F))

  let plane_material = material_assets
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.15F, 0.2F, 0.18F)),
    )
  let custom_material = material_assets
    .peek()
    .add(
      @pbr.StandardMaterial::StandardMaterial()
      .with_base_color(@sprite.Color::white())
      .with_base_color_texture(
        Some(asset_server.get().load_image(IMAGE_ASSET_PATH)),
      )
      .with_reflectance(0.45F)
      .with_perceptual_roughness(0.95F),
    )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::identity(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(custom_material).with_extension_fragment_shader_path(
          Some(SHADER_ASSET_PATH),
        ),
        @transform.Transform::from_xyz(0.0F, 1.2F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(@sprite.Color::white(), 1_500_000.0F, 30.0F, false),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
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
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, @app.system_config_param4(setup))
  .run()
}
