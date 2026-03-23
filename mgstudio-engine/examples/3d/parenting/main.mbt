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
/// Port of `bevy/examples/3d/parenting.rs`.

///|
struct Rotator {}

///|
let rotator_key : @ecs.ComponentKey[Rotator] = @ecs.register_component(
  debug_name="examples.3d.parenting.Rotator",
)

///|
pub impl @ecs.Component for Rotator with component() {
  rotator_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val
  let cube_handle = mesh_assets
    |> @pbr.add_mesh(@math.Cuboid::new(2.0F, 2.0F, 2.0F))
  let material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
      ),
    )

  let parent = commands.spawn(
    (
      @pbr.Mesh3d::new(cube_handle),
      @pbr.MeshMaterial3d::new(material),
      @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
      Rotator::{  },
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_handle),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 3.0F),
        @hierarchy.Parent::new(parent),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(4.0F, 5.0F, -4.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(5.0F, 10.0F, 10.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotator_system(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query1Filtered[@transform.Transform, @ecs.With[Rotator]],
) -> Unit {
  let delta = 3.0F * time.get().delta_seconds()
  let spin = @math.Quat::from_rotation_x(delta)
  try! query.view(fn(_entity, transform) {
    transform.rotation = transform.rotation.mul(spin).normalize()
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotator_system)))
  .run()
}
