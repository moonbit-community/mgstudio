// Copyright 2025 International Digital Economy Academy
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
/// Ported from rapier collider position setters.
test "collider position setters" {
  let collider = ColliderBuilder::ball(1.0F).build()
  collider.set_translation(@core.Vec2::new(1.0F, -2.0F)) |> ignore
  collider.set_rotation(1.5F) |> ignore
  inspect(collider.translation().x == 1.0F, content="true")
  inspect(collider.translation().y == -2.0F, content="true")
  inspect(collider.rotation() == 1.5F, content="true")
  let position = collider.position()
  inspect(position.translation.x == 1.0F, content="true")
  inspect(position.translation.y == -2.0F, content="true")
  inspect(position.rotation.angle() == 1.5F, content="true")
}

///|
/// Ported from rapier collider shape setters.
test "collider shape setters" {
  let collider = ColliderBuilder::ball(1.0F).build()
  let collider = collider.set_shape(Shape::Cuboid(0.5F, 1.25F))
  if collider.shape() is Shape::Cuboid(half_width, half_height) {
    inspect(half_width == 0.5F, content="true")
    inspect(half_height == 1.25F, content="true")
  } else {
    inspect(false, content="true")
  }
}

///|
/// Ported from rapier interaction groups.
test "interaction groups behavior" {
  let group_a = @dynamics.InteractionGroups::new(
    @dynamics.Group::group_1(),
    @dynamics.Group::group_2(),
    @dynamics.InteractionTestMode::And,
  )
  let group_b = @dynamics.InteractionGroups::new(
    @dynamics.Group::group_2(),
    @dynamics.Group::group_1(),
    @dynamics.InteractionTestMode::And,
  )
  inspect(group_a.test_groups(group_b), content="true")
  let group_c = @dynamics.InteractionGroups::new(
    @dynamics.Group::group_1(),
    @dynamics.Group::group_2(),
    @dynamics.InteractionTestMode::Or,
  )
  let group_d = @dynamics.InteractionGroups::new(
    @dynamics.Group::group_3(),
    @dynamics.Group::group_1(),
    @dynamics.InteractionTestMode::Or,
  )
  inspect(group_c.test_groups(group_d), content="true")
  let customized = @dynamics.InteractionGroups::default()
    .with_memberships(@dynamics.Group::group_4())
    .with_filter(@dynamics.Group::group_5())
  inspect(
    customized.memberships().equals(@dynamics.Group::group_4()),
    content="true",
  )
  inspect(
    customized.filter().equals(@dynamics.Group::group_5()),
    content="true",
  )
}

///|
/// Ported from rapier collider group setters.
test "collider groups accessors" {
  let collision_groups = @dynamics.InteractionGroups::new(
    @dynamics.Group::group_1(),
    @dynamics.Group::group_2(),
    @dynamics.InteractionTestMode::And,
  )
  let solver_groups = @dynamics.InteractionGroups::none()
  let collider = ColliderBuilder::ball(1.0F)
    .collision_groups(collision_groups)
    .solver_groups(solver_groups)
    .build()
  let collision = collider.collision_groups()
  inspect(
    collision.memberships().equals(@dynamics.Group::group_1()),
    content="true",
  )
  inspect(collision.filter().equals(@dynamics.Group::group_2()), content="true")
  let solver = collider.solver_groups()
  inspect(solver.memberships().equals(@dynamics.Group::none()), content="true")
  let collider = collider.set_collision_groups(
    @dynamics.InteractionGroups::all(),
  )
  inspect(
    collider.collision_groups().test_mode()
    is @dynamics.InteractionTestMode::And,
    content="true",
  )
  let collider = collider.set_solver_groups(
    @dynamics.InteractionGroups::default().with_filter(
      @dynamics.Group::group_3(),
    ),
  )
  inspect(
    collider.solver_groups().filter().equals(@dynamics.Group::group_3()),
    content="true",
  )
}

