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
const SHADER_ASSET_PATH : String = "shaders/fullscreen_effect.wgsl"

///|
fn setup(
  commands : @app.Commands,
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cube_mesh = mesh_assets.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.5F, 1.5F, 1.5F))
  let cube_material = material_assets.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.8F, 0.7F, 0.6F)),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @post_process.CustomPostProcess3d::new(SHADER_ASSET_PATH)
        .with_enabled(true)
        .with_intensity(0.005F),
        @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(cube_material),
        @transform.Transform::identity(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 1_000.0F, false),
        @transform.Transform::from_xyz(2.0F, 4.0F, 2.0F).looking_at(
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
