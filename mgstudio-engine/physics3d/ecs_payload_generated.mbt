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
  EcsPayload_physics3d_Ccd3d(Ccd3d)
  EcsPayload_physics3d_Damping3d(Damping3d)
  EcsPayload_physics3d_Collider3d(Collider3d)
  EcsPayload_physics3d_Friction3d(Friction3d)
  EcsPayload_physics3d_Sleeping3d(Sleeping3d)
  EcsPayload_physics3d_Velocity3d(Velocity3d)
  EcsPayload_physics3d_Dominance3d(Dominance3d)
  EcsPayload_physics3d_RigidBody3d(RigidBody3d)
  EcsPayload_physics3d_LockedAxes3d(LockedAxes3d)
  EcsPayload_physics3d_ActiveHooks3d(ActiveHooks3d)
  EcsPayload_physics3d_ContactSkin3d(ContactSkin3d)
  EcsPayload_physics3d_Restitution3d(Restitution3d)
  EcsPayload_physics3d_ActiveEvents3d(ActiveEvents3d)
  EcsPayload_physics3d_GravityScale3d(GravityScale3d)
  EcsPayload_physics3d_ImpulseJoint3d(ImpulseJoint3d)
  EcsPayload_physics3d_SolverGroups3d(SolverGroups3d)
  EcsPayload_physics3d_ExternalForce3d(ExternalForce3d)
  EcsPayload_physics3d_ColliderParent3d(ColliderParent3d)
  EcsPayload_physics3d_MultibodyJoint3d(MultibodyJoint3d)
  EcsPayload_physics3d_ColliderDensity3d(ColliderDensity3d)
  EcsPayload_physics3d_ColliderEnabled3d(ColliderEnabled3d)
  EcsPayload_physics3d_CollisionGroups3d(CollisionGroups3d)
  EcsPayload_physics3d_ExternalImpulse3d(ExternalImpulse3d)
  EcsPayload_physics3d_RapierBodyHandle3d(RapierBodyHandle3d)
  EcsPayload_physics3d_RigidBodyEnabled3d(RigidBodyEnabled3d)
  EcsPayload_physics3d_FrictionCombineRule3d(FrictionCombineRule3d)
  EcsPayload_physics3d_ActiveCollisionTypes3d(ActiveCollisionTypes3d)
  EcsPayload_physics3d_RapierColliderHandle3d(RapierColliderHandle3d)
  EcsPayload_physics3d_ColliderMassProperties3d(ColliderMassProperties3d)
  EcsPayload_physics3d_RestitutionCombineRule3d(RestitutionCombineRule3d)
  EcsPayload_physics3d_AdditionalMassProperties3d(AdditionalMassProperties3d)
  EcsPayload_physics3d_RapierImpulseJointHandle3d(RapierImpulseJointHandle3d)
  EcsPayload_physics3d_AdditionalSolverIterations3d(
    AdditionalSolverIterations3d
  )
  EcsPayload_physics3d_ContactForceEventThreshold3d(
    ContactForceEventThreshold3d
  )
  EcsPayload_physics3d_RapierMultibodyJointHandle3d(
    RapierMultibodyJointHandle3d
  )
  EcsPayload_physics3d_KinematicCharacterController3d(
    KinematicCharacterController3d
  )
  EcsPayload_physics3d_KinematicCharacterControllerOutput3d(
    KinematicCharacterControllerOutput3d
  )
  EcsPayload_physics3d_Physics3dConfig(Physics3dConfig)
  EcsPayload_physics3d_Physics3dEvents(Physics3dEvents)
  EcsPayload_physics3d_Physics3dContext(Physics3dContext)
  EcsPayload_physics3d_Physics3dHooksConfig(Physics3dHooksConfig)
}

