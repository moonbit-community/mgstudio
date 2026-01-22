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
/// Ported from rapier rigid_body_components handle helpers.
test "rigid body handle raw parts round trip" {
  let handle = RigidBodyHandle::from_raw_parts(3, 7)
  let (id, generation) = handle.into_raw_parts()
  inspect(id == 3, content="true")
  inspect(generation == 7, content="true")
  let invalid = RigidBodyHandle::invalid()
  let (invalid_id, invalid_generation) = invalid.into_raw_parts()
  inspect(invalid_id == -1, content="true")
  inspect(invalid_generation == -1, content="true")
}

///|
/// Ported from rapier rigid_body_components kinematic velocity type.
test "rigid body builder kinematic velocity based" {
  let body = RigidBodyBuilder::kinematic_velocity_based().build()
  inspect(
    body.body_type is RigidBodyType::KinematicVelocityBased,
    content="true",
  )
  inspect(RigidBodyType::Dynamic.is_dynamic(), content="true")
  inspect(RigidBodyType::Fixed.is_fixed(), content="true")
  inspect(RigidBodyType::KinematicVelocityBased.is_kinematic(), content="true")
  inspect(
    RigidBodyType::KinematicVelocityBased.is_dynamic_or_kinematic(),
    content="true",
  )
}

///|
/// Ported from rapier rigid_body velocity setters.
test "rigid body velocity setters" {
  let body = RigidBodyBuilder::dynamic().build().sleep()
  let body = body.set_linvel(@core.Vec2::new(1.0F, -2.0F), true)
  inspect(!body.is_sleeping(), content="true")
  let body = body.set_angvel(3.5F, true)
  inspect(body.linvel().x == 1.0F, content="true")
  inspect(body.linvel().y == -2.0F, content="true")
  inspect(body.angvel() == 3.5F, content="true")
  let kinematic = RigidBodyBuilder::kinematic_position_based().build()
  let kinematic = kinematic.set_linvel(@core.Vec2::new(5.0F, 0.0F), true)
  inspect(kinematic.linvel().x == 0.0F, content="true")
  inspect(kinematic.linvel().y == 0.0F, content="true")
}

///|
/// Ported from rapier rigid_body force accumulation.
test "rigid body forces and torques" {
  let body = RigidBodyBuilder::dynamic().build()
  let body = body.add_force(@core.Vec2::new(2.0F, -1.0F), true)
  let body = body.add_torque(0.5F, true)
  let forces = body.forces()
  inspect(forces.user_force.x == 2.0F, content="true")
  inspect(forces.user_force.y == -1.0F, content="true")
  inspect(forces.user_torque == 0.5F, content="true")
  let body = body.reset_forces(false)
  let body = body.reset_torques(false)
  let cleared = body.forces()
  inspect(cleared.user_force.x == 0.0F, content="true")
  inspect(cleared.user_force.y == 0.0F, content="true")
  inspect(cleared.user_torque == 0.0F, content="true")
}

///|
/// Ported from rapier rigid_body force-at-point behavior.
test "rigid body force at point" {
  let body = RigidBodyBuilder::dynamic().build()
  let force = @core.Vec2::new(1.0F, 0.0F)
  let point = @core.Vec2::new(0.0F, 1.0F)
  let body = body.add_force_at_point(force, point, true)
  let forces = body.forces()
  inspect(forces.user_force.x == 1.0F, content="true")
  inspect(forces.user_force.y == 0.0F, content="true")
  inspect(forces.user_torque == -1.0F, content="true")
}

///|
/// Ported from rapier rigid_body damping, gravity, and CCD setters.
test "rigid body damping and ccd setters" {
  let body = RigidBodyBuilder::dynamic().build()
  let body = body.set_linear_damping(0.25F).set_angular_damping(0.5F)
  inspect(body.linear_damping() == 0.25F, content="true")
  inspect(body.angular_damping() == 0.5F, content="true")
  let body = body.set_gravity_scale(0.0F, true)
  inspect(body.gravity_scale() == 0.0F, content="true")
  let body = body.enable_ccd(true).set_soft_ccd_prediction(2.5F)
  inspect(body.is_ccd_enabled(), content="true")
  inspect(body.soft_ccd_prediction() == 2.5F, content="true")
  inspect(!body.is_ccd_active(), content="true")
}

///|
/// Ported from rapier rigid_body builder CCD options.
test "rigid body builder ccd options" {
  let body = RigidBodyBuilder::dynamic()
    .ccd_enabled(true)
    .soft_ccd_prediction(1.25F)
    .build()
  inspect(body.is_ccd_enabled(), content="true")
  inspect(body.soft_ccd_prediction() == 1.25F, content="true")
}

