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
/// Bevy-like 2D joint authoring components.
///
/// Notes:
/// - v1 assumes at most one joint component per entity.
/// - Joints are inserted only when both entities have `RapierBodyHandle2d`.

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ImpulseJoint2d {
  other : @core.Entity
  data : @dynamics.GenericJoint
  wake_up : Bool
}

///|
pub fn ImpulseJoint2d::new(
  other : @core.Entity,
  data : @dynamics.GenericJoint,
) -> ImpulseJoint2d {
  { other, data, wake_up: true }
}

///|
pub fn ImpulseJoint2d::with_wake_up(
  self : ImpulseJoint2d,
  wake_up : Bool,
) -> ImpulseJoint2d {
  ImpulseJoint2d::{ ..self, wake_up, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RapierImpulseJointHandle2d {
  handle : @dynamics.ImpulseJointHandle
  other : @core.Entity
}

///|
pub fn RapierImpulseJointHandle2d::new(
  handle : @dynamics.ImpulseJointHandle,
  other : @core.Entity,
) -> RapierImpulseJointHandle2d {
  { handle, other }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct MultibodyJoint2d {
  other : @core.Entity
  /// moon_rapier currently models multibody joints as revolute joints.
  data : @dynamics.RevoluteJoint
  wake_up : Bool
  /// If true, insert using `MultibodyJointSet::insert_kinematic`.
  kinematic : Bool
}

///|
pub fn MultibodyJoint2d::new(
  other : @core.Entity,
  data : @dynamics.RevoluteJoint,
) -> MultibodyJoint2d {
  { other, data, wake_up: true, kinematic: false }
}

///|
pub fn MultibodyJoint2d::with_wake_up(
  self : MultibodyJoint2d,
  wake_up : Bool,
) -> MultibodyJoint2d {
  MultibodyJoint2d::{ ..self, wake_up, }
}

///|
pub fn MultibodyJoint2d::with_kinematic(
  self : MultibodyJoint2d,
  kinematic : Bool,
) -> MultibodyJoint2d {
  MultibodyJoint2d::{ ..self, kinematic, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RapierMultibodyJointHandle2d {
  handle : @dynamics.MultibodyJointHandle
  other : @core.Entity
}

///|
pub fn RapierMultibodyJointHandle2d::new(
  handle : @dynamics.MultibodyJointHandle,
  other : @core.Entity,
) -> RapierMultibodyJointHandle2d {
  { handle, other }
}

///|
/// Mgstudio-friendly 2D joint builders that produce `@dynamics.GenericJoint`.
///
/// These helpers mirror Bevy+Rapier's intent: keep user code in mgstudio math
/// types and let the integration layer handle conversions.
///|
pub fn joint2d_fixed(
  local_anchor1 : @math.Vec2,
  local_anchor2 : @math.Vec2,
) -> @dynamics.GenericJoint {
  let j = @dynamics.FixedJointBuilder::new()
    .local_anchor1(mg_vec2_to_rapier(local_anchor1))
    .local_anchor2(mg_vec2_to_rapier(local_anchor2))
    .build()
  @dynamics.GenericJoint::from_fixed(j)
}

///|
pub fn joint2d_revolute(
  local_anchor1 : @math.Vec2,
  local_anchor2 : @math.Vec2,
) -> @dynamics.GenericJoint {
  let j = @dynamics.RevoluteJointBuilder::new()
    .local_anchor1(mg_vec2_to_rapier(local_anchor1))
    .local_anchor2(mg_vec2_to_rapier(local_anchor2))
    .build()
  @dynamics.GenericJoint::from_revolute(j)
}

///|
pub fn joint2d_prismatic(
  local_axis : @math.Vec2,
  local_anchor1 : @math.Vec2,
  local_anchor2 : @math.Vec2,
) -> @dynamics.GenericJoint {
  let j = @dynamics.PrismaticJointBuilder::new(mg_vec2_to_rapier(local_axis))
    .local_anchor1(mg_vec2_to_rapier(local_anchor1))
    .local_anchor2(mg_vec2_to_rapier(local_anchor2))
    .build()
  @dynamics.GenericJoint::from_prismatic(j)
}

///|
pub fn joint2d_rope(
  max_distance : Float,
  local_anchor1 : @math.Vec2,
  local_anchor2 : @math.Vec2,
) -> @dynamics.GenericJoint {
  let j = @dynamics.RopeJointBuilder::new(max_distance)
    .local_anchor1(mg_vec2_to_rapier(local_anchor1))
    .local_anchor2(mg_vec2_to_rapier(local_anchor2))
    .build()
  @dynamics.GenericJoint::from_rope(j)
}

///|
pub fn joint2d_pin_slot(
  local_axis : @math.Vec2,
  local_anchor1 : @math.Vec2,
  local_anchor2 : @math.Vec2,
) -> @dynamics.GenericJoint {
  let j = @dynamics.PinSlotJointBuilder::new(mg_vec2_to_rapier(local_axis))
    .local_anchor1(mg_vec2_to_rapier(local_anchor1))
    .local_anchor2(mg_vec2_to_rapier(local_anchor2))
    .build()
  @dynamics.GenericJoint::from_pin_slot(j)
}
