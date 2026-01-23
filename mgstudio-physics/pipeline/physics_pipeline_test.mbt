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
/// Ported from rapier/src/pipeline/physics_pipeline.rs (kinematic_and_fixed_contact_crash).
test "kinematic and fixed contact crash" {
  let colliders = @collision.ColliderSet::new()
  let impulse_joints = @dynamics.ImpulseJointSet::new()
  let multibody_joints = @dynamics.MultibodyJointSet::new()
  let pipeline = PhysicsPipeline::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let bodies = @dynamics.RigidBodySet::new()
  let islands = @dynamics.IslandManager::new()
  let rb_fixed = @dynamics.RigidBodyBuilder::fixed().build()
  let h1 = bodies.insert(rb_fixed)
  let co = @collision.ColliderBuilder::ball(10.0F).build()
  colliders.insert_with_parent(co, h1, bodies) |> ignore
  let rb_kinematic = @dynamics.RigidBodyBuilder::kinematic_position_based().build()
  let h2 = bodies.insert(rb_kinematic)
  let co2 = @collision.ColliderBuilder::ball(10.0F).build()
  colliders.insert_with_parent(co2, h2, bodies) |> ignore
  pipeline.step(
    @core.Vec2::zero(),
    IntegrationParameters::default(),
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    impulse_joints,
    multibody_joints,
    @dynamics.CCDSolver::new(),
    (),
    (),
  )
}

///|
/// Ported from rapier/src/pipeline/physics_pipeline.rs (rigid_body_removal_before_step).
test "rigid body removal before step" {
  let colliders = @collision.ColliderSet::new()
  let impulse_joints = @dynamics.ImpulseJointSet::new()
  let multibody_joints = @dynamics.MultibodyJointSet::new()
  let pipeline = PhysicsPipeline::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let islands = @dynamics.IslandManager::new()
  let bodies = @dynamics.RigidBodySet::new()
  let h1 = bodies.insert(@dynamics.RigidBodyBuilder::dynamic().build())
  let h2 = bodies.insert(@dynamics.RigidBodyBuilder::dynamic().build())
  let h3 = bodies.insert(
    @dynamics.RigidBodyBuilder::kinematic_position_based().build(),
  )
  let h4 = bodies.insert(@dynamics.RigidBodyBuilder::fixed().build())
  let to_delete = [h1, h2, h3, h4]
  for h in to_delete {
    bodies.remove(h, islands, (), impulse_joints, multibody_joints, true)
    |> ignore
  }
  pipeline.step(
    @core.Vec2::zero(),
    IntegrationParameters::default(),
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    impulse_joints,
    multibody_joints,
    @dynamics.CCDSolver::new(),
    (),
    (),
  )
}

///|
/// Ported from rapier/src/pipeline/physics_pipeline.rs (collider_removal_before_step).
test "collider removal before step" {
  let pipeline = PhysicsPipeline::new()
  let gravity = @core.Vec2::new(0.0F, -9.81F)
  let integration_parameters = IntegrationParameters::default()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let bodies = @dynamics.RigidBodySet::new()
  let colliders = @collision.ColliderSet::new()
  let ccd = @dynamics.CCDSolver::new()
  let impulse_joints = @dynamics.ImpulseJointSet::new()
  let multibody_joints = @dynamics.MultibodyJointSet::new()
  let islands = @dynamics.IslandManager::new()
  let body = @dynamics.RigidBodyBuilder::dynamic().build()
  let b_handle = bodies.insert(body)
  let collider = @collision.ColliderBuilder::ball(1.0F).build()
  let c_handle = colliders.insert_with_parent(collider, b_handle, bodies)
  colliders.remove(c_handle, islands, bodies, true)
  bodies.remove(b_handle, islands, (), impulse_joints, multibody_joints, true)
  |> ignore
  for _ in 0..<10 {
    pipeline.step(
      gravity,
      integration_parameters,
      islands,
      broad_phase,
      narrow_phase,
      bodies,
      colliders,
      impulse_joints,
      multibody_joints,
      ccd,
      (),
      (),
    )
  }
}

