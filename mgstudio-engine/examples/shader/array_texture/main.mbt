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
const SHADER_PATH : String = "shaders/array_texture.wgsl"

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.3F, 1.3F, 1.3F))
  let image = asset_server.get().load_image("branding/icon.png")
  for i in 0..<3 {
    let uv_transform = @transform.Affine2::from_scale_translation(
      @math.Vec2::new(0.33F, 1.0F),
      @math.Vec2::new(Float::from_int(i) * 0.33F, 0.0F),
    )
    let material = materials.get_ref().val.add(
      @pbr.StandardMaterial::default()
      .with_base_color(@sprite.Color::white())
      .with_base_color_texture(Some(image))
      .with_uv_transform(uv_transform),
    )
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material).with_extension_shader_path(
          Some(SHADER_PATH),
        ),
        @transform.Transform::from_xyz(
          (Float::from_int(i) - 1.0F) * 1.8F,
          0.9F,
          0.0F,
        ),
      ),
    )
    |> ignore
  }

  let floor_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(8.0F, 8.0F)),
  )
  let floor_mat = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.17F, 0.2F, 0.22F)),
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
      @pbr.PointLight::new(@sprite.Color::white(), 1_300_000.0F, 25.0F, false),
      @transform.Transform::from_xyz(4.0F, 7.0F, 3.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(-3.0F, 2.4F, 6.0F).looking_at(
        @math.Vec3::new(0.0F, 0.5F, 0.0F),
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
