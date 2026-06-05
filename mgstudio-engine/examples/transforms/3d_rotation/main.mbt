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
pub struct Rotatable {
  speed : Float
}

///|
let rotatable_component_key : @ecs.ComponentKey[Rotatable] = @ecs.register_component(
  debug_name="examples.transforms.3d_rotation.Rotatable",
)

///|
impl @ecs.Component for Rotatable with fn component() {
  rotatable_component_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(meshes) {
            meshes |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
          }),
        ),
        @pbr.MeshMaterial3d::new(
          materials
          .peek()
          .add(@pbr.StandardMaterial::from_color(@color.Color::white())),
        ),
        @transform.Transform::from_translation(@math.Vec3::zero()),
        Rotatable::{ speed: 0.3F },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::DirectionalLight(),
        @transform.Transform::from_xyz(3.0F, 3.0F, 3.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate_cube(
  cubes : @ecs.Query[
    (@ecs.Read[Rotatable], @ecs.Write[@transform.Transform]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs()
  try! cubes.view(fn(_entity, data) {
    let (cube, transform) = data
    transform.modify(fn(value) {
      value.rotate_y(cube.value().speed * (@math.pi() * 2.0F) * delta)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems(@app.Startup, @app.system_config_param3(setup))
  .add_systems(@app.Update, @app.system_config_param2(rotate_cube))
  .run()
}
