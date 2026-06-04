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
  .add_systems(@app.Startup, @app.system_config_param3(setup))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::Camera2d()))

  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(
          meshes
          .peek()
          .add(
            @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::Rectangle()).to_mesh(),
          ),
        ),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::from_color(
              @sprite.Color::srgba(0.5019608F, 0.0F, 0.5019608F, 1.0F),
            ),
          ),
        ),
        @transform.Transform::identity().with_scale(
          @math.Vec3::new(128.0F, 128.0F, 1.0F),
        ),
      ),
    ),
  )
}
