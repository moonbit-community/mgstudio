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
      @math.Vec3::new(200.1F, 0.1F, 200.1F),
      @math.Vec3::new(0.0F, -0.1F, 0.0F),
    ),
  )

  let num = 8
  let rad = 1.0F
  let shift = rad * 3.0F
  let centerx = shift * Float::from_int(num / 2)
  let centery = shift / 2.0F
  let centerz = shift * Float::from_int(num / 2)
  let mut offset = -Float::from_int(num) * shift * 0.5F
  for j in 0..<20 {
    for i in 0..<num {
      for k in 0..<num {
        let x = Float::from_int(i) * shift - centerx + offset
        let y = Float::from_int(j) * shift + centery + 3.0F
        let z = Float::from_int(k) * shift - centerz + offset
        let color = @rapier_examples.rapier3d_color(i + j + k)
        ignore(
          @rapier_examples.rapier3d_spawn_cuboid(
            world,
            @math.Vec3::new(x, y, z),
            @math.Vec3::splat(rad),
            color,
            Some(@physics3d.RigidBody3d::dynamic()),
          ),
        )
      }
    }
    offset -= 0.05F * rad * Float::from_int(num - 1)
  }
}
