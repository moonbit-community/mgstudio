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
let player_entity : Ref[@core.Entity?] = Ref::new(None)

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.FixedUpdate, @app.system(controller_input))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_basic_lighting(world)
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(0.0F, 5.0F, 8.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )

  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(12.0F, 0.5F, 12.0F),
      @math.Vec3::new(0.0F, -0.5F, 0.0F),
    ),
  )

  let player = @rapier_examples.rapier3d_spawn_capsule_y(
    world,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    0.75F,
    0.35F,
    @sprite.Color::new(0.95F, 0.72F, 0.22F, 1.0F),
    Some(@physics3d.RigidBody3d::dynamic()),
  )
  try! world.set_by_key(
    player,
    @physics3d.ecs_key_kinematic_character_controller3d,
    @physics3d.KinematicCharacterController3d::default(),
  )
  player_entity.val = Some(player)
  println("[character_controller3] WASD to move the capsule controller")
}

///|
fn controller_input(world : @ecs.World) -> Unit {
  guard player_entity.val is Some(player) else { return }
  guard (try! world.get_by_key(
      player, @physics3d.ecs_key_kinematic_character_controller3d,
    ))
    is Some(kcc) else {
    return
  }
  let dt = @time.time_fixed_timestep_seconds()
  let speed = 4.0F
  let mut axis = @math.Vec3::zero()
  if @input.key_pressed(@window.KeyCode::KeyA) {
    axis = @math.Vec3::new(axis.x - 1.0F, axis.y, axis.z)
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    axis = @math.Vec3::new(axis.x + 1.0F, axis.y, axis.z)
  }
  if @input.key_pressed(@window.KeyCode::KeyW) {
    axis = @math.Vec3::new(axis.x, axis.y, axis.z - 1.0F)
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    axis = @math.Vec3::new(axis.x, axis.y, axis.z + 1.0F)
  }
  if axis.x == 0.0F && axis.z == 0.0F {
    return
  }
  let len = Float::sqrt(axis.x * axis.x + axis.z * axis.z)
  let dir = if len > 0.0F {
    @math.Vec3::new(axis.x / len, 0.0F, axis.z / len)
  } else {
    @math.Vec3::zero()
  }
  try! (world.replace(
    player,
    @physics3d.ecs_key_kinematic_character_controller3d,
    kcc.add_translation(
      @math.Vec3::new(dir.x * speed * dt, 0.0F, dir.z * speed * dt),
    ),
  )
  |> ignore)
}