///|
/// Ported from rapier collider material and event accessors.
test "collider material and event accessors" {
  let collider = ColliderBuilder::ball(1.0F)
    .friction(0.75F)
    .friction_combine_rule(@dynamics.CoefficientCombineRule::Max)
    .restitution(0.25F)
    .restitution_combine_rule(@dynamics.CoefficientCombineRule::Min)
    .contact_skin(0.1F)
    .contact_force_event_threshold(3.0F)
    .user_data(7)
    .active_hooks(ActiveHooks::filter_contact_pairs())
    .active_events(ActiveEvents::CollisionEvents)
    .build()
  inspect(collider.friction() == 0.75F, content="true")
  inspect(
    collider.friction_combine_rule() is @dynamics.CoefficientCombineRule::Max,
    content="true",
  )
  inspect(collider.restitution() == 0.25F, content="true")
  inspect(
    collider.restitution_combine_rule() is @dynamics.CoefficientCombineRule::Min,
    content="true",
  )
  inspect(collider.contact_skin() == 0.1F, content="true")
  inspect(collider.contact_force_event_threshold() == 3.0F, content="true")
  inspect(collider.user_data() == 7, content="true")
  inspect(
    collider.active_hooks().contains(ActiveHooks::filter_contact_pairs()),
    content="true",
  )
  inspect(
    collider.active_events() is Some(ActiveEvents::CollisionEvents),
    content="true",
  )
  inspect(
    collider.active_collision_types().equals(ActiveCollisionTypes::default()),
    content="true",
  )
  let collider = collider.set_restitution(0.5F)
  inspect(collider.restitution() == 0.5F, content="true")
  let collider = collider.set_friction(0.25F)
  inspect(collider.friction() == 0.25F, content="true")
  let collider = collider.set_restitution_combine_rule(
    @dynamics.CoefficientCombineRule::Max,
  )
  inspect(
    collider.restitution_combine_rule() is @dynamics.CoefficientCombineRule::Max,
    content="true",
  )
  let collider = collider.set_friction_combine_rule(
    @dynamics.CoefficientCombineRule::Average,
  )
  inspect(
    collider.friction_combine_rule()
    is @dynamics.CoefficientCombineRule::Average,
    content="true",
  )
  let collider = collider.set_contact_skin(0.2F)
  inspect(collider.contact_skin() == 0.2F, content="true")
  let collider = collider.set_contact_force_event_threshold(5.0F)
  inspect(collider.contact_force_event_threshold() == 5.0F, content="true")
  let collider = collider.set_user_data(11)
  inspect(collider.user_data() == 11, content="true")
  let collider = collider.set_active_hooks(
    ActiveHooks::filter_contact_pairs().insert(
      ActiveHooks::modify_solver_contacts(),
    ),
  )
  inspect(
    collider.active_hooks().contains(ActiveHooks::modify_solver_contacts()),
    content="true",
  )
  let collider = collider.set_active_events(None)
  inspect(collider.active_events() is None, content="true")
  let collider = collider.set_active_events(
    Some(ActiveEvents::ContactForceEvents),
  )
  inspect(
    collider.active_events() is Some(ActiveEvents::ContactForceEvents),
    content="true",
  )
}

///|
/// Ported from rapier active collision types checks.
test "active collision types test" {
  let defaults = ActiveCollisionTypes::default()
  inspect(
    defaults.test_body_types(
      @dynamics.RigidBodyType::Dynamic,
      @dynamics.RigidBodyType::Dynamic,
    ),
    content="true",
  )
  inspect(
    defaults.test_body_types(
      @dynamics.RigidBodyType::Dynamic,
      @dynamics.RigidBodyType::Fixed,
    ),
    content="true",
  )
  inspect(
    defaults.test_body_types(
      @dynamics.RigidBodyType::Dynamic,
      @dynamics.RigidBodyType::KinematicPositionBased,
    ),
    content="true",
  )
  inspect(
    defaults.test_body_types(
      @dynamics.RigidBodyType::KinematicPositionBased,
      @dynamics.RigidBodyType::KinematicVelocityBased,
    ),
    content="false",
  )
  inspect(
    defaults.test_body_types(
      @dynamics.RigidBodyType::Fixed,
      @dynamics.RigidBodyType::Fixed,
    ),
    content="false",
  )
  let all_types = ActiveCollisionTypes::all()
  inspect(
    all_types.test_body_types(
      @dynamics.RigidBodyType::Fixed,
      @dynamics.RigidBodyType::Fixed,
    ),
    content="true",
  )
}

///|
/// Ported from rapier collider parent offset setters.
test "collider parent offset setters" {
  let bodies = @dynamics.RigidBodySet::new()
  let body = @dynamics.RigidBodyBuilder::dynamic().build()
  let body_handle = bodies.insert(body)
  let colliders = ColliderSet::new()
  let collider = ColliderBuilder::ball(0.5F).enabled(false).build()
  let handle = colliders.insert_with_parent(collider, body_handle, bodies)
  if colliders.get_mut(handle) is Some(owned) {
    owned.set_translation_wrt_parent(@core.Vec2::new(0.5F, 1.0F)) |> ignore
    owned.set_rotation_wrt_parent(0.25F) |> ignore
  }
  if colliders.get(handle) is Some(stored) {
    inspect(!stored.is_enabled(), content="true")
    if stored.parent() is Some(parent) {
      inspect(
        @dynamics.RigidBodyHandle::equals(parent, body_handle),
        content="true",
      )
    } else {
      inspect(false, content="true")
    }
    if stored.position_wrt_parent() is Some(position) {
      inspect(position.translation.x == 0.5F, content="true")
      inspect(position.translation.y == 1.0F, content="true")
      inspect(position.rotation.angle() == 0.25F, content="true")
    } else {
      inspect(false, content="true")
    }
  } else {
    inspect(false, content="true")
  }
}
