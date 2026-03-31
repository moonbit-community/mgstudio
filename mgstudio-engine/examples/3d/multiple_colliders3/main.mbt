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
    @math.Vec3::new(-30.0F, 30.0F, 100.0F),
    @math.Vec3::new(0.0F, 10.0F, 0.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(50.0F, 0.1F, 50.0F),
      @math.Vec3::new(0.0F, -0.1F, 0.0F),
    ),
  )

  let num = 4
  let rad = 0.2F
  let shift = rad * 5.0F
  let centerx = shift * Float::from_int(num / 2)
  let centery = shift / 2.0F
  let centerz = shift * Float::from_int(num / 2)
  let mut offset = -Float::from_int(num) * rad * 1.5F
  let mut color = 0
  for j in 0..<20 {
    for i in 0..<num {
      for k in 0..<num {
        let x = Float::from_int(i) * shift * 5.0F - centerx + offset
        let y = Float::from_int(j) * shift * 5.0F + centery + 3.0F
        let z = Float::from_int(k) * shift * 2.0F - centerz + offset
        color = color + 1

        let body = @rapier_examples.rapier3d_spawn_body_mesh(
          world,
          @pbr.mesh3d_geometry_cuboid(rad * 10.0F, rad * 20.0F, rad * 20.0F),
          @rapier_examples.rapier3d_color(color),
          @transform.Transform::from_xyz(x, y, z),
          Some(@physics3d.RigidBody3d::dynamic()),
          None,
        )

        let child0 = world.spawn_empty()
        try! world.set_by_key(
          child0,
          @transform.ecs_key_transform,
          @transform.Transform::from_xyz(rad * 10.0F, rad * 10.0F, 0.0F),
        )
        try! world.set_by_key(
          child0,
          @physics3d.ecs_key_collider_parent3d,
          @physics3d.ColliderParent3d::new(body),
        )
        try! world.set_by_key(
          child0,
          @physics3d.ecs_key_collider3d,
          @physics3d.Collider3d::new(
            @physics3d.ColliderShape3d::cuboid(rad, rad * 10.0F, rad),
          ),
        )

        let child1 = world.spawn_empty()
        try! world.set_by_key(
          child1,
          @transform.ecs_key_transform,
          @transform.Transform::from_xyz(-rad * 10.0F, rad * 10.0F, 0.0F),
        )
        try! world.set_by_key(
          child1,
          @physics3d.ecs_key_collider_parent3d,
          @physics3d.ColliderParent3d::new(body),
        )
        try! world.set_by_key(
          child1,
          @physics3d.ecs_key_collider3d,
          @physics3d.Collider3d::new(
            @physics3d.ColliderShape3d::cuboid(rad, rad * 10.0F, rad),
          ),
        )
      }
    }
    offset -= 0.05F * rad * Float::from_int(num - 1)
  }
}
