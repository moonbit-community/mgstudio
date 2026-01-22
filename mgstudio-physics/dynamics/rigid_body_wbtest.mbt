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
