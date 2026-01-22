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
pub struct RigidBodyHandle {
  id : Int
  generation : Int
}

///|
fn RigidBodyHandle::new(id : Int, generation : Int) -> RigidBodyHandle {
  RigidBodyHandle::{ id, generation }
}

///|
pub fn RigidBodyHandle::equals(
  self : RigidBodyHandle,
  other : RigidBodyHandle,
) -> Bool {
  self.id == other.id && self.generation == other.generation
}

///|
pub fn RigidBodyHandle::from_raw_parts(
  id : Int,
  generation : Int,
) -> RigidBodyHandle {
  RigidBodyHandle::new(id, generation)
}

///|
pub fn RigidBodyHandle::into_raw_parts(self : RigidBodyHandle) -> (Int, Int) {
  (self.id, self.generation)
}

///|
pub fn RigidBodyHandle::invalid() -> RigidBodyHandle {
  RigidBodyHandle::new(-1, -1)
}

///|
struct RigidBodyIds {
  mut active_island_id : Int
  mut active_set_id : Int
  mut active_set_timestamp : Int
}

///|
fn RigidBodyIds::default() -> RigidBodyIds {
  { active_island_id: -1, active_set_id: -1, active_set_timestamp: 0 }
}

///|
const RIGID_BODY_CHANGES_IN_MODIFIED_SET : Int = 1 << 0

///|
const RIGID_BODY_CHANGES_POSITION : Int = 1 << 1

///|
const RIGID_BODY_CHANGES_SLEEP : Int = 1 << 2

///|
const RIGID_BODY_CHANGES_COLLIDERS : Int = 1 << 3

///|
const RIGID_BODY_CHANGES_TYPE : Int = 1 << 4

///|
const RIGID_BODY_CHANGES_DOMINANCE : Int = 1 << 5

///|
const RIGID_BODY_CHANGES_LOCAL_MASS_PROPERTIES : Int = 1 << 6

///|
const RIGID_BODY_CHANGES_ENABLED_OR_DISABLED : Int = 1 << 7

///|
const RIGID_BODY_CHANGES_ALL : Int = RIGID_BODY_CHANGES_IN_MODIFIED_SET |
  RIGID_BODY_CHANGES_POSITION |
  RIGID_BODY_CHANGES_SLEEP |
  RIGID_BODY_CHANGES_COLLIDERS |
  RIGID_BODY_CHANGES_TYPE |
  RIGID_BODY_CHANGES_DOMINANCE |
  RIGID_BODY_CHANGES_LOCAL_MASS_PROPERTIES |
  RIGID_BODY_CHANGES_ENABLED_OR_DISABLED

///|
struct RigidBodyChanges {
  mut bits : Int
}

///|
fn RigidBodyChanges::all() -> RigidBodyChanges {
  { bits: RIGID_BODY_CHANGES_ALL }
}

///|
fn RigidBodyChanges::insert(
  self : RigidBodyChanges,
  flag : Int,
) -> RigidBodyChanges {
  self.bits = self.bits | flag
  self
}

///|
fn RigidBodyChanges::contains(self : RigidBodyChanges, flag : Int) -> Bool {
  (self.bits & flag) != 0
}

///|
fn RigidBodyChanges::remove(
  self : RigidBodyChanges,
  flag : Int,
) -> RigidBodyChanges {
  let clear_bits = self.bits & flag
  self.bits = self.bits - clear_bits
  self
}

///|
pub struct RigidBodyDominance {
  mut group : Int
}

///|
pub fn RigidBodyDominance::new(group : Int) -> RigidBodyDominance {
  { group, }
}

///|
pub fn RigidBodyDominance::default() -> RigidBodyDominance {
  RigidBodyDominance::new(0)
}

///|
pub fn RigidBodyDominance::effective_group(
  self : RigidBodyDominance,
  body_type : RigidBodyType,
) -> Int {
  if body_type.is_dynamic_or_kinematic() {
    self.group
  } else {
    128
  }
}

///|
pub fn RigidBodyType::is_fixed(self : RigidBodyType) -> Bool {
  self is RigidBodyType::Fixed
}

///|
pub fn RigidBodyType::is_dynamic(self : RigidBodyType) -> Bool {
  self is RigidBodyType::Dynamic
}

///|
pub fn RigidBodyType::is_kinematic(self : RigidBodyType) -> Bool {
  self is RigidBodyType::KinematicPositionBased ||
  self is RigidBodyType::KinematicVelocityBased
}

///|
pub fn RigidBodyType::is_dynamic_or_kinematic(self : RigidBodyType) -> Bool {
  !self.is_fixed()
}

///|
pub struct RigidBodyPosition {
  mut position : @core.Isometry2
  mut next_position : @core.Isometry2
}

///|
pub fn RigidBodyPosition::new(
  position : @core.Isometry2,
  next_position : @core.Isometry2,
) -> RigidBodyPosition {
  { position, next_position }
}

///|
pub fn RigidBodyPosition::interpolate_velocity(
  self : RigidBodyPosition,
  inv_dt : @core.Real,
  local_com : @core.Vec2,
) -> RigidBodyVelocity {
  let com = self.position.transform_point(local_com)
  let shift = @core.Isometry2::from_translation(com)
  let dpos = shift
    .inverse()
    .mul(self.next_position)
    .mul(self.position.inverse())
    .mul(shift)
  let angular = dpos.rotation.angle()
  let linear = dpos.translation
  RigidBodyVelocity::{
    linvel: @core.Vec2::new(linear.x * inv_dt, linear.y * inv_dt),
    angvel: angular * inv_dt,
  }
}

///|
pub fn RigidBodyPosition::integrate_forces_and_velocities(
  self : RigidBodyPosition,
  dt : @core.Real,
  forces : RigidBodyForces,
  vels : RigidBodyVelocity,
  mprops : RigidBodyMassProps,
) -> @core.Isometry2 {
  let new_vels = forces.integrate(dt, vels, mprops)
  let local_com = mprops.local_mprops.center_of_mass
  new_vels.integrate(dt, self.position, local_com)
}

///|
pub struct RigidBodyVelocity {
  mut linvel : @core.Vec2
  mut angvel : @core.Real
}

///|
pub fn RigidBodyVelocity::integrate(
  self : RigidBodyVelocity,
  dt : @core.Real,
  curr_pos : @core.Isometry2,
  local_com : @core.Vec2,
) -> @core.Isometry2 {
  let com = curr_pos.transform_point(local_com)
  let shift = @core.Isometry2::from_translation(@core.Vec2::new(-com.x, -com.y))
  let rot = @core.Isometry2::new(
    @core.Vec2::zero(),
    @core.Rot2::from_angle(self.angvel * dt),
  )
  let translation = @core.Vec2::new(self.linvel.x * dt, self.linvel.y * dt)
  let unshift = @core.Isometry2::from_translation(com.add(translation))
  unshift.mul(rot).mul(shift).mul(curr_pos)
}

///|
pub fn RigidBodyVelocity::zero() -> RigidBodyVelocity {
  { linvel: @core.Vec2::zero(), angvel: 0.0F }
}

