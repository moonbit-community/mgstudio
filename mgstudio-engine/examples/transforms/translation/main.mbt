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
pub struct Movable {
  spawn : @math.Vec3
  max_distance : Float
  mut speed : Float
}

///|
let movable_component_key : @ecs.ComponentKey[Movable] = @ecs.register_component(
  debug_name="examples.transforms.translation.Movable",
)

///|
impl @ecs.Component for Movable with component() {
  movable_component_key
}

///|
fn Movable::new(spawn : @math.Vec3) -> Movable {
  { spawn, max_distance: 5.0F, speed: 2.0F }
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let entity_spawn = @math.Vec3::zero()
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          meshes.peek() |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F)),
        ),
        @pbr.MeshMaterial3d::new(
          materials.peek() |> @pbr.add_material(@sprite.Color::white()),
        ),
        @transform.Transform::from_translation(entity_spawn),
        Movable::new(entity_spawn),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 10.0F, 20.0F).looking_at(
          entity_spawn,
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::default(),
        @transform.Transform::from_xyz(3.0F, 3.0F, 3.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn move_cube(
  commands : @app.Commands,
  cubes : @ecs.Query[
    (@ecs.Comp[Movable], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_secs()
  try! cubes.view(fn(entity, data) {
    let (movable, transform) = data
    let next_movable = movable.value()
    let current_transform = transform.value()
    if movable.value().spawn.sub(current_transform.translation).length() >
      movable.value().max_distance {
      next_movable.speed = -next_movable.speed
    }

    transform.modify(fn(value) {
      let direction = value.local_x()
      value.translation = value.translation.add(
        direction.mul_scalar(next_movable.speed * delta),
      )
    })
    if next_movable.speed != movable.value().speed {
      commands.entity(entity).insert_component(next_movable)
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(move_cube)))
  .run()
}
