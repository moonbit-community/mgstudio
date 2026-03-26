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
const SHADER_PATH : String = "shaders/custom/specialized_mesh_pipeline_3d.wgsl"

///|
struct Spin {}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.shader_advanced.specialized_mesh_pipeline.Spin",
)

///|
pub impl @ecs.Component for Spin with component() {
  spin_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cube = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.1F, 1.1F, 1.1F))
  let sphere = meshes.get_ref().val |> @pbr.add_mesh(@math.Sphere::new(0.7F))
  let matte = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.82F, 0.24F, 0.3F)).with_perceptual_roughness(
      0.95F,
    ),
  )
  let glossy = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.2F, 0.38F, 0.95F)).with_perceptual_roughness(
      0.15F,
    ),
  )

  commands.spawn(
    (
      @pbr.Mesh3d::new(cube),
      @pbr.MeshMaterial3d::new(matte)
      .with_extension_shader_path(Some(SHADER_PATH))
      .with_extension_tag(10)
      .with_extension_disable_shadows(true),
      Spin::{  },
      @transform.Transform::from_xyz(-1.5F, 0.7F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Mesh3d::new(sphere),
      @pbr.MeshMaterial3d::new(glossy)
      .with_extension_shader_path(Some(SHADER_PATH))
      .with_extension_tag(20)
      .with_extension_disable_shadows(false),
      Spin::{  },
      @transform.Transform::from_xyz(1.5F, 0.7F, 0.0F),
    ),
  )
  |> ignore
  let floor = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(8.0F, 8.0F)),
  )
  let floor_mat = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.2F, 0.22F, 0.26F)),
  )
  commands.spawn(
    (
      @pbr.Mesh3d::new(floor),
      @pbr.MeshMaterial3d::new(floor_mat),
      @transform.Transform::identity(),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_300_000.0F, 30.0F, false),
      @transform.Transform::from_xyz(4.0F, 7.0F, 4.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(-3.0F, 2.7F, 6.3F).looking_at(
        @math.Vec3::new(0.0F, 0.6F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn rotate(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Spin]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.get_ref().val.rotate_y(delta * 0.8F)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate)))
  .run()
}
