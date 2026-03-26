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
const SHADER_PATH : String = "shaders/custom/texture_binding_array_3d.wgsl"

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(0.8F, 0.8F, 0.8F))
  let textures : Array[@asset.Handle[@asset.Image]] = [
    asset_server.get().load_image("branding/icon.png"),
    asset_server.get().load_image("branding/banner.png"),
    asset_server.get().load_image("branding/icon.png"),
    asset_server.get().load_image("branding/banner.png"),
    asset_server.get().load_image("branding/icon.png"),
    asset_server.get().load_image("branding/banner.png"),
  ]

  for i in 0..<24 {
    let texture = textures[i % textures.length()]
    let material = materials.get_ref().val.add(
      @pbr.StandardMaterial::from_color(@sprite.Color::white())
      .with_base_color_texture(Some(texture))
      .with_reflectance(0.3F),
    )
    let x = Float::from_int(i % 6) - 2.5F
    let z = Float::from_int(i / 6) - 1.5F
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material)
        .with_extension_shader_path(Some(SHADER_PATH))
        .with_extension_tag(i % textures.length()),
        @transform.Transform::from_xyz(x * 1.4F, 0.6F, z * 1.4F),
      ),
    )
    |> ignore
  }

  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_300_000.0F, 35.0F, false),
      @transform.Transform::from_xyz(0.0F, 7.0F, 6.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 5.0F, 11.0F).looking_at(
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
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}
