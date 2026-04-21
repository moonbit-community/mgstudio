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
const SHADER_PATH : String = "shaders/custom_phase_item.wgsl"

///|
struct CustomPhase {
  phase : Float
}

///|
let custom_phase_key : @ecs.ComponentKey[CustomPhase] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_phase_item.CustomPhase",
)

///|
pub impl @ecs.Component for CustomPhase with component() {
  custom_phase_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh = meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(0.6F, 0.6F, 0.6F))
  for i in 0..<48 {
    let phase = Float::from_int(i) * 0.21F
    let radius = 2.2F + Float::from_int(i % 4) * 0.35F
    let angle = phase
    let material = materials
      .peek()
      .add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(0.62F, 0.72F, 0.96F),
        ),
      )
    commands.spawn(
      (
        CustomPhase::{ phase, },
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material)
        .with_extension_shader_path(Some(SHADER_PATH))
        .with_extension_tag(i % 3),
        @transform.Transform::from_xyz(
          @math.cos(angle) * radius,
          @math.sin(Float::from_int(i) * 0.13F) * 0.8F,
          @math.sin(angle) * radius,
        ),
      ),
    )
    |> ignore
  }
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_600_000.0F, 36.0F, false),
      @transform.Transform::from_xyz(0.0F, 7.0F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 3.5F, 10.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn animate_custom_phase(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Comp[CustomPhase], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, data) {
    let (phase, transform) = data
    let angle = elapsed * 0.35F + phase.value().phase
    let radius = 2.4F + @math.sin(phase.value().phase * 1.7F) * 0.3F
    transform.modify(fn(value) {
      value.translation.x = @math.cos(angle) * radius
      value.translation.z = @math.sin(angle) * radius
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_custom_phase)),
  )
  .run()
}
