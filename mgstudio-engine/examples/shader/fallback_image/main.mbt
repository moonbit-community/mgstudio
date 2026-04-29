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
const SHADER_PATH : String = "shaders/fallback_image_test.wgsl"

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let mesh = meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(1.4F, 1.4F, 1.4F))
  let valid_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::default()
      .with_base_color(@sprite.Color::white())
      .with_base_color_texture(
        Some(asset_server.get().load_image("branding/icon.png")),
      ),
    )
  let fallback_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::default()
      .with_base_color(@sprite.Color::srgb(0.8F, 0.6F, 0.2F))
      .with_base_color_texture(
        Some(
          asset_server.get().load_image("textures/this_file_does_not_exist.png"),
        ),
      ),
    )

  commands.spawn(
    (
      @pbr.Mesh3d::new(mesh),
      @pbr.MeshMaterial3d::new(valid_material).with_extension_fragment_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(-1.2F, 0.9F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Mesh3d::new(mesh),
      @pbr.MeshMaterial3d::new(fallback_material).with_extension_fragment_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(1.2F, 0.9F, 0.0F),
    ),
  )
  |> ignore

  let floor_mesh = meshes
    .peek()
    .add(@pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(7.0F, 7.0F)))
  let floor_mat = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.2F, 0.22F, 0.25F)),
    )
  commands.spawn(
    (
      @pbr.Mesh3d::new(floor_mesh),
      @pbr.MeshMaterial3d::new(floor_mat),
      @transform.Transform::identity(),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_000_000.0F, 24.0F, false),
      @transform.Transform::from_xyz(3.0F, 6.0F, 3.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(-3.0F, 2.8F, 5.4F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}
