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
pub struct PhysicsPipeline {}

///|
pub fn PhysicsPipeline::new() -> PhysicsPipeline {
  PhysicsPipeline::{  }
}

///|
fn is_dynamic_body(body : @dynamics.RigidBody) -> Bool {
  match body.body_type {
    @dynamics.RigidBodyType::Dynamic => true
    _ => false
  }
}

///|
fn apply_body_translation(
  bodies : @dynamics.RigidBodySet,
  handle : @dynamics.RigidBodyHandle,
  delta : @core.Vec2,
) -> Unit {
  if bodies.get_mut(handle) is Some(body) {
    let translation = body.translation()
    body.set_translation(translation.add(delta), true) |> ignore
  }
}

///|
fn min_value(a : @core.Real, b : @core.Real) -> @core.Real {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_value(a : @core.Real, b : @core.Real) -> @core.Real {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp_value(
  value : @core.Real,
  min_val : @core.Real,
  max_val : @core.Real,
) -> @core.Real {
  max_value(min_val, min_value(max_val, value))
}

///|
fn separation_ball_ball(
  pos1 : @core.Vec2,
  r1 : @core.Real,
  pos2 : @core.Vec2,
  r2 : @core.Real,
) -> @core.Vec2? {
  let delta = pos1.sub(pos2)
  let dist = delta.length()
  let radius = r1 + r2
  if dist > radius {
    None
  } else {
    let dir = if dist <= 1.0e-6F {
      @core.Vec2::new(1.0F, 0.0F)
    } else {
      delta.normalize()
    }
    let depth = radius - dist
    Some(@core.Vec2::new(dir.x * depth, dir.y * depth))
  }
}

///|
fn separation_cuboid_cuboid(
  pos1 : @core.Vec2,
  hw1 : @core.Real,
  hh1 : @core.Real,
  pos2 : @core.Vec2,
  hw2 : @core.Real,
  hh2 : @core.Real,
) -> @core.Vec2? {
  let dx = pos1.x - pos2.x
  let dy = pos1.y - pos2.y
  let overlap_x = hw1 + hw2 - @core.abs(dx)
  let overlap_y = hh1 + hh2 - @core.abs(dy)
  if overlap_x <= 0.0F || overlap_y <= 0.0F {
    return None
  }
  if overlap_x < overlap_y {
    let sign = if dx < 0.0F { -1.0F } else { 1.0F }
    Some(@core.Vec2::new(sign * overlap_x, 0.0F))
  } else {
    let sign = if dy < 0.0F { -1.0F } else { 1.0F }
    Some(@core.Vec2::new(0.0F, sign * overlap_y))
  }
}

///|
fn separation_ball_cuboid(
  ball_pos : @core.Vec2,
  radius : @core.Real,
  cuboid_pos : @core.Vec2,
  half_width : @core.Real,
  half_height : @core.Real,
) -> @core.Vec2? {
  let dx = clamp_value(ball_pos.x - cuboid_pos.x, -half_width, half_width)
  let dy = clamp_value(ball_pos.y - cuboid_pos.y, -half_height, half_height)
  let closest = @core.Vec2::new(cuboid_pos.x + dx, cuboid_pos.y + dy)
  let delta = ball_pos.sub(closest)
  let dist = delta.length()
  if dist > radius {
    None
  } else {
    let dir = if dist <= 1.0e-6F {
      @core.Vec2::new(1.0F, 0.0F)
    } else {
      delta.normalize()
    }
    let depth = radius - dist
    Some(@core.Vec2::new(dir.x * depth, dir.y * depth))
  }
}

///|
fn separation_vector(
  shape1 : @collision.Shape,
  pos1 : @core.Vec2,
  shape2 : @collision.Shape,
  pos2 : @core.Vec2,
) -> @core.Vec2? {
  match (shape1, shape2) {
    (@collision.Shape::Ball(r1), @collision.Shape::Ball(r2)) =>
      separation_ball_ball(pos1, r1, pos2, r2)
    (@collision.Shape::Cuboid(hw1, hh1), @collision.Shape::Cuboid(hw2, hh2)) =>
      separation_cuboid_cuboid(pos1, hw1, hh1, pos2, hw2, hh2)
    (@collision.Shape::Ball(r), @collision.Shape::Cuboid(hw, hh)) =>
      separation_ball_cuboid(pos1, r, pos2, hw, hh)
    (@collision.Shape::Cuboid(hw, hh), @collision.Shape::Ball(r)) =>
      if separation_ball_cuboid(pos2, r, pos1, hw, hh) is Some(sep) {
        Some(@core.Vec2::new(-sep.x, -sep.y))
      } else {
        None
      }
  }
}

///|
fn resolve_contact(
  bodies : @dynamics.RigidBodySet,
  colliders : @collision.ColliderSet,
  first : @collision.ColliderHandle,
  second : @collision.ColliderHandle,
) -> Unit {
  if colliders.get(first) is Some(collider1) &&
    colliders.get(second) is Some(collider2) {
    if collider1.sensor || collider2.sensor {
      return
    }
    let pos1 = collider1.translation()
    let pos2 = collider2.translation()
    let separation = separation_vector(
      collider1.shape,
      pos1,
      collider2.shape,
      pos2,
    )
    if separation is None {
      return
    }
    let sep = separation.unwrap()
    let mut move1 = false
    let mut move2 = false
    if collider1.parent is Some(parent1) {
      if bodies.get(parent1) is Some(body1) {
        move1 = body1.enabled && is_dynamic_body(body1)
      }
    }
    if collider2.parent is Some(parent2) {
      if bodies.get(parent2) is Some(body2) {
        move2 = body2.enabled && is_dynamic_body(body2)
      }
    }
    if collider1.parent is Some(parent1) && collider2.parent is Some(parent2) {
      if move1 && move2 {
        let half = @core.Vec2::new(sep.x * 0.5F, sep.y * 0.5F)
        apply_body_translation(bodies, parent1, half)
        apply_body_translation(
          bodies,
          parent2,
          @core.Vec2::new(-half.x, -half.y),
        )
      } else if move1 {
        apply_body_translation(bodies, parent1, sep)
      } else if move2 {
        apply_body_translation(bodies, parent2, @core.Vec2::new(-sep.x, -sep.y))
      }
    } else if collider1.parent is Some(parent1) {
      if move1 {
        apply_body_translation(bodies, parent1, sep)
      }
    } else if collider2.parent is Some(parent2) {
      if move2 {
        apply_body_translation(bodies, parent2, @core.Vec2::new(-sep.x, -sep.y))
      }
    }
  }
}

///|
fn handle_user_changes_to_bodies(
  islands : @dynamics.IslandManager,
  bodies : @dynamics.RigidBodySet,
  colliders : @collision.ColliderSet,
  impulse_joints : @dynamics.ImpulseJointSet,
  multibody_joints : @dynamics.MultibodyJointSet,
  modified_bodies : Array[@dynamics.RigidBodyHandle],
) -> Unit {
  for i in 0..<modified_bodies.length() {
    let handle = modified_bodies[i]
    if bodies.get(handle) is Some(body) {
      if body.is_enabled() {
        islands.rigid_body_updated(handle, bodies)
      } else {
        islands.rigid_body_removed_or_disabled(handle, bodies)
      }
      colliders.set_parent_enabled(handle, body.is_enabled())
      impulse_joints.map_attached_joints_mut(handle, (
        parent,
        child,
        joint_handle,
        joint,
      ) => {
        parent |> ignore
        child |> ignore
        joint_handle |> ignore
        joint.set_enabled_by_attached_body(body.is_enabled()) |> ignore
      })
      multibody_joints |> ignore
    }
  }
}

///|
fn clear_modified_bodies(
  bodies : @dynamics.RigidBodySet,
  modified_bodies : Array[@dynamics.RigidBodyHandle],
) -> Unit {
  for i in 0..<modified_bodies.length() {
    let handle = modified_bodies[i]
    if bodies.get_mut_internal(handle) is Some(body) {
      body.clear_changes() |> ignore
    }
  }
}

///|
fn clear_modified_colliders(
  colliders : @collision.ColliderSet,
  modified_colliders : Array[@collision.ColliderHandle],
) -> Unit {
  colliders.clear_changes_for(modified_colliders)
}

///|
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
  self |> ignore
  ccd_solver |> ignore
  physics_hooks |> ignore
  event_handler |> ignore
  let wake_from_impulse = impulse_joints.take_wake_up()
  for i in 0..<wake_from_impulse.length() {
    islands.wake_up(bodies, wake_from_impulse[i], true)
  }
  let wake_from_multibody = multibody_joints.take_wake_up()
  for i in 0..<wake_from_multibody.length() {
    islands.wake_up(bodies, wake_from_multibody[i], true)
  }
  let modified_colliders_before_step = colliders.take_modified()
  @collision.handle_user_changes_to_colliders(
    bodies, colliders, modified_colliders_before_step,
  )
  let modified_bodies_before_step = bodies.take_modified()
  handle_user_changes_to_bodies(
    islands, bodies, colliders, impulse_joints, multibody_joints, modified_bodies_before_step,
  )
  let join_from_impulse = impulse_joints.take_to_join()
  for i in 0..<join_from_impulse.length() {
    let pair = join_from_impulse[i]
    islands.interaction_started_or_stopped(
      bodies,
      Some(pair.0),
      Some(pair.1),
      true,
      false,
    )
  }
  let join_from_multibody = multibody_joints.take_to_join()
  for i in 0..<join_from_multibody.length() {
    let pair = join_from_multibody[i]
    islands.interaction_started_or_stopped(
      bodies,
      Some(pair.0),
      Some(pair.1),
      true,
      false,
    )
  }
  let dt = parameters.dt
  let gravity_step = @core.Vec2::new(gravity.x * dt, gravity.y * dt)
  for i in 0..<bodies.bodies.length() {
    if bodies.bodies[i] is Some(body) {
      if body.enabled && is_dynamic_body(body) && !body.is_sleeping() {
        let translation = body.translation()
        body.set_translation(translation.add(gravity_step), true) |> ignore
      }
    }
  }
  let collision_pipeline = CollisionPipeline::new()
  collision_pipeline.step(
    parameters.prediction_distance(),
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    physics_hooks,
    event_handler,
  )
  for i in 0..<narrow_phase.contacts.length() {
    let pair = narrow_phase.contacts[i]
    resolve_contact(bodies, colliders, pair.0, pair.1)
  }
  collision_pipeline.step(
    parameters.prediction_distance(),
    islands,
    broad_phase,
    narrow_phase,
    bodies,
    colliders,
    physics_hooks,
    event_handler,
  )
  let contacts = @dynamics.ContactGraph::new()
  for i in 0..<narrow_phase.contacts.length() {
    let contact = narrow_phase.contacts[i]
    if colliders.get(contact.0) is Some(collider1) &&
      colliders.get(contact.1) is Some(collider2) {
      if collider1.parent is Some(parent1) && collider2.parent is Some(parent2) {
        if !@dynamics.RigidBodyHandle::equals(parent1, parent2) {
          contacts.add_pair(parent1, parent2)
        }
      }
    }
  }
  islands.update_islands(
    dt, 1.0F, bodies, contacts, impulse_joints, multibody_joints,
  )
  let modified_colliders_after_step = colliders.take_modified()
  let modified_bodies_after_step = bodies.take_modified()
  clear_modified_colliders(colliders, modified_colliders_before_step)
  clear_modified_colliders(colliders, modified_colliders_after_step)
  clear_modified_bodies(bodies, modified_bodies_before_step)
  clear_modified_bodies(bodies, modified_bodies_after_step)
}
