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
const SHADER_PATH : String = "shaders/shader_defs.wgsl"

///|
struct Rotates {}

///|
let rotates_key : @ecs.ComponentKey[Rotates] = @ecs.register_component(
  debug_name="examples.shader.shader_defs.Rotates",
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
  let cube = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.3F, 1.3F, 1.3F))
  let low_steps = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.85F, 0.28F, 0.28F)).with_reflectance(
      0.05F,
    ),
  )
  let high_steps = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.28F, 0.45F, 0.95F)).with_reflectance(
      0.95F,
    ),
  )

  commands.spawn(
    (
      @pbr.Mesh3d::new(cube),
      @pbr.MeshMaterial3d::new(low_steps).with_extension_shader_path(
        Some(SHADER_PATH),
      ),
      Rotates::{  },
      @transform.Transform::from_xyz(-1.6F, 0.8F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Mesh3d::new(cube),
      @pbr.MeshMaterial3d::new(high_steps).with_extension_shader_path(
        Some(SHADER_PATH),
      ),
      Rotates::{  },
      @transform.Transform::from_xyz(1.6F, 0.8F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_100_000.0F, 20.0F, false),
      @transform.Transform::from_xyz(3.0F, 5.0F, 2.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(-2.8F, 2.1F, 5.6F).looking_at(
        @math.Vec3::new(0.0F, 0.4F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
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
    transform.get_ref().val.rotate_y(delta * 0.75F)
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
