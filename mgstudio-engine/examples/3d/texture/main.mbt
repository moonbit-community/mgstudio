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
const PI : Float = 3.141592653589793F

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let texture = asset_server.get().load("branding/bevy_logo_dark_big.png")
  let aspect = 0.25F
  let quad_width = 8.0F
  let mesh_assets = meshes.peek()
  let material_assets = materials.peek()
  let quad_handle = mesh_assets
    |> @pbr.add_mesh(
      @mesh.Mesh3dGeometry::rectangle(quad_width, quad_width * aspect),
    )

  let base_material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::default()
      .with_base_color_texture(Some(texture))
      .with_alpha_mode(@pbr.AlphaMode3d::Blend)
      .with_unlit(true),
    )

  let red_material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(1.0F, 0.0F, 0.0F, 0.5F),
      )
      .with_base_color_texture(Some(texture))
      .with_alpha_mode(@pbr.AlphaMode3d::Blend)
      .with_unlit(true),
    )

  let blue_material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(0.0F, 0.0F, 1.0F, 0.5F),
      )
      .with_base_color_texture(Some(texture))
      .with_alpha_mode(@pbr.AlphaMode3d::Blend)
      .with_unlit(true),
    )

  let rotation = @math.Quat::from_rotation_x(-PI / 5.0F)

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(quad_handle),
        @pbr.MeshMaterial3d::new(base_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 1.5F).with_rotation(rotation),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(quad_handle),
        @pbr.MeshMaterial3d::new(red_material),
        @transform.Transform::identity().with_rotation(rotation),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(quad_handle),
        @pbr.MeshMaterial3d::new(blue_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, -1.5F).with_rotation(
          rotation,
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(3.0F, 5.0F, 8.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
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
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}
