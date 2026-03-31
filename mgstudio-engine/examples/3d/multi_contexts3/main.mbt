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
  .add_systems(@app.PostUpdate, @app.system(report_hits))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(0.0F, 12.0F, 26.0F),
    @math.Vec3::new(0.0F, 3.0F, 0.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(8.0F, 0.5F, 8.0F),
      @math.Vec3::new(-10.0F, -0.5F, 0.0F),
    ),
  )
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(8.0F, 0.5F, 8.0F),
      @math.Vec3::new(10.0F, -0.5F, 0.0F),
    ),
  )

  let colors = [0, 1]
  let offsets = [-10.0F, 10.0F]
  for lane in 0..<2 {
    let group = 1 << lane
    for i in 0..<20 {
      ignore(
        @rapier_examples.rapier3d_spawn_cuboid(
          world,
          @math.Vec3::new(
            offsets[lane] + Float::from_int(i % 4) * 1.1F,
            1.0F + Float::from_int(i / 4) * 1.3F,
            Float::from_int(i % 3) * 1.1F - 1.0F,
          ),
          @math.Vec3::splat(0.45F),
          @rapier_examples.rapier3d_color(colors[lane]),
          Some(@physics3d.RigidBody3d::dynamic()),
        ),
      )
      let entity = world.entities.alive_entities()[world.entities
        .alive_entities()
        .length() -
        1]
      try! world.set_by_key(
        entity,
        @physics3d.ecs_key_collision_groups3d,
        @physics3d.CollisionGroups3d::new(
          group,
          group,
          @dynamics.InteractionTestMode::And,
        ),
      )
    }
  }
}

///|
fn report_hits(world : @ecs.World) -> Unit {
  guard @physics3d.get_physics3d_context_resource(world).get() is Some(ctx) else {
    return
  }
  let left_hit = ctx.cast_ray_entity(
    @math.Vec3::new(-10.0F, 5.0F, 20.0F),
    @math.Vec3::new(0.0F, -0.2F, -1.0F),
    100.0F,
    true,
  )
  let right_hit = ctx.cast_ray_entity(
    @math.Vec3::new(10.0F, 5.0F, 20.0F),
    @math.Vec3::new(0.0F, -0.2F, -1.0F),
    100.0F,
    true,
  )
  if left_hit is Some(hit) {
    println("[multi_contexts3] left lane hit entity=\{hit.entity.id}")
  }
  if right_hit is Some(hit) {
    println("[multi_contexts3] right lane hit entity=\{hit.entity.id}")
  }
}
