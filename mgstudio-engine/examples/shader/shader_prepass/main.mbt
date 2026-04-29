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
const SHADER_PATH : String = "shaders/custom_material.wgsl"

///|
struct Rotates {}

///|
let rotates_key : @ecs.ComponentKey[Rotates] = @ecs.register_component(
  debug_name="examples.shader.shader_prepass.Rotates",
)

///|
pub impl @ecs.Component for Rotates with component() {
  rotates_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh = meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(1.8F, 1.8F, 1.8F))
  let material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.7F, 0.85F, 1.0F)).with_reflectance(
        0.4F,
      ),
    )

  commands.spawn(
    (
      @pbr.Mesh3d::new(mesh),
      @pbr.MeshMaterial3d::new(material).with_extension_fragment_shader_path(
        Some(SHADER_PATH),
      ),
      Rotates::{  },
      @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @pbr.DepthPrepass::default(),
      @pbr.NormalPrepass::default(),
      @pbr.MotionVectorPrepass::default(),
      @transform.Transform::from_xyz(-2.6F, 2.6F, 5.4F).looking_at(
        @math.Vec3::new(0.0F, 0.5F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_500_000.0F, 30.0F, false),
      @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
    ),
  )
  |> ignore
}

///|
fn rotate(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Rotates]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate_y(delta * 0.9F) })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate)))
  .run()
}