///|
pub fn RigidBodyVelocity::apply_damping(
  self : RigidBodyVelocity,
  dt : @core.Real,
  damping : RigidBodyDamping,
) -> RigidBodyVelocity {
  let lin_scale = 1.0F / (1.0F + dt * damping.linear_damping)
  let ang_scale = 1.0F / (1.0F + dt * damping.angular_damping)
  {
    linvel: @core.Vec2::new(
      self.linvel.x * lin_scale,
      self.linvel.y * lin_scale,
    ),
    angvel: self.angvel * ang_scale,
  }
}

///|
const DEFAULT_SLEEP_LINEAR_THRESHOLD : @core.Real = 0.4F

///|
const DEFAULT_SLEEP_ANGULAR_THRESHOLD : @core.Real = 0.5F

///|
const DEFAULT_TIME_UNTIL_SLEEP : @core.Real = 2.0F

///|
enum SleepRootState {
  Unknown
  TraversalPending
  Traversed
}

///|
pub struct RigidBodyActivation {
  mut normalized_linear_threshold : @core.Real
  mut angular_threshold : @core.Real
  mut time_until_sleep : @core.Real
  mut time_since_can_sleep : @core.Real
  mut sleeping : Bool
  mut sleep_root_state : SleepRootState
}

///|
pub fn RigidBodyActivation::default() -> RigidBodyActivation {
  RigidBodyActivation::active()
}

///|
pub fn RigidBodyActivation::default_normalized_linear_threshold() -> @core.Real {
  DEFAULT_SLEEP_LINEAR_THRESHOLD
}

///|
pub fn RigidBodyActivation::default_angular_threshold() -> @core.Real {
  DEFAULT_SLEEP_ANGULAR_THRESHOLD
}

///|
pub fn RigidBodyActivation::default_time_until_sleep() -> @core.Real {
  DEFAULT_TIME_UNTIL_SLEEP
}

///|
pub fn RigidBodyActivation::active() -> RigidBodyActivation {
  {
    normalized_linear_threshold: RigidBodyActivation::default_normalized_linear_threshold(),
    angular_threshold: RigidBodyActivation::default_angular_threshold(),
    time_until_sleep: RigidBodyActivation::default_time_until_sleep(),
    time_since_can_sleep: 0.0F,
    sleeping: false,
    sleep_root_state: SleepRootState::Unknown,
  }
}

///|
pub fn RigidBodyActivation::inactive() -> RigidBodyActivation {
  {
    normalized_linear_threshold: RigidBodyActivation::default_normalized_linear_threshold(),
    angular_threshold: RigidBodyActivation::default_angular_threshold(),
    time_until_sleep: RigidBodyActivation::default_time_until_sleep(),
    time_since_can_sleep: RigidBodyActivation::default_time_until_sleep(),
    sleeping: true,
    sleep_root_state: SleepRootState::Unknown,
  }
}

///|
pub fn RigidBodyActivation::cannot_sleep() -> RigidBodyActivation {
  let active = RigidBodyActivation::active()
  active.normalized_linear_threshold = -1.0F
  active.angular_threshold = -1.0F
  active
}

///|
pub fn RigidBodyActivation::is_active(self : RigidBodyActivation) -> Bool {
  !self.sleeping
}

///|
pub fn RigidBodyActivation::wake_up(
  self : RigidBodyActivation,
  strong : Bool,
) -> RigidBodyActivation {
  self.sleeping = false
  if !(self.sleep_root_state is SleepRootState::TraversalPending) {
    self.sleep_root_state = SleepRootState::Unknown
  }
  if strong {
    self.time_since_can_sleep = 0.0F
  }
  self
}

///|
pub fn RigidBodyActivation::sleep(
  self : RigidBodyActivation,
) -> RigidBodyActivation {
  self.sleeping = true
  self.time_since_can_sleep = self.time_until_sleep
  self
}

///|
pub fn RigidBodyActivation::is_eligible_for_sleep(
  self : RigidBodyActivation,
) -> Bool {
  self.time_since_can_sleep >= self.time_until_sleep
}

///|
pub fn RigidBodyActivation::update_energy(
  self : RigidBodyActivation,
  body_type : RigidBodyType,
  length_unit : @core.Real,
  sq_linvel : @core.Real,
  sq_angvel : @core.Real,
  dt : @core.Real,
) -> RigidBodyActivation {
  if self.normalized_linear_threshold < 0.0F || self.angular_threshold < 0.0F {
    self.time_since_can_sleep = 0.0F
    return self
  }
  let can_sleep = match body_type {
    RigidBodyType::Dynamic => {
      let linear_threshold = self.normalized_linear_threshold * length_unit
      sq_linvel < linear_threshold * linear_threshold &&
      sq_angvel < self.angular_threshold * self.angular_threshold
    }
    RigidBodyType::KinematicPositionBased =>
      sq_linvel == 0.0F && sq_angvel == 0.0F
    RigidBodyType::KinematicVelocityBased =>
      sq_linvel == 0.0F && sq_angvel == 0.0F
    RigidBodyType::Fixed => true
  }
  if can_sleep {
    self.time_since_can_sleep = self.time_since_can_sleep + dt
  } else {
    self.time_since_can_sleep = 0.0F
  }
  self
}

///|
pub struct RigidBodyDamping {
  mut linear_damping : @core.Real
  mut angular_damping : @core.Real
}

///|
pub fn RigidBodyDamping::default() -> RigidBodyDamping {
  { linear_damping: 0.0F, angular_damping: 0.0F }
}

///|
pub struct RigidBodyForces {
  mut force : @core.Vec2
  mut torque : @core.Real
  mut gravity_scale : @core.Real
  mut user_force : @core.Vec2
  mut user_torque : @core.Real
}

///|
pub fn RigidBodyForces::default() -> RigidBodyForces {
  {
    force: @core.Vec2::zero(),
    torque: 0.0F,
    gravity_scale: 1.0F,
    user_force: @core.Vec2::zero(),
    user_torque: 0.0F,
  }
}

///|
pub fn RigidBodyForces::integrate(
  self : RigidBodyForces,
  dt : @core.Real,
  init_vels : RigidBodyVelocity,
  mprops : RigidBodyMassProps,
) -> RigidBodyVelocity {
  let linear_acc = @core.Vec2::new(
    self.force.x * mprops.effective_inv_mass.x,
    self.force.y * mprops.effective_inv_mass.y,
  )
  let angular_acc = mprops.effective_world_inv_inertia * self.torque
  {
    linvel: @core.Vec2::new(
      init_vels.linvel.x + linear_acc.x * dt,
      init_vels.linvel.y + linear_acc.y * dt,
    ),
    angvel: init_vels.angvel + angular_acc * dt,
  }
}

///|
pub fn RigidBodyForces::compute_effective_force_and_torque(
  self : RigidBodyForces,
  gravity : @core.Vec2,
  mass : @core.Vec2,
) -> RigidBodyForces {
  self.force = @core.Vec2::new(
    self.user_force.x + gravity.x * mass.x * self.gravity_scale,
    self.user_force.y + gravity.y * mass.y * self.gravity_scale,
  )
  self.torque = self.user_torque
  self
}

