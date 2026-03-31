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
priv struct DumpState {
  mut done : Bool
}

///|
let dump_state : Ref[DumpState] = Ref::new({ done: false })

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.PostUpdate, @app.system(display_nb_colliders))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(0.0F, 3.0F, -10.0F),
    @math.Vec3::zero(),
  )
  @rapier_examples.rapier3d_basic_lighting(world)
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(5.1F, 0.1F, 5.1F),
      @math.Vec3::new(0.0F, -0.6F, 0.0F),
    ),
  )
  for i in 0..<3 {
    ignore(
      @rapier_examples.rapier3d_spawn_cuboid(
        world,
        @math.Vec3::new(Float::from_int(i) * 1.5F - 1.5F, 0.5F, 0.0F),
        @math.Vec3::new(0.5F, 0.5F, 0.5F),
        @rapier_examples.rapier3d_color(i),
        Some(@physics3d.RigidBody3d::dynamic()),
      ),
    )
  }
}

///|
fn display_nb_colliders(world : @ecs.World) -> Unit {
  if dump_state.val.done {
    return
  }
  guard @physics3d.get_physics3d_context_resource(world).get() is Some(ctx) else {
    return
  }
  let hits = ctx.intersect_shape_entities(
    @transform.Transform::identity(),
    @collision.Shape3D::ball(100.0F),
  )
  println("[rapier_context_component] visible colliders = \{hits.length()}")
  dump_state.val.done = true
}