///|
/// Ported from rapier/src/pipeline/physics_pipeline.rs (rigid_body_type_changed_dynamic_is_in_active_set).
test "rigid body type changed dynamic is in active set" {
  let colliders = @collision.ColliderSet::new()
  let impulse_joints = @dynamics.ImpulseJointSet::new()
  let multibody_joints = @dynamics.MultibodyJointSet::new()
  let pipeline = PhysicsPipeline::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let islands = @dynamics.IslandManager::new()
  let bodies = @dynamics.RigidBodySet::new()
  let rb = @dynamics.RigidBodyBuilder::kinematic_position_based()
    .additional_mass(1.0F)
    .build()
  let h = bodies.insert(rb)
  let gravity = @core.Vec2::new(0.0F, -9.81F)
  pipeline.step(
    gravity,
    IntegrationParameters::default(),
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    impulse_joints,
    multibody_joints,
    @dynamics.CCDSolver::new(),
    (),
    (),
  )
  if bodies.get_mut(h) is Some(body) {
    body.set_body_type(@dynamics.RigidBodyType::Dynamic, true) |> ignore
  }
  pipeline.step(
    gravity,
    IntegrationParameters::default(),
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    impulse_joints,
    multibody_joints,
    @dynamics.CCDSolver::new(),
    (),
    (),
  )
  if bodies.get(h) is Some(body_after) {
    let position = body_after.translation()
    inspect(position.y < 0.0F, content="true")
    inspect(body_after.is_sleeping(), content="false")
  }
}

///|
/// Ported from rapier/src/pipeline/physics_pipeline.rs (joint_step_delta_time_0).
test "joint step delta time 0" {
  let colliders = @collision.ColliderSet::new()
  let impulse_joints = @dynamics.ImpulseJointSet::new()
  let multibody_joints = @dynamics.MultibodyJointSet::new()
  let pipeline = PhysicsPipeline::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let islands = @dynamics.IslandManager::new()
  let bodies = @dynamics.RigidBodySet::new()
  let rb_fixed = @dynamics.RigidBodyBuilder::fixed()
    .additional_mass(1.0F)
    .build()
  let h_fixed = bodies.insert(rb_fixed)
  let rb_dynamic = @dynamics.RigidBodyBuilder::dynamic()
    .additional_mass(1.0F)
    .build()
  let h_dynamic = bodies.insert(rb_dynamic)
  let joint = @dynamics.GenericJoint::from_revolute(
    @dynamics.RevoluteJointBuilder::new()
    .local_anchor1(@core.Vec2::new(0.0F, 1.0F))
    .local_anchor2(@core.Vec2::new(0.0F, -3.0F))
    .build(),
  )
  impulse_joints.insert(h_fixed, h_dynamic, joint, true) |> ignore
  let parameters = IntegrationParameters::default().with_dt(0.0F)
  let gravity = @core.Vec2::new(0.0F, -9.81F)
  pipeline.step(
    gravity,
    parameters,
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    impulse_joints,
    multibody_joints,
    @dynamics.CCDSolver::new(),
    (),
    (),
  )
  if bodies.get(h_dynamic) is Some(body) {
    let translation = body.translation()
    let rotation = body.rotation()
    inspect(translation.x == translation.x, content="true")
    inspect(translation.y == translation.y, content="true")
    inspect(rotation.sin == rotation.sin, content="true")
    inspect(rotation.cos == rotation.cos, content="true")
  }
}

