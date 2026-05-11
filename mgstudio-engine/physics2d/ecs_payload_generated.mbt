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
extenum @ecs.EcsPayload += {
  EcsPayload_physics2d_Ccd2d(Ccd2d)
  EcsPayload_physics2d_Damping2d(Damping2d)
  EcsPayload_physics2d_Collider2d(Collider2d)
  EcsPayload_physics2d_Friction2d(Friction2d)
  EcsPayload_physics2d_Sleeping2d(Sleeping2d)
  EcsPayload_physics2d_Velocity2d(Velocity2d)
  EcsPayload_physics2d_Dominance2d(Dominance2d)
  EcsPayload_physics2d_RigidBody2d(RigidBody2d)
  EcsPayload_physics2d_LockedAxes2d(LockedAxes2d)
  EcsPayload_physics2d_ActiveHooks2d(ActiveHooks2d)
  EcsPayload_physics2d_ContactSkin2d(ContactSkin2d)
  EcsPayload_physics2d_Restitution2d(Restitution2d)
  EcsPayload_physics2d_ActiveEvents2d(ActiveEvents2d)
  EcsPayload_physics2d_GravityScale2d(GravityScale2d)
  EcsPayload_physics2d_ImpulseJoint2d(ImpulseJoint2d)
  EcsPayload_physics2d_SolverGroups2d(SolverGroups2d)
  EcsPayload_physics2d_ExternalForce2d(ExternalForce2d)
  EcsPayload_physics2d_ColliderParent2d(ColliderParent2d)
  EcsPayload_physics2d_MultibodyJoint2d(MultibodyJoint2d)
  EcsPayload_physics2d_ColliderDensity2d(ColliderDensity2d)
  EcsPayload_physics2d_ColliderEnabled2d(ColliderEnabled2d)
  EcsPayload_physics2d_CollisionGroups2d(CollisionGroups2d)
  EcsPayload_physics2d_ExternalImpulse2d(ExternalImpulse2d)
  EcsPayload_physics2d_RapierBodyHandle2d(RapierBodyHandle2d)
  EcsPayload_physics2d_RigidBodyEnabled2d(RigidBodyEnabled2d)
  EcsPayload_physics2d_FrictionCombineRule2d(FrictionCombineRule2d)
  EcsPayload_physics2d_ActiveCollisionTypes2d(ActiveCollisionTypes2d)
  EcsPayload_physics2d_RapierColliderHandle2d(RapierColliderHandle2d)
  EcsPayload_physics2d_ColliderMassProperties2d(ColliderMassProperties2d)
  EcsPayload_physics2d_RestitutionCombineRule2d(RestitutionCombineRule2d)
  EcsPayload_physics2d_AdditionalMassProperties2d(AdditionalMassProperties2d)
  EcsPayload_physics2d_RapierImpulseJointHandle2d(RapierImpulseJointHandle2d)
  EcsPayload_physics2d_AdditionalSolverIterations2d(
    AdditionalSolverIterations2d
  )
  EcsPayload_physics2d_ContactForceEventThreshold2d(
    ContactForceEventThreshold2d
  )
  EcsPayload_physics2d_RapierMultibodyJointHandle2d(
    RapierMultibodyJointHandle2d
  )
  EcsPayload_physics2d_KinematicCharacterController2d(
    KinematicCharacterController2d
  )
  EcsPayload_physics2d_KinematicCharacterControllerOutput2d(
    KinematicCharacterControllerOutput2d
  )
  EcsPayload_physics2d_Physics2dConfig(Physics2dConfig)
  EcsPayload_physics2d_Physics2dEvents(Physics2dEvents)
  EcsPayload_physics2d_Physics2dContext(Physics2dContext)
  EcsPayload_physics2d_Physics2dHooksConfig(Physics2dHooksConfig)
}

