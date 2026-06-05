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
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, @app.system_config_param4(setup))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  let texture = asset_server.get().load("branding/icon.png")
  let mesh = meshes
    .peek()
    .add(
      @sprite.mesh2d_geometry_rectangle(
        @math.Rectangle::from_size(@math.Vec2::new(256.0F, 256.0F)),
      ).to_mesh(),
    )
  let white = @color.Color::srgba(1.0F, 1.0F, 1.0F, 1.0F)
  let blue = @color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F)
  let green = @color.Color::srgba(0.0F, 0.5019608F, 0.0F, 1.0F)

  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::new(
              white,
              @sprite_render.AlphaMode2d::Opaque,
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(-400.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::new(
              blue,
              @sprite_render.AlphaMode2d::Opaque,
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(-300.0F, 0.0F, 1.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::new(
              green,
              @sprite_render.AlphaMode2d::Opaque,
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(-200.0F, 0.0F, -1.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::new(
              white,
              @sprite_render.AlphaMode2d::Mask(0.5F),
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(200.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::new(
              blue.with_alpha(0.7F),
              @sprite_render.AlphaMode2d::Blend,
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(300.0F, 0.0F, 1.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::new(
              green.with_alpha(0.7F),
              @sprite_render.AlphaMode2d::Blend,
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(400.0F, 0.0F, -1.0F),
      ),
    ),
  )
}
