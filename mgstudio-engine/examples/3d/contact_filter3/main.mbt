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
const CUSTOM_FILTER_TAG_GROUP_A : Int = 0

///|
const CUSTOM_FILTER_TAG_GROUP_B : Int = 1

///|
let custom_filter_tags : Ref[@hashmap.HashMap[Int, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
fn tag_for_entity(entity : @core.Entity) -> Int? {
  custom_filter_tags.val.get(entity.id)
}

///|
fn same_user_data_filter(
  _rigid_body_set : @dynamics.RigidBodySet3D,
  _collider_set : @collision.ColliderSet3D,
  collider1 : @collision.ColliderHandle3D,
  collider2 : @collision.ColliderHandle3D,
) -> Bool {
  guard @physics3d.physics3d_hook_entity_from_collider_handle(collider1)
    is Some(entity1) else {
    return false
  }
  guard @physics3d.physics3d_hook_entity_from_collider_handle(collider2)
    is Some(entity2) else {
    return false
  }
  tag_for_entity(entity1) == tag_for_entity(entity2)
}

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
  @physics3d.physics3d_set_filter_contact_pair(world, same_user_data_filter)

  let ground_a = @rapier_examples.rapier3d_spawn_ground(
    world,
    @math.Vec3::new(10.0F, 1.2F, 10.0F),
    @math.Vec3::new(0.0F, -10.0F, 0.0F),
  )
  custom_filter_tags.val.set(ground_a.id, CUSTOM_FILTER_TAG_GROUP_A)
  let ground_b = @rapier_examples.rapier3d_spawn_ground(
    world,
    @math.Vec3::new(10.0F, 1.2F, 10.0F),
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
  )
  custom_filter_tags.val.set(ground_b.id, CUSTOM_FILTER_TAG_GROUP_B)

  let num = 4
  let rad = 0.5F
  let shift = rad * 2.0F
  let centerx = shift * Float::from_int(num) / 2.0F
  let centery = shift / 2.0F
  let tags = [CUSTOM_FILTER_TAG_GROUP_A, CUSTOM_FILTER_TAG_GROUP_B]
  let mut group_id = 0
  for i in 0..<num {
    for j in 0..<(num * 5) {
      let x = (Float::from_int(i) + Float::from_int(j) * 0.2F) * shift - centerx
      let y = Float::from_int(j) * shift + centery + 2.0F
      let body = @rapier_examples.rapier3d_spawn_cuboid(
        world,
        @math.Vec3::new(x, y, 0.0F),
        @math.Vec3::splat(rad),
        @rapier_examples.rapier3d_color(group_id),
        Some(@physics3d.RigidBody3d::dynamic()),
      )
      let tag = tags[group_id % 2]
      custom_filter_tags.val.set(body.id, tag)
      group_id = group_id + 1
    }
  }
  println("[contact_filter3] only bodies from the same group should collide")
}
