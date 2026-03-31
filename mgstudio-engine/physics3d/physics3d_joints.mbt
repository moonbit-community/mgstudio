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
/// Bevy-like 3D joint authoring components.
///
/// Notes:
/// - v1 assumes at most one joint component per entity.
/// - Joints are inserted only when both entities have `RapierBodyHandle3d`.

///|
pub struct ImpulseJoint3d {
  other : @core.Entity
  data : @dynamics.GenericJoint
  wake_up : Bool
}

///|
pub fn ImpulseJoint3d::new(
  other : @core.Entity,
  data : @dynamics.GenericJoint,
) -> ImpulseJoint3d {
  { other, data, wake_up: true }
}

///|
pub fn ImpulseJoint3d::with_wake_up(
  self : ImpulseJoint3d,
  wake_up : Bool,
) -> ImpulseJoint3d {
  ImpulseJoint3d::{ ..self, wake_up, }
}

///|
pub struct RapierImpulseJointHandle3d {
  handle : @dynamics.JointHandle3DReal
  other : @core.Entity
}

///|
pub fn RapierImpulseJointHandle3d::new(
  handle : @dynamics.JointHandle3DReal,
  other : @core.Entity,
) -> RapierImpulseJointHandle3d {
  { handle, other }
}

///|
pub struct MultibodyJoint3d {
  other : @core.Entity
  data : @dynamics.GenericJoint
  wake_up : Bool
  /// If true, insert using `MultibodyJointSet3DReal::insert_kinematic`.
  kinematic : Bool
}

///|
pub fn MultibodyJoint3d::new(
  other : @core.Entity,
  data : @dynamics.GenericJoint,
) -> MultibodyJoint3d {
  { other, data, wake_up: true, kinematic: false }
}

///|
pub fn MultibodyJoint3d::with_wake_up(
  self : MultibodyJoint3d,
  wake_up : Bool,
) -> MultibodyJoint3d {
  MultibodyJoint3d::{ ..self, wake_up, }
}

///|
pub fn MultibodyJoint3d::with_kinematic(
  self : MultibodyJoint3d,
  kinematic : Bool,
) -> MultibodyJoint3d {
  MultibodyJoint3d::{ ..self, kinematic, }
}

///|
pub struct RapierMultibodyJointHandle3d {
  handle : @dynamics.MultibodyJointHandle
  other : @core.Entity
}

///|
pub fn RapierMultibodyJointHandle3d::new(
  handle : @dynamics.MultibodyJointHandle,
  other : @core.Entity,
) -> RapierMultibodyJointHandle3d {
  { handle, other }
}

///|
/// Mgstudio-friendly 3D joint builders that produce `@dynamics.GenericJoint`.

///|
pub fn joint3d_fixed(
  local_anchor1 : @math.Vec3,
  local_anchor2 : @math.Vec3,
) -> @dynamics.GenericJoint {
  @dynamics.FixedJoint3DRealBuilder::new()
  .local_anchor1(mg_vec3_to_rapier(local_anchor1))
  .local_anchor2(mg_vec3_to_rapier(local_anchor2))
  .build()
  .to_generic_joint()
}

///|
pub fn joint3d_revolute(
  axis : @math.Vec3,
  local_anchor1 : @math.Vec3,
  local_anchor2 : @math.Vec3,
) -> @dynamics.GenericJoint {
  @dynamics.RevoluteJoint3DRealBuilder::new(mg_vec3_to_rapier(axis))
  .local_anchor1(mg_vec3_to_rapier(local_anchor1))
  .local_anchor2(mg_vec3_to_rapier(local_anchor2))
  .build()
  .to_generic_joint()
}

///|
pub fn joint3d_prismatic(
  axis : @math.Vec3,
  local_anchor1 : @math.Vec3,
  local_anchor2 : @math.Vec3,
) -> @dynamics.GenericJoint {
  @dynamics.PrismaticJoint3DRealBuilder::new(mg_vec3_to_rapier(axis))
  .local_anchor1(mg_vec3_to_rapier(local_anchor1))
  .local_anchor2(mg_vec3_to_rapier(local_anchor2))
  .build()
  .to_generic_joint()
}

///|
pub fn joint3d_spherical(
  local_anchor1 : @math.Vec3,
  local_anchor2 : @math.Vec3,
) -> @dynamics.GenericJoint {
  @dynamics.SphericalJoint3DRealBuilder::new()
  .local_anchor1(mg_vec3_to_rapier(local_anchor1))
  .local_anchor2(mg_vec3_to_rapier(local_anchor2))
  .build()
  .to_generic_joint()
}

///|
pub fn joint3d_spring(
  rest_length : Float,
  stiffness : Float,
  damping : Float,
  local_anchor1 : @math.Vec3,
  local_anchor2 : @math.Vec3,
) -> @dynamics.GenericJoint {
  @dynamics.GenericJoint3DRealBuilder::new(
    @dynamics.JointAxesMask3DReal::empty(),
  )
  .coupled_axes(@dynamics.JointAxesMask3DReal::lin_axes())
  .local_anchor1(mg_vec3_to_rapier(local_anchor1))
  .local_anchor2(mg_vec3_to_rapier(local_anchor2))
  .motor_position(
    @dynamics.JointAxis3DReal::LinX,
    rest_length,
    stiffness,
    damping,
  )
  .build()
  .to_generic_joint()
}

///|
pub fn joint3d_rope(
  max_distance : Float,
  local_anchor1 : @math.Vec3,
  local_anchor2 : @math.Vec3,
) -> @dynamics.GenericJoint {
  let joint = @dynamics.RopeJointBuilder3::new(max_distance)
    .local_anchor1(mg_vec3_to_rapier(local_anchor1))
    .local_anchor2(mg_vec3_to_rapier(local_anchor2))
    .build()
  @dynamics.GenericJoint::from_rope(joint)
}