///|
pub impl @ecs.EcsPayloadCodec for Ccd2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Ccd2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Ccd2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Ccd2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Damping2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Damping2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Damping2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Damping2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Collider2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Collider2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Collider2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Collider2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Friction2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Friction2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Friction2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Friction2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Sleeping2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Sleeping2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Sleeping2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Sleeping2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Velocity2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Velocity2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Velocity2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Velocity2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Dominance2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Dominance2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Dominance2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Dominance2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBody2d with to_ecs_payload(self) {
  EcsPayload_physics2d_RigidBody2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBody2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_RigidBody2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LockedAxes2d with to_ecs_payload(self) {
  EcsPayload_physics2d_LockedAxes2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LockedAxes2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_LockedAxes2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveHooks2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ActiveHooks2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveHooks2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_ActiveHooks2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContactSkin2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ContactSkin2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContactSkin2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_ContactSkin2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Restitution2d with to_ecs_payload(self) {
  EcsPayload_physics2d_Restitution2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Restitution2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Restitution2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveEvents2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ActiveEvents2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveEvents2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_ActiveEvents2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GravityScale2d with to_ecs_payload(self) {
  EcsPayload_physics2d_GravityScale2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GravityScale2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_GravityScale2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ImpulseJoint2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ImpulseJoint2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ImpulseJoint2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_ImpulseJoint2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SolverGroups2d with to_ecs_payload(self) {
  EcsPayload_physics2d_SolverGroups2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SolverGroups2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_SolverGroups2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalForce2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ExternalForce2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalForce2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_ExternalForce2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderParent2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ColliderParent2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderParent2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ColliderParent2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MultibodyJoint2d with to_ecs_payload(self) {
  EcsPayload_physics2d_MultibodyJoint2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MultibodyJoint2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_MultibodyJoint2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderDensity2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ColliderDensity2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderDensity2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ColliderDensity2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderEnabled2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ColliderEnabled2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderEnabled2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ColliderEnabled2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CollisionGroups2d with to_ecs_payload(self) {
  EcsPayload_physics2d_CollisionGroups2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CollisionGroups2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_CollisionGroups2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalImpulse2d with to_ecs_payload(self) {
  EcsPayload_physics2d_ExternalImpulse2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalImpulse2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ExternalImpulse2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierBodyHandle2d with to_ecs_payload(self) {
  EcsPayload_physics2d_RapierBodyHandle2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierBodyHandle2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_RapierBodyHandle2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBodyEnabled2d with to_ecs_payload(self) {
  EcsPayload_physics2d_RigidBodyEnabled2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBodyEnabled2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_RigidBodyEnabled2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FrictionCombineRule2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_FrictionCombineRule2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FrictionCombineRule2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_FrictionCombineRule2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveCollisionTypes2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_ActiveCollisionTypes2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveCollisionTypes2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ActiveCollisionTypes2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierColliderHandle2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_RapierColliderHandle2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierColliderHandle2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_RapierColliderHandle2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderMassProperties2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_ColliderMassProperties2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderMassProperties2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ColliderMassProperties2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RestitutionCombineRule2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_RestitutionCombineRule2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RestitutionCombineRule2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_RestitutionCombineRule2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalMassProperties2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_AdditionalMassProperties2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalMassProperties2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_AdditionalMassProperties2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierImpulseJointHandle2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_RapierImpulseJointHandle2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierImpulseJointHandle2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_RapierImpulseJointHandle2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalSolverIterations2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_AdditionalSolverIterations2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalSolverIterations2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_AdditionalSolverIterations2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContactForceEventThreshold2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_ContactForceEventThreshold2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContactForceEventThreshold2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_ContactForceEventThreshold2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierMultibodyJointHandle2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_RapierMultibodyJointHandle2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierMultibodyJointHandle2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_RapierMultibodyJointHandle2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterController2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_KinematicCharacterController2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterController2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_KinematicCharacterController2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterControllerOutput2d with to_ecs_payload(
  self,
) {
  EcsPayload_physics2d_KinematicCharacterControllerOutput2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterControllerOutput2d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_KinematicCharacterControllerOutput2d(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dConfig with to_ecs_payload(self) {
  EcsPayload_physics2d_Physics2dConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Physics2dConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dEvents with to_ecs_payload(self) {
  EcsPayload_physics2d_Physics2dEvents(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dEvents with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics2d_Physics2dEvents(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dContext with to_ecs_payload(self) {
  EcsPayload_physics2d_Physics2dContext(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dContext with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_Physics2dContext(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dHooksConfig with to_ecs_payload(self) {
  EcsPayload_physics2d_Physics2dHooksConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics2dHooksConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics2d_Physics2dHooksConfig(value) => Some(value)
    _ => None
  }
}
