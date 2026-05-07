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
priv struct Testbed3State {
  spawned : Array[@core.Entity]
}

///|
let testbed3_state : Ref[Testbed3State] = Ref({ spawned: [] })

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(-30.0F, 24.0F, 70.0F),
    @math.Vec3::new(0.0F, 8.0F, 0.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
  testbed3_spawn_mode(world, 0)
  println("[testbed3] 1: stack, 2: joints, 3: ccd")
}

///|
fn clear_spawned(world : @ecs.World) -> Unit {
  for e in testbed3_state.val.spawned {
    try! world.despawn(e)
  }
  testbed3_state.val.spawned.clear()
}

///|
fn testbed3_spawn_mode(world : @ecs.World, mode : Int) -> Unit {
  clear_spawned(world)
  let ground = @rapier_examples.rapier3d_spawn_ground(
    world,
    @math.Vec3::new(60.0F, 0.8F, 60.0F),
    @math.Vec3::new(0.0F, -0.8F, 0.0F),
  )
  testbed3_state.val.spawned.push(ground)
  match mode {
    0 =>
      for y in 0..<14 {
        for x in 0..<9 {
          let entity = @rapier_examples.rapier3d_spawn_cuboid(
            world,
            @math.Vec3::new(
              (Float::from_int(x) - 4.0F) * 2.2F,
              2.0F + Float::from_int(y) * 2.1F,
              0.0F,
            ),
            @math.Vec3::new(0.9F, 0.9F, 0.9F),
            @rapier_examples.rapier3d_color(x + y),
            Some(@physics3d.RigidBody3d::dynamic()),
          )
          testbed3_state.val.spawned.push(entity)
        }
      }
    1 => {
      let mut previous = ground
      for i in 0..<16 {
        let ball = @rapier_examples.rapier3d_spawn_ball(
          world,
          @math.Vec3::new(0.0F, 2.0F + Float::from_int(i) * 2.0F, 0.0F),
          0.7F,
          @rapier_examples.rapier3d_color(i),
          Some(@physics3d.RigidBody3d::dynamic()),
        )
        let joint = if i == 0 {
          @physics3d.joint3d_spherical(
            @math.Vec3::new(0.0F, 1.2F, 0.0F),
            @math.Vec3::new(0.0F, -1.2F, 0.0F),
          )
        } else {
          @physics3d.joint3d_revolute(
            @math.Vec3::new(0.0F, 1.0F, 0.0F),
            @math.Vec3::new(0.0F, -1.0F, 0.0F),
            @math.Vec3::new(0.0F, 0.0F, 1.0F),
          )
        }
        try! world.set_by_key(
          ball,
          @physics3d.ecs_key_impulse_joint3d,
          @physics3d.ImpulseJoint3d::new(previous, joint),
        )
        previous = ball
        testbed3_state.val.spawned.push(ball)
      }
    }
    _ =>
      for i in 0..<36 {
        let ball = @rapier_examples.rapier3d_spawn_ball(
          world,
          @math.Vec3::new(
            -26.0F + Float::from_int(i % 12) * 4.6F,
            2.0F + Float::from_int(i / 12) * 3.2F,
            Float::from_int(i / 12) * 2.0F,
          ),
          1.0F,
          @rapier_examples.rapier3d_color(i),
          Some(@physics3d.RigidBody3d::dynamic()),
        )
        try! world.set_by_key(
          ball,
          @physics3d.ecs_key_ccd3d,
          @physics3d.Ccd3d::enabled(),
        )
        testbed3_state.val.spawned.push(ball)
      }
  }
}

///|
fn update(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    testbed3_spawn_mode(world, 0)
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    testbed3_spawn_mode(world, 1)
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    testbed3_spawn_mode(world, 2)
  }
}
