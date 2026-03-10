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
/// Adapted line-by-line from:
/// https://github.com/dimforge/bevy_rapier/blob/master/bevy_rapier3d/examples/events3.rs
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@physics3d.physics3d_debug_render_plugin])
  .add_systems(@app.Startup, @app.system(setup_graphics))
  .add_systems(@app.Startup, @app.system(setup_physics))
  .add_systems(@app.PostUpdate, @app.system(display_events))
  .run()
}

///|
fn setup_graphics(world : @ecs.World) -> Unit {
  let clear_color = @sprite.Color::new(0.9764706F, 0.9764706F, 1.0F, 1.0F)
  @pbr.Camera3dBundle::new(
    @sprite.Camera::new(clear_color),
    @math.Transform::from_xyz(0.0F, 0.0F, 25.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn setup_physics(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let ground = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(ground, @math.Transform::from_xyz(0.0F, -1.2F, 0.0F), tick)
  @physics3d.get_collider3d_store(world).insert(
    ground,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(4.0F, 1.0F, 1.0F),
    ),
    tick,
  )

  let sensor = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(sensor, @math.Transform::from_xyz(0.0F, 5.0F, 0.0F), tick)
  @physics3d.get_collider3d_store(world).insert(
    sensor,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(4.0F, 1.5F, 1.0F),
    ).sensor(true),
    tick,
  )

  let dynamic_cube = world.spawn_empty()
  world
  .component(@math.ecs_key_transform)
  .insert(dynamic_cube, @math.Transform::from_xyz(0.0F, 13.0F, 0.0F), tick)
  @physics3d.get_rigid_body3d_store(world).insert(
    dynamic_cube,
    @physics3d.RigidBody3d::dynamic(),
    tick,
  )
  @physics3d.get_collider3d_store(world).insert(
    dynamic_cube,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(0.5F, 0.5F, 0.5F),
    ),
    tick,
  )
  @physics3d.get_active_events3d_store(world).insert(
    dynamic_cube,
    @physics3d.ActiveEvents3d::new(@collision.ActiveEvents::collision_events()),
    tick,
  )
  @physics3d.get_contact_force_event_threshold3d_store(world).insert(
    dynamic_cube,
    @physics3d.ContactForceEventThreshold3d::new(30.0F),
    tick,
  )
}

///|
fn display_events(world : @ecs.World) -> Unit {
  let events_resource = @physics3d.get_physics3d_events_resource(world)
  guard events_resource.get() is Some(events) else { return }

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