///|
pub fn RigidBodyForces::apply_force_at_point(
  self : RigidBodyForces,
  rb_mprops : RigidBodyMassProps,
  force : @core.Vec2,
  point : @core.Vec2,
) -> RigidBodyForces {
  self.user_force = self.user_force.add(force)
  let delta = @core.Vec2::new(
    point.x - rb_mprops.world_com.x,
    point.y - rb_mprops.world_com.y,
  )
  self.user_torque = self.user_torque + delta.cross(force)
  self
}

///|
const DEFAULT_CCD_THICKNESS : @core.Real = 1.0e30F

///|
pub struct RigidBodyCcd {
  ccd_thickness : @core.Real
  ccd_max_dist : @core.Real
  ccd_active : Bool
  mut ccd_enabled : Bool
  mut soft_ccd_prediction : @core.Real
}

///|
pub fn RigidBodyCcd::default() -> RigidBodyCcd {
  {
    ccd_thickness: DEFAULT_CCD_THICKNESS,
    ccd_max_dist: 0.0F,
    ccd_active: false,
    ccd_enabled: false,
    soft_ccd_prediction: 0.0F,
  }
}

///|
pub fn RigidBodyCcd::max_point_velocity(
  self : RigidBodyCcd,
  vels : RigidBodyVelocity,
) -> @core.Real {
  vels.linvel.length() + @core.abs(vels.angvel) * self.ccd_max_dist
}

///|
pub fn RigidBodyCcd::is_moving_fast(
  self : RigidBodyCcd,
  dt : @core.Real,
  vels : RigidBodyVelocity,
  forces : RigidBodyForces?,
) -> Bool {
  let threshold = self.ccd_thickness / 10.0F
  if forces is Some(active_forces) {
    let force_term = @core.Vec2::new(
      active_forces.force.x * dt,
      active_forces.force.y * dt,
    )
    let linvel = @core.Vec2::new(
      vels.linvel.x + force_term.x,
      vels.linvel.y + force_term.y,
    )
    let angular = vels.angvel + active_forces.torque * dt
    let angular_part = @core.abs(angular) * self.ccd_max_dist
    linvel.length() + angular_part > threshold
  } else {
    self.max_point_velocity(vels) * dt > threshold
  }
}

///|
pub struct RigidBodyMassProps {
  mut world_com : @core.Vec2
  mut effective_inv_mass : @core.Vec2
  mut effective_world_inv_inertia : @core.Real
  local_mprops : @core.MassProperties
}

///|
pub fn RigidBodyMassProps::default() -> RigidBodyMassProps {
  {
    world_com: @core.Vec2::zero(),
    effective_inv_mass: @core.Vec2::zero(),
    effective_world_inv_inertia: 0.0F,
    local_mprops: @core.MassProperties::new(0.0F, 0.0F, @core.Vec2::zero()),
  }
}

///|
pub fn RigidBodyMassProps::set_effective_inv_mass(
  self : RigidBodyMassProps,
  inv_mass : @core.Vec2,
) -> RigidBodyMassProps {
  self.effective_inv_mass = inv_mass
  self
}

///|
pub fn RigidBodyMassProps::set_effective_world_inv_inertia(
  self : RigidBodyMassProps,
  inv_inertia : @core.Real,
) -> RigidBodyMassProps {
  self.effective_world_inv_inertia = inv_inertia
  self
}

///|
pub struct RigidBody {
  mut ids : RigidBodyIds
  position : RigidBodyPosition
  mut body_type : RigidBodyType
  dominance : RigidBodyDominance
  mut enabled : Bool
  mut activation : RigidBodyActivation
  mut damping : RigidBodyDamping
  mut vels : RigidBodyVelocity
  mut forces : RigidBodyForces
  mut ccd : RigidBodyCcd
  mut mass_props : RigidBodyMassProps
  mut additional_mass : @core.Real
  mut additional_solver_iterations : Int
  mut changes : RigidBodyChanges
}

