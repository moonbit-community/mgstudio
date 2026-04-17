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
const SHADER_PATH : String = "shaders/animate_shader.wgsl"

///|
struct AnimatedMaterial {}

///|
let animated_material_key : @ecs.ComponentKey[AnimatedMaterial] = @ecs.register_component(
  debug_name="examples.shader.animate_shader.AnimatedMaterial",
)

///|
pub impl @ecs.Component for AnimatedMaterial with component() {
  animated_material_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cube_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.2F, 1.2F, 1.2F))
  let material_handle = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.72F, 0.95F)),
  )

  commands.spawn(
    (
      @pbr.Mesh3d::new(cube_mesh),
      @pbr.MeshMaterial3d::new(material_handle).with_extension_shader_path(
        Some(SHADER_PATH),
      ),
      AnimatedMaterial::{  },
      @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
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
fn animate_material_color(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    @ecs.Comp[@pbr.MeshMaterial3d],
    @ecs.With[AnimatedMaterial],
  ],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, component) {
    let handle = component.value().material
    guard materials.get_ref().val.get(handle) is Some(material) else { return }
    let red = 0.45F + 0.4F * @math.sin(elapsed * 1.1F)
    let green = 0.5F + 0.35F * @math.sin(elapsed * 0.8F + 1.7F)
    let blue = 0.6F + 0.3F * @math.sin(elapsed * 1.5F + 3.1F)
    let updated = material.with_base_color(
      @sprite.Color::srgb(red, green, blue),
    )
    materials.get_ref().val.set(handle, updated) |> ignore
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(animate_material_color)),
  )
  .run()
}
