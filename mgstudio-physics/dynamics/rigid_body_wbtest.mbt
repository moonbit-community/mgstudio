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
