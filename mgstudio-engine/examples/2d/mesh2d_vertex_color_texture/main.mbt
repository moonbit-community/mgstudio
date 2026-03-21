// Copyright 2025 International Digital Economy Academy
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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let texture_handle = asset_server.get().load("branding/banner.png")
  let mesh_handle = meshes.get_ref().val.add(create_colored_quad_mesh())

  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(mesh_handle),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(@sprite.Color::white()),
          ),
        ),
        @transform.Transform::from_translation(
          @math.Vec3::new(-96.0F, 0.0F, 0.0F),
        ).with_scale(@math.Vec3::splat(128.0F)),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(mesh_handle),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_image(texture_handle),
          ),
        ),
        @transform.Transform::from_translation(
          @math.Vec3::new(96.0F, 0.0F, 0.0F),
        ).with_scale(@math.Vec3::splat(128.0F)),
      ),
    ),
  )
}

///|
fn create_colored_quad_mesh() -> @mesh.Mesh {
  @mesh.Mesh::from_2d_geometry(
    @mesh.Mesh2dGeometry::new_with_colors(
      [
        @math.Vec2::new(-0.5F, -0.5F),
        @math.Vec2::new(0.5F, -0.5F),
        @math.Vec2::new(0.5F, 0.5F),
        @math.Vec2::new(-0.5F, 0.5F),
      ],
      [
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        @math.Vec2::new(0.0F, 1.0F),
      ],
      [
        @math.Vec4::new(1.0F, 0.0F, 0.0F, 1.0F),
        @math.Vec4::new(0.0F, 1.0F, 0.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
      ],
      Some([0, 1, 2, 0, 2, 3]),
    ),
  )
}
