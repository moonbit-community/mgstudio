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
extend DespawnTarget with @ecs.Component::{component}

///|
priv struct DespawnTarget {}

///|
let despawn_target_component_key : @ecs.ComponentKey[DespawnTarget] = @ecs.register_component(
  debug_name="examples.3d.custom_system_setup3.DespawnTarget",
)

///|
impl @ecs.Component for DespawnTarget with fn component() {
  despawn_target_component_key
}

///|
fn main {
  let app = @app.App::new(@ecs.World::new())
  app
  .add_plugins(
    @mgstudio.DefaultPlugins::build()
    .disable(@physics3d.Physics3dPlugin::Physics3dPlugin())
    .add(
      @rapier_examples.Rapier3dDebugRenderPlugin::Rapier3dDebugRenderPlugin(),
    ),
  )
  .add_startup_system(@physics3d.physics3d_init_resources_system)
  .add_pre_update_system(@physics3d.physics3d_clear_events_system)
  .add_pre_update_system(@physics3d.physics3d_cleanup_despawned_system)
  .add_fixed_update_system(@physics3d.physics3d_sync_insertions_system)
  .add_fixed_update_system(@physics3d.physics3d_sync_joints_system)
  .add_fixed_update_system(@physics3d.physics3d_sync_world_to_rapier_system)
  .add_fixed_update_system(@physics3d.physics3d_character_controller_system)
  .add_fixed_update_system(@physics3d.physics3d_step_system)
  .add_fixed_update_system(@physics3d.physics3d_writeback_system)
  .add_systems_world(Startup, setup_graphics)
  .add_systems_world(Startup, setup_physics)
  .add_systems_world(Update, despawn_one_box)
  .run()
}

///|
fn setup_graphics(world : @ecs.World) -> Unit {
  @rapier_examples.rapier3d_basic_lighting(world)
  @rapier_examples.rapier3d_camera(
    world,
    @math.Vec3::new(-30.0F, 30.0F, 100.0F),
    @math.Vec3::new(0.0F, 10.0F, 0.0F),
  )
  @physics3d.physics3d_debug_render_set_enabled(true)
}

///|
fn setup_physics(world : @ecs.World) -> Unit {
  ignore(
    @rapier_examples.rapier3d_spawn_ground(
      world,
      @math.Vec3::new(500.0F, 12.0F, 500.0F),
      @math.Vec3::new(0.0F, -10.0F, 0.0F),
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
        let box = @rapier_examples.rapier3d_spawn_cuboid(
          world,
          @math.Vec3::new(x, y, z),
          @math.Vec3::splat(rad),
          @rapier_examples.rapier3d_color(i + j + k),
          Some(@physics3d.RigidBody3d::dynamic()),
        )
        let target = DespawnTarget::{  }
        try! world.set_by_key(box, DespawnTarget::component(), target)
      }
    }
    offset -= 0.05F * rad * Float::from_int(num - 1)
  }
}

///|
fn despawn_one_box(world : @ecs.World) -> Unit {
  let tick = match world.get_resource(@diagnostic.FrameCount::resource()) {
    Some(frame_count) => frame_count.value
    None => 0
  }
  if tick % 5 != 0 {
    return
  }
  let boxes : Array[@core.Entity] = []
  world.for_each_component(DespawnTarget::component(), fn(entity, _target) {
    if !(try! world.contains_by_key(entity, @physics3d.ecs_key_rigid_body3d)) {
      return
    }
    if (try! world.contains_by_key(entity, @physics3d.ecs_key_collider3d)) {
      boxes.push(entity)
    }
  })
  if boxes.is_empty() {
    return
  }
  let index = tick % boxes.length()
  try! (world.despawn(boxes[index]) |> ignore)
}
