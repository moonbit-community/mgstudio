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
pub struct IntegrationParameters {
  dt : @core.Real
}

///|
#declaration_only
pub fn IntegrationParameters::default() -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::with_dt(
  self : IntegrationParameters,
  dt : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::prediction_distance(
  self : IntegrationParameters,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub type CollisionPipeline

///|
#declaration_only
pub fn CollisionPipeline::new() -> CollisionPipeline {
  ...
}

///|
#declaration_only
pub fn CollisionPipeline::step(
  self : CollisionPipeline,
  prediction_distance : @core.Real,
  islands : @dynamics.IslandManager,
  broad_phase : @collision.BroadPhaseBvh,
  narrow_phase : @collision.NarrowPhase,
  bodies : @dynamics.RigidBodySet,
  colliders : @collision.ColliderSet,
  physics_hooks : Unit,
  event_handler : Unit,
) -> Unit {
  ...
}

///|
#declaration_only
pub type PhysicsPipeline

///|
#declaration_only
pub fn PhysicsPipeline::new() -> PhysicsPipeline {
  ...
}

///|
#declaration_only
pub fn PhysicsPipeline::step(
  self : PhysicsPipeline,
  gravity : @core.Vec2,
  parameters : IntegrationParameters,
  islands : @dynamics.IslandManager,
  broad_phase : @collision.BroadPhaseBvh,
  narrow_phase : @collision.NarrowPhase,
  bodies : @dynamics.RigidBodySet,
  colliders : @collision.ColliderSet,
  impulse_joints : @dynamics.ImpulseJointSet,
  multibody_joints : @dynamics.MultibodyJointSet,
  ccd_solver : @dynamics.CCDSolver,
  physics_hooks : Unit,
  event_handler : Unit,
) -> Unit {
  ...
}
