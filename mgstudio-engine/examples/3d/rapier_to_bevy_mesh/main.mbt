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
    @math.Vec3::new(-30.0F, 30.0F, 90.0F),
    @math.Vec3::new(0.0F, 8.0F, 0.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(50.0F, 0.5F, 50.0F),
      @math.Vec3::new(0.0F, -0.5F, 0.0F),
    ),
  )

  ignore(
    @rapier_examples.rapier3d_spawn_cuboid(
      world,
      @math.Vec3::new(-6.0F, 2.0F, 0.0F),
      @math.Vec3::new(1.0F, 1.0F, 1.0F),
      @sprite.Color::new(0.90F, 0.60F, 0.20F, 1.0F),
      Some(@physics3d.RigidBody3d::dynamic()),
    ),
  )
  ignore(
    @rapier_examples.rapier3d_spawn_ball(
      world,
      @math.Vec3::new(-2.0F, 2.0F, 0.0F),
      1.0F,
      @sprite.Color::new(0.20F, 0.75F, 0.95F, 1.0F),
      Some(@physics3d.RigidBody3d::dynamic()),
    ),
  )
  ignore(
    @rapier_examples.rapier3d_spawn_capsule_y(
      world,
      @math.Vec3::new(2.0F, 2.0F, 0.0F),
      1.0F,
      0.5F,
      @sprite.Color::new(0.95F, 0.72F, 0.22F, 1.0F),
      Some(@physics3d.RigidBody3d::dynamic()),
    ),
  )

  let cylinder = @pbr.mesh3d_geometry_cylinder(@math.Cylinder::new(0.6F, 2.0F))
  ignore(
    @rapier_examples.rapier3d_spawn_body_mesh(
      world,
      cylinder,
      @sprite.Color::new(0.58F, 0.78F, 0.28F, 1.0F),
      @transform.Transform::from_xyz(6.0F, 2.0F, 0.0F),
      Some(@physics3d.RigidBody3d::dynamic()),
      Some(
        @physics3d.Collider3d::new(
          @physics3d.ColliderShape3d::cylinder(1.0F, 0.6F),
        ),
      ),
    ),
  )
}
