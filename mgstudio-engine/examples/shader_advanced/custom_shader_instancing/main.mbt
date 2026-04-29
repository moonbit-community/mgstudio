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
const SHADER_PATH : String = "shaders/instancing.wgsl"

///|
const INSTANCE_COUNT : Int = 256

///|
struct InstancePhase {
  index : Int
}

///|
let instance_phase_key : @ecs.ComponentKey[InstancePhase] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_shader_instancing.InstancePhase",
)

///|
pub impl @ecs.Component for InstancePhase with component() {
  instance_phase_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_handle = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(0.18F, 0.18F, 0.18F))
  let material_handle = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.95F, 0.96F, 1.0F)),
    )

  for i in 0..<INSTANCE_COUNT {
    let x = Float::from_int(i % 16) - 7.5F
    let y = Float::from_int(i / 16) - 7.5F
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh_handle),
        @pbr.MeshMaterial3d::new(material_handle).with_extension_fragment_shader_path(
          Some(SHADER_PATH),
        ),
        InstancePhase::{ index: i },
        @transform.Transform::from_xyz(x * 0.22F, y * 0.22F, 0.0F),
      ),
    )
    |> ignore
  }

  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 5.8F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn animate_instances(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Comp[InstancePhase], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, data) {
    let (phase, transform) = data
    let value = Float::from_int(phase.value().index) * 0.07F
    transform.modify(fn(current) {
      current.translation.z = 0.75F * @math.sin(elapsed + value)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_instances)))
  .run()
}