///|
pub fn RigidBody::set_body_type(
  self : RigidBody,
  body_type : RigidBodyType,
  wake_up : Bool,
) -> RigidBody {
  if body_type_to_int(self.body_type) != body_type_to_int(body_type) {
    self.changes = self.changes.insert(RIGID_BODY_CHANGES_TYPE)
    self.body_type = body_type
    if body_type is RigidBodyType::Fixed {
      self.vels = RigidBodyVelocity::zero()
    }
    if wake_up && self.is_dynamic_or_kinematic() {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::body_type(self : RigidBody) -> RigidBodyType {
  self.body_type
}

///|
pub fn RigidBody::is_enabled(self : RigidBody) -> Bool {
  self.enabled
}

///|
pub fn RigidBody::is_fixed(self : RigidBody) -> Bool {
  self.body_type.is_fixed()
}

///|
pub fn RigidBody::is_dynamic(self : RigidBody) -> Bool {
  self.body_type.is_dynamic()
}

///|
pub fn RigidBody::is_kinematic(self : RigidBody) -> Bool {
  self.body_type.is_kinematic()
}

///|
pub fn RigidBody::is_dynamic_or_kinematic(self : RigidBody) -> Bool {
  self.body_type.is_dynamic_or_kinematic()
}

///|
pub fn RigidBody::dominance_group(self : RigidBody) -> Int {
  self.dominance.group
}

///|
pub fn RigidBody::effective_dominance_group(self : RigidBody) -> Int {
  self.dominance.effective_group(self.body_type)
}

///|
pub fn RigidBody::set_dominance_group(
  self : RigidBody,
  group : Int,
) -> RigidBody {
  if self.dominance.group != group {
    self.dominance.group = group
    self.changes = self.changes.insert(RIGID_BODY_CHANGES_DOMINANCE)
  }
  self
}

///|
pub fn RigidBody::additional_solver_iterations(self : RigidBody) -> Int {
  self.additional_solver_iterations
}

///|
pub fn RigidBody::additional_mass(self : RigidBody) -> @core.Real {
  self.additional_mass
}

///|
pub fn RigidBody::set_additional_mass(
  self : RigidBody,
  mass : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  if self.additional_mass != mass {
    self.additional_mass = mass
    self.mark_local_mass_properties_changed() |> ignore
    if wake_up && self.is_dynamic_or_kinematic() {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::set_additional_solver_iterations(
  self : RigidBody,
  additional_iterations : Int,
) -> RigidBody {
  self.additional_solver_iterations = additional_iterations
  self
}

///|
pub fn RigidBody::is_sleeping(self : RigidBody) -> Bool {
  self.activation.sleeping
}

///|
pub fn RigidBody::activation(self : RigidBody) -> RigidBodyActivation {
  self.activation
}

///|
pub fn RigidBody::damping(self : RigidBody) -> RigidBodyDamping {
  self.damping
}

///|
pub fn RigidBody::linear_damping(self : RigidBody) -> @core.Real {
  self.damping.linear_damping
}

///|
pub fn RigidBody::set_linear_damping(
  self : RigidBody,
  damping : @core.Real,
) -> RigidBody {
  let state = self.damping
  state.linear_damping = damping
  self.damping = state
  self
}

///|
pub fn RigidBody::angular_damping(self : RigidBody) -> @core.Real {
  self.damping.angular_damping
}

///|
pub fn RigidBody::set_angular_damping(
  self : RigidBody,
  damping : @core.Real,
) -> RigidBody {
  let state = self.damping
  state.angular_damping = damping
  self.damping = state
  self
}

///|
pub fn RigidBody::vels(self : RigidBody) -> RigidBodyVelocity {
  self.vels
}

///|
pub fn RigidBody::linvel(self : RigidBody) -> @core.Vec2 {
  self.vels.linvel
}

///|
pub fn RigidBody::angvel(self : RigidBody) -> @core.Real {
  self.vels.angvel
}

///|
pub fn RigidBody::set_vels(
  self : RigidBody,
  vels : RigidBodyVelocity,
  wake_up : Bool,
) -> RigidBody {
  let updated = self.set_linvel(vels.linvel, wake_up)
  updated.set_angvel(vels.angvel, wake_up)
}

///|
pub fn RigidBody::set_linvel(
  self : RigidBody,
  linvel : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  if !vec2_equal(self.vels.linvel, linvel) {
    if self.body_type is RigidBodyType::Dynamic ||
      self.body_type is RigidBodyType::KinematicVelocityBased {
      self.vels.linvel = linvel
      if wake_up {
        self.wake_up(true) |> ignore
      }
    }
  }
  self
}

///|
pub fn RigidBody::set_angvel(
  self : RigidBody,
  angvel : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  if self.vels.angvel != angvel {
    if self.body_type is RigidBodyType::Dynamic ||
      self.body_type is RigidBodyType::KinematicVelocityBased {
      self.vels.angvel = angvel
      if wake_up {
        self.wake_up(true) |> ignore
      }
    }
  }
  self
}

///|
pub fn RigidBody::apply_impulse(
  self : RigidBody,
  impulse : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  if self.body_type is RigidBodyType::Dynamic {
    let inv_mass = self.mass_props.effective_inv_mass
    self.vels.linvel = self.vels.linvel.add(
      @core.Vec2::new(impulse.x * inv_mass.x, impulse.y * inv_mass.y),
    )
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::apply_torque_impulse(
  self : RigidBody,
  torque_impulse : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  if self.body_type is RigidBodyType::Dynamic {
    self.vels.angvel = self.vels.angvel +
      torque_impulse * self.mass_props.effective_world_inv_inertia
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::apply_impulse_at_point(
  self : RigidBody,
  impulse : @core.Vec2,
  point : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  if self.body_type is RigidBodyType::Dynamic {
    let delta = @core.Vec2::new(
      point.x - self.mass_props.world_com.x,
      point.y - self.mass_props.world_com.y,
    )
    let torque_impulse = delta.cross(impulse)
    self.apply_impulse(impulse, wake_up) |> ignore
    self.apply_torque_impulse(torque_impulse, wake_up) |> ignore
  }
  self
}

///|
pub fn RigidBody::forces(self : RigidBody) -> RigidBodyForces {
  self.forces
}

///|
pub fn RigidBody::gravity_scale(self : RigidBody) -> @core.Real {
  self.forces.gravity_scale
}

///|
pub fn RigidBody::set_gravity_scale(
  self : RigidBody,
  scale : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  if self.forces.gravity_scale != scale {
    if wake_up && self.activation.sleeping {
      self.changes = self.changes.insert(RIGID_BODY_CHANGES_SLEEP)
      self.activation.sleeping = false
    }
    self.forces.gravity_scale = scale
  }
  self
}

///|
pub fn RigidBody::reset_forces(self : RigidBody, wake_up : Bool) -> RigidBody {
  if !vec2_equal(self.forces.user_force, @core.Vec2::zero()) {
    self.forces.user_force = @core.Vec2::zero()
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::reset_torques(self : RigidBody, wake_up : Bool) -> RigidBody {
  if self.forces.user_torque != 0.0F {
    self.forces.user_torque = 0.0F
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::add_force(
  self : RigidBody,
  force : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  if !vec2_equal(force, @core.Vec2::zero()) &&
    self.body_type is RigidBodyType::Dynamic {
    self.forces.user_force = self.forces.user_force.add(force)
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::add_torque(
  self : RigidBody,
  torque : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  if torque != 0.0F && self.body_type is RigidBodyType::Dynamic {
    self.forces.user_torque = self.forces.user_torque + torque
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::add_force_at_point(
  self : RigidBody,
  force : @core.Vec2,
  point : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  if !vec2_equal(force, @core.Vec2::zero()) &&
    self.body_type is RigidBodyType::Dynamic {
    self.forces = self.forces.apply_force_at_point(
      self.mass_props,
      force,
      point,
    )
    if wake_up {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::ccd(self : RigidBody) -> RigidBodyCcd {
  self.ccd
}

///|
pub fn RigidBody::enable_ccd(self : RigidBody, enabled : Bool) -> RigidBody {
  let ccd = self.ccd
  ccd.ccd_enabled = enabled
  self.ccd = ccd
  self
}

///|
pub fn RigidBody::is_ccd_enabled(self : RigidBody) -> Bool {
  self.ccd.ccd_enabled
}

///|
pub fn RigidBody::set_soft_ccd_prediction(
  self : RigidBody,
  prediction_distance : @core.Real,
) -> RigidBody {
  let ccd = self.ccd
  ccd.soft_ccd_prediction = prediction_distance
  self.ccd = ccd
  self
}

///|
pub fn RigidBody::soft_ccd_prediction(self : RigidBody) -> @core.Real {
  self.ccd.soft_ccd_prediction
}

///|
pub fn RigidBody::is_ccd_active(self : RigidBody) -> Bool {
  self.ccd.ccd_active
}

///|
pub fn RigidBody::mass_props(self : RigidBody) -> RigidBodyMassProps {
  self.mass_props
}

///|
pub fn RigidBody::mass(self : RigidBody) -> @core.Real {
  self.mass_props.local_mprops.mass
}

///|
pub fn RigidBody::inv_mass(self : RigidBody) -> @core.Real {
  self.mass_props.local_mprops.inv_mass
}

///|
pub fn RigidBody::inertia(self : RigidBody) -> @core.Real {
  self.mass_props.local_mprops.inertia
}

///|
pub fn RigidBody::inv_inertia(self : RigidBody) -> @core.Real {
  self.mass_props.local_mprops.inv_inertia
}

///|
pub fn RigidBody::center_of_mass(self : RigidBody) -> @core.Vec2 {
  self.mass_props.local_mprops.center_of_mass
}

///|
pub fn RigidBody::world_com(self : RigidBody) -> @core.Vec2 {
  self.mass_props.world_com
}

///|
pub fn RigidBody::wake_up(self : RigidBody, strong : Bool) -> RigidBody {
  if self.activation.sleeping {
    self.changes = self.changes.insert(RIGID_BODY_CHANGES_SLEEP)
  }
  self.activation = self.activation.wake_up(strong)
  self
}

///|
pub fn RigidBody::sleep(self : RigidBody) -> RigidBody {
  self.activation = self.activation.sleep()
  self.vels = RigidBodyVelocity::zero()
  self
}

///|
fn RigidBody::reset_internal_references(self : RigidBody) -> RigidBody {
  self.ids = RigidBodyIds::default()
  self
}

///|
pub fn RigidBody::translation(self : RigidBody) -> @core.Vec2 {
  self.position.position.translation
}

///|
pub fn RigidBody::rotation(self : RigidBody) -> @core.Rot2 {
  self.position.position.rotation
}

///|
pub fn RigidBody::set_translation(
  self : RigidBody,
  translation : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  let curr_rot = self.position.position.rotation
  let next_rot = self.position.next_position.rotation
  let same_curr = vec2_equal(self.position.position.translation, translation)
  let same_next = vec2_equal(
    self.position.next_position.translation,
    translation,
  )
  if !same_curr || !same_next {
    self.changes = self.changes.insert(RIGID_BODY_CHANGES_POSITION)
    self.position.position = @core.Isometry2::new(translation, curr_rot)
    self.position.next_position = @core.Isometry2::new(translation, next_rot)
    let mass_props = self.mass_props
    mass_props.world_com = self.position.position.transform_point(
      mass_props.local_mprops.center_of_mass,
    )
    self.mass_props = mass_props
    if wake_up && self.is_dynamic_or_kinematic() {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::set_rotation(
  self : RigidBody,
  rotation : @core.Rot2,
  wake_up : Bool,
) -> RigidBody {
  let curr_translation = self.position.position.translation
  let next_translation = self.position.next_position.translation
  let same_curr = rot2_equal(self.position.position.rotation, rotation)
  let same_next = rot2_equal(self.position.next_position.rotation, rotation)
  if !same_curr || !same_next {
    self.changes = self.changes.insert(RIGID_BODY_CHANGES_POSITION)
    self.position.position = @core.Isometry2::new(curr_translation, rotation)
    self.position.next_position = @core.Isometry2::new(
      next_translation, rotation,
    )
    self.mass_props.world_com = self.position.position.transform_point(
      self.mass_props.local_mprops.center_of_mass,
    )
    if wake_up && self.is_dynamic_or_kinematic() {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::set_position(
  self : RigidBody,
  position : @core.Isometry2,
  wake_up : Bool,
) -> RigidBody {
  let same_curr = vec2_equal(
      self.position.position.translation,
      position.translation,
    ) &&
    rot2_equal(self.position.position.rotation, position.rotation)
  let same_next = vec2_equal(
      self.position.next_position.translation,
      position.translation,
    ) &&
    rot2_equal(self.position.next_position.rotation, position.rotation)
  if !same_curr || !same_next {
    self.changes = self.changes.insert(RIGID_BODY_CHANGES_POSITION)
    self.position.position = position
    self.position.next_position = position
    let mass_props = self.mass_props
    mass_props.world_com = self.position.position.transform_point(
      mass_props.local_mprops.center_of_mass,
    )
    self.mass_props = mass_props
    if wake_up && self.is_dynamic_or_kinematic() {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::set_enabled(self : RigidBody, enabled : Bool) -> RigidBody {
  if enabled != self.enabled {
    if enabled {
      self.changes = RigidBodyChanges::all()
    } else {
      self.changes = self.changes.insert(RIGID_BODY_CHANGES_ENABLED_OR_DISABLED)
    }
    self.enabled = enabled
  }
  self
}

///|
pub fn RigidBody::clear_changes(self : RigidBody) -> RigidBody {
  self.changes = self.changes.remove(RIGID_BODY_CHANGES_ALL)
  self
}

///|
pub fn RigidBody::mark_local_mass_properties_changed(
  self : RigidBody,
) -> RigidBody {
  self.changes = self.changes.insert(RIGID_BODY_CHANGES_LOCAL_MASS_PROPERTIES)
  self
}

///|
pub fn RigidBody::position(self : RigidBody) -> @core.Isometry2 {
  self.position.position
}

///|
pub fn RigidBody::set_next_kinematic_translation(
  self : RigidBody,
  translation : @core.Vec2,
) -> RigidBody {
  if self.is_kinematic() {
    let next_rot = self.position.next_position.rotation
    self.position.next_position = @core.Isometry2::new(translation, next_rot)
    if !vec2_equal(self.position.position.translation, translation) {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::set_next_kinematic_rotation(
  self : RigidBody,
  rotation : @core.Rot2,
) -> RigidBody {
  if self.is_kinematic() {
    let next_translation = self.position.next_position.translation
    self.position.next_position = @core.Isometry2::new(
      next_translation, rotation,
    )
    if !rot2_equal(self.position.position.rotation, rotation) {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub fn RigidBody::set_next_kinematic_position(
  self : RigidBody,
  position : @core.Isometry2,
) -> RigidBody {
  if self.is_kinematic() {
    self.position.next_position = position
    if !vec2_equal(self.position.position.translation, position.translation) ||
      !rot2_equal(self.position.position.rotation, position.rotation) {
      self.wake_up(true) |> ignore
    }
  }
  self
}

///|
pub struct RigidBodyBuilder {
  mut position : @core.Isometry2
  mut linvel : @core.Vec2
  mut angvel : @core.Real
  mut gravity_scale : @core.Real
  mut linear_damping : @core.Real
  mut angular_damping : @core.Real
  body_type : RigidBodyType
  mut additional_mass : @core.Real
  mut additional_solver_iterations : Int
  mut can_sleep : Bool
  mut sleeping : Bool
  mut enabled : Bool
  mut ccd_enabled : Bool
  mut soft_ccd_prediction : @core.Real
  mut dominance_group : Int
}

///|
fn RigidBodyBuilder::new(body_type : RigidBodyType) -> RigidBodyBuilder {
  {
    position: @core.Isometry2::identity(),
    linvel: @core.Vec2::zero(),
    angvel: 0.0F,
    gravity_scale: 1.0F,
    linear_damping: 0.0F,
    angular_damping: 0.0F,
    body_type,
    additional_mass: 0.0F,
    additional_solver_iterations: 0,
    can_sleep: true,
    sleeping: false,
    enabled: true,
    ccd_enabled: false,
    soft_ccd_prediction: 0.0F,
    dominance_group: 0,
  }
}

///|
pub fn RigidBodyBuilder::dynamic() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::Dynamic)
}

///|
pub fn RigidBodyBuilder::fixed() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::Fixed)
}

///|
pub fn RigidBodyBuilder::kinematic_position_based() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::KinematicPositionBased)
}

///|
pub fn RigidBodyBuilder::kinematic_velocity_based() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::KinematicVelocityBased)
}

///|
pub fn RigidBodyBuilder::translation(
  self : RigidBodyBuilder,
  translation : @core.Vec2,
) -> RigidBodyBuilder {
  let rot = self.position.rotation
  self.position = @core.Isometry2::new(translation, rot)
  self
}

///|
pub fn RigidBodyBuilder::position(
  self : RigidBodyBuilder,
  position : @core.Isometry2,
) -> RigidBodyBuilder {
  self.position = position
  self
}

///|
pub fn RigidBodyBuilder::rotation(
  self : RigidBodyBuilder,
  rotation : @core.Rot2,
) -> RigidBodyBuilder {
  let translation = self.position.translation
  self.position = @core.Isometry2::new(translation, rotation)
  self
}

///|
pub fn RigidBodyBuilder::linvel(
  self : RigidBodyBuilder,
  linvel : @core.Vec2,
) -> RigidBodyBuilder {
  self.linvel = linvel
  self
}

///|
pub fn RigidBodyBuilder::angvel(
  self : RigidBodyBuilder,
  angvel : @core.Real,
) -> RigidBodyBuilder {
  self.angvel = angvel
  self
}

///|
pub fn RigidBodyBuilder::gravity_scale(
  self : RigidBodyBuilder,
  scale : @core.Real,
) -> RigidBodyBuilder {
  self.gravity_scale = scale
  self
}

///|
pub fn RigidBodyBuilder::linear_damping(
  self : RigidBodyBuilder,
  damping : @core.Real,
) -> RigidBodyBuilder {
  self.linear_damping = damping
  self
}

///|
pub fn RigidBodyBuilder::angular_damping(
  self : RigidBodyBuilder,
  damping : @core.Real,
) -> RigidBodyBuilder {
  self.angular_damping = damping
  self
}

///|
pub fn RigidBodyBuilder::additional_mass(
  self : RigidBodyBuilder,
  mass : @core.Real,
) -> RigidBodyBuilder {
  self.additional_mass = mass
  self
}

///|
pub fn RigidBodyBuilder::additional_solver_iterations(
  self : RigidBodyBuilder,
  additional_iterations : Int,
) -> RigidBodyBuilder {
  self.additional_solver_iterations = additional_iterations
  self
}

///|
pub fn RigidBodyBuilder::dominance_group(
  self : RigidBodyBuilder,
  group : Int,
) -> RigidBodyBuilder {
  self.dominance_group = group
  self
}

///|
pub fn RigidBodyBuilder::can_sleep(
  self : RigidBodyBuilder,
  can_sleep : Bool,
) -> RigidBodyBuilder {
  self.can_sleep = can_sleep
  self
}

///|
pub fn RigidBodyBuilder::sleeping(
  self : RigidBodyBuilder,
  sleeping : Bool,
) -> RigidBodyBuilder {
  self.sleeping = sleeping
  self
}

///|
pub fn RigidBodyBuilder::enabled(
  self : RigidBodyBuilder,
  enabled : Bool,
) -> RigidBodyBuilder {
  self.enabled = enabled
  self
}

///|
pub fn RigidBodyBuilder::ccd_enabled(
  self : RigidBodyBuilder,
  enabled : Bool,
) -> RigidBodyBuilder {
  self.ccd_enabled = enabled
  self
}

///|
pub fn RigidBodyBuilder::soft_ccd_prediction(
  self : RigidBodyBuilder,
  prediction_distance : @core.Real,
) -> RigidBodyBuilder {
  self.soft_ccd_prediction = prediction_distance
  self
}

///|
pub fn RigidBodyBuilder::build(self : RigidBodyBuilder) -> RigidBody {
  let pos = RigidBodyPosition::new(self.position, self.position)
  let activation = if self.can_sleep {
    RigidBodyActivation::active()
  } else {
    RigidBodyActivation::cannot_sleep()
  }
  let forces = RigidBodyForces::default()
  forces.gravity_scale = self.gravity_scale
  let mut rb = {
    ids: RigidBodyIds::default(),
    position: pos,
    body_type: self.body_type,
    dominance: RigidBodyDominance::new(self.dominance_group),
    enabled: self.enabled,
    activation,
    damping: RigidBodyDamping::{
      linear_damping: self.linear_damping,
      angular_damping: self.angular_damping,
    },
    vels: RigidBodyVelocity::{ linvel: self.linvel, angvel: self.angvel },
    forces,
    ccd: RigidBodyCcd::default(),
    mass_props: RigidBodyMassProps::default(),
    additional_mass: self.additional_mass,
    additional_solver_iterations: self.additional_solver_iterations,
    changes: RigidBodyChanges::all(),
  }
  rb = rb.enable_ccd(self.ccd_enabled)
  rb = rb.set_soft_ccd_prediction(self.soft_ccd_prediction)
  if self.can_sleep && self.sleeping {
    rb = rb.sleep()
  }
  rb
}

///|
pub struct RigidBodySet {
  bodies : Array[RigidBody?]
  generations : Array[Int]
  free_list : Array[Int]
  modified_bodies : Array[RigidBodyHandle]
}

///|
pub fn RigidBodySet::new() -> RigidBodySet {
  { bodies: [], generations: [], free_list: [], modified_bodies: [] }
}

///|
pub fn RigidBodySet::with_capacity(capacity : Int) -> RigidBodySet {
  capacity |> ignore
  RigidBodySet::new()
}

///|
pub fn RigidBodySet::len(self : RigidBodySet) -> Int {
  let mut count = 0
  for i in 0..<self.bodies.length() {
    if self.bodies[i] is Some(_) {
      count = count + 1
    }
  }
  count
}

///|
pub fn RigidBodySet::is_empty(self : RigidBodySet) -> Bool {
  self.len() == 0
}

///|
pub fn RigidBodySet::contains(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> Bool {
  self.get(handle) is Some(_)
}

///|
pub fn RigidBodySet::take_modified(
  self : RigidBodySet,
) -> Array[RigidBodyHandle] {
  let result : Array[RigidBodyHandle] = []
  for i in 0..<self.modified_bodies.length() {
    let handle = self.modified_bodies[i]
    result.push(handle)
    if handle.id >= 0 && handle.id < self.bodies.length() {
      if self.generations[handle.id] == handle.generation {
        if self.bodies[handle.id] is Some(body) {
          body.changes = body.changes.remove(RIGID_BODY_CHANGES_IN_MODIFIED_SET)
        }
      }
    }
  }
  self.modified_bodies.clear()
  result
}

///|
fn RigidBodySet::push_modified_unchecked(
  self : RigidBodySet,
  handle : RigidBodyHandle,
  body : RigidBody,
) -> Unit {
  body.changes = body.changes.insert(RIGID_BODY_CHANGES_IN_MODIFIED_SET)
  self.modified_bodies.push(handle)
}

///|
fn RigidBodySet::push_modified(
  self : RigidBodySet,
  handle : RigidBodyHandle,
  body : RigidBody,
) -> Unit {
  if !body.changes.contains(RIGID_BODY_CHANGES_IN_MODIFIED_SET) {
    self.push_modified_unchecked(handle, body)
  }
}

///|
pub fn RigidBodySet::insert(
  self : RigidBodySet,
  body : RigidBody,
) -> RigidBodyHandle {
  let body = body.reset_internal_references()
  body.changes = RigidBodyChanges::all()
  if self.free_list.pop() is Some(index) {
    self.bodies[index] = Some(body)
    let generation = self.generations[index]
    let handle = RigidBodyHandle::new(index, generation)
    if self.bodies[index] is Some(body_ref) {
      self.push_modified_unchecked(handle, body_ref)
    }
    handle
  } else {
    let index = self.bodies.length()
    self.bodies.push(Some(body))
    self.generations.push(0)
    let handle = RigidBodyHandle::new(index, 0)
    if self.bodies[index] is Some(body_ref) {
      self.push_modified_unchecked(handle, body_ref)
    }
    handle
  }
}

///|
pub fn RigidBodySet::get(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  if handle.id < 0 || handle.id >= self.bodies.length() {
    return None
  }
  if self.generations[handle.id] != handle.generation {
    return None
  }
  self.bodies[handle.id]
}

///|
pub fn RigidBodySet::get_mut(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  self.get_mut_internal_with_modification_tracking(handle)
}

///|
pub fn RigidBodySet::get_mut_internal(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  if handle.id < 0 || handle.id >= self.bodies.length() {
    return None
  }
  if self.generations[handle.id] != handle.generation {
    return None
  }
  self.bodies[handle.id]
}

///|
pub fn RigidBodySet::get_mut_internal_with_modification_tracking(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  if self.get_mut_internal(handle) is Some(body) {
    self.push_modified(handle, body)
    Some(body)
  } else {
    None
  }
}

///|
pub fn RigidBodySet::get_unknown_gen(
  self : RigidBodySet,
  id : Int,
) -> (RigidBody, RigidBodyHandle)? {
  if id < 0 || id >= self.bodies.length() {
    return None
  }
  if self.bodies[id] is Some(body) {
    let handle = RigidBodyHandle::new(id, self.generations[id])
    Some((body, handle))
  } else {
    None
  }
}

///|
pub fn RigidBodySet::get_unknown_gen_mut(
  self : RigidBodySet,
  id : Int,
) -> (RigidBody, RigidBodyHandle)? {
  if id < 0 || id >= self.bodies.length() {
    return None
  }
  if self.bodies[id] is Some(body) {
    let handle = RigidBodyHandle::new(id, self.generations[id])
    self.push_modified(handle, body)
    Some((body, handle))
  } else {
    None
  }
}

///|
pub fn RigidBodySet::get_pair_mut(
  self : RigidBodySet,
  handle1 : RigidBodyHandle,
  handle2 : RigidBodyHandle,
) -> (RigidBody?, RigidBody?) {
  if RigidBodyHandle::equals(handle1, handle2) {
    (self.get_mut(handle1), None)
  } else {
    (self.get_mut(handle1), self.get_mut(handle2))
  }
}

///|
pub fn RigidBodySet::iter(
  self : RigidBodySet,
) -> Array[(RigidBodyHandle, RigidBody)] {
  let result : Array[(RigidBodyHandle, RigidBody)] = []
  for i in 0..<self.bodies.length() {
    if self.bodies[i] is Some(body) {
      result.push((RigidBodyHandle::new(i, self.generations[i]), body))
    }
  }
  result
}

///|
pub fn RigidBodySet::iter_mut(
  self : RigidBodySet,
) -> Array[(RigidBodyHandle, RigidBody)] {
  self.modified_bodies.clear()
  let result : Array[(RigidBodyHandle, RigidBody)] = []
  for i in 0..<self.bodies.length() {
    if self.bodies[i] is Some(body) {
      let handle = RigidBodyHandle::new(i, self.generations[i])
      self.push_modified_unchecked(handle, body)
      result.push((handle, body))
    }
  }
  result
}

///|
pub fn RigidBodySet::remove(
  self : RigidBodySet,
  handle : RigidBodyHandle,
  islands : IslandManager,
  colliders : Unit,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
  remove_attached_colliders : Bool,
) -> RigidBody? {
  if handle.id < 0 || handle.id >= self.bodies.length() {
    islands |> ignore
    colliders |> ignore
    impulse_joints |> ignore
    multibody_joints |> ignore
    remove_attached_colliders |> ignore
    return None
  }
  if self.generations[handle.id] != handle.generation {
    islands |> ignore
    colliders |> ignore
    impulse_joints |> ignore
    multibody_joints |> ignore
    remove_attached_colliders |> ignore
    return None
  }
  if self.bodies[handle.id] is Some(body) {
    let ids = body.ids
    self.bodies[handle.id] = None
    self.generations[handle.id] = self.generations[handle.id] + 1
    self.free_list.push(handle.id)
    islands.remove_body_with_ids(self, handle, ids)
    colliders |> ignore
    remove_attached_colliders |> ignore
    impulse_joints.remove_joints_attached_to_rigid_body(handle) |> ignore
    multibody_joints.remove_joints_attached_to_rigid_body(handle)
    Some(body)
  } else {
    islands |> ignore
    colliders |> ignore
    impulse_joints |> ignore
    multibody_joints |> ignore
    remove_attached_colliders |> ignore
    None
  }
}

///|
fn body_type_to_int(body_type : RigidBodyType) -> Int {
  match body_type {
    RigidBodyType::Dynamic => 0
    RigidBodyType::Fixed => 1
    RigidBodyType::KinematicPositionBased => 2
    RigidBodyType::KinematicVelocityBased => 3
  }
}

///|
fn body_type_from_int(value : Int) -> RigidBodyType {
  if value == 1 {
    RigidBodyType::Fixed
  } else if value == 2 {
    RigidBodyType::KinematicPositionBased
  } else if value == 3 {
    RigidBodyType::KinematicVelocityBased
  } else {
    RigidBodyType::Dynamic
  }
}

///|
fn split_values(text : String, sep : String) -> Array[String] {
  let values : Array[String] = []
  for part in text.split(sep[:]) {
    let value = part.to_string()
    if value.length() > 0 {
      values.push(value)
    }
  }
  values
}

///|
fn parse_int_value(text : String) -> Int {
  let result : Result[Int, @strconv.StrConvError] = try? @strconv.parse_int(
    text[:],
    base=10,
  )
  if result is Ok(value) {
    value
  } else {
    0
  }
}

///|
fn parse_real_value(text : String) -> @core.Real {
  let result : Result[Double, @strconv.StrConvError] = try? @strconv.parse_double(
    text[:],
  )
  if result is Ok(value) {
    Float::from_double(value)
  } else {
    0.0F
  }
}

///|
fn parse_bool_value(text : String) -> Bool {
  text == "1"
}

///|
fn vec2_equal(left : @core.Vec2, right : @core.Vec2) -> Bool {
  left.x == right.x && left.y == right.y
}

///|
fn rot2_equal(left : @core.Rot2, right : @core.Rot2) -> Bool {
  left.sin == right.sin && left.cos == right.cos
}

///|
pub fn RigidBodySet::serialize(self : RigidBodySet) -> String {
  let sb = StringBuilder::new()
  sb.write_string("len=")
  sb.write_object(self.bodies.length())
  sb.write_char(';')
  sb.write_string("gens=")
  for i in 0..<self.generations.length() {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_object(self.generations[i])
  }
  sb.write_char(';')
  sb.write_string("free=")
  for i in 0..<self.free_list.length() {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_object(self.free_list[i])
  }
  sb.write_char(';')
  sb.write_string("bodies=")
  for i in 0..<self.bodies.length() {
    if i > 0 {
      sb.write_char('|')
    }
    if self.bodies[i] is Some(body) {
      let pos = body.position.position
      let next_pos = body.position.next_position
      sb.write_string("B,")
      sb.write_object(body_type_to_int(body.body_type))
      sb.write_char(',')
      sb.write_object(pos.translation.x)
      sb.write_char(',')
      sb.write_object(pos.translation.y)
      sb.write_char(',')
      sb.write_object(pos.rotation.angle())
      sb.write_char(',')
      sb.write_object(next_pos.translation.x)
      sb.write_char(',')
      sb.write_object(next_pos.translation.y)
      sb.write_char(',')
      sb.write_object(next_pos.rotation.angle())
      sb.write_char(',')
      sb.write_object(if body.enabled { 1 } else { 0 })
      sb.write_char(',')
      sb.write_object(if body.activation.sleeping { 1 } else { 0 })
      sb.write_char(',')
      sb.write_object(body.activation.normalized_linear_threshold)
      sb.write_char(',')
      sb.write_object(body.activation.angular_threshold)
      sb.write_char(',')
      sb.write_object(body.activation.time_until_sleep)
      sb.write_char(',')
      sb.write_object(body.activation.time_since_can_sleep)
      sb.write_char(',')
      sb.write_object(body.additional_mass)
      sb.write_char(',')
      sb.write_object(body.additional_solver_iterations)
      sb.write_char(',')
      sb.write_object(body.dominance.group)
    } else {
      sb.write_char('N')
    }
  }
  sb.to_string()
}

///|
pub fn RigidBodySet::deserialize(data : String) -> RigidBodySet {
  let mut len = 0
  let generations : Array[Int] = []
  let free_list : Array[Int] = []
  let bodies : Array[RigidBody?] = []
  for part in data.split(";"[:]) {
    let value = part.to_string()
    if value.strip_prefix("len="[:]) is Some(raw_view) {
      let raw = raw_view.to_string()
      len = parse_int_value(raw)
    } else if value.strip_prefix("gens="[:]) is Some(raw_view) {
      let raw = raw_view.to_string()
      let items = split_values(raw, ",")
      for item in items {
        generations.push(parse_int_value(item))
      }
    } else if value.strip_prefix("free="[:]) is Some(raw_view) {
      let raw = raw_view.to_string()
      let items = split_values(raw, ",")
      for item in items {
        free_list.push(parse_int_value(item))
      }
    } else if value.strip_prefix("bodies="[:]) is Some(raw_view) {
      let raw = raw_view.to_string()
      let entries = split_values(raw, "|")
      for entry in entries {
        if entry == "N" {
          bodies.push(None)
        } else if entry.strip_prefix("B,"[:]) is Some(entry_view) {
          let fields = split_values(entry_view.to_string(), ",")
          let body_type = body_type_from_int(
            if fields.length() > 0 {
              parse_int_value(fields[0])
            } else {
              0
            },
          )
          let tx = if fields.length() > 1 {
            parse_real_value(fields[1])
          } else {
            0.0F
          }
          let ty = if fields.length() > 2 {
            parse_real_value(fields[2])
          } else {
            0.0F
          }
          let rot = if fields.length() > 3 {
            parse_real_value(fields[3])
          } else {
            0.0F
          }
          let ntx = if fields.length() > 4 {
            parse_real_value(fields[4])
          } else {
            tx
          }
          let nty = if fields.length() > 5 {
            parse_real_value(fields[5])
          } else {
            ty
          }
          let nrot = if fields.length() > 6 {
            parse_real_value(fields[6])
          } else {
            rot
          }
          let enabled = if fields.length() > 7 {
            parse_bool_value(fields[7])
          } else {
            true
          }
          let activation = if fields.length() > 12 {
            let sleeping = if fields.length() > 8 {
              parse_bool_value(fields[8])
            } else {
              false
            }
            let normalized_linear_threshold = if fields.length() > 9 {
              parse_real_value(fields[9])
            } else {
              DEFAULT_SLEEP_LINEAR_THRESHOLD
            }
            let angular_threshold = if fields.length() > 10 {
              parse_real_value(fields[10])
            } else {
              DEFAULT_SLEEP_ANGULAR_THRESHOLD
            }
            let time_until_sleep = if fields.length() > 11 {
              parse_real_value(fields[11])
            } else {
              DEFAULT_TIME_UNTIL_SLEEP
            }
            let time_since_can_sleep = if fields.length() > 12 {
              parse_real_value(fields[12])
            } else {
              0.0F
            }
            let activation = RigidBodyActivation::active()
            activation.normalized_linear_threshold = normalized_linear_threshold
            activation.angular_threshold = angular_threshold
            activation.time_until_sleep = time_until_sleep
            activation.time_since_can_sleep = time_since_can_sleep
            activation.sleeping = sleeping
            activation
          } else {
            let can_sleep = if fields.length() > 8 {
              parse_bool_value(fields[8])
            } else {
              true
            }
            let sleeping = if fields.length() > 9 {
              parse_bool_value(fields[9])
            } else {
              false
            }
            let activation = if can_sleep {
              RigidBodyActivation::active()
            } else {
              RigidBodyActivation::cannot_sleep()
            }
            activation.sleeping = sleeping
            if sleeping {
              activation.time_since_can_sleep = activation.time_until_sleep
            }
            activation
          }
          let additional_mass_index = if fields.length() > 12 { 13 } else { 10 }
          let additional_mass = if fields.length() > additional_mass_index {
            parse_real_value(fields[additional_mass_index])
          } else {
            0.0F
          }
          let solver_index = if fields.length() > 12 { 14 } else { 11 }
          let additional_solver_iterations = if fields.length() > solver_index {
            parse_int_value(fields[solver_index])
          } else {
            0
          }
          let dominance_index = solver_index + 1
          let dominance_group = if fields.length() > dominance_index {
            parse_int_value(fields[dominance_index])
          } else {
            0
          }
          let position = @core.Isometry2::new(
            @core.Vec2::new(tx, ty),
            @core.Rot2::from_angle(rot),
          )
          let next_position = @core.Isometry2::new(
            @core.Vec2::new(ntx, nty),
            @core.Rot2::from_angle(nrot),
          )
          let rb_pos = RigidBodyPosition::new(position, next_position)
          let body : RigidBody = {
            ids: RigidBodyIds::default(),
            position: rb_pos,
            body_type,
            dominance: RigidBodyDominance::new(dominance_group),
            enabled,
            activation,
            damping: RigidBodyDamping::default(),
            vels: RigidBodyVelocity::zero(),
            forces: RigidBodyForces::default(),
            ccd: RigidBodyCcd::default(),
            mass_props: RigidBodyMassProps::default(),
            additional_mass,
            additional_solver_iterations,
            changes: RigidBodyChanges::all(),
          }
          bodies.push(Some(body))
        } else {
          bodies.push(None)
        }
      }
    }
  }
  while generations.length() < len {
    generations.push(0)
  }
  while bodies.length() < len {
    bodies.push(None)
  }
  { bodies, generations, free_list, modified_bodies: [] }
}
