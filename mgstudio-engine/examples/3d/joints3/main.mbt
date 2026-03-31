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
    @math.Vec3::new(0.0F, 6.0F, 10.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(16.0F, 0.5F, 16.0F),
      @math.Vec3::new(0.0F, -0.5F, 0.0F),
    ),
  )

  let a = @rapier_examples.rapier3d_spawn_ball(
    world,
    @math.Vec3::new(-1.5F, 2.0F, 0.0F),
    0.4F,
    @sprite.Color::new(0.90F, 0.60F, 0.20F, 1.0F),
    Some(@physics3d.RigidBody3d::dynamic()),
  )
  let b = @rapier_examples.rapier3d_spawn_ball(
    world,
    @math.Vec3::new(1.5F, 2.0F, 0.0F),
    0.4F,
    @sprite.Color::new(0.20F, 0.75F, 0.95F, 1.0F),
    Some(@physics3d.RigidBody3d::dynamic()),
  )
  try! world.set_by_key(
    b,
    @physics3d.ecs_key_impulse_joint3d,
    @physics3d.ImpulseJoint3d::new(
      a,
      @physics3d.joint3d_fixed(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
  try! world.set_by_key(
    a,
    @physics3d.ecs_key_velocity3d,
    @physics3d.Velocity3d::new(
      @math.Vec3::new(0.0F, 0.0F, 2.5F),
      @math.Vec3::zero(),
    ),
  )
  try! world.set_by_key(
    b,
    @physics3d.ecs_key_velocity3d,
    @physics3d.Velocity3d::new(
      @math.Vec3::new(0.0F, 0.0F, -2.5F),
      @math.Vec3::zero(),
    ),
  )
  println("[joints3] two dynamic bodies are connected by a fixed joint")
}