///|
/// Ported from rapier rigid_body builder initialization fields.
test "rigid body builder initial state" {
  let body = RigidBodyBuilder::dynamic()
    .translation(@core.Vec2::new(1.0F, 2.0F))
    .rotation(@core.Rot2::from_angle(0.5F))
    .linvel(@core.Vec2::new(3.0F, -1.0F))
    .angvel(2.5F)
    .gravity_scale(0.5F)
    .linear_damping(0.1F)
    .angular_damping(0.2F)
    .enabled(false)
    .build()
  inspect(body.translation().x == 1.0F, content="true")
  inspect(body.translation().y == 2.0F, content="true")
  let angle_delta = @core.abs(body.rotation().angle() - 0.5F)
  inspect(angle_delta < 1.0e-4F, content="true")
  inspect(body.linvel().x == 3.0F, content="true")
  inspect(body.linvel().y == -1.0F, content="true")
  inspect(body.angvel() == 2.5F, content="true")
  inspect(body.gravity_scale() == 0.5F, content="true")
  inspect(body.linear_damping() == 0.1F, content="true")
  inspect(body.angular_damping() == 0.2F, content="true")
  inspect(!body.is_enabled(), content="true")
}

///|
/// Ported from rapier rigid-body dominance groups.
test "rigid body dominance groups" {
  let body = RigidBodyBuilder::dynamic().build()
  inspect(body.dominance_group() == 0, content="true")
  let body = body.set_dominance_group(2)
  inspect(body.dominance_group() == 2, content="true")
  inspect(body.effective_dominance_group() == 2, content="true")
  let fixed = RigidBodyBuilder::fixed().build().set_dominance_group(5)
  inspect(fixed.effective_dominance_group() == 128, content="true")
  let body = RigidBodyBuilder::dynamic().dominance_group(7).build()
  inspect(body.dominance_group() == 7, content="true")
}

///|
/// Ported from rapier rigid_body builder sleeping behavior.
test "rigid body builder sleeping state" {
  let body = RigidBodyBuilder::dynamic().sleeping(true).build()
  inspect(body.is_sleeping(), content="true")
  inspect(body.linvel().x == 0.0F, content="true")
  inspect(body.linvel().y == 0.0F, content="true")
  inspect(body.angvel() == 0.0F, content="true")
}

///|
/// Ported from rapier rigid_body builder position setter.
test "rigid body builder position" {
  let position = @core.Isometry2::new(
    @core.Vec2::new(-1.0F, 3.0F),
    @core.Rot2::from_angle(-0.25F),
  )
  let body = RigidBodyBuilder::dynamic().position(position).build()
  inspect(body.translation().x == -1.0F, content="true")
  inspect(body.translation().y == 3.0F, content="true")
  let angle_delta = @core.abs(body.rotation().angle() + 0.25F)
  inspect(angle_delta < 1.0e-4F, content="true")
}

///|
/// Ported from rapier rigid_body additional mass setter.
test "rigid body additional mass" {
  let body = RigidBodyBuilder::dynamic().build()
  let body = body.set_additional_mass(2.0F, false)
  inspect(body.additional_mass() == 2.0F, content="true")
}

///|
/// Ported from rapier rigid_body impulse application.
test "rigid body impulse application" {
  let body = RigidBodyBuilder::dynamic().build()
  let mprops = body.mass_props
    .set_effective_inv_mass(@core.Vec2::new(0.5F, 0.5F))
    .set_effective_world_inv_inertia(2.0F)
  body.mass_props = mprops
  let body = body.apply_impulse(@core.Vec2::new(2.0F, -1.0F), true)
  inspect(body.linvel().x == 1.0F, content="true")
  inspect(body.linvel().y == -0.5F, content="true")
  let body = body.apply_torque_impulse(0.5F, true)
  inspect(body.angvel() == 1.0F, content="true")
  let body = body.apply_impulse_at_point(
    @core.Vec2::new(1.0F, 0.0F),
    @core.Vec2::new(0.0F, 1.0F),
    true,
  )
  inspect(body.angvel() == -1.0F, content="true")
}

///|
/// Ported from rapier rigid_body mass property accessors.
test "rigid body mass properties" {
  let body = RigidBodyBuilder::dynamic().build()
  inspect(body.mass() == 0.0F, content="true")
  inspect(body.inv_mass() == 0.0F, content="true")
  inspect(body.inertia() == 0.0F, content="true")
  inspect(body.inv_inertia() == 0.0F, content="true")
  let com = body.center_of_mass()
  inspect(com.x == 0.0F, content="true")
  inspect(com.y == 0.0F, content="true")
  let world_com = body.world_com()
  inspect(world_com.x == 0.0F, content="true")
  inspect(world_com.y == 0.0F, content="true")
}
