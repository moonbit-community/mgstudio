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
pub struct DespawnMarker {
  value : Bool
}

///|
pub fn DespawnMarker::new() -> DespawnMarker {
  DespawnMarker::{ value: true }
}

///|
let despawn_marker_component_key : @ecs.ComponentKey[DespawnMarker] = @ecs.register_component(
  debug_name="examples.3d.joints_despawn3.DespawnMarker",
)

///|
pub impl @ecs.Component for DespawnMarker with component() {
  despawn_marker_component_key
}

///|
priv struct DespawnState {
  mut timer : Float
}

///|
let despawn_state : Ref[DespawnState] = Ref({ timer: 5.0F })

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@rapier_examples.rapier3d_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(despawn))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(15.0F, 5.0F, 42.0F),
    @math.Vec3::new(13.0F, 1.0F, 1.0F),
  )
  @rapier_examples.rapier3d_basic_lighting(world)

  let mut parent = @rapier_examples.rapier3d_spawn_ball(
    world,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    0.4F,
    @sprite.Color::new(0.85F, 0.85F, 0.95F, 1.0F),
    Some(@physics3d.RigidBody3d::fixed()),
  )
  let rad = 0.4F
  for i in 0..<8 {
    let z = Float::from_int(i + 1)
    let entity = @rapier_examples.rapier3d_spawn_ball(
      world,
      @math.Vec3::new(0.0F, 1.0F, z * 1.2F),
      rad,
      @rapier_examples.rapier3d_color(i),
      Some(@physics3d.RigidBody3d::dynamic()),
    )
    if i == 3 {
      try! world.set_by_key(
        entity,
        DespawnMarker::component(),
        DespawnMarker::new(),
      )
    }
    try! world.set_by_key(
      entity,
      @physics3d.ecs_key_impulse_joint3d,
      @physics3d.ImpulseJoint3d::new(
        parent,
        @physics3d.joint3d_spherical(
          @math.Vec3::new(0.0F, 0.0F, 0.6F),
          @math.Vec3::new(0.0F, 0.0F, -0.6F),
        ),
      ),
    )
    parent = entity
  }
}

///|
fn despawn(world : @ecs.World) -> Unit {
  let dt = @time.time_real_delta_seconds()
  despawn_state.val.timer = despawn_state.val.timer - dt
  if despawn_state.val.timer > 0.0F {
    return
  }
  for entity in world.entities.alive_entities() {
    if (try! world.contains_by_key(entity, DespawnMarker::component())) {
      try! world.despawn(entity)
      println("[joints_despawn3] despawned one tagged joint body")
      break
    }
  }
  despawn_state.val.timer = 5.0F
}
