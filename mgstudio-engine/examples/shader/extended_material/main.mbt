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
const SHADER_PATH : String = "shaders/extended_material.wgsl"

///|
struct Rotate {}

///|
let rotate_key : @ecs.ComponentKey[Rotate] = @ecs.register_component(
  debug_name="examples.shader.extended_material.Rotate",
)

///|
pub impl @ecs.Component for Rotate with component() {
  rotate_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let sphere_mesh = meshes.peek() |> @pbr.add_mesh(@math.Sphere::new(1.0F))
  let material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::srgb(0.92F, 0.25F, 0.25F),
      )
      .with_reflectance(0.4F)
      .with_perceptual_roughness(0.35F),
    )

  commands.spawn(
    (
      @pbr.Mesh3d::new(sphere_mesh),
      @pbr.MeshMaterial3d::new(material)
      .with_extension_shader_path(Some(SHADER_PATH))
      .with_extension_tag(1),
      @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.DirectionalLight::default(),
      Rotate::{  },
      @transform.Transform::from_xyz(1.0F, 1.0F, 1.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn rotate_light(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Rotate]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate_y(delta) })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_light)))
  .run()
}
