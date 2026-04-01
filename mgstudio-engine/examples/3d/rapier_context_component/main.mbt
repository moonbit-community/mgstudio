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
  .add_systems(@app.Startup, @app.system(setup_physics))
  .add_systems(@app.Startup, @app.system(setup_graphics))
  .add_systems(
    @app.PostUpdate,
    @app.system(@app.system_param2(display_nb_colliders)).after(
      @physics3d.physics3d_set_writeback,
    ),
  )
  .run()
}

///|
fn display_nb_colliders(
  colliders : @ecs.Query[@ecs.Comp[@physics3d.RapierColliderHandle3d], @ecs.All],
  exit : @ecs.MessageWriter[@app.AppExit],
) -> Unit {
  let nb_colliders = colliders.count()
  println("There are \{nb_colliders} colliders.")
  if nb_colliders <= 0 {
    abort("Expected at least one collider in rapier_context_component.")
  }
  ignore(exit.write(@app.AppExit::Success))
}

///|
fn setup_physics(world : @ecs.World) -> Unit {
  let ground_size = 5.1F
  let ground_height = 0.1F
  let starting_y = -0.5F - ground_height

  let ground = world.spawn_empty()
  try! world.set_by_key(
    ground,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, starting_y, 0.0F),
  )
  try! world.set_by_key(
    ground,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(
        ground_size, ground_height, ground_size,
      ),
    ),
  )

  for _ in 0..<3 {
    let cube = world.spawn_empty()
    try! world.set_by_key(
      cube,
      @transform.ecs_key_transform,
      @transform.Transform::identity(),
    )
    try! world.set_by_key(
      cube,
      @physics3d.ecs_key_rigid_body3d,
      @physics3d.RigidBody3d::dynamic(),
    )
    try! world.set_by_key(
      cube,
      @physics3d.ecs_key_collider3d,
      @physics3d.Collider3d::new(
        @physics3d.ColliderShape3d::cuboid(0.5F, 0.5F, 0.5F),
      ),
    )
  }
}

///|
fn setup_graphics(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(0.0F, 3.0F, -10.0F),
    @math.Vec3::zero(),
  )
}