///|
pub impl @ecs.EcsPayloadCodec for Ccd3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Ccd3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Ccd3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Ccd3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Damping3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Damping3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Damping3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Damping3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Collider3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Collider3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Collider3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Collider3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Friction3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Friction3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Friction3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Friction3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Sleeping3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Sleeping3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Sleeping3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Sleeping3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Velocity3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Velocity3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Velocity3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Velocity3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Dominance3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Dominance3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Dominance3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Dominance3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBody3d with to_ecs_payload(self) {
  EcsPayload_physics3d_RigidBody3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBody3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_RigidBody3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LockedAxes3d with to_ecs_payload(self) {
  EcsPayload_physics3d_LockedAxes3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LockedAxes3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_LockedAxes3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveHooks3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ActiveHooks3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveHooks3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_ActiveHooks3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContactSkin3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ContactSkin3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContactSkin3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_ContactSkin3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Restitution3d with to_ecs_payload(self) {
  EcsPayload_physics3d_Restitution3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Restitution3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Restitution3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveEvents3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ActiveEvents3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveEvents3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_ActiveEvents3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GravityScale3d with to_ecs_payload(self) {
  EcsPayload_physics3d_GravityScale3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GravityScale3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_GravityScale3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ImpulseJoint3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ImpulseJoint3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ImpulseJoint3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_ImpulseJoint3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SolverGroups3d with to_ecs_payload(self) {
  EcsPayload_physics3d_SolverGroups3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SolverGroups3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_SolverGroups3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalForce3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ExternalForce3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalForce3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_ExternalForce3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderParent3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ColliderParent3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderParent3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ColliderParent3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MultibodyJoint3d with to_ecs_payload(self) {
  EcsPayload_physics3d_MultibodyJoint3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MultibodyJoint3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_MultibodyJoint3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderDensity3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ColliderDensity3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderDensity3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ColliderDensity3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderEnabled3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ColliderEnabled3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderEnabled3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ColliderEnabled3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CollisionGroups3d with to_ecs_payload(self) {
  EcsPayload_physics3d_CollisionGroups3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CollisionGroups3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_CollisionGroups3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalImpulse3d with to_ecs_payload(self) {
  EcsPayload_physics3d_ExternalImpulse3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ExternalImpulse3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ExternalImpulse3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierBodyHandle3d with to_ecs_payload(self) {
  EcsPayload_physics3d_RapierBodyHandle3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierBodyHandle3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_RapierBodyHandle3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBodyEnabled3d with to_ecs_payload(self) {
  EcsPayload_physics3d_RigidBodyEnabled3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RigidBodyEnabled3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_RigidBodyEnabled3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FrictionCombineRule3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_FrictionCombineRule3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FrictionCombineRule3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_FrictionCombineRule3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveCollisionTypes3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_ActiveCollisionTypes3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ActiveCollisionTypes3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ActiveCollisionTypes3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierColliderHandle3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_RapierColliderHandle3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierColliderHandle3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_RapierColliderHandle3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderMassProperties3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_ColliderMassProperties3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColliderMassProperties3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ColliderMassProperties3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RestitutionCombineRule3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_RestitutionCombineRule3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RestitutionCombineRule3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_RestitutionCombineRule3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalMassProperties3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_AdditionalMassProperties3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalMassProperties3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_AdditionalMassProperties3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierImpulseJointHandle3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_RapierImpulseJointHandle3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierImpulseJointHandle3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_RapierImpulseJointHandle3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalSolverIterations3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_AdditionalSolverIterations3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AdditionalSolverIterations3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_AdditionalSolverIterations3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContactForceEventThreshold3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_ContactForceEventThreshold3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContactForceEventThreshold3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_ContactForceEventThreshold3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RapierMultibodyJointHandle3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_RapierMultibodyJointHandle3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RapierMultibodyJointHandle3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_RapierMultibodyJointHandle3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterController3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_KinematicCharacterController3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterController3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_KinematicCharacterController3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterControllerOutput3d with to_ecs_payload(
  self,
) {
  EcsPayload_physics3d_KinematicCharacterControllerOutput3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for KinematicCharacterControllerOutput3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_KinematicCharacterControllerOutput3d(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dConfig with to_ecs_payload(self) {
  EcsPayload_physics3d_Physics3dConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Physics3dConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dEvents with to_ecs_payload(self) {
  EcsPayload_physics3d_Physics3dEvents(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dEvents with from_ecs_payload(payload) {
  match payload {
    EcsPayload_physics3d_Physics3dEvents(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dContext with to_ecs_payload(self) {
  EcsPayload_physics3d_Physics3dContext(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dContext with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_Physics3dContext(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dHooksConfig with to_ecs_payload(self) {
  EcsPayload_physics3d_Physics3dHooksConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Physics3dHooksConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_physics3d_Physics3dHooksConfig(value) => Some(value)
    _ => None
  }
}
