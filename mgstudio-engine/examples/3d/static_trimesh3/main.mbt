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
priv struct BallState {
  mut balls_spawned : Int
  max_balls : Int
  mut timer : Float
}

///|
let ball_state : Ref[BallState] = Ref({
  balls_spawned: 0,
  max_balls: 10,
  timer: 2.0F,
})

///|
const TAU : Float = 6.283185307179586F

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup_graphics))
  .add_systems(@app.Startup, @app.system(setup_physics))
  .add_systems(@app.Update, @app.system(ball_spawner))
  .run()
}

///|
fn setup_graphics(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(-15.0F, 8.0F, 15.0F),
    @math.Vec3::new(-5.0F, 0.0F, 5.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
}

///|
fn setup_physics(world : @ecs.World) -> Unit {
  ball_state.val.balls_spawned = 0

  let ramp_vertices : Array[@math.Vec3] = []
  let ramp_indices : Array[(Int, Int, Int)] = []
  let segments = 32
  let ramp_size = @math.Vec3::new(10.0F, 1.0F, 1.0F)
  for i in 0..<=segments {
    let t = Float::from_int(i) / Float::from_int(segments)
    let x = t * ramp_size.x
    let y = (-@math.cos(t * TAU / 2.0F) + 1.0F) * ramp_size.y / 2.0F
    ramp_vertices.push(@math.Vec3::new(x, y, -ramp_size.z / 2.0F))
    ramp_vertices.push(@math.Vec3::new(x, y, ramp_size.z / 2.0F))
  }
  for i in 0..<segments {
    ramp_indices.push((2 * i, 2 * i + 1, 2 * i + 2))
    ramp_indices.push((2 * i + 2, 2 * i + 1, 2 * i + 3))
  }
  let ramp = world.spawn_empty()
  try! world.set_by_key(
    ramp,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::fixed(),
  )
  try! world.set_by_key(
    ramp,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::trimesh(ramp_vertices, ramp_indices),
    ),
  )

  let bowl_vertices : Array[@math.Vec3] = []
  let bowl_indices : Array[(Int, Int, Int)] = []
  let bowl_segments = 32
  let bowl_size = @math.Vec3::new(10.0F, 3.0F, 10.0F)
  for ix in 0..<=bowl_segments {
    for iz in 0..<=bowl_segments {
      let shifted_z = (
          Float::from_int(iz) / Float::from_int(bowl_segments) - 0.5F
        ) *
        2.0F
      let shifted_x = (
          Float::from_int(ix) / Float::from_int(bowl_segments) - 0.5F
        ) *
        2.0F
      let radius = @math.sqrt(shifted_z * shifted_z + shifted_x * shifted_x)
      let clamped_radius = if radius > 1.0F { 1.0F } else { radius }
      let x = shifted_x * bowl_size.x / 2.0F
      let z = shifted_z * bowl_size.z / 2.0F
      let y = @math.sin((clamped_radius - 0.5F) * TAU / 2.0F) *
        bowl_size.y /
        2.0F
      bowl_vertices.push(@math.Vec3::new(x, y, z))
    }
  }
  for ix in 0..<bowl_segments {
    for iz in 0..<bowl_segments {
      let row0 = ix * (bowl_segments + 1)
      let row1 = (ix + 1) * (bowl_segments + 1)
      bowl_indices.push((row0 + iz, row0 + iz + 1, row1 + iz))
      bowl_indices.push((row1 + iz, row0 + iz + 1, row1 + iz + 1))
    }
  }
  let bowl = world.spawn_empty()
  try! world.set_by_key(
    bowl,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(
      -bowl_size.x / 2.0F,
      -bowl_size.y / 2.0F,
      bowl_size.z / 2.0F - ramp_size.z / 2.0F,
    ),
  )
  try! world.set_by_key(
    bowl,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::fixed(),
  )
  try! world.set_by_key(
    bowl,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::trimesh(bowl_vertices, bowl_indices),
    ),
  )
}

///|
fn ball_spawner(world : @ecs.World) -> Unit {
  if ball_state.val.balls_spawned >= ball_state.val.max_balls {
    return
  }
  let dt = @time.time_real_delta_seconds()
  ball_state.val.timer = ball_state.val.timer - dt
  if ball_state.val.timer > 0.0F {
    return
  }
  ignore(
    @rapier_examples.rapier3d_spawn_ball(
      world,
      @math.Vec3::new(9.0F, 3.0F, 0.0F),
      0.3F,
      @rapier_examples.rapier3d_color(ball_state.val.balls_spawned),
      Some(@physics3d.RigidBody3d::dynamic()),
    ),
  )
  ball_state.val.balls_spawned = ball_state.val.balls_spawned + 1
  ball_state.val.timer = 2.0F
}
