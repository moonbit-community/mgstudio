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
const SHADER_PATH : String = "shaders/custom_stencil.wgsl"

///|
struct PhaseA {}

///|
struct PhaseB {}

///|
let phase_a_key : @ecs.ComponentKey[PhaseA] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_render_phase.PhaseA",
)

///|
let phase_b_key : @ecs.ComponentKey[PhaseB] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_render_phase.PhaseB",
)

///|
pub impl @ecs.Component for PhaseA with component() {
  phase_a_key
}

///|
pub impl @ecs.Component for PhaseB with component() {
  phase_b_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh = meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(0.8F, 0.8F, 0.8F))
  for i in 0..<16 {
    let x = Float::from_int(i % 4) - 1.5F
    let z = Float::from_int(i / 4) - 1.5F
    let material = materials
      .peek()
      .add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(0.95F, 0.95F, 0.98F),
        ).with_perceptual_roughness(0.4F),
      )
    if i % 2 == 0 {
      commands.spawn(
        (
          PhaseA::{  },
          @pbr.Mesh3d::new(mesh),
          @pbr.MeshMaterial3d::new(material)
          .with_extension_shader_path(Some(SHADER_PATH))
          .with_extension_tag(0),
          @transform.Transform::from_xyz(x * 1.4F, 0.6F, z * 1.4F),
        ),
      )
      |> ignore
    } else {
      commands.spawn(
        (
          PhaseB::{  },
          @pbr.Mesh3d::new(mesh),
          @pbr.MeshMaterial3d::new(material)
          .with_extension_shader_path(Some(SHADER_PATH))
          .with_extension_tag(1),
          @transform.Transform::from_xyz(x * 1.4F, 0.6F, z * 1.4F),
        ),
      )
      |> ignore
    }
  }
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_400_000.0F, 30.0F, false),
      @transform.Transform::from_xyz(0.0F, 7.0F, 4.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 5.0F, 10.0F).looking_at(
        @math.Vec3::new(0.0F, 0.5F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn animate_phase_a(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[PhaseA]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.translation.y = 0.6F + @math.sin(elapsed * 1.2F) * 0.3F
    })
  })
}

///|
fn animate_phase_b(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[PhaseB]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.translation.y = 0.6F + @math.cos(elapsed * 1.2F) * 0.3F
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_phase_a)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_phase_b)))
  .run()
}
