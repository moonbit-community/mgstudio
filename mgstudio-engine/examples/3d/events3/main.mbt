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
  .add_systems(@app.Startup, @app.system(setup_graphics))
  .add_systems(@app.Startup, @app.system(setup_physics))
  .add_systems(@app.PostUpdate, @app.system(display_events))
  .run()
}

///|
fn setup_graphics(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(0.0F, 0.0F, 25.0F),
    @math.Vec3::zero(),
  )
}

///|
fn setup_physics(world : @ecs.World) -> Unit {
  let ground = world.spawn_empty()
  try! world.set_by_key(
    ground,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, -1.2F, 0.0F),
  )
  try! world.set_by_key(
    ground,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(4.0F, 1.0F, 1.0F),
    ),
  )

  let sensor = world.spawn_empty()
  try! world.set_by_key(
    sensor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 5.0F, 0.0F),
  )
  try! world.set_by_key(
    sensor,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(4.0F, 1.5F, 1.0F),
    ).sensor(true),
  )

  let dynamic_cube = world.spawn_empty()
  try! world.set_by_key(
    dynamic_cube,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 13.0F, 0.0F),
  )
  try! world.set_by_key(
    dynamic_cube,
    @physics3d.ecs_key_rigid_body3d,
    @physics3d.RigidBody3d::dynamic(),
  )
  try! world.set_by_key(
    dynamic_cube,
    @physics3d.ecs_key_collider3d,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(0.5F, 0.5F, 0.5F),
    ),
  )
  try! world.set_by_key(
    dynamic_cube,
    @physics3d.ecs_key_active_events3d,
    @physics3d.ActiveEvents3d::collision_events(),
  )
  try! world.set_by_key(
    dynamic_cube,
    @physics3d.ecs_key_contact_force_event_threshold3d,
    @physics3d.ContactForceEventThreshold3d::new(30.0F),
  )
}

///|
fn display_events(world : @ecs.World) -> Unit {
  guard @physics3d.get_physics3d_events_resource(world).get() is Some(events) else {
    return
  }

  for collision_event in events.collisions {
    match collision_event {
      @physics3d.CollisionEvent3d::Started(a, b, sensor) =>
        println(
          "Received collision event: Started(\{a.id}, \{b.id}, sensor=\{sensor})",
        )
      @physics3d.CollisionEvent3d::Stopped(a, b, sensor) =>
        println(
          "Received collision event: Stopped(\{a.id}, \{b.id}, sensor=\{sensor})",
        )
    }
  }

  for contact_event in events.contact_forces {
    println(
      "Received contact force event: (\{contact_event.entity1.id}, \{contact_event.entity2.id}, max_force=\{contact_event.max_force_magnitude}, total_force=\{contact_event.total_force_magnitude})",
    )
  }
}