///|
/// Ported from rapier/src/pipeline/physics_pipeline.rs (test_multi_sap_disable_body).
test "multi sap disable body" {
  let rigid_body_set = @dynamics.RigidBodySet::new()
  let collider_set = @collision.ColliderSet::new()
  let ground = @collision.ColliderBuilder::cuboid(100.0F, 0.1F).build()
  collider_set.insert(ground) |> ignore
  let rigid_body = @dynamics.RigidBodyBuilder::dynamic()
    .translation(@core.Vec2::new(0.0F, 10.0F))
    .build()
  let collider = @collision.ColliderBuilder::ball(0.5F)
    .restitution(0.7F)
    .build()
  let ball_body_handle = rigid_body_set.insert(rigid_body)
  collider_set.insert_with_parent(collider, ball_body_handle, rigid_body_set)
  |> ignore
  let gravity = @core.Vec2::new(0.0F, -9.81F)
  let integration_parameters = IntegrationParameters::default()
  let physics_pipeline = PhysicsPipeline::new()
  let island_manager = @dynamics.IslandManager::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let impulse_joint_set = @dynamics.ImpulseJointSet::new()
  let multibody_joint_set = @dynamics.MultibodyJointSet::new()
  let ccd_solver = @dynamics.CCDSolver::new()
  physics_pipeline.step(
    gravity,
    integration_parameters,
    island_manager,
    broad_phase,
    narrow_phase,
    rigid_body_set,
    collider_set,
    impulse_joint_set,
    multibody_joint_set,
    ccd_solver,
    (),
    (),
  )
  if rigid_body_set.get_mut(ball_body_handle) is Some(ball_body) {
    ball_body.set_translation(@core.Vec2::new(1.0F, 1.0F), true) |> ignore
    ball_body.set_rotation(@core.Rot2::from_angle(1.0F), true) |> ignore
    ball_body.set_enabled(false) |> ignore
  }
  physics_pipeline.step(
    gravity,
    integration_parameters,
    island_manager,
    broad_phase,
    narrow_phase,
    rigid_body_set,
    collider_set,
    impulse_joint_set,
    multibody_joint_set,
    ccd_solver,
    (),
    (),
  )
  if rigid_body_set.get_mut(ball_body_handle) is Some(ball_body) {
    ball_body.set_translation(@core.Vec2::new(0.0F, 0.0F), true) |> ignore
    ball_body.set_rotation(@core.Rot2::from_angle(0.0F), true) |> ignore
    ball_body.set_enabled(true) |> ignore
  }
  physics_pipeline.step(
    gravity,
    integration_parameters,
    island_manager,
    broad_phase,
    narrow_phase,
    rigid_body_set,
    collider_set,
    impulse_joint_set,
    multibody_joint_set,
    ccd_solver,
    (),
    (),
  )
}

///|
/// Ported from rapier/src/pipeline/physics_pipeline.rs (rigid_body_removal_snapshot_handle_determinism).
test "rigid body removal snapshot handle determinism" {
  let colliders = @collision.ColliderSet::new()
  let impulse_joints = @dynamics.ImpulseJointSet::new()
  let multibody_joints = @dynamics.MultibodyJointSet::new()
  let islands = @dynamics.IslandManager::new()
  let bodies = @dynamics.RigidBodySet::new()
  let rb = @dynamics.RigidBodyBuilder::dynamic().build()
  let h1 = bodies.insert(rb)
  let h2 = bodies.insert(rb)
  let h3 = bodies.insert(rb)
  bodies.remove(h1, islands, (), impulse_joints, multibody_joints, true)
  |> ignore
  bodies.remove(h3, islands, (), impulse_joints, multibody_joints, true)
  |> ignore
  bodies.remove(h2, islands, (), impulse_joints, multibody_joints, true)
  |> ignore
  let snapshot = bodies.serialize()
  let bodies2 = @dynamics.RigidBodySet::deserialize(snapshot)
  let h1a = bodies.insert(rb)
  let h2a = bodies.insert(rb)
  let h3a = bodies.insert(rb)
  let h1b = bodies2.insert(rb)
  let h2b = bodies2.insert(rb)
  let h3b = bodies2.insert(rb)
  inspect(@dynamics.RigidBodyHandle::equals(h1a, h1b), content="true")
  inspect(@dynamics.RigidBodyHandle::equals(h2a, h2b), content="true")
  inspect(@dynamics.RigidBodyHandle::equals(h3a, h3b), content="true")
  colliders |> ignore
}
