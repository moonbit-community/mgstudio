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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(10.0F, 3.0F, 0.0F),
    @math.Vec3::new(0.0F, 3.0F, 0.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)

  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(5.0F, 0.1F, 5.0F),
      @math.Vec3::new(0.0F, -0.1F, 0.0F),
    ),
  )

  let x_only = @rapier_examples.rapier3d_spawn_cuboid(
    world,
    @math.Vec3::new(0.0F, 3.0F, 0.0F),
    @math.Vec3::new(0.2F, 0.6F, 2.0F),
    @sprite.Color::new(0.95F, 0.55F, 0.20F, 1.0F),
    Some(@physics3d.RigidBody3d::dynamic()),
  )
  try! world.set_by_key(
    x_only,
    @physics3d.ecs_key_locked_axes3d,
    @physics3d.LockedAxes3d::new(false, false, false, false, true, true),
  )

  let no_rotation = @rapier_examples.rapier3d_spawn_cuboid(
    world,
    @math.Vec3::new(0.0F, 5.0F, 0.0F),
    @math.Vec3::new(0.6F, 0.4F, 0.4F),
    @sprite.Color::new(0.20F, 0.70F, 0.95F, 1.0F),
    Some(@physics3d.RigidBody3d::dynamic()),
  )
  try! world.set_by_key(
    no_rotation,
    @physics3d.ecs_key_locked_axes3d,
    @physics3d.LockedAxes3d::new(false, false, false, true, true, true),
  )
}
