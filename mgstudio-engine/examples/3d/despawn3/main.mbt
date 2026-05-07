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
priv struct DespawnResource {
  mut timer : Float
}

///|
let despawn_state : Ref[DespawnResource] = Ref({ timer: 5.0F })

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
  debug_name="examples.3d.despawn3.DespawnMarker",
)

///|
pub impl @ecs.Component for DespawnMarker with component() {
  despawn_marker_component_key
}

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
        let body = @rapier_examples.rapier3d_spawn_cuboid(
          world,
          @math.Vec3::new(x, y, z),
          @math.Vec3::splat(rad),
          @rapier_examples.rapier3d_color(i + j + k),
          Some(@physics3d.RigidBody3d::dynamic()),
        )
        if (i + j + k) % 7 == 0 {
          try! world.set_by_key(
            body,
            DespawnMarker::component(),
            DespawnMarker::new(),
          )
        }
      }
    }
    offset -= 0.05F * rad * Float::from_int(num - 1)
  }
  despawn_state.val.timer = 5.0F
}

///|
fn despawn(world : @ecs.World) -> Unit {
  let dt = @time.time_real_delta_seconds()
  if despawn_state.val.timer > 0.0F {
    despawn_state.val.timer = despawn_state.val.timer - dt
    return
  }
  let mut despawned = false
  for entity in world.entities.alive_entities() {
    if (try! world.contains_by_key(entity, DespawnMarker::component())) {
      try! world.despawn(entity)
      despawned = true
      break
    }
  }
  if despawned {
    println("[despawn3] removed one tagged cube")
  }
  despawn_state.val.timer = 5.0F
}
