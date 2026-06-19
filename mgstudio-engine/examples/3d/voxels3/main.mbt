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
  .add_systems_world(@app.Startup, setup)
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  let extents = 64.0F
  let field_center = extents / 2.0F
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(field_center, 52.0F, field_center + 72.0F),
    @math.Vec3::new(field_center, 5.0F, field_center),
  )
  @rapier_examples.rapier3d_basic_lighting(world)

  let heightfield_scale = @math.Vec3::new(extents, 1.0F, extents)
  let n = 64
  let heights : Array[Float] = []
  for i in 0..<n {
    for j in 0..<n {
      let height_x = @math.sin(Float::from_int(i) / Float::from_int(n) * 10.0F)
      let height_y = @math.cos(Float::from_int(j) / Float::from_int(n) * 10.0F)
      let clamped_x = if height_x < -0.8F {
        -0.8F
      } else if height_x > 0.8F {
        0.8F
      } else {
        height_x
      }
      let clamped_y = if height_y < -0.8F {
        -0.8F
      } else if height_y > 0.8F {
        0.8F
      } else {
        height_y
      }
      let height = clamped_x * clamped_y * 16.0F
      heights.push(height)
    }
  }
  let ground = world.spawn_empty()
  try! world.set_by_key(
    ground,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(field_center, 0.0F, field_center),
  )
  try! world.set_by_key(
    ground,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::fixed(),
  )
  try! world.set_by_key(
    ground,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::heightfield(heights, n, n, heightfield_scale),
    ),
  )

  for i in 0..<12 {
    for j in 0..<4 {
      for k in 0..<12 {
        let kind = (i + j + k) % 3
        let y = 10.0F + Float::from_int(j) * 2.0F
        let position = @math.Vec3::new(
          Float::from_int(i) * extents / 12.0F,
          y,
          Float::from_int(k) * extents / 12.0F,
        )
        match kind {
          0 =>
            ignore(
              @rapier_examples.rapier3d_spawn_ball(
                world,
                position,
                0.5F,
                @rapier_examples.rapier3d_color(i + j + k),
                Some(@physics3d.RigidBody3d::dynamic()),
              ),
            )
          1 =>
            ignore(
              @rapier_examples.rapier3d_spawn_cuboid(
                world,
                position,
                @math.Vec3::splat(0.5F),
                @rapier_examples.rapier3d_color(i + j + k),
                Some(@physics3d.RigidBody3d::dynamic()),
              ),
            )
          _ =>
            ignore(
              @rapier_examples.rapier3d_spawn_capsule_y(
                world,
                position,
                0.5F,
                0.35F,
                @rapier_examples.rapier3d_color(i + j + k),
                Some(@physics3d.RigidBody3d::dynamic()),
              ),
            )
        }
      }
    }
  }
}
