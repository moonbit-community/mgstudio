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
const SHADER_PATH : String = "shaders/gpu_readback.wgsl"

///|
const SAMPLE_COUNT : Int = 36

///|
struct ReadbackSample {
  phase : Float
}

///|
let readback_sample_key : @ecs.ComponentKey[ReadbackSample] = @ecs.register_component(
  debug_name="examples.shader.gpu_readback.ReadbackSample",
)

///|
pub impl @ecs.Component for ReadbackSample with component() {
  readback_sample_key
}

///|
struct ReadbackState {
  average_height : Float
}

///|
let readback_state_key : @ecs.ResourceKey[ReadbackState] = @ecs.register_resource(
  debug_name="examples.shader.gpu_readback.ReadbackState",
)

///|
pub impl @app.Resource for ReadbackState with resource() {
  readback_state_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  commands.insert_resource(ReadbackState::{ average_height: 0.0F })

  let mesh = meshes.peek()
    |> @pbr.add_mesh(@math.Cuboid::new(0.25F, 0.25F, 0.25F))
  let material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.26F, 0.4F, 0.9F)),
    )
  for i in 0..<SAMPLE_COUNT {
    let x = Float::from_int(i % 12) - 5.5F
    let y = Float::from_int(i / 12) - 1.0F
    let phase = Float::from_int(i) * 0.31F
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material).with_extension_fragment_shader_path(
          Some(SHADER_PATH),
        ),
        ReadbackSample::{ phase, },
        @transform.Transform::from_xyz(x * 0.45F, y * 0.45F, 0.0F),
      ),
    )
    |> ignore
  }
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_000_000.0F, 30.0F, false),
      @transform.Transform::from_xyz(0.0F, 5.0F, 7.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn animate_samples(
  time : @app.Res[@time.Time[Unit]],
  samples : @ecs.Query[
    (@ecs.Comp[ReadbackSample], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! samples.view(fn(_entity, data) {
    let (sample, transform) = data
    transform.modify(fn(value) {
      value.translation.z = @math.sin(elapsed + sample.value().phase) * 0.8F
    })
  })
}

///|
fn emulate_gpu_readback(
  samples : @ecs.Query[
    @ecs.Comp[@transform.Transform],
    @ecs.With[ReadbackSample],
  ],
  readback_state : @app.ResMut[ReadbackState],
) -> Unit {
  let mut total = 0.0F
  let mut count = 0
  try! samples.view(fn(_entity, transform) {
    total = total + transform.value().translation.z
    count = count + 1
  })
  if count > 0 {
    readback_state.set(ReadbackState::{
      average_height: total / Float::from_int(count),
    })
  }
}

///|
fn tint_from_readback(
  readback_state : @app.Res[ReadbackState],
  mesh_materials : @ecs.Query[@ecs.Comp[@pbr.MeshMaterial3d], @ecs.All],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let value = 0.5F + readback_state.get().average_height * 0.4F
  try! mesh_materials.view(fn(_entity, mesh_material) {
    let handle = mesh_material.value().material
    guard materials.peek().get(handle) is Some(material) else { return }
    let updated = material.with_base_color(
      @sprite.Color::srgb(0.18F + value * 0.3F, 0.28F + value * 0.35F, 0.7F),
    )
    materials.peek().set(handle, updated) |> ignore
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(animate_samples)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(emulate_gpu_readback)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param3(tint_from_readback)))
  .run()
}
