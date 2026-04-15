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
const SHADER_ASSET_PATH : String = "shaders/custom_postprocess_3d.wgsl"

///|
struct Rotates {}

///|
let rotates_key : @ecs.ComponentKey[Rotates] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_post_processing.Rotates",
)

///|
pub impl @ecs.Component for Rotates with component() {
  rotates_key
}

///|
fn setup(
  commands : @app.Commands,
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let plane_mesh = mesh_assets.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(8.0F, 8.0F)),
  )
  let cube_mesh = mesh_assets.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.8F, 1.8F, 1.8F))
  let plane_material = material_assets.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.2F, 0.22F, 0.24F)),
  )
  let cube_material = material_assets.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.95F, 0.8F, 0.25F))
    .with_reflectance(0.35F)
    .with_perceptual_roughness(0.7F),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::identity(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(cube_material),
        Rotates::{  },
        @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(@sprite.Color::white(), 1_300_000.0F, 30.0F, false),
        @transform.Transform::from_xyz(3.0F, 7.0F, 3.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @post_process.CustomPostProcess3d::new(SHADER_ASSET_PATH).with_enabled(
          true,
        ),
        @transform.Transform::from_xyz(-3.0F, 3.0F, 8.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate_cube(
  time : @app.Res[@time.Time[Unit]],
  cube_query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Rotates]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! cube_query.view(fn(_entity, transform) {
    let value = transform.get_ref()
    value.val.rotation = value.val.rotation
      .mul(@math.Quat::from_rotation_y(delta * 0.95F))
      .normalize()
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cube)))
  .run()
}
